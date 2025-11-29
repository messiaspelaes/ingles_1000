@echo off
echo Inicializando Git e enviando para GitHub...

cd /d "C:\Users\messi\StudioProjects\ingles1000"

echo.
echo 1. Inicializando Git...
git init

echo.
echo 2. Adicionando arquivos...
git add .

echo.
echo 3. Criando commit inicial...
git commit -m "Initial commit: App de repeticao espacada baseado em Anki com FSRS"

echo.
echo 4. Adicionando remote do GitHub...
git remote add origin https://github.com/messiaspelaes/ingles_1000.git

echo.
echo 5. Renomeando branch para main...
git branch -M main

echo.
echo 6. Enviando para GitHub...
git push -u origin main

echo.
echo Concluido! Projeto enviado para GitHub.
pause

