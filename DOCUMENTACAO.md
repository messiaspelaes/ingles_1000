# Inglês 1000 — Documentação do App

Aplicativo Flutter 100% offline para aprender as **1000 frases mais comuns em inglês**, baseado no método de **repetição espaçada FSRS** (Free Spaced Repetition Scheduler), inspirado no AnkiDroid.

---

## Sumário

- [Visão Geral](#visão-geral)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Telas](#telas)
- [Modelos de Dados](#modelos-de-dados)
- [Serviços](#serviços)
- [Widgets](#widgets)
- [Banco de Dados Local](#banco-de-dados-local)
- [Algoritmo FSRS](#algoritmo-fsrs)
- [Como adicionar um novo deck](#como-adicionar-um-novo-deck)

---

## Visão Geral

| Item | Detalhe |
|------|---------|
| Plataforma | Android / iOS (Flutter) |
| Armazenamento | 100% local — SQLite via `sqflite` |
| Algoritmo | FSRS nativo em Dart (pacote `fsrs`) |
| Fonte dos dados | Arquivo `.apkg` embutido em `assets/decks/` |
| Autenticação | Nenhuma — sem login |
| Conexão | Não necessária (completamente offline) |

---

## Estrutura do Projeto

```
lib/
├── main.dart                    # Ponto de entrada
├── home_screen.dart             # Tela principal / menu
│
├── features/
│   ├── study/
│   │   └── study_screen.dart    # Tela de estudo/revisão
│   └── progress/
│       └── progress_screen.dart # Tela de estatísticas
│
├── models/
│   ├── card.dart                # Modelo do card + enums
│   ├── note.dart                # Modelo da nota (conteúdo)
│   ├── deck.dart                # Modelo do deck
│   └── review_log.dart          # Modelo do histórico de revisão
│
├── services/
│   ├── apkg_service.dart        # Importação de arquivos .apkg
│   ├── database_service.dart    # CRUD SQLite local
│   └── fsrs_service.dart        # Cálculo do próximo intervalo FSRS
│
├── core/
│   ├── widgets/
│   │   └── anki_content.dart    # Widget de conteúdo (texto + áudio)
│   ├── config/
│   │   └── app_config.dart      # Configurações globais
│   └── license/
│       └── about_screen.dart    # Tela Sobre / Licenças
│
├── utils/
│   └── date_utils.dart          # Utilitários de data (conversão Anki)
│
assets/
└── decks/
    └── ingles_1000.apkg         # Deck padrão embutido no app
```

---

## Telas

### `home_screen.dart` — Menu Principal

Ponto de entrada do app após o `main.dart`. Responsável por:

- **Auto-importação**: Na primeira execução (banco vazio), importa automaticamente o deck `assets/decks/ingles_1000.apkg` para o SQLite local, incluindo todas as notas, cards e arquivos de áudio MP3
- **Navegação**: Botões para acessar "Começar a Estudar", "Meu Progresso" e "Sobre"

**Funções principais:**

| Função | Descrição |
|--------|-----------|
| `_checkAndAutoImport()` | Verifica se o banco está vazio; se sim, dispara a importação do deck padrão |
| `_importDefaultDeck()` | Lê o `.apkg` dos assets, cria o deck no SQLite, salva notas, cards e arquivos de áudio em disco |

---

### `study_screen.dart` — Tela de Estudo

Tela principal de aprendizado. Implementa o fluxo FSRS completo.

**Fluxo da sessão:**
1. No início, carrega as filas de cards da sessão (`_initSession`)
2. Revisões aparecem primeiro, depois os novos
3. O usuário vê a frente do card → toca "Mostrar Resposta" → avalia com um dos 4 botões
4. O algoritmo FSRS calcula o próximo intervalo e a sessão se encerra quando ambas as filas ficam vazias

**Funções principais:**

| Função | Descrição |
|--------|-----------|
| `_initSession()` | Carrega as filas de revisão (todos os devidos) e novos (até 10/dia) no início da sessão |
| `_showNextCard()` | Pega o próximo card da fila (revisão tem prioridade) e atualiza a UI |
| `_answerCard(rating)` | Processa a resposta: calcula FSRS, salva card atualizado, salva ReviewLog, decrementa contador, chama próximo |

**Limites:**

| Tipo | Comportamento |
|------|--------------|
| Novos | Máximo 10 por dia (configurado em `_limitNovos`) |
| Revisões | Sem limite — todos os cards devidos no dia são apresentados |

**Contadores:**
- Decrementam em tempo real conforme as respostas são dadas
- `Novos: X` → decrementa ao responder um card novo
- `Revisão: X` → decrementa ao responder um card de revisão

---

### `progress_screen.dart` — Tela de Progresso

Exibe estatísticas gerais do aprendizado.

**Métricas exibidas:**

| Métrica | Fonte |
|---------|-------|
| Total de Cards | Contagem total na tabela `cards` |
| Cards para Revisar | Novos + devidos hoje |
| Revisados Hoje | Cards com `last_review_at` no dia atual |

Suporta **pull-to-refresh** para atualizar os dados.

---

### `about_screen.dart` — Sobre / Licenças

Exibe informações sobre o app, créditos e licenças (GPL v3, AnkiDroid).

---

## Modelos de Dados

### `Card` (`card.dart`)

Representa um flashcard individual com seu estado de agendamento FSRS.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | String | ID único |
| `noteId` | String | Referência à nota com o conteúdo |
| `deckId` | String | Referência ao deck |
| `queueType` | CardQueueType | Estado atual: NEW / LEARNING / REVIEW / RELEARNING |
| `fsrsDifficulty` | double | Dificuldade FSRS (0–1) |
| `fsrsStability` | double | Estabilidade em dias |
| `fsrsRetrievability` | double | Probabilidade de recall (0–1) |
| `dueDate` | DateTime | Data da próxima revisão |
| `intervalDays` | int | Intervalo atual em dias |
| `reviewsCount` | int | Total de revisões realizadas |
| `lapsesCount` | int | Total de esquecimentos |

**Enums:**

```
CardQueueType: newCard | learning | review | relearning
CardRating:    again(1) | hard(2) | good(3) | easy(4)
```

---

### `Note` (`note.dart`)

Conteúdo base do flashcard. Um note pode gerar múltiplos cards.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `fields` | List\<String\> | Campos do card (field[0] = frente, field[1] = verso) |
| `frontField` | String (getter) | Primeiro campo — exibido na frente do card |
| `backField` | String (getter) | Segundo campo — exibido no verso do card |
| `tags` | List\<String\> | Tags para categorização |

> Os campos podem conter tags de áudio no formato `[sound:arquivo.mp3]`, que são processadas automaticamente pelo widget `AnkiContent`.

---

### `Deck` (`deck.dart`)

Agrupa notas e cards em uma coleção.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | String | ID único |
| `name` | String | Nome do deck |
| `description` | String? | Descrição opcional |

---

### `ReviewLog` (`review_log.dart`)

Histórico completo de cada revisão realizada. Usado para calcular os contadores diários e para análise de progresso.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `cardId` | String | Card que foi revisado |
| `rating` | CardRating | Resposta dada (again/hard/good/easy) |
| `intervalBefore` | int? | Intervalo antes da revisão |
| `intervalAfter` | int? | Intervalo calculado após a revisão |
| `timeTakenMs` | int | Tempo gasto na revisão (ms) |
| `fsrsDifficultyBefore/After` | double? | Estado FSRS antes e depois |
| `reviewedAt` | DateTime | Momento da revisão |

---

## Serviços

### `apkg_service.dart` — Importação de Decks

Lê e processa arquivos `.apkg` do Anki.

> Um `.apkg` é um arquivo ZIP contendo:
> - `collection.anki2`: banco SQLite com notas, cards e configurações
> - `media`: JSON mapeando IDs numéricos → nomes reais dos arquivos (`{"0": "audio.mp3", ...}`)
> - Arquivos numerados ("0", "1", "2"...): os arquivos de mídia propriamente ditos

| Função | Descrição |
|--------|-----------|
| `importApkg(path)` | Importa de um arquivo no sistema de arquivos |
| `importApkgFromAsset(assetPath)` | Importa de um asset embutido no app |
| `importApkgFromBytes(bytes)` | Importa de bytes em memória (base para os outros) |
| `_readNotes(db)` | Lê a tabela `notes` do SQLite do Anki |
| `_readCards(db)` | Lê a tabela `cards` do SQLite do Anki |
| `_readMedia(archive)` | Extrai arquivos de mídia do ZIP usando o mapa JSON |

**Retorna** `ApkgImportResult` com `notes`, `cards` e `mediaFiles`.

---

### `database_service.dart` — Banco de Dados Local

Gerencia o banco SQLite local do app (`ingles1000.db`). Singleton — uma única instância em todo o app.

**Tabelas:**

| Tabela | Conteúdo |
|--------|---------|
| `decks` | Decks importados |
| `notes` | Notas com conteúdo dos cards |
| `cards` | Cards com estado FSRS e agendamento |
| `review_logs` | Histórico de todas as revisões |
| `media_files` | Referências aos arquivos de mídia (metadados) |

**Funções principais:**

| Função | Descrição |
|--------|-----------|
| `getNewCards({limit})` | Retorna cards com `queue_type = NEW`, ordenados por data de criação |
| `getReviewCards({limit})` | Retorna cards devidos (todos os tipos exceto NEW), ordenados por `due_date` |
| `saveCard(card)` | Insert ou update de um card (upsert) |
| `saveNote(note)` | Insert ou update de uma nota |
| `saveReviewLog(log)` | Insere um novo registro de revisão |
| `getStudiedNewCardsTodayCount()` | Conta cards novos estudados hoje (via review_logs com `interval_before = 0`) |
| `getStudiedReviewCardsTodayCount()` | Conta revisões feitas hoje (via review_logs com `interval_before > 0`) |
| `getReviewedTodayCount()` | Total de cards com `last_review_at` hoje |
| `getTotalCardsCount()` | Contagem total de cards no banco |

---

### `fsrs_service.dart` — Algoritmo de Repetição Espaçada

Calcula o próximo intervalo de revisão usando o pacote oficial **FSRS** nativo em Dart.

| Função | Descrição |
|--------|-----------|
| `initialize()` | Inicializa o serviço FSRS |
| `calculateNextState(card, rating, now)` | Retorna `FsrsResult` com difficulty, stability, intervalDays e dueDate |

**Fallback:** Se o cálculo do pacote falhar, usa um cálculo simplificado baseado em SM-2:

| Rating | Comportamento |
|--------|--------------|
| Again (1) | Intervalo = 1 dia, dificuldade aumenta |
| Hard (2) | Intervalo = stability × 1.2 |
| Good (3) | Intervalo = stability × 2.5 |
| Easy (4) | Intervalo = stability × 4.0, dificuldade diminui |

---

## Widgets

### `anki_content.dart` — Widget de Conteúdo do Card

Processa e exibe o conteúdo de um campo do Anki, suportando texto e áudio.

**Funcionalidades:**
- Detecta tags `[sound:arquivo.mp3]` no conteúdo via regex
- Exibe um botão de play quando há áudio detectado
- Remove a tag `[sound:...]` do texto exibido, mostrando apenas as palavras
- Reproduz o áudio a partir de `documents/media/{deckId}/arquivo.mp3`
- **Fallback de busca**: se não encontrar o arquivo no deck atual, procura em todas as pastas de mídia disponíveis

| Propriedade | Descrição |
|-------------|-----------|
| `content` | Texto cru do campo (pode conter `[sound:...]`) |
| `deckId` | ID do deck para localizar os arquivos de áudio |
| `style` | Estilo do texto exibido |

---

## Banco de Dados Local

O banco SQLite é criado automaticamente no diretório de documentos do dispositivo em `ingles1000.db`.

Os **arquivos de áudio** são salvos em:
```
documents/media/{deckId}/arquivo.mp3
```

O banco **persiste entre sessões** — o progresso não é perdido ao fechar o app.

---

## Algoritmo FSRS

O FSRS (Free Spaced Repetition Scheduler) agenda cada card individualmente com base em três parâmetros fundamentais. Este app utiliza o pacote oficial `fsrs` nativo em Dart para estes cálculos.

| Parâmetro | Significado |
|-----------|-------------|
| **Difficulty** (0–1) | Quão difícil o card é para o usuário |
| **Stability** (dias) | Por quantos dias a memória se mantém sem revisão |
| **Retrievability** (0–1) | Probabilidade atual de lembrar o card |

**Regras de sessão:**
- **10 novos por dia** (fixo)
- **Revisões sem limite** — todos os cards que atingiram o `due_date` são apresentados
- **Prioridade**: revisões aparecem antes dos novos na sessão
- **Dia 1**: apenas novos cards (nenhuma revisão ainda existe)

---

## Como adicionar um novo deck

1. Adicione o arquivo `.apkg` em `assets/decks/`
2. Declare o asset no `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/decks/ingles_1000.apkg
       - assets/decks/novo_deck.apkg   # adicionar aqui
   ```
3. No `home_screen.dart`, dentro de `_importDefaultDeck()`, carregue o novo arquivo usando `_apkgService.importApkgFromAsset('assets/decks/novo_deck.apkg')`
4. Recompile o app
