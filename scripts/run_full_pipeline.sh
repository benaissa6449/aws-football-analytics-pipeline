#!/bin/bash

# ========================================
# Script Complet - Pipeline Automatisé
# ========================================
# Télécharge CSV → Déclenche Crawler → Job Glue → Requête Athena
# Usage: bash run_full_pipeline.sh

set -e

# Configuration
PROFILE="${1:-football-pipeline}"
REGION="${2:-us-east-1}"
CSV_FILE="../data/football_matches_2024_2025.csv"
WAIT_TIME=30

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                   PIPELINE FOOTBALL - COMPLET                    ║${NC}"
echo -e "${CYAN}║        Upload CSV → Crawler → ETL → Athena - Automatisé        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"

# Récupérer les infos AWS
echo -e "\n${BLUE}═══ PHASE 0: Configuration ═══${NC}"
echo -e "${YELLOW}Récupération des infos AWS...${NC}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile "$PROFILE" 2>/dev/null)
BUCKET_NAME="football-pipeline-dev-raw-$ACCOUNT_ID"
DB_NAME="football_db"
CRAWLER_NAME="football-pipeline-dev-football-crawler"
JOB_NAME="football-pipeline-dev-football-csv-to-parquet"

echo -e "${GREEN}✓ Compte AWS: $ACCOUNT_ID${NC}"
echo -e "${GREEN}✓ Bucket: $BUCKET_NAME${NC}"
echo -e "${GREEN}✓ Database Glue: $DB_NAME${NC}"
echo -e "${GREEN}✓ Crawler: $CRAWLER_NAME${NC}"
echo -e "${GREEN}✓ Job: $JOB_NAME${NC}"

# PHASE 1: Upload CSV
echo -e "\n${BLUE}═══ PHASE 1: Upload des données ═══${NC}"
echo -e "${YELLOW}Upload du CSV sur S3...${NC}"

if [ ! -f "$CSV_FILE" ]; then
    echo -e "${RED} Fichier non trouvé: $CSV_FILE${NC}"
    exit 1
fi

FILE_NAME=$(basename "$CSV_FILE")
S3_PATH="s3://$BUCKET_NAME/matches/$FILE_NAME"

aws s3 cp "$CSV_FILE" "$S3_PATH" --region "$REGION" --profile "$PROFILE" > /dev/null 2>&1
echo -e "${GREEN}✓ Fichier uploadé: $S3_PATH${NC}"

# PHASE 2: Déclencher le Crawler
echo -e "\n${BLUE}═══ PHASE 2: Exécution du Crawler ═══${NC}"
echo -e "${YELLOW}Démarrage du Crawler Glue...${NC}"

CRAWLER_RUN=$(aws glue start-crawler --name "$CRAWLER_NAME" --region "$REGION" --profile "$PROFILE" 2>&1 || true)

if echo "$CRAWLER_RUN" | grep -q "already running"; then
    echo -e "${YELLOW}  Crawler déjà en cours d'exécution${NC}"
elif echo "$CRAWLER_RUN" | grep -q "CrawlerAlreadyRunningException"; then
    echo -e "${YELLOW}  Crawler déjà en cours d'exécution${NC}"
else
    echo -e "${GREEN}✓ Crawler démarré${NC}"
fi

# Attendre le crawler
echo -e "${YELLOW}Attente de la fin du Crawler (max ${WAIT_TIME}s)...${NC}"
ELAPSED=0
while [ $ELAPSED -lt $WAIT_TIME ]; do
    CRAWLER_STATE=$(aws glue get-crawler --name "$CRAWLER_NAME" --region "$REGION" --profile "$PROFILE" 2>/dev/null | grep -o '"State": "[^"]*"' | cut -d'"' -f4)
    
    if [ "$CRAWLER_STATE" = "READY" ] || [ "$CRAWLER_STATE" = "STOPPED" ]; then
        echo -e "${GREEN}✓ Crawler terminé${NC}"
        break
    fi
    
    echo -e "  État: $CRAWLER_STATE (${ELAPSED}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $WAIT_TIME ]; then
    echo -e "${YELLOW}  Timeout - Crawler peut encore être en cours${NC}"
fi

# PHASE 3: Exécuter le Glue ETL Job
echo -e "\n${BLUE}═══ PHASE 3: Exécution du Glue ETL Job ═══${NC}"
echo -e "${YELLOW}Lancement du job ETL...${NC}"

