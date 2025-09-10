@echo off
:: Caminho do projeto
cd /d C:\chofer_motorista_clean

:: Mostra status antes de atualizar
echo ===========================
echo   STATUS DO PROJETO
echo ===========================
git status

:: Adiciona todos os arquivos
git add .

:: Cria commit com data/hora
set hora=%time:~0,2%-%time:~3,2%
set data=%date:~6,4%-%date:~3,2%-%date:~0,2%
git commit -m "Atualização automática em %data% %hora%"

:: Puxa alterações do repositório remoto
git pull origin main

:: Envia alterações para o repositório remoto
git push origin main

echo ===========================
echo   ATUALIZAÇÃO CONCLUÍDA!
echo ===========================
pause
