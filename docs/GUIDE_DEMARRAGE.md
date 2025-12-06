# Guide de Démarrage - Football Pipeline

## 📦 Prérequis Système

- **Terraform** ≥ 1.0
- **AWS CLI** configurée (avec credentials valides)
- **Python** ≥ 3.8
- **Git**

### Installation sur Windows

#### 1. AWS CLI
```powershell
# Via Chocolatey
choco install awscli

# Via MSI
# Télécharger: https://aws.amazon.com/cli/
```

#### 2. Terraform
```powershell
# Via Chocolatey
choco install terraform

# Vérifier
terraform version
```

#### 3. Python
```powershell
# Via Chocolatey
choco install python

# Vérifier
python --version
```

#### 4. Git
```powershell
# Via Chocolatey
choco install git
```

## 🚀 Démarrage Rapide

### 1. Configuration AWS

```powershell
# Configurer les credentials
aws configure

# Vérifier la connexion
aws sts get-caller-identity
```

### 2. Cloner le Projet

```powershell
git clone <repo-url>
cd "PROJET - Pipeline de traitements de données pour le cloud"
```

### 3. Déploiement Automatisé (recommandé)

```powershell
# Installer les dépendances Python
pip install -r requirements.txt

# Lancer le script de déploiement
python deploy.py
```

### 4. Déploiement Manuel

```powershell
# Initialiser Terraform
cd terraform
terraform init

# Planifier
terraform plan -out=tfplan

# Appliquer
terraform apply tfplan

# Récupérer les outputs
terraform output

# Revenir
cd ..
```

## 📊 Flux de Données

```
1. Données CSV (S3)
         ↓
   [Glue Crawler]
         ↓
2. Catalog Glue
         ↓
3. Script Goals (Kinesis)
         ↓
   [Firehose]
         ↓
4. S3 (goals_raw)
         ↓
   [Glue ETL Job]
         ↓
5. S3 (goals_clean)
         ↓
   [Athena Vues]
         ↓
6. Power BI (Dashboards)
```

## 🔧 Configuration

### Paramètres Terraform (`terraform/variables.tf`)

```hcl
# Région AWS
aws_region = "eu-west-1"

# Noms des ressources
project_name = "football-pipeline"
glue_job_name = "goals-etl"
kinesis_stream_name = "goals-stream"
```

### Fichier `.env` (optionnel)

```bash
AWS_REGION=eu-west-1
AWS_PROFILE=default
BUCKET_PREFIX=foot-data
```

## 📥 Upload des Données

### 1. Charger le CSV des matchs

```powershell
# Obtenir le nom du bucket
$BUCKET = terraform -chdir=terraform output -raw data_bucket_name

# Uploader les données
aws s3 cp football_matches_2024_2025.csv "s3://$BUCKET/matches/"

# Vérifier
aws s3 ls "s3://$BUCKET/matches/"
```

### 2. Lancer le Producteur Goals

```powershell
# Avec environnement virtuel
.\venv\Scripts\Activate.ps1
python scripts/goals_producer.py

# Pour l'arrêter: Ctrl+C
```

## 📊 Vérification des Données

### 1. Vérifier S3

```powershell
# Lister les buckets
aws s3 ls

# Voir les données
aws s3 ls s3://foot-data-bucket/goals_raw/
aws s3 ls s3://foot-data-bucket/matches/
```

### 2. Vérifier Glue Catalog

```powershell
# Lister les tables
aws glue get-tables --database-name football_db --region eu-west-1
```

### 3. Tester Athena

```powershell
# Via AWS Console: Services → Athena
# - Sélectionner workgroup: football-workgroup
# - Exécuter une requête:
#   SELECT * FROM goals_clean LIMIT 10;
```

### 4. Vérifier Kinesis

```powershell
# Voir le stream
aws kinesis describe-stream --stream-name goals-stream --region eu-west-1

# Voir les shards
aws kinesis list-shards --stream-name goals-stream --region eu-west-1
```

## 📈 Monitoring

### CloudWatch Logs

```powershell
# Logs du Glue Job
aws logs tail /aws-glue/football-pipeline --follow

# Logs du Firehose
aws logs tail /aws/firehose/football-pipeline --follow
```

### Métriques Kinesis

```powershell
# Vue d'ensemble du stream
aws cloudwatch get-metric-statistics `
  --namespace AWS/Kinesis `
  --metric-name IncomingRecords `
  --dimensions Name=StreamName,Value=goals-stream `
  --start-time 2024-01-01T00:00:00Z `
  --end-time 2024-01-02T00:00:00Z `
  --period 3600 `
  --statistics Sum
```

## 🔗 Connexion Power BI

### 1. Installer ODBC Driver Athena

- Télécharger: https://www.progress.com/odbc/amazon-athena
- Installer le driver

### 2. Configurer la connexion

```
Driver: Amazon Athena ODBC Driver
AuthType: IAM Credentials
AwsRegion: eu-west-1
S3OutputLocation: s3://foot-data-bucket-query-results/results/
Database: football_db
```

### 3. Créer les dashboards

- Utiliser les vues Athena comme sources
- Graphiques:
  - Buts par ligue
  - Top buteurs
  - Buts par minute
  - Comparaison équipes

## 🧹 Nettoyage

### Supprimer tout

```powershell
# Attention: Cela supprime TOUTES les ressources!

cd terraform
terraform destroy
cd ..
```

### Supprimer les données S3

```powershell
# Vider les buckets
aws s3 rm s3://foot-data-bucket --recursive
aws s3 rm s3://foot-data-bucket-query-results --recursive
```

## 🐛 Dépannage

### Erreur: "No credentials found"

```powershell
# Configurer AWS
aws configure

# Vérifier
aws sts get-caller-identity
```

### Erreur: "Access Denied"

- Vérifier les permissions IAM
- Vérifier la région AWS
- Vérifier les buckets S3

### Erreur: "Stream not found"

```powershell
# Vérifier le stream existe
aws kinesis list-streams --region eu-west-1
```

### Erreur: "Job bookmark"

```powershell
# Réinitialiser le bookmark du job
aws glue reset-job-bookmark --job-name goals-etl --region eu-west-1
```

## 📞 Support

- AWS Documentation: https://docs.aws.amazon.com/
- Terraform Docs: https://www.terraform.io/docs
- Boto3 Docs: https://boto3.amazonaws.com/

## ✅ Checklist de Déploiement

- [ ] Prérequis installés
- [ ] AWS configurée
- [ ] Terraform init
- [ ] Terraform apply
- [ ] CSV uploadé
- [ ] Producteur lancé
- [ ] Données dans S3
- [ ] Vues Athena créées
- [ ] Power BI connecté
- [ ] Dashboards fonctionnels

---

**Création**: 6 décembre 2024
**Dernière mise à jour**: 6 décembre 2024
