# 🚀 Football Pipeline - Terraform Infrastructure as Code

## 📋 Vue d'ensemble

Ce répertoire contient la configuration **Terraform complète** pour déployer automatiquement le pipeline de données de football sur AWS **de A à Z**.

### ✨ Ce qui est automatisé

✅ **S3 Buckets** - Stockage de données brutes, traitées et scripts  
✅ **Kinesis Stream** - Ingestion temps réel des données de buts  
✅ **Kinesis Firehose** - Livraison automatique vers S3  
✅ **AWS Glue** - ETL, Crawler, et Glue Catalog  
✅ **Amazon Athena** - Requêtes SQL analytiques  
✅ **IAM Roles** - Permissions granulaires least-privilege  
✅ **CloudWatch** - Monitoring et alertes  
✅ **Lambda** - Transformation Firehose  

---

## 📁 Structure du projet

```
terraform/
├── main.tf              # Configuration provider + locals
├── variables.tf         # Toutes les variables d'entrée
├── iam.tf              # Rôles et politiques IAM
├── s3.tf               # Buckets S3
├── kinesis.tf          # Kinesis Stream
├── firehose.tf         # Kinesis Firehose + Lambda
├── glue.tf             # Glue Job, Crawler, Database
├── athena.tf           # Athena Workgroup + Named Queries
├── outputs.tf          # Outputs pour tous les ressources
├── terraform.tfstate   # État (ne pas committer)
└── terraform.tfstate.backup

scripts/
├── lambda_firehose_transformer.py   # Lambda function
└── [autres scripts]

deploy.ps1              # Script PowerShell (Windows)
deploy.sh              # Script Bash (Linux/Mac)
Makefile               # Commandes pour déploiement
```

---

## 🔧 Installation et Configuration

### Prérequis

1. **Terraform** >= 1.0  
   ```powershell
   # Windows (via Chocolatey)
   choco install terraform
   
   # Ou télécharger depuis: https://www.terraform.io/downloads.html
   ```

2. **AWS CLI** >= 2.0  
   ```powershell
   # Windows (via Chocolatey)
   choco install awscli
   ```

3. **AWS Account** avec credentials configurées  
   ```powershell
   aws configure
   # Entrez: Access Key ID, Secret Access Key, région, format (json)
   ```

### Configuration des variables

Créez un fichier `terraform/terraform.tfvars` pour personnaliser:

```hcl
aws_region = "us-east-1"
environment = "dev"
project_name = "football-pipeline"

# Kinesis
kinesis_stream_name = "goals-stream"
kinesis_shard_count = 1
kinesis_retention_period = 24

# Firehose
firehose_stream_name = "goals-firehose"
firehose_buffer_size_mb = 5
firehose_buffer_interval_sec = 300

# Glue
glue_database_name = "football_db"
glue_worker_type = "G.2X"
glue_num_workers = 2

# S3
s3_enable_versioning = true
s3_enable_encryption = true
s3_block_public_access = true
```

---

## 🚀 Déploiement

### Option 1: PowerShell (Windows) ⭐

```powershell
# Valider la configuration
.\deploy.ps1 validate

# Voir le plan
.\deploy.ps1 plan

# Déployer complètement
.\deploy.ps1 deploy

# Voir le statut
.\deploy.ps1 status

# Afficher les outputs
.\deploy.ps1 outputs

# Détruire les ressources
.\deploy.ps1 destroy
```

### Option 2: Bash (Linux/Mac/WSL)

```bash
# Valider
./deploy.sh validate

# Voir le plan
./deploy.sh plan

# Déployer
./deploy.sh deploy

# Voir le statut
./deploy.sh status

# Détruire
./deploy.sh destroy
```

### Option 3: Makefile (Windows, Linux, Mac)

```bash
# Initialiser Terraform
make init

# Formater les fichiers
make fmt

# Valider
make validate

# Voir le plan
make plan

# Déployer
make apply

# Déploiement complet
make deploy

# Statut
make status

# Détruire
make destroy

# Aide
make help
```

### Option 4: Commandes Terraform directes

```bash
cd terraform

# Initialiser
terraform init

# Valider
terraform validate

# Voir le plan
terraform plan -var="environment=dev"

# Appliquer
terraform apply

# Détruire
terraform destroy
```

---

## 📊 Outputs disponibles

Après déploiement, utilisez `deploy.ps1 outputs` ou `terraform output` pour voir:

```json
{
  "account_id": "123456789012",
  "region": "us-east-1",
  "raw_data_bucket": "football-pipeline-dev-raw-123456789012",
  "processed_data_bucket": "football-pipeline-dev-processed-123456789012",
  "scripts_bucket": "football-pipeline-dev-scripts-123456789012",
  "athena_results_bucket": "football-pipeline-dev-athena-results-123456789012",
  "kinesis_stream_name": "football-pipeline-dev-goals-stream",
  "firehose_delivery_stream_name": "football-pipeline-dev-goals-firehose",
  "glue_database_name": "football_db",
  "glue_job_name": "football-pipeline-dev-football-csv-to-parquet",
  "athena_workgroup_name": "football-pipeline-dev-football-workgroup",
  "pipeline_summary": {
    "kinesis_stream": {...},
    "firehose_stream": {...},
    "s3_buckets": {...},
    "glue_resources": {...},
    "athena_resources": {...},
    "iam_roles": {...}
  }
}
```

