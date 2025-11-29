# Inglês 1000

Aplicativo de repetição espaçada baseado no método Anki, utilizando o algoritmo FSRS para otimização do aprendizado.

## 📋 Características

- ✅ **Importação de arquivos .apkg** do Anki
- ✅ **Algoritmo FSRS** (Free Spaced Repetition Scheduler) para otimização
- ✅ **Backend Supabase** para sincronização
- ✅ **Design simples e amigável**
- ✅ **Código open source** (GPL v3)

## 🏗️ Arquitetura

```
lib/
├── main.dart
├── core/
│   ├── license/              # Compliance GPL v3
│   └── config/               # Configurações
├── features/
│   ├── import/               # Importação .apkg
│   ├── study/                # Tela de estudo
│   └── home/                 # Tela inicial
├── models/                   # Modelos de dados
├── services/                 # Serviços (FSRS, APKG, Supabase)
└── utils/                    # Utilitários
```

## 🚀 Setup

### 1. Configurar Supabase

1. Crie um projeto no [Supabase](https://supabase.com)
2. Execute o script SQL em `supabase_schema.sql`
3. Configure as credenciais em `lib/core/config/app_config.dart`:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

### 2. Adicionar FSRS.js

1. Baixe `fsrs.js` de: https://github.com/open-spaced-repetition/fsrs.js
2. Coloque em `assets/js/fsrs.js`
3. Adicione ao `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/js/fsrs.js
   ```

### 3. Instalar dependências

```bash
flutter pub get
```

## 📦 Dependências Principais

- `supabase_flutter`: Backend e autenticação
- `flutter_js`: Executar FSRS.js
- `archive`: Descompactar arquivos .apkg
- `sqflite`: Ler banco SQLite do Anki
- `file_picker`: Selecionar arquivos .apkg

## 📄 Licença

Este projeto está licenciado sob **GPL v3**.

### Créditos

- **AnkiDroid**: Código adaptado de [AnkiDroid](https://github.com/ankidroid/Anki-Android) (GPL v3)
- **FSRS**: Algoritmo de [FSRS](https://github.com/open-spaced-repetition/fsrs4anki) (MIT)

Veja `LICENSE` para mais detalhes.

## 🔧 Desenvolvimento

### Estrutura de Dados

O app utiliza a mesma estrutura de dados do Anki:
- **Notes**: Conteúdo base dos flashcards
- **Cards**: Instâncias de revisão
- **Review Logs**: Histórico de revisões
- **Decks**: Baralhos de cards

### Algoritmo FSRS

O algoritmo FSRS calcula automaticamente:
- **Difficulty**: Dificuldade do card (0-1)
- **Stability**: Estabilidade da memória em dias
- **Retrievability**: Probabilidade de recall (0-1)
- **Interval**: Próximo intervalo de revisão

## 📱 Uso

1. **Importar Deck**: Selecione um arquivo .apkg do Anki
2. **Estudar**: Revise os cards usando repetição espaçada
3. **Avaliar**: Use os botões (Novamente, Difícil, Bom, Fácil)

## 🤝 Contribuindo

Este projeto é open source. Contribuições são bem-vindas!

## 📞 Suporte

Para questões ou problemas, abra uma issue no repositório.
