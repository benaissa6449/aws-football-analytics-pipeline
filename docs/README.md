# Football Pipeline - Data Processing for Cloud

Un pipeline complet de traitement de données de football utilisant les services AWS pour l'ingestion, la transformation, l'analyse et la visualisation en temps réel et différé.

## 🎯 Vue d'ensemble

Ce projet implémente une **architecture serverless complète** sur AWS pour :

- ✅ **Ingestion** : CSV batch + Kinesis streaming
- ✅ **Transformation** : AWS Glue ETL Spark
- ✅ **Catalogage** : Glue Data Catalog
- ✅ **Analyse** : Amazon Athena SQL
- ✅ **Visualisation** : Power BI Dashboards

---

## 🏗️ Architecture

### Vue Globale du Pipeline

```
                           TERRAFORM
                    (Création de l'infra)
                    ┌─────────────────────┐
                    │  VPC, Subnets, SG   │
                    │   Rôles IAM         │
                    │   Buckets S3        │
                    └─────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
   ┌─────────┐          ┌──────────┐          ┌──────────┐
   │   VPC   │          │  Rôles   │          │ Buckets  │
   │ Network │          │   IAM    │          │    S3    │
   └─────────┘          └──────────┘          └──────────┘
```

### Infrastructure (Terraform)

L'infrastructure est entièrement codifiée avec Terraform et provisionne :

- **VPC, Subnets, Security Groups** : Isolation réseau et contrôle d'accès
- **Rôles IAM** : Permissions granulaires pour les services AWS
- **Buckets S3** : Stockage des données à différents stades du pipeline

---

## 📥 Producteurs / Sources de Données

```
SOURCES DE DONNÉES
┌──────────────────────────────────────┐      ┌──────────────────────────────────┐
│ 1) Fichier Batch des Matchs          │      │ 2) Script Python "Goals"         │
│    football_matches_2024_2025.csv    │      │    sur EC2 / Cloud9              │
└────────────────┬─────────────────────┘      └────────────┬─────────────────────┘
                 │                                         │
                 │ Upload CSV                             │ PutRecord (JSON)
                 │ (manuel ou script)                     │
                 ▼                                         ▼
         ┌─────────────────┐                  ┌──────────────────────┐
         │  Amazon S3      │                  │ Amazon Kinesis Data  │
         │ foot-data-      │                  │ Streams "goals-      │
         │ bucket/matches/ │                  │ stream"              │
         └────────┬────────┘                  └──────────┬───────────┘
                  │                                      │
                  │                                      │ Records depuis stream
                  │                                      ▼
                  │                           ┌──────────────────────────┐
                  │                           │ Amazon Data Firehose     │
                  │                           │ "goals-firehose"         │
                  │                           │ Source: KDS              │
                  │                           │ Destination: S3          │
                  │                           └──────────┬───────────────┘
                  │                                      │
                  │                    Deliver (1–5 min) vers S3
                  │                                      │
                  │                                      ▼
                  │                           ┌──────────────────────────┐
                  │                           │ Amazon S3                │
                  │                           │ foot-data-bucket/        │
                  │                           │ goals_raw/               │
                  │                           └──────────┬───────────────┘
                  │                                      │
                  └──────────────┬───────────────────────┘
                                 │
                    (optionnel ETL temps différé)
                                 │
                                 ▼
                    ┌──────────────────────────┐
                    │ AWS Glue Job "goals-etl" │
                    │ (Spark ETL)              │
                    │ Lit goals_raw + matches  │
                    └──────────┬───────────────┘
                               │ Écrit S3
                               ▼
                    ┌──────────────────────────┐
                    │ Amazon S3                │
                    │ foot-data-bucket/        │
                    │ goals_clean/             │
                    └──────────────────────────┘
```

---

## 🔄 Pipeline de Données

```
PIPELINE COMPLET
┌───────────────────────────────────────────────────────────────────┐
│                        INGESTION                                  │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  S3 Bucket (foot-data-bucket/)                                  │
│  ├── matches/           ◄─── CSV batch                          │
│  ├── goals_raw/         ◄─── Firehose                           │
│  └── goals_clean/       ◄─── Glue Job                           │
│                                                                   │
│  Kinesis Stream (goals-stream)                                   │
│  └── reçoit événements JSON en temps réel                       │
│      │                                                            │
│      ▼                                                            │
│  Data Firehose (goals-firehose)                                  │
│  └── Buffer 1–5 min → Livraison à S3 goals_raw/                 │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│                    TRANSFORMATION (ETL)                           │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  AWS Glue Job "goals-etl" (Spark)                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Entrées:                                               │    │
│  │  ├── goals_raw/ (depuis Firehose)                       │    │
│  │  └── matches/ (données historiques)                     │    │
│  │                                                          │    │
│  │  Traitement: Nettoyage, enrichissement, jointures      │    │
│  │                                                          │    │
│  │  Sortie: goals_clean/                                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│  Exécution: Temps différé (nuit, heures creuses)                │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│                  PRÉPARATION & CATALOGUE                          │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  AWS Glue Crawler "football-crawler" (On demand)                │
│  └── Scanne: matches/, goals_raw/, goals_clean/                 │
│      │                                                            │
│      ▼ Crée/actualise                                            │
│  AWS Glue Data Catalog                                          │
│  ┌──────────────────────────────────┐                           │
│  │ Database: football_db            │                           │
│  │ ├── Table: matches               │                           │
│  │ ├── Table: goals_raw             │                           │
│  │ └── Table: goals_clean           │                           │
│  └──────────────────────────────────┘                           │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## 📊 Préparation & Catalogue

### AWS Glue Crawler (`football-crawler`)
- **Exécution** : À la demande (on demand)
- **Fonction** : Scanner les données S3 et détecter les schémas
- **Sortie** : Actualise le catalogue AWS Glue

### AWS Glue Data Catalog
```
Database: football_db
  ├── Table: matches         (données historiques des matchs)
  ├── Table: goals_raw       (buts bruts)
  └── Table: goals_clean     (buts nettoyés)
