# 📊 PROJET-QLIO : Dashboard Industriel TELEFAN

**TELEFAN** est une application de tableau de bord industriel développée avec **Flask** et **MariaDB**. Elle permet de visualiser en temps réel les indicateurs de performance (KPI) et les consommations énergétiques d'un parc de machines. 🚀

---

## ⚙️ Installation et Lancement

Pour faire fonctionner l'application sur votre poste, suivez ces étapes chronologiques :

### 1. Récupérer le projet (Git)
Ouvrez un terminal (PowerShell ou Bash) et exécutez les commandes suivantes pour cloner le dépôt et accéder au dossier du projet :

```bash
# Cloner le dépôt complet
git clone [https://github.com/okanmin/PROJET-QLIO.git](https://github.com/okanmin/PROJET-QLIO.git)

# Se déplacer dans le dossier du dashboard
cd PROJET-QLIO/telephan_dashboard
```

## 🚀 Guide de Lancement Rapide

Pour faire fonctionner l'application sur votre poste, suivez ces deux étapes :

1.  **Démarrer Docker** : Ouvrez l'application **Docker Desktop** et assurez-vous que le moteur est bien en cours d'exécution.
2.  **Lancer l'automatisation** : Double-cliquez sur le fichier `run_telefan.bat` à la racine du projet.
    * *Ce script se charge de construire les images et de monter les conteneurs automatiquement via Docker Compose.*

L'application sera ensuite accessible à l'adresse suivante : [http://localhost:5000](http://localhost:5000)

---

## 🛠️ Stack Technique et Architecture

L'infrastructure est entièrement conteneurisée pour garantir la stabilité de l'environnement :

* **Backend** : Python 3.11 avec Flask et SQLAlchemy.
* **Base de Données** : MariaDB (Schéma principal : `MES4_Analysis`).
* **Design** : Interface moderne en **Glassmorphism** (fond sombre, cartes avec flou de transparence) gérée via `style.css`.
* **Outils** : phpMyAdmin intégré pour la gestion SQL http://localhost:8080

## 📁 Structure du Code Source

```plaintext
telephan_dashboard/
├── app/
│   ├── static/          # Fichiers CSS (style.css)
│   ├── templates/       # Fichiers HTML (base.html, home.html)
│   ├── auth.py          # Gestion des routes et requêtes SQL
│   └── __init__.py      # Initialisation Flask et SQLAlchemy
├── scripts_sql/         # Scripts d'initialisation de la BDD MariaDB
├── Dockerfile           # Configuration de l'image Web
└── docker-compose.yml   # Orchestration des conteneurs