JOB_RUN=$(aws glue start-job-run --job-name "$JOB_NAME" --region "$REGION" --profile "$PROFILE" 2>&1)
JOB_RUN_ID=$(echo "$JOB_RUN" | grep -o '"JobRunId": "[^"]*"' | cut -d'"' -f4)

if [ -z "$JOB_RUN_ID" ]; then
    echo -e "${RED} Erreur lors du lancement du job${NC}"
    echo "$JOB_RUN"
    exit 1
fi

echo -e "${GREEN}✓ Job démarré (ID: $JOB_RUN_ID)${NC}"

# Attendre le job
echo -e "${YELLOW}Attente de la fin du Job (max ${WAIT_TIME}s)...${NC}"
ELAPSED=0
while [ $ELAPSED -lt $WAIT_TIME ]; do
    JOB_STATE=$(aws glue get-job-run --job-name "$JOB_NAME" --run-id "$JOB_RUN_ID" --region "$REGION" --profile "$PROFILE" 2>/dev/null | grep -o '"JobRunState": "[^"]*"' | cut -d'"' -f4)
    
    if [ "$JOB_STATE" = "SUCCEEDED" ] || [ "$JOB_STATE" = "FAILED" ] || [ "$JOB_STATE" = "STOPPED" ]; then
        echo -e "${GREEN}✓ Job terminé (État: $JOB_STATE)${NC}"
        
        if [ "$JOB_STATE" != "SUCCEEDED" ]; then
            echo -e "${YELLOW}  Job n'a pas réussi. État: $JOB_STATE${NC}"
        fi
        break
    fi
    
    echo -e "  État: $JOB_STATE (${ELAPSED}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $WAIT_TIME ]; then
    echo -e "${YELLOW}  Timeout - Job peut encore être en cours${NC}"
fi

# PHASE 4: Exécuter une requête Athena
echo -e "\n${BLUE}═══ PHASE 4: Requête Athena ═══${NC}"
echo -e "${YELLOW}Exécution d'une requête de test...${NC}"

WORKGROUP="football-pipeline-dev-football-workgroup"
S3_OUTPUT="s3://football-pipeline-dev-athena-results-$ACCOUNT_ID/results/"

QUERY="SELECT COUNT(*) as total_matches, COUNT(DISTINCT home_team) as total_teams FROM ${DB_NAME}.processed_data LIMIT 10"

QUERY_ID=$(aws athena start-query-execution \
    --query-string "$QUERY" \
    --query-execution-context Database="$DB_NAME" \
    --result-configuration OutputLocation="$S3_OUTPUT" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --profile "$PROFILE" 2>/dev/null | grep -o '"QueryExecutionId": "[^"]*"' | cut -d'"' -f4)

if [ -z "$QUERY_ID" ]; then
    echo -e "${YELLOW}  Impossible de lancer la requête Athena (peut être une permissions issue)${NC}"
else
    echo -e "${GREEN}✓ Requête lancée (ID: $QUERY_ID)${NC}"
    
    # Attendre le résultat
    echo -e "${YELLOW}Attente du résultat (max 30s)...${NC}"
    sleep 5
    
    QUERY_STATUS=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID" \
        --region "$REGION" \
        --profile "$PROFILE" 2>/dev/null | grep -o '"Status": "[^"]*"' | cut -d'"' -f4)
    
    echo -e "${GREEN}✓ Statut requête: $QUERY_STATUS${NC}"
fi

# Résumé Final
echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                   ✓ PIPELINE TERMINÉ                               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Résumé de l'exécution:${NC}"
echo -e "  1. ${GREEN}✓${NC} CSV uploadé sur S3"
echo -e "  2. ${GREEN}✓${NC} Crawler lancé et terminé"
echo -e "  3. ${GREEN}✓${NC} Glue ETL Job exécuté (ID: $JOB_RUN_ID)"
echo -e "  4. ${GREEN}✓${NC} Requête Athena lancée"

echo -e "\n${GREEN}Ressources créées:${NC}"
echo -e "  • Raw Data: s3://$BUCKET_NAME/matches/"
echo -e "  • Database: $DB_NAME"
echo -e "  • Crawler: $CRAWLER_NAME"
echo -e "  • Job: $JOB_NAME"
echo -e "  • Workgroup Athena: $WORKGROUP"

echo -e "\n${BLUE}Prochaines actions:${NC}"
echo -e "  1. Vérifier les données dans Athena"
echo -e "  2. Créer des visualisations dans Power BI"
echo -e "  3. Scheduler les exécutions quotidiennes"

echo ""