```

---

## 🔍 Analyse SQL

```
ANALYSE AVEC AMAZON ATHENA
┌───────────────────────────────────────────────────────────────────┐
│                    AWS Glue Data Catalog                          │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │ Database: football_db                                    │     │
│  │ Tables: matches, goals_raw, goals_clean                  │     │
│  └──────────────────┬───────────────────────────────────────┘     │
└─────────────────────┼─────────────────────────────────────────────┘
                      │
                      ▼
         ┌──────────────────────────┐
         │  Amazon Athena           │
         │  (SQL Presto)            │
         └──────────┬───────────────┘
                    │
         ┌──────────┴──────────┬──────────────────┬──────────────┐
         │                     │                  │              │
         ▼                     ▼                  ▼              ▼
    ┌─────────────┐    ┌──────────────┐   ┌─────────────┐  ┌────────────┐
    │ vw_match_   │    │ vw_live_     │   │ vw_goals_by │  │ vw_top_    │
    │ stats       │    │ goals        │   │ _league     │  │ scorers    │
    └──────┬──────┘    └──────┬───────┘   └──────┬──────┘  └────────┬───┘
           │                  │                   │                  │
           └──────────────────┼───────────────────┼──────────────────┘
                              │
                              ▼
                   ┌──────────────────────┐
                   │ S3 query-results-    │
                   │ bucket/              │
                   │ (résultats requêtes) │
                   └──────────────────────┘
```

---

## 📈 Visualisation

```
DASHBOARDS POWER BI
┌───────────────────────────────────────────────────────────────────┐
│               Connexion ODBC/JDBC ◄──────────────────┐            │
│                                                      │            │
│  ┌──────────────────────────────────────────────┐   │            │
│  │       Power BI Dashboards                    │   │            │
│  ├──────────────────────────────────────────────┤   │            │
│  │                                              │   │            │
│  │  1. Buts par Ligue                          │   │            │
│  │     ├── Distribution par ligue              │   │            │
│  │     └── Tendances temporelles               │   │            │
│  │                                              │   │            │
│  │  2. Top Buteurs                             │   │            │
│  │     ├── Classement général                  │   │            │
│  │     └── Evolution des performances          │   │            │
│  │                                              │   │            │
│  │  3. Buts par Minute                         │   │            │
│  │     ├── Heatmap temporelle                  │   │            │
│  │     └── Moments critiques des matchs        │   │            │
│  │                                              │   │            │
│  │  4. Filtres Ligues (PL, Liga, L1, etc)     │   │            │
│  │                                              │   │            │
│  └──────────────────────────────────────────────┘   │            │
│                                                      │            │
└──────────────────────────────────────────────────────┼────────────┘
                                                       │
                                                       ▼
                                          ┌──────────────────────┐
                                          │ Amazon Athena        │
                                          │ (Vues SQL)           │
                                          └──────────────────────┘
```

### Dashboards Détaillés

| Dashboard | Description | Filtres |
|-----------|-------------|---------|
| **Buts par Ligue** | Distribution et tendances des buts | Ligue, Date |
| **Top Buteurs** | Classement des meilleurs buteurs | Ligue, Saison |
| **Buts par Minute** | Analyse temporelle des buts | Ligue, Minute |
| **Vue Synthétique** | KPIs clés | Toutes ligues |

---

## 🚀 Déploiement

```
FLUX DE DÉPLOIEMENT
┌─────────────────────────────────────────────────────────┐
│ 1. Infrastructure (Terraform)                           │
│    terraform init → terraform plan → terraform apply    │
└────────────────────┬────────────────────────────────────┘
                     │ Crée
                     ▼
            ┌─────────────────────┐
            │ VPC, IAM, S3, etc   │
            └────────────┬────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
  ┌─────────────┐ ┌──────────────┐ ┌─────────────┐
  │ Charger CSV │ │ Déployer     │ │ Configurer  │
  │ dans S3     │ │ Script Goals │ │ Glue Job    │
  └──────┬──────┘ │ sur EC2      │ └──────┬──────┘
         │        └──────┬───────┘        │
         │               │                │
         └───────────────┼────────────────┘
                         │
                         ▼
            ┌──────────────────────────┐
            │ Créer Crawler Glue       │
            │ → Actualiser Catalog     │
            └────────────┬─────────────┘
                         │
                         ▼
            ┌──────────────────────────┐
            │ Créer Vues Athena        │
            │ (SQL queries)            │
            └────────────┬─────────────┘
                         │
                         ▼
            ┌──────────────────────────┐
            │ Connecter Power BI       │
            │ (ODBC/JDBC)              │
            └────────────┬─────────────┘
                         │
                         ▼
                   ✅ DÉPLOIEMENT OK
