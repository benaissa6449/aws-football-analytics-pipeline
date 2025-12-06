# Configuration Terraform

Ce dossier contient toute l'infrastructure AWS pour le pipeline.

## 📁 Structure

- **provider.tf** : Configuration du provider AWS
- **variables.tf** : Variables réutilisables
- **vpc.tf** : VPC, Subnets, Security Groups
- **iam.tf** : Rôles et policies IAM
- **s3.tf** : Buckets S3 et configurations
- **kinesis.tf** : Kinesis Streams et Firehose
- **glue.tf** : Glue Database, Jobs, Crawlers
- **athena.tf** : Athena Workgroup et Database
- **outputs.tf** : Outputs importants

### 2. Planification

```bash
terraform plan -out=tfplan
```

### 3. Application

```bash
terraform apply tfplan
```

### 4. Destruction (optionnel)

```bash
terraform destroy
```

## 📝 Variables importantes

Créer un fichier `terraform.tfvars` :

```hcl
aws_region            = "eu-west-1"
environment           = "production"
project_name          = "football-pipeline"
bucket_prefix         = "foot-data"
glue_job_name         = "goals-etl"
kinesis_stream_name   = "goals-stream"
firehose_name         = "goals-firehose"
glue_database_name    = "football_db"
glue_crawler_name     = "football-crawler"
```

## 📊 Ressources créées

- VPC avec subnets publics/privés
- 2 NAT Gateways pour haute disponibilité
- Security Groups pour EC2 et Glue
- Rôles IAM pour tous les services
- 2 Buckets S3 (data + query results)
- Kinesis Stream (ON_DEMAND)
- Firehose vers S3
- Glue Database
- Glue ETL Job
- Glue Crawler
- Athena Workgroup

## 🔑 Outputs

Après le déploiement, récupérer les outputs :

```bash
terraform output
```

## 💡 Tips

- Backend S3 : Décommenter dans provider.tf pour état centralisé
- Tags : Modifier dans variables.tf pour tous les services
- Cost optimization : Changer worker_type en G.1X pour ETL petit volume
