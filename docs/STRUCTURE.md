# Structure du Projet

```
PROJET - Pipeline de traitements de données pour le cloud/
│
├── 📘 README.md                          ← Documentation principale
├── 📘 GUIDE_DEMARRAGE.md                 ← Guide d'installation
│
├── 📁 terraform/                         ← Infrastructure AWS
│   ├── provider.tf                       (Config AWS)
│   ├── variables.tf                      (Variables réutilisables)
│   ├── vpc.tf                            (VPC + Subnets + SG)
│   ├── iam.tf                            (Rôles + Policies)
│   ├── s3.tf                             (Buckets S3)
│   ├── kinesis.tf                        (Kinesis + Firehose)
│   ├── glue.tf                           (Glue Catalog + Jobs + Crawler)
│   ├── athena.tf                         (Athena Workgroup)
│   ├── outputs.tf                        (Outputs)
│   └── README.md                         (Doc Terraform)
│
├── 📁 scripts/                           ← Scripts et ETL
│   ├── goals_producer.py                 (Producteur Kinesis)
│   ├── glue_job_etl.py                  (Job Spark ETL)
│   ├── athena_queries.sql                (Vues Athena)
│   └── README.md                         (Doc Scripts)
│
├── 📁 data/                              ← Données locales
│   └── football_matches_2024_2025.csv   (CSV des matchs)
│
├── 📁 dashboards/                        ← Dashboards Power BI
│   └── (fichiers .pbit à créer)
│
├── 📄 config.ini                         ← Configuration locale
├── 📄 requirements.txt                   ← Dépendances Python
├── 📄 deploy.py                          ← Script déploiement auto
├── 📄 .gitignore                         ← Git ignore
├── 📄 à faire.txt                        ← Tâches
│
└── 📁 .azure/ (après azd)
    └── (fichiers config Azure)
```

## 📊 Architecture Récapitulative

```
                        SOURCES
                    ┌─────┬─────┐
                    │     │     │
            CSV     │  Python   │
            ↓       │  Goals    │
        ┌─────┐     │           │
        │  S3 │     └─────┬─────┘
        │     │           │
        └─────┘           ↓
            │      ┌──────────────────┐
            └─────→│  Kinesis Stream  │
                   │  (goals-stream)  │
                   └────────┬─────────┘
                            │
                            ↓
                   ┌──────────────────┐
                   │ Firehose         │
                   │ (goals-firehose) │
                   └────────┬─────────┘
                            │
                            ↓
        ┌───────────────────────────────────┐
        │ S3 CENTRAL (foot-data-bucket)     │
        ├───────────────────────────────────┤
        │ ├─ matches/         ← CSV batch   │
        │ ├─ goals_raw/       ← Firehose   │
        │ └─ goals_clean/     ← ETL Glue   │
        └───────────────────┬───────────────┘
                            │
                 ┌──────────┼──────────┐
                 │          │          │
                 ↓          ↓          ↓
            ┌────────┐  ┌────────┐  ┌────────┐
            │Crawler │  │Glue Job│  │Athena  │
            │Glue    │  │ ETL    │  │Queries │
            └───┬────┘  └───┬────┘  └───┬────┘
                │           │           │
                └───┬───────┴────────┬──┘
                    │                │
                    ↓                ↓
            ┌──────────────┐  ┌────────────┐
            │Glue Catalog  │  │Query Res.  │
            │(Métadonnées) │  │(S3 bucket) │
            └──────┬───────┘  └────────────┘
                   │
                   ↓
            ┌──────────────┐
            │ Power BI     │
            │ Dashboards   │
            └──────────────┘
```

## 🔑 Fichiers Clés

| Fichier | Description | Priorité |
|---------|-------------|----------|
| `terraform/*.tf` | Infrastructure AWS complète | 🔴 Critique |
| `scripts/goals_producer.py` | Producteur de données | 🔴 Critique |
| `scripts/glue_job_etl.py` | ETL Spark | 🟡 Important |
| `scripts/athena_queries.sql` | Vues analytiques | 🟡 Important |
| `config.ini` | Configuration | 🟢 Optionnel |
| `deploy.py` | Déploiement auto | 🟢 Pratique |

## 🚀 Commandes Utiles

```bash
# Déploiement complet
python deploy.py

# Ou manuellement
cd terraform && terraform init && terraform plan && terraform apply && cd ..

# Producteur de données
python scripts/goals_producer.py

# Upload données
aws s3 cp data/football_matches_2024_2025.csv s3://foot-data-bucket/matches/

# Requêtes Athena
# (via AWS Console ou CLI)
aws athena start-query-execution --query-string "SELECT * FROM goals_clean LIMIT 10" ...
```

## 📈 Flux de Travail

1. **Setup Infrastructure** → `terraform apply`
2. **Charger Données** → CSV vers S3
3. **Démarrer Producteur** → `python goals_producer.py`
4. **Vérifier Données** → S3, Glue, Athena
5. **Créer Vues** → Athena SQL
6. **Connecter Power BI** → ODBC/JDBC
7. **Créer Dashboards** → Power BI

## ✅ Checklist Finale

- [ ] Infrastructure déployée (Terraform)
- [ ] Données CSV uploadées
- [ ] Producteur lancé
- [ ] Données dans S3 (goals_raw + goals_clean)
- [ ] Tables dans Glue Catalog
- [ ] Vues Athena créées
- [ ] Power BI connecté
- [ ] Dashboards opérationnels
