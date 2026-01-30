@echo off
title Lancement TELEFAN Dashboard
echo [1/2] Demarrage des conteneurs Docker...

:: Lance docker-compose en arriere-plan
docker-compose up -d

echo Attente du demarrage des services...
timeout /t 5 /nobreak > nul

echo [2/2] Ouverture de l'application web...
:: Ouvre l'URL dans le navigateur par defaut
start http://localhost:5000

echo Tout est pret !
pause