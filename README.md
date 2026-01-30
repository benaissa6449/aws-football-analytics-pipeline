# Informations Projet

## Métadonnées

- **Nom** : Football Pipeline - Data Processing for Cloud
- **Version** : 1.0.0
- **Date de création** : 6 décembre 2024
- **Statut** : Production-Ready

## Objectifs

1. Ingérer les données de matchs de football (CSV batch)
2. Collecter les événements de buts en temps réel (Kinesis)
3. Transformer et nettoyer les données (Glue ETL)
4. Cataloguer les données (Glue Data Catalog)
5. Analyser via SQL (Amazon Athena)
6. Visualiser dans Power BI

## Stakeholders

- **Product Owner** : [À définir]
- **Data Engineers** : [À définir]
- **DevOps** : [À définir]

## Métriques

- **Volume de données** : ~1M de goals/jour (à l'échelle)
- **Latence** : Temps réel (< 5 min) pour Firehose
- **RTO** : 1 heure
- **RPO** : 15 minutes

## Coûts Estimés (par mois)

| Service | Estimation |
|---------|-----------|
| S3 | $5-10 |
| Kinesis (ON_DEMAND) | $10-20 |
| Firehose | $5-10 |
| Glue ETL | $5-15 |
| Athena | $5-10 |
| **Total** | **$30-65** |

*Note: À adapter selon l'utilisation réelle*

## Phases de Déploiement

### Phase 1: Infrastructure (Semaine 1)
- [x] Terraform setup
- [x] VPC configuration
- [x] IAM roles
- [x] S3 buckets

### Phase 2: Ingestion (Semaine 2)
- [x] Kinesis setup
- [x] Firehose configuration
- [x] Producteur Python
- [x] CSV upload

### Phase 3: Transformation (Semaine 3)
- [x] Glue Job ETL
- [x] Glue Crawler
- [x] Data Catalog

### Phase 4: Analyse (Semaine 4)
- [x] Athena workgroup
- [x] Vues SQL
- [x] Power BI connection
- [x] Dashboards

## Checklist Pré-Déploiement

- [ ] AWS Account créé
- [ ] Credentials configurées
- [ ] Terraform installé
- [ ] Python 3.8+ installé
- [ ] Git configuré
- [ ] Budget alertes configurées
- [ ] Approvals obtenues

## Conformité & Sécurité

- [ ] VPC privé configuré
- [ ] IAM Least Privilege appliqué
- [ ] Encryption S3 activée
- [ ] Logs CloudWatch configurés
- [ ] Backup S3 configuré
- [ ] Monitoring alertes configurées
- [ ] Audit logging activé

## Support

Pour des questions ou problèmes :
1. Consulter la documentation : `docs/`
2. Vérifier les logs : `make logs`
3. Contacter l'équipe DevOps

## Évolution Future

- [ ] Multi-région
- [ ] Machine Learning (predictions)
- [ ] Real-time notifications
- [ ] Mobile app
- [ ] API REST
- [ ] Slack integration

## Références

- AWS Glue: https://docs.aws.amazon.com/glue/
- Terraform: https://www.terraform.io/docs
- Kinesis: https://docs.aws.amazon.com/kinesis/
- Athena: https://docs.aws.amazon.com/athena/

---

**Document créé** : 6 décembre 2024
