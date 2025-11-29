# Guia de Setup - Inglês 1000

## ✅ Arquitetura Criada

A estrutura básica do aplicativo foi criada com sucesso! Aqui está o que foi implementado:

### 📁 Estrutura de Pastas

```
lib/
├── main.dart                          # ✅ Atualizado com Supabase
├── core/
│   ├── license/
│   │   ├── license_info.dart         # ✅ Informações de licença
│   │   └── about_screen.dart          # ✅ Tela "Sobre"
│   └── config/
│       └── app_config.dart            # ✅ Configurações do app
├── features/
│   ├── import/
│   │   └── import_screen.dart         # ✅ Tela de importação .apkg
│   ├── study/
│   │   └── study_screen.dart          # ✅ Tela de estudo
│   └── home/
│       └── home_screen.dart           # ✅ Tela inicial (atualizada)
├── models/
│   ├── card.dart                      # ✅ Modelo Card
│   ├── note.dart                      # ✅ Modelo Note
│   └── review_log.dart                # ✅ Modelo ReviewLog
├── services/
│   ├── fsrs_service.dart              # ✅ Serviço FSRS
│   ├── apkg_service.dart              # ✅ Serviço importação .apkg
│   └── supabase_service.dart          # ✅ Serviço Supabase
└── utils/
    └── date_utils.dart                # ✅ Utilitários de data
```

### 📄 Arquivos de Configuração

- ✅ `LICENSE` - Licença GPL v3
- ✅ `supabase_schema.sql` - Schema do banco de dados
- ✅ `pubspec.yaml` - Dependências atualizadas
- ✅ `README.md` - Documentação
- ✅ `.gitignore` - Arquivos ignorados

## 🚀 Próximos Passos

### 1. Configurar Supabase

1. Acesse [Supabase](https://supabase.com) e crie um projeto
2. Vá em **SQL Editor** e execute o conteúdo de `supabase_schema.sql`
3. Copie a **URL** e **Anon Key** do projeto
4. Atualize `lib/core/config/app_config.dart`:
   ```dart
   static const String supabaseUrl = 'https://seu-projeto.supabase.co';
   static const String supabaseAnonKey = 'sua-anon-key-aqui';
   ```

### 2. Adicionar FSRS.js

1. Baixe `fsrs.js` de: https://github.com/open-spaced-repetition/fsrs.js
2. Crie a pasta `assets/js/` se não existir
3. Coloque `fsrs.js` em `assets/js/fsrs.js`
4. Atualize `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/js/fsrs.js
   ```

### 3. Instalar Dependências

```bash
flutter pub get
```

### 4. Completar Implementações

#### a) Integração Supabase no Import

Edite `lib/features/import/import_screen.dart` e complete a função de salvamento:

```dart
// Após importar .apkg, salvar no Supabase
final supabaseService = SupabaseService(Supabase.instance.client);

// Criar deck
final deckId = await supabaseService.createDeck('Deck Importado');

// Salvar notas e cards
for (final note in importResult.notes) {
  // Converter AnkiNote para Note e salvar
}
```

#### b) Carregar Cards no Study Screen

Edite `lib/features/study/study_screen.dart`:

```dart
Future<void> _loadNextCard() async {
  final supabaseService = SupabaseService(Supabase.instance.client);
  final dueCards = await supabaseService.getDueCards();
  
  if (dueCards.isNotEmpty) {
    setState(() {
      _currentCard = dueCards.first;
      // Carregar note associado
    });
  }
}
```

#### c) Inicializar FSRS

No `main.dart`, adicione:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(...);
  
  // Inicializar FSRS
  await FsrsService().initialize();
  
  runApp(const MyApp());
}
```

## 🧪 Testar

1. Execute o app: `flutter run`
2. Teste a importação de um arquivo .apkg
3. Verifique se os cards aparecem na tela de estudo
4. Teste responder um card e verificar se o FSRS calcula corretamente

## 📝 Notas Importantes

### Compliance GPL v3

✅ Todos os arquivos adaptados do AnkiDroid incluem:
- Cabeçalho de copyright
- Referência ao código original
- Link para o repositório do AnkiDroid

### Estrutura de Dados

O schema do Supabase segue a estrutura do Anki:
- **decks**: Baralhos
- **notes**: Conteúdo base
- **cards**: Instâncias de revisão
- **review_logs**: Histórico
- **media_files**: Arquivos de mídia

### FSRS

O algoritmo FSRS está implementado via `flutter_js` executando `fsrs.js`. 
O serviço inclui um fallback simplificado caso o JS falhe.

## 🐛 Troubleshooting

### Erro ao importar .apkg
- Verifique se o arquivo é válido
- Confira os logs no console

### FSRS não funciona
- Verifique se `fsrs.js` está em `assets/js/`
- Confira se está no `pubspec.yaml`

### Supabase não conecta
- Verifique URL e Anon Key
- Confira se o schema foi executado
- Verifique RLS policies

## 📚 Recursos

- [AnkiDroid](https://github.com/ankidroid/Anki-Android)
- [FSRS](https://github.com/open-spaced-repetition/fsrs4anki)
- [Supabase Docs](https://supabase.com/docs)

