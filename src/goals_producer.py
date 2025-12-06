#!/usr/bin/env python3
"""
Script producteur pour envoyer les données de buts à Amazon Kinesis
Ce script simule des buts marqués et les envoie à Kinesis en temps réel.
"""

import json
import boto3
import time
import random
from datetime import datetime
from typing import Dict, Any

# Configuration
KINESIS_STREAM_NAME = "goals-stream"
REGION = "eu-west-1"

# Listes d'équipes et de ligues
TEAMS = {
    "PL": ["Man City", "Man United", "Liverpool", "Arsenal", "Chelsea"],
    "La Liga": ["Real Madrid", "Barcelona", "Atletico Madrid", "Sevilla", "Valencia"],
    "Ligue 1": ["PSG", "Marseille", "Monaco", "Rennes", "Lille"],
    "Serie A": ["Juventus", "AC Milan", "Inter Milan", "Roma", "Napoli"],
}

LEAGUES = list(TEAMS.keys())


class GoalsProducer:
    """Producteur de données de buts pour Kinesis"""

    def __init__(self, stream_name: str, region: str):
        """
        Initialiser le producteur Kinesis

        Args:
            stream_name: Nom du stream Kinesis
            region: Région AWS
        """
        self.kinesis_client = boto3.client("kinesis", region_name=region)
        self.stream_name = stream_name

    def generate_goal_event(self) -> Dict[str, Any]:
        """
        Générer un événement de but

        Returns:
            Dict contenant les informations du but
        """
        league = random.choice(LEAGUES)
        home_team = random.choice(TEAMS[league])
        away_team = random.choice(
            [t for t in TEAMS[league] if t != home_team]
        )
        scorer = f"Player_{random.randint(1, 50)}"
        minute = random.randint(1, 90)
        goal_type = random.choice(["Open Play", "Penalty", "Free Kick", "Header"])

        goal_event = {
            "event_id": f"goal_{datetime.now().timestamp()}",
            "timestamp": datetime.now().isoformat(),
            "league": league,
            "home_team": home_team,
            "away_team": away_team,
            "scorer": scorer,
            "minute": minute,
            "goal_type": goal_type,
            "match_id": f"match_{datetime.now().date()}_{home_team}_{away_team}",
        }

        return goal_event

    def send_goal(self, goal_event: Dict[str, Any]) -> None:
        """
        Envoyer un événement de but à Kinesis

        Args:
            goal_event: Événement de but à envoyer
        """
        try:
            response = self.kinesis_client.put_record(
                StreamName=self.stream_name,
                Data=json.dumps(goal_event),
                PartitionKey=goal_event["league"],
            )
            print(
                f"✓ But envoyé: {goal_event['scorer']} ({goal_event['league']}) - "
                f"SeqNum: {response['SequenceNumber']}"
            )
        except Exception as e:
            print(f"✗ Erreur lors de l'envoi: {e}")

    def run(self, interval: int = 5, duration: int = None) -> None:
        """
        Exécuter le producteur en continu

        Args:
            interval: Intervalle entre les buts (secondes)
            duration: Durée d'exécution (secondes), None = infini
        """
        start_time = time.time()

        print(f"🚀 Démarrage du producteur Kinesis...")
        print(f"   Stream: {self.stream_name}")
        print(f"   Intervalle: {interval}s")
        if duration:
            print(f"   Durée: {duration}s")
        print()

        try:
            while True:
                # Vérifier la durée si spécifiée
                if duration and (time.time() - start_time) > duration:
                    print("\n⏹ Arrêt du producteur (durée atteinte)")
                    break

                # Générer et envoyer un but
                goal_event = self.generate_goal_event()
                self.send_goal(goal_event)

                # Attendre avant le prochain but
                time.sleep(interval)

        except KeyboardInterrupt:
            print("\n\n⏹ Producteur arrêté (Ctrl+C)")
        except Exception as e:
            print(f"\n✗ Erreur fatale: {e}")


def main():
    """Point d'entrée du script"""
    producer = GoalsProducer(KINESIS_STREAM_NAME, REGION)

    # Exécuter le producteur
    # - interval=5: un but toutes les 5 secondes (à adapter)
    # - duration=None: exécution infinie (à adapter pour les tests)
    producer.run(interval=5, duration=None)


if __name__ == "__main__":
    main()
