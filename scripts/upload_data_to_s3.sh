#!/bin/bash

# ========================================
# Script d'upload automatisé des données CSV sur S3
# ========================================
# Usage: bash upload_data_to_s3.sh

set -e

# Configuration
PROFILE="${1:-football-pipeline}"
REGION="${2:-us-east-1}"
CSV_FILE="${3:-../data/football_matches_2024_2025.csv}"
S3_PATH="${4:-matches/}"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Upload Football Data to S3 - Automated Script         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"

# [1/5] Vérifier que le fichier CSV existe
echo -e "\n${YELLOW}[1/5] Vérification du fichier CSV...${NC}"
if [ ! -f "$CSV_FILE" ]; then
    echo -e "${RED}❌ Fichier non trouvé: $CSV_FILE${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Fichier trouvé: $CSV_FILE${NC}"

FILE_SIZE=$(du -h "$CSV_FILE" | cut -f1)
echo -e "    Taille: $FILE_SIZE"

# [2/5] Obtenir le compte AWS
echo -e "\n${YELLOW}[2/5] Récupération de l'ID du compte AWS...${NC}"
if ! ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile "$PROFILE" 2>/dev/null); then
    echo -e "${RED}❌ Erreur: Impossible de récupérer l'ID du compte${NC}"
    echo -e "${RED}   Vérifiez votre profil AWS: $PROFILE${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Compte AWS: $ACCOUNT_ID${NC}"

# Construire le nom du bucket
BUCKET_NAME="football-pipeline-dev-raw-$ACCOUNT_ID"
echo -e "    Bucket: $BUCKET_NAME"

# [3/5] Vérifier que le bucket existe
echo -e "\n${YELLOW}[3/5] Vérification du bucket S3...${NC}"
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" --profile "$PROFILE" 2>/dev/null; then
    echo -e "${RED}❌ Bucket non accessible: $BUCKET_NAME${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Bucket accessible${NC}"

# [4/5] Uploader le fichier
echo -e "\n${YELLOW}[4/5] Upload du fichier CSV sur S3...${NC}"
S3_URI="s3://$BUCKET_NAME/$S3_PATH"
FILE_NAME=$(basename "$CSV_FILE")

echo -e "    Source: $CSV_FILE"
echo -e "    Destination: $S3_URI$FILE_NAME"

if ! aws s3 cp "$CSV_FILE" "$S3_URI$FILE_NAME" --region "$REGION" --profile "$PROFILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ Erreur lors de l'upload${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Fichier uploadé avec succès${NC}"

# [5/5] Vérifier l'upload
echo -e "\n${YELLOW}[5/5] Vérification de l'upload...${NC}"
if OUTPUT=$(aws s3api head-object --bucket "$BUCKET_NAME" --key "$S3_PATH$FILE_NAME" --region "$REGION" --profile "$PROFILE" 2>/dev/null); then
    SIZE=$(echo "$OUTPUT" | grep -o '"ContentLength": [0-9]*' | grep -o '[0-9]*' | awk '{print $1/1024/1024}')
    ETAG=$(echo "$OUTPUT" | grep -o '"ETag": "[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}✓ Fichier vérifié sur S3${NC}"
    echo -e "    Taille: ${SIZE}MB"
    echo -e "    ETag: $ETAG"
else
    echo -e "${YELLOW}⚠️  Impossible de vérifier le fichier${NC}"
fi

# Résumé final
echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                   ✓ Upload Complété                           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Résumé:${NC}"
echo -e "  • Fichier: $FILE_NAME"
echo -e "  • Bucket: $BUCKET_NAME"
echo -e "  • Chemin S3: $S3_PATH$FILE_NAME"
echo -e "  • Région: $REGION"
echo -e "  • Compte: $ACCOUNT_ID"

echo -e "\n${GREEN}Prochaines étapes:${NC}"
echo -e "  1. Déclencher le Glue Crawler"
echo -e "  2. Exécuter le Glue ETL Job"
echo -e "  3. Requêter les données dans Athena"

echo ""
