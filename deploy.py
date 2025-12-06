#!/usr/bin/env python3
"""
Script de déploiement automatisé du pipeline football
"""

import os
import sys
import subprocess
import json
from pathlib import Path

# Couleurs pour terminal
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"

def print_status(status, message):
    """Afficher un message de statut"""
    colors = {
        "INFO": BLUE,
        "OK": GREEN,
        "ERROR": RED,
        "WARNING": YELLOW,
    }
    color = colors.get(status, RESET)
    print(f"{color}[{status}]{RESET} {message}")

def check_prerequisites():
    """Vérifier les prérequis"""
    print_status("INFO", "Vérification des prérequis...")

    requirements = {
        "terraform": "terraform version",
        "aws": "aws --version",
        "python3": "python3 --version",
    }

    missing = []
    for tool, cmd in requirements.items():
        try:
            subprocess.run(cmd, shell=True, capture_output=True, check=True)
            print_status("OK", f"✓ {tool} trouvé")
        except subprocess.CalledProcessError:
            print_status("ERROR", f"✗ {tool} non trouvé")
            missing.append(tool)

    if missing:
        print_status("ERROR", f"Outils manquants: {', '.join(missing)}")
        return False

    return True

def terraform_init():
    """Initialiser Terraform"""
    print_status("INFO", "Initialisation de Terraform...")
    try:
        os.chdir("terraform")
        subprocess.run("terraform init", shell=True, check=True)
        print_status("OK", "✓ Terraform initialisé")
        os.chdir("..")
        return True
    except subprocess.CalledProcessError:
        print_status("ERROR", "✗ Erreur lors de l'init Terraform")
        return False

def terraform_plan():
    """Planifier le déploiement"""
    print_status("INFO", "Planification Terraform...")
    try:
        os.chdir("terraform")
        subprocess.run("terraform plan -out=tfplan", shell=True, check=True)
        print_status("OK", "✓ Plan créé (tfplan)")
        os.chdir("..")
        return True
    except subprocess.CalledProcessError:
        print_status("ERROR", "✗ Erreur lors du plan Terraform")
        return False

def terraform_apply():
    """Appliquer la configuration"""
    print_status("INFO", "Application de Terraform...")
    try:
        os.chdir("terraform")
        subprocess.run("terraform apply tfplan", shell=True, check=True)
        print_status("OK", "✓ Infrastructure créée")
        os.chdir("..")
        return True
    except subprocess.CalledProcessError:
        print_status("ERROR", "✗ Erreur lors de l'apply Terraform")
        return False

def get_terraform_outputs():
    """Récupérer les outputs Terraform"""
    print_status("INFO", "Récupération des outputs...")
    try:
        os.chdir("terraform")
        result = subprocess.run(
            "terraform output -json",
            shell=True,
            capture_output=True,
            text=True,
            check=True
        )
        outputs = json.loads(result.stdout)
        os.chdir("..")
        return outputs
    except Exception as e:
        print_status("ERROR", f"✗ Erreur récupération outputs: {e}")
        return None

def upload_scripts(bucket_name):
    """Uploader les scripts dans S3"""
    print_status("INFO", f"Upload des scripts vers S3 ({bucket_name})...")
    try:
        subprocess.run(
            f"aws s3 cp scripts/ s3://{bucket_name}/scripts/ --recursive",
            shell=True,
            check=True
        )
        print_status("OK", "✓ Scripts uploadés")
        return True
    except subprocess.CalledProcessError:
        print_status("ERROR", "✗ Erreur upload scripts")
        return False

def setup_python_env():
    """Configurer l'environnement Python"""
    print_status("INFO", "Configuration Python...")
    try:
        subprocess.run("python3 -m venv venv", shell=True, check=True)
        print_status("OK", "✓ Environnement virtuel créé")

        # Installation des dépendances
        pip_cmd = "venv/Scripts/pip" if sys.platform == "win32" else "venv/bin/pip"
        subprocess.run(f"{pip_cmd} install -q boto3 requests", shell=True, check=True)
        print_status("OK", "✓ Dépendances installées")
        return True
    except subprocess.CalledProcessError:
        print_status("ERROR", "✗ Erreur configuration Python")
        return False

def main():
    """Fonction principale"""
    print(f"\n{BLUE}{'='*60}")
    print("Football Pipeline - Déploiement Automatisé")
    print(f"{'='*60}{RESET}\n")

    # Vérifier les prérequis
    if not check_prerequisites():
        print_status("ERROR", "Prérequis non satisfaits")
        return 1

    # Configuration Python
    if not setup_python_env():
        print_status("WARNING", "Environnement Python non configuré")

    # Terraform init
    if not terraform_init():
        return 1

    # Terraform plan
    if not terraform_plan():
        return 1

    # Confirmation avant apply
    print(f"\n{YELLOW}Êtes-vous sûr de vouloir déployer? (oui/non){RESET} ", end="")
    if input().lower() not in ["oui", "yes", "y"]:
        print_status("INFO", "Déploiement annulé")
        return 0

    # Terraform apply
    if not terraform_apply():
        return 1

    # Récupérer les outputs
    outputs = get_terraform_outputs()
    if outputs:
        print(f"\n{GREEN}Outputs Terraform:{RESET}")
        print(json.dumps(outputs, indent=2))

        # Upload des scripts si bucket trouvé
        if "data_bucket_name" in outputs:
            bucket = outputs["data_bucket_name"]["value"]
            if not upload_scripts(bucket):
                print_status("WARNING", "Scripts non uploadés")

    print(f"\n{GREEN}{'='*60}")
    print("✓ Déploiement terminé avec succès!")
    print(f"{'='*60}{RESET}\n")

    # Prochaines étapes
    print("Prochaines étapes:")
    print("1. Configurer les vues Athena: scripts/athena_queries.sql")
    print("2. Déployer le producteur: python3 scripts/goals_producer.py")
    print("3. Vérifier les données: AWS Console Glue/Athena")
    print("4. Connecter Power BI via ODBC/JDBC")

    return 0

if __name__ == "__main__":
    sys.exit(main())
