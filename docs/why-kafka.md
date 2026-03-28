# Pourquoi Kafka ?

![Topologie du système](./compiled/Diagramme%20sans%20nom-System%20Topology.drawio.png)

Dans Nintcha, six services indépendants doivent collaborer pour réaliser des opérations complexes (invoquer un monstre, lancer un combat). Ce document explique pourquoi **Kafka** a été choisi pour orchestrer ces échanges.

---

## Le problème du couplage direct

Sans Kafka, quand un joueur lance une invocation, `invocation-service` devrait appeler directement `monster-service`, qui appellerait directement `player-service`, etc. :

```
invocation-service  ->  monster-service  ->  player-service
```

Problèmes :
- **Si `monster-service` est down**, toute l'invocation échoue immédiatement
- **Les services sont couplés** : changer l'API de `monster-service` casse `invocation-service`
- **Le client attend** pendant toute la chaîne, latence qui s'accumule
- **Un seul point de défaillance** pour une opération qui touche 3 services

---

## La solution : découplage par événements

Kafka introduit un intermédiaire : un **bus de messages** entre les services.
Plutôt que d'appeler directement un autre service, un service publie un événement dans un *topic* Kafka et continue son travail.

Les autres services consomment cet événement quand ils sont prêts.

```
invocation-service  ->  [invocations.requested]   ->  monster-service
monster-service     ->  [monsters.created]        ->  player-service
player-service      ->  [invocations.completed]   ->  invocation-service
```

Résultats :
- **Si `monster-service` est down**, l'événement reste dans Kafka et sera traité au redémarrage — rien n'est perdu
- **Les services ne se connaissent pas** : `invocation-service` n'a pas besoin de l'URL de `monster-service`
- **Le client reçoit une réponse immédiate** (202 Accepted) et poll le statut jusqu'à completion

---

## Exemple concret : le flux d'invocation

```
Client -> POST /invocations
           └─ invocation-service crée l'invocation (PENDING_STAMINA)
              └─ publie StaminaConsumeRequest → [stamina.consume-requests]

                 stamina-service consomme l'événement
                 └─ vérifie la stamina, déduit 20
                    └─ publie StaminaConsumeResult → [stamina.consume-results]

                       invocation-service consomme le résultat
                       └─ stamina OK → lance l'algo gacha
                          └─ publie InvocationTask → [invocations.requested]

                             monster-service consomme la tâche
                             └─ crée l'instance monstre en base
                                └─ publie MonsterCreatedEvent → [monsters.created]

                                   player-service consomme l'événement
                                   └─ ajoute le monstre à l'inventaire
                                      └─ publie InvocationCompletedEvent → [invocations.completed]

                                         invocation-service met à jour le statut → COMPLETED
```

Le client poll `GET /invocations/{id}`
Dès que le statut passe à `COMPLETED`, il récupère son monstre.

Chaque étape est **indépendante et réessayable** en cas d'échec.

---

## Le pattern Saga (choreography)

Ce flux illustre le **pattern Saga par chorégraphie** : il n'y a pas d'orchestrateur central qui dirige les étapes. Chaque service réagit aux événements qui le concernent et publie le suivant. Les services sont **autonomes**

C'est différent du pattern Orchestration où un service central (ex: un workflow engine) appellerait chaque service dans l'ordre et gérerait les compensations

---

## L'exception : l'authentification reste synchrone

L'auth est le **seul échange synchrone** entre services. Chaque service appelle `auth-service` via REST (via `AuthClient` dans le module `common`) avant de traiter une requête.

Pourquoi ne pas passer par Kafka ici ? Parce que la validation est **bloquante par nature** : on ne peut pas commencer à traiter une requête sans savoir d'abord si l'utilisateur est autorisé. Il faut une réponse immédiate.

```
Toutes les communications inter-services
  ├── auth validation  -> REST synchrone  (AuthClient de common)
  └── tout le reste    ->  Kafka asynchrone
```
