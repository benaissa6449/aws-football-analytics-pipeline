# Structure du Projet Restructuré

## Nouvelle Organisation

```
football-pipeline/
│
├── docs/                           Documentation
│   ├── README.md                     Vue d'ensemble + liens
│   ├── GUIDE_DEMARRAGE.md            Installation détaillée
│   └── ARCHITECTURE.md               Détails techniques
│
├── infrastructure/                 Terraform
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── iam.tf
│   ├── s3.tf
│   ├── kinesis.tf
│   ├── glue.tf
│   ├── athena.tf
│   ├── outputs.tf
│   └── README.md
│
├── src/                            Code source
│   ├── producers/
│   │   └── goals_producer.py         Kinesis producer
│   ├── etl/
│   │   └── glue_job_etl.py          Spark ETL job
│   ├── analytics/
│   │   └── athena_queries.sql        Vues SQL
│   ├── utils/
│   │   └── helpers.py                Utilitaires
│   └── README.md
│
├── tests/                          Tests
│   ├── unit/
│   │   └── test_producer.py
│   └── integration/
│       └── test_pipeline.py
│
├── configs/                        Configuration
│   ├── config.ini                    Paramètres généraux
│   ├── aws-config.json               Config AWS
│   └── .env.example                  Variables d'env
│
├── data/                           Données
│   ├── input/
│   │   └── football_matches_2024_2025.csv
│   └── output/
│       └── (résultats)
│
├── dashboards/                     Power BI
│   └── football-analytics.pbit       Template
│
├── Fichiers Racine
│   ├── PROJECT.md                    Métadonnée projet
│   ├── Makefile                      Commandes utiles
│   ├── requirements.txt              Dépendances Python
│   ├── .gitignore                    Git ignore
│   └── deploy.py                     Script déploiement
│
└── Architecture/                   (Anciens fichiers)
    └── (diagrams DrawIO)
```

## Améliorations

| Aspect | Avant | Après |
|--------|-------|-------|
| **Infrastructure** | terraform/ (racine) | infrastructure/ (dossier) |
| **Code** | scripts/ (mélangé) | src/ (organisé par type) |
| **Documentation** | Fichiers à la racine | docs/ (centralisé) |
| **Configuration** | config.ini (racine) | configs/ (regroupé) |
| **Tests** | Aucun | tests/ (créé) |
| **Commandes** | `terraform apply` | `make deploy` |
| **Info Projet** | Aucun | PROJECT.md |

## Navigation

```
Démarrer              → docs/README.md
Installation          → docs/GUIDE_DEMARRAGE.md
Architecture Technique → docs/ARCHITECTURE.md
Infrastructure Code   → infrastructure/README.md
Code Source          → src/README.md
Configuration        → configs/README.md
Infos Projet         → PROJECT.md
Commandes            → make help
```

## Bénéfices

- **Scalabilité** : Structure extensible pour nouvelles fonctionnalités
- **Maintenabilité** : Code organisé et facile à trouver
- **Collaboratif** : Clair pour les autres développeurs
- **Professionnel** : Standard de l'industrie
- **Automatisé** : Makefile pour simplifier

---

**Structure complète et professionnelle!** 🎯
