# Makefile - Football Pipeline

.PHONY: help init plan apply destroy clean deploy logs check-data upload-data run-producer

SHELL := /bin/bash
TERRAFORM_DIR := infrastructure
PROJECT_NAME := football-pipeline
AWS_REGION := eu-west-1

help:
	@echo "Football Pipeline - Commandes disponibles:"
	@echo ""
	@echo "Infrastructure:"
	@echo "  make tf-init       - Initialiser Terraform"
	@echo "  make tf-plan       - Planifier le déploiement"
	@echo "  make tf-apply      - Appliquer l'infrastructure"
	@echo "  make tf-destroy    - Supprimer l'infrastructure"
	@echo ""
	@echo "Données:"
	@echo "  make upload-data   - Uploader le CSV"
	@echo "  make check-data    - Vérifier les données"
	@echo ""
	@echo "Producteur:"
	@echo "  make run-producer  - Lancer le producteur de goals"
	@echo ""
	@echo "Utilitaires:"
	@echo "  make setup         - Configuration initiale"
	@echo "  make clean         - Nettoyer les fichiers temp"
	@echo "  make logs          - Voir les logs AWS"
	@echo "  make structure     - Afficher la structure du projet"
	@echo "  make help          - Afficher cette aide"

# Terraform
tf-init:
	@echo "Initialisation de Terraform..."
	cd $(TERRAFORM_DIR) && terraform init

tf-plan:
	@echo "Planification Terraform..."
	cd $(TERRAFORM_DIR) && terraform plan -out=tfplan

tf-apply: tf-plan
	@echo "Application de Terraform..."
	cd $(TERRAFORM_DIR) && terraform apply tfplan
	@echo "Infrastructure créée!"

tf-destroy:
	@echo "Suppression de l'infrastructure..."
	cd $(TERRAFORM_DIR) && terraform destroy
	@echo "Infrastructure supprimée!"

tf-output:
	@echo "Outputs Terraform:"
	cd $(TERRAFORM_DIR) && terraform output

# Données
upload-data:
	@echo "Upload du CSV..."
	@BUCKET=$$(cd $(TERRAFORM_DIR) && terraform output -raw data_bucket_name 2>/dev/null); \
	if [ -z "$$BUCKET" ]; then \
		echo "Bucket introuvable. Assurez-vous que Terraform a été appliqué."; \
		exit 1; \
	fi; \
	aws s3 cp data/input/football_matches_2024_2025.csv "s3://$$BUCKET/matches/" --region $(AWS_REGION)
	@echo "Données uploadées!"

check-data:
	@echo "Vérification des données..."
	@BUCKET=$$(cd $(TERRAFORM_DIR) && terraform output -raw data_bucket_name 2>/dev/null); \
	if [ -z "$$BUCKET" ]; then \
		echo "Bucket introuvable."; \
		exit 1; \
	fi; \
	echo "S3 matches/:" && aws s3 ls "s3://$$BUCKET/matches/" --region $(AWS_REGION) || true; \
	echo ""; \
	echo "S3 goals_raw/:" && aws s3 ls "s3://$$BUCKET/goals_raw/" --region $(AWS_REGION) || true; \
	echo ""; \
	echo "S3 goals_clean/:" && aws s3 ls "s3://$$BUCKET/goals_clean/" --region $(AWS_REGION) || true

# Producteur
setup-env:
	@echo "Configuration Python..."
	python -m venv venv
	./venv/Scripts/pip install -q -r requirements.txt
	@echo "Environnement Python prêt!"

run-producer: setup-env
	@echo "Lancement du producteur..."
	./venv/Scripts/python src/producers/goals_producer.py

# Logs
logs:
	@echo "Logs AWS Glue:"
	aws logs tail /aws-glue/$(PROJECT_NAME) --follow --region $(AWS_REGION) 2>/dev/null || echo "Aucun log disponible"

# Utilitaires
setup: tf-init setup-env
	@echo "Configuration initiale terminée!"

clean:
	@echo "Nettoyage..."
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	rm -rf .pytest_cache 2>/dev/null || true
	rm -rf venv 2>/dev/null || true
	@echo "Nettoyage terminé!"

structure:
	@echo "Structure du projet:"
	@tree -L 3 -I '__pycache__|*.pyc|venv' . 2>/dev/null || find . -type d | head -30

deploy: tf-apply upload-data
	@echo "Déploiement complet terminé!"
	@echo ""
	@echo "Prochaines étapes:"
	@echo "1. Lancer le producteur: make run-producer"
	@echo "2. Vérifier les données: make check-data"
	@echo "3. Créer les vues Athena (AWS Console)"
	@echo "4. Connecter Power BI"

destroy: tf-destroy clean
	@echo "Tout a été supprimé!"

.DEFAULT_GOAL := help