---

## 🔐 Sécurité

### IAM Least Privilege

Tous les rôles IAM sont configurés avec le **minimum de permissions**:

- **Glue Role**: S3 (read/write), CloudWatch Logs, Glue Catalog
- **Firehose Role**: S3 (write), CloudWatch Logs
- **Lambda Role**: CloudWatch Logs uniquement

### Encryption

- ✅ S3 encryption (AES256)
- ✅ S3 versioning
- ✅ Block public access
- ✅ CloudWatch logs encrypted

---

## 📝 Utilisation après déploiement

### 1. Uploader des données

```bash
# Uploader un CSV dans S3
aws s3 cp data/football_matches.csv \
  s3://$(terraform output -raw raw_data_bucket)/matches/

# Ou via PowerShell
$bucket = (aws s3 ls | grep raw)
aws s3 cp .\data\football_matches.csv s3://$bucket/matches/
```

### 2. Déclencher le Glue Crawler

```bash
aws glue start-crawler \
  --name $(terraform output -raw glue_crawler_name) \
  --region us-east-1
```

### 3. Exécuter le Glue Job (ETL)

```bash
aws glue start-job-run \
  --job-name $(terraform output -raw glue_job_name) \
  --region us-east-1
```

### 4. Requêtes Athena

```bash
# Requête simple
aws athena start-query-execution \
  --query-string "SELECT * FROM football_db.parquet LIMIT 10" \
  --query-execution-context Database=football_db \
  --result-configuration OutputLocation=s3://athena-bucket/results/ \
  --region us-east-1
```

### 5. Envoyer des données Kinesis (temps réel)

```bash
# Via Python (exemple)
import boto3
kinesis = boto3.client('kinesis')
kinesis.put_record(
    StreamName='football-pipeline-dev-goals-stream',
    Data='{"goal": "Messi", "team": "PSG"}',
    PartitionKey='psg'
)
```

---

## 🔍 Monitoring

### CloudWatch Alarms

Des alarmes sont configurées pour:

- ✅ Kinesis Iterator Age
- ✅ Kinesis Read Throughput Exceeded
- ✅ Glue Job Failures
- ✅ Athena Query Issues

Visualisez via CloudWatch Console AWS.

### Logs

```bash
# Logs Glue Job
aws logs tail /aws-glue/jobs/football-pipeline-dev-football-csv-to-parquet --follow

# Logs Firehose
aws logs tail /aws/kinesisfirehose/football-pipeline-dev-goals-firehose --follow

# Logs Lambda
aws logs tail /aws/lambda/football-pipeline-dev-firehose-transformer --follow
```

---

## 🛠️ Troubleshooting

### Erreur: "credentials not found"

```bash
aws configure
# Entrez vos AWS credentials
```

### Erreur: "InvalidAction.NotFound"

Les ressources IAM doivent être créées en premier:
```bash
terraform apply -target=aws_iam_role.glue_role
```

### Erreur: "Bucket already exists"

S3 bucket names doivent être globalement uniques. Terraform génère automatiquement des noms avec account_id.

### État Terraform désynchronisé

```bash
# Rafraîchir l'état
terraform refresh

# Ou recréer les ressources
terraform destroy
terraform apply
```

---

## 🚨 Coûts

**Coût estimé par mois** (dev/test):

| Service | Coût |
|---------|------|
| S3 | $1-5 |
| Kinesis | $5-15 |
| Firehose | $5-10 |
| Glue | $5-15 |
| Athena | $5-10 |
| Lambda | < $1 |
| **Total** | **$21-56** |

⚠️ **Important**: Activez les budget alerts:

```bash
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

---

## 📚 Ressources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Amazon Athena Documentation](https://docs.aws.amazon.com/athena/)
- [Kinesis Firehose Guide](https://docs.aws.amazon.com/kinesis/latest/dev/what-is-kinesis.html)

---

## 🆘 Support

Pour des problèmes:

1. Vérifier les logs Terraform:
   ```bash
   export TF_LOG=DEBUG
   terraform apply
   ```

2. Vérifier AWS Console (CloudFormation, CloudWatch)

3. Consulter `deployment.log` généré par `deploy.ps1/deploy.sh`

---

## ✅ Checklist de déploiement

- [ ] AWS CLI configurée (`aws configure`)
- [ ] Terraform installé (`terraform --version`)
- [ ] `terraform/terraform.tfvars` créé
- [ ] `terraform init` exécuté
- [ ] `terraform plan` validé
- [ ] `terraform apply` exécuté
- [ ] Outputs vérifiés (`terraform output`)
- [ ] S3 buckets visibles dans AWS Console
- [ ] Glue Database visible dans Glue Console
- [ ] Athena Workgroup visible dans Athena Console
- [ ] Budget alerts configurées

---

**Auteurs**: Ismail Benaissa & Khalil Arraoui  
**Date**: 2024  
**Version**: 1.0.0  