```
- AWS CLI configurée
- Terraform installé
- Python 3.8+ (pour les scripts ETL)
- Compte AWS avec permissions appropriées

### Installation de l'Infrastructure

```bash
# 1. Initialiser Terraform
cd terraform/
terraform init

# 2. Planifier le déploiement
terraform plan

# 3. Appliquer la configuration
terraform apply
```

### Déploiement du Pipeline

1. **Charger les données des matchs**
   ```bash
   aws s3 cp football_matches_2024_2025.csv s3://foot-data-bucket/matches/
   ```

2. **Déployer le script Python Goals**
   - Déployer sur EC2 ou Cloud9
   - Configurer les credentials AWS
   - Lancer le script pour envoyer les événements à Kinesis

3. **Configurer Glue Job**
   - Charger le script Spark dans S3
   - Configurer les rôles IAM
   - Planifier l'exécution (ex. : quotidiennement)

4. **Configurer le Crawler**
   - Créer le crawler Glue `football-crawler`
   - Définir le chemin S3 à scanner
   - Configurer la sortie vers `football_db`

5. **Créer les Vues Athena**
   - Exécuter les requêtes SQL pour créer les vues
   - Vérifier les résultats dans `query-results-bucket/`

6. **Connecter Power BI**
   - Ajouter une source de données Athena (ODBC/JDBC)
   - Créer les dashboards en fonction des vues

---

## 📁 Structure du Projet

```
PROJET - Pipeline de traitements de données pour le cloud/
├── README.md                              (ce fichier)
├── terraform/
│   ├── main.tf                           (configuration principale)
│   ├── vpc.tf                            (réseau)
│   ├── iam.tf                            (rôles et permissions)
│   ├── s3.tf                             (buckets S3)
│   └── variables.tf                      (variables Terraform)
├── scripts/
│   ├── goals_producer.py                 (script Python pour Kinesis)
│   ├── glue_job_etl.py                  (job Spark Glue)
│   └── athena_queries.sql                (requêtes SQL pour les vues)
├── data/
│   └── football_matches_2024_2025.csv   (données des matchs)
└── dashboards/
    └── power_bi_config.pbit             (template Power BI)
```

---

## 🔧 Configuration

### Variables d'Environnement
```bash
export AWS_REGION=eu-west-1
export AWS_PROFILE=default
export BUCKET_NAME=foot-data-bucket
export GLUE_JOB_NAME=goals-etl
```

### Paramètres Terraform
Mettre à jour `terraform/variables.tf` :
```hcl
variable "aws_region" {
  default = "eu-west-1"
}

variable "environment" {
  default = "production"
}

variable "bucket_prefix" {
  default = "foot-data"
}
```

---

## 🔐 Sécurité

- **IAM Roles** : Permissions minimales (principle of least privilege)
- **S3 Encryption** : Chiffrement au repos (SSE-S3 par défaut)
- **VPC** : Isolation réseau complète
- **Security Groups** : Restriction des accès par port et protocole

---

## 📊 Métriques et Monitoring

### CloudWatch
- Surveiller les erreurs des jobs Glue
- Monitorer le débit Kinesis
- Tracker les coûts S3

### AWS X-Ray
- Tracer les requêtes Athena
- Analyser les performances du pipeline

---

## 🛠️ Dépannage

### Problème : Job Glue échoue
```
Solution : Vérifier les logs CloudWatch
aws logs tail /aws-glue/jobs --follow
```

### Problème : Données manquantes dans S3
```
Solution : Vérifier la configuration du Firehose
aws firehose describe-delivery-stream --delivery-stream-name goals-firehose
```

### Problème : Power BI ne se connecte pas
```
Solution : Vérifier la configuration ODBC/JDBC et les credentials Athena
```

---

## 📚 Ressources

- [Documentation AWS Glue](https://docs.aws.amazon.com/glue/)
- [Documentation Amazon Kinesis](https://docs.aws.amazon.com/kinesis/)
- [Documentation Amazon Athena](https://docs.aws.amazon.com/athena/)
- [Documentation Terraform AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 👥 Contribution

Pour contribuer au projet :
1. Fork le repository
2. Créer une branche (`git checkout -b feature/ma-feature`)
3. Commit les changements (`git commit -m 'Ajouter ma feature'`)
4. Push vers la branche (`git push origin feature/ma-feature`)
5. Ouvrir une Pull Request

---

## 📄 Licence

Ce projet est sous licence MIT. Voir `LICENSE.md` pour plus de détails.

---

## 📧 Contact

Pour toute question ou support : [votre-email@example.com](mailto:votre-email@example.com)

---

**Dernière mise à jour** : 6 décembre 2025
