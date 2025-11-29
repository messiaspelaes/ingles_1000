# Comandos Git para Enviar ao GitHub

Execute estes comandos no terminal PowerShell ou CMD, dentro da pasta do projeto:

```bash
# 1. Navegar para a pasta do projeto
cd C:\Users\messi\StudioProjects\ingles1000

# 2. Inicializar Git (se ainda não estiver inicializado)
git init

# 3. Adicionar todos os arquivos
git add .

# 4. Criar commit inicial
git commit -m "Initial commit: App de repetição espaçada baseado em Anki com FSRS"

# 5. Adicionar remote do GitHub
git remote add origin https://github.com/messiaspelaes/ingles_1000.git

# 6. Renomear branch para main
git branch -M main

# 7. Enviar para GitHub
git push -u origin main
```

## Alternativa: Executar o script

Você também pode executar o arquivo `git_setup.bat` que foi criado na raiz do projeto.

## Nota

Se você já tiver um remote configurado, use:
```bash
git remote set-url origin https://github.com/messiaspelaes/ingles_1000.git
```

Se precisar fazer login no GitHub, o Git pode pedir suas credenciais durante o `git push`.

