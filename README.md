# Data Platform MLOps

Plateforme data complète avec Docker Compose pour le MLOps.

## Services

| Service | Description | Port | URL |
|---------|-------------|------|-----|
| PostgreSQL | Base de données | 5432 | - |
| Airflow | Orchestration des pipelines | 8080 | http://localhost:8080 |
| Spark | Traitement de données | 8081 | http://localhost:8081 |
| Jupyter | Notebooks Data Science | 8888 | http://localhost:8888 |
| MLflow | Tracking ML | 5001 | http://localhost:5001 |
| MinIO | Stockage S3 | 9001 | http://localhost:9001 |

## Identifiants

| Service | Username | Password |
|---------|----------|----------|
| Airflow | admin | admin |
| MinIO | minioadmin | minioadmin |

## Etape 1 : Lancement rapide

```bash
# Créer les dossiers
mkdir -p airflow/dags spark/jobs notebooks

# Lancer la plateforme
docker compose up -d

# Vérifier le statut
docker compose ps
```

## Etape 2 : Docker Secrets (Swarm)

Les secrets permettent de sécuriser les mots de passe au lieu de les mettre en clair.

### 2.1 Initialiser Docker Swarm

```bash
docker swarm init
```

### 2.2 Créer les secrets

```bash
# Secret pour PostgreSQL
echo "airflow_secure_password" | docker secret create postgres_password -

# Secrets pour MinIO
echo "minio_access_key" | docker secret create minio_access_key -
echo "minio_secret_key" | docker secret create minio_secret_key -
```

### 2.3 Vérifier les secrets

```bash
docker secret ls
```

### 2.4 Déployer avec Swarm

```bash
# Arrêter docker compose classique
docker compose down

# Déployer en mode Swarm
docker stack deploy -c docker-compose.yml data_platform

# Vérifier les services
docker stack services data_platform
```

### 2.5 Commandes utiles Swarm

```bash
# Voir les logs d'un service
docker service logs data_platform_airflow

# Arrêter la stack
docker stack rm data_platform

# Quitter Swarm
docker swarm leave --force
```

## Etape 3 : Pipeline Data (Airflow + Spark)

### 3.1 DAG Airflow

Le fichier `airflow/dags/data_pipeline.py` définit un pipeline ETL :
- **extract** : Extraction des données
- **transform** : Transformation avec Spark
- **load** : Chargement des résultats

### 3.2 Job Spark

Le fichier `spark/jobs/transform_job.py` :
- Lit un fichier CSV (`/data/input.csv`)
- Supprime les lignes avec des valeurs null
- Ecrit le résultat en Parquet (`/data/output`)

### 3.3 Tester le job Spark

```bash
docker exec $(docker ps -q -f name=data_platform_spark) /opt/spark/bin/spark-submit /opt/spark/jobs/transform_job.py
```

## Etape 4 : Jupyter Notebook

### 4.1 Accès

- URL : http://localhost:8888
- Pas de mot de passe

### 4.2 Volume partagé

Jupyter accède aux données via le volume `./data` monté dans `/home/jovyan/data`.

### 4.3 Notebook d'exploration

Le fichier `notebooks/exploration.ipynb` :
- Crée une session Spark
- Lit les données Parquet générées par le job Spark
- Affiche les données et statistiques

## Etape 5 : MLOps avec MLflow + MinIO

Tracer et stocker les expériences ML avec les artefacts dans MinIO.

### 5.1 Créer le bucket MinIO

Avant de lancer un entraînement, créer le bucket `mlflow` dans MinIO :

1. Ouvrir MinIO : http://localhost:9001
2. Se connecter avec les credentials (valeur des secrets `minio_access_key` / `minio_secret_key`)
3. Créer un bucket nommé `mlflow`

### 5.2 Script d'entraînement

Le fichier `ml/train.py` :
- Charge le dataset Iris et entraîne un RandomForestClassifier
- Log les paramètres (`n_estimators`, `random_state`) et métriques (`accuracy`)
- Sauvegarde le modèle dans MinIO via `mlflow.sklearn.log_model()`

### 5.3 Accès aux interfaces

| Service | URL | Description |
|---------|-----|-------------|
| MLflow | http://localhost:5001 | Tracking des expériences ML |
| MinIO | http://localhost:9001 | Console de stockage S3 |

### 5.4 Volume partagé

Le dossier `./ml` est monté dans Jupyter (`/home/jovyan/ml`) pour permettre l'exécution des scripts d'entraînement depuis les notebooks.

### 5.5 Exécuter un entraînement depuis Jupyter

1. Ouvrir Jupyter : http://localhost:8888
2. Ouvrir un terminal
3. Installer les dépendances :
```bash
pip install mlflow==2.9.2 boto3
```
4. Lancer le script d'entraînement :
```bash
python /home/jovyan/ml/train.py
```

### 5.6 Visualiser les expériences

1. Ouvrir MLflow : http://localhost:5001
2. Sélectionner l'expérience "mlops-iris"
3. Consulter les runs, paramètres et métriques
4. Cliquer sur un run pour voir les artefacts (modèle sauvegardé)

### 5.7 Vérifier les artefacts dans MinIO

1. Ouvrir MinIO : http://localhost:9001
2. Naviguer dans le bucket `mlflow/artifacts`
3. Les modèles sont stockés avec leurs métadonnées MLflow

## Structure du projet

```
data-platform/
├── docker-compose.yml
├── airflow/
│   └── dags/
│       └── data_pipeline.py    # DAG ETL
├── spark/
│   └── jobs/
│       └── transform_job.py    # Job Spark
├── data/
│   ├── input.csv               # Données source
│   └── output/                 # Résultat Parquet
├── notebooks/
│   └── exploration.ipynb       # Notebook exploration
├── ml/
│   └── train.py                # Script MLflow
└── README.md
```

## Arrêt

```bash
# Mode Compose
docker compose down

# Mode Swarm
docker stack rm data_platform
```
