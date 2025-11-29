-- ============================================================================
-- Schema para App de Repetição Espaçada (Baseado em Anki)
-- Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
-- ============================================================================

-- Tabela de Decks (Baralhos)
CREATE TABLE decks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Notas (Notes) - Conteúdo base dos flashcards
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID REFERENCES decks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Campos do card (JSON array de strings)
    -- Ex: ["Hello", "Olá", "audio.mp3"]
    fields JSONB NOT NULL,
    
    -- Tags
    tags TEXT[] DEFAULT '{}',
    
    -- Modelo/Template (ex: "Basic", "Basic (and reversed card)")
    model_name TEXT NOT NULL DEFAULT 'Basic',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Metadata do Anki (se importado)
    anki_guid TEXT, -- GUID original do Anki
    anki_note_id BIGINT -- ID original do Anki (se importado)
);

-- Tabela de Cards - Instâncias de revisão
CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
    deck_id UUID REFERENCES decks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Estado do card (NEW, LEARNING, REVIEW, RELEARNING)
    -- Baseado em AnkiDroid QueueType
    queue_type TEXT NOT NULL DEFAULT 'NEW' CHECK (queue_type IN ('NEW', 'LEARNING', 'REVIEW', 'RELEARNING')),
    
    -- FSRS Parameters (Free Spaced Repetition Scheduler)
    -- Adaptado de AnkiDroid FSRS implementation
    fsrs_difficulty REAL DEFAULT 0.3,      -- Dificuldade (0-1)
    fsrs_stability REAL DEFAULT 0.0,      -- Estabilidade em dias
    fsrs_retrievability REAL DEFAULT 1.0, -- Probabilidade de recall (0-1)
    
    -- Scheduling (compatível com Anki)
    due_date TIMESTAMP WITH TIME ZONE NOT NULL, -- Próxima revisão
    interval_days INTEGER DEFAULT 0,             -- Intervalo atual em dias
    ease_factor REAL DEFAULT 2.5,               -- Fator de facilidade (legado SM-2)
    
    -- Estatísticas
    reviews_count INTEGER DEFAULT 0,      -- Total de revisões
    lapses_count INTEGER DEFAULT 0,       -- Quantas vezes esqueceu
    last_review_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Metadata do Anki (se importado)
    anki_card_id BIGINT, -- ID original do Anki
    anki_due BIGINT      -- Due original do Anki
);

-- Tabela de Review Log (Histórico de revisões)
-- Baseado em AnkiDroid revlog
CREATE TABLE review_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Rating (AGAIN=1, HARD=2, GOOD=3, EASY=4)
    -- Baseado em AnkiDroid Rating enum
    rating INTEGER NOT NULL CHECK (rating IN (1, 2, 3, 4)),
    
    -- Intervalo antes e depois da revisão
    interval_before INTEGER, -- Intervalo antes (em dias)
    interval_after INTEGER,  -- Intervalo depois (em dias)
    
    -- Tempo gasto na revisão (milissegundos)
    time_taken_ms INTEGER DEFAULT 0,
    
    -- FSRS state antes e depois
    fsrs_difficulty_before REAL,
    fsrs_stability_before REAL,
    fsrs_difficulty_after REAL,
    fsrs_stability_after REAL,
    
    -- Timestamp
    reviewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Mídia (imagens, áudios)
CREATE TABLE media_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    deck_id UUID REFERENCES decks(id) ON DELETE CASCADE,
    
    filename TEXT NOT NULL,
    file_path TEXT NOT NULL, -- Path no storage do Supabase
    file_size BIGINT,
    mime_type TEXT,
    
    -- Metadata do Anki
    anki_filename TEXT, -- Nome original do Anki
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_cards_user_deck ON cards(user_id, deck_id);
CREATE INDEX idx_cards_due_date ON cards(due_date) WHERE queue_type != 'NEW';
CREATE INDEX idx_cards_queue_type ON cards(queue_type, due_date);
CREATE INDEX idx_notes_deck ON notes(deck_id);
CREATE INDEX idx_review_logs_card ON review_logs(card_id);
CREATE INDEX idx_review_logs_user_date ON review_logs(user_id, reviewed_at);

-- RLS (Row Level Security) - Segurança Supabase
ALTER TABLE decks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE media_files ENABLE ROW LEVEL SECURITY;

-- Políticas RLS: Usuários só veem seus próprios dados
CREATE POLICY "Users can view own decks" ON decks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own decks" ON decks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own decks" ON decks
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own notes" ON notes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notes" ON notes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notes" ON notes
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own cards" ON cards
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cards" ON cards
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cards" ON cards
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own review_logs" ON review_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own review_logs" ON review_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_decks_updated_at BEFORE UPDATE ON decks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cards_updated_at BEFORE UPDATE ON cards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

