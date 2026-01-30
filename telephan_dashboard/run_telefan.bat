@echo off
title Lancement TELEFAN Dashboard
setlocal

:: --- CONFIGURATION ---
set URL=http://localhost:5000
set WAIT_TIME=10

echo ======================================================
echo           LANCEMENT DU DASHBOARD TELEFAN
echo ======================================================

echo [1/3] Nettoyage de l'environnement Docker...
:: Arrete les conteneurs et nettoie les reseaux/orphelins
docker-compose down --remove-orphans

echo [2/3] Demarrage des services...
:: Note : On ne met PAS -d pour que le script attende l'arret des conteneurs
:: On lance le build et le demarrage en une fois
start /b docker-compose up --build

echo.
echo Attente de l'initialisation de MariaDB (%WAIT_TIME% secondes)...
timeout /t %WAIT_TIME% /nobreak > nul

echo [3/3] Ouverture automatique de l'interface web...
start %URL%

echo.
echo ======================================================
echo   ETAT : EN COURS D'EXECUTION
echo   ----------------------------------------------------
echo   - Pour eteindre : Utilisez le bouton rouge dans l'app
echo   - Ou faites Ctrl+C ici dans ce terminal
echo ======================================================
echo.