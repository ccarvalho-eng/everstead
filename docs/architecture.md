# Architecture

## OTP Supervision Tree

```mermaid
graph TB
    App[Everstead.Application]
    App --> Telemetry[EversteadWeb.Telemetry]
    App --> Repo[Everstead.Repo]
    App --> PubSub[Phoenix.PubSub]
    App --> Endpoint[EversteadWeb.Endpoint]
    App --> PlayerReg[PlayerRegistry]
    App --> KingdomReg[KingdomRegistry]
    App --> VillagerReg[VillagerRegistry]
    App --> WorldSup[World.Supervisor]
    
    WorldSup --> WorldServer[World.Server]
    WorldSup --> PlayerDynSup[Player.DynamicSupervisor]
    
    PlayerDynSup --> PlayerSup[Player.Supervisor]
    PlayerSup --> PlayerServer[Player.Server]
    PlayerSup --> KingdomSup[Kingdom.Supervisor]
    
    KingdomSup --> VillagerSup[Villager.Supervisor]
    KingdomSup --> JobManagerSup[JobManager.Supervisor]
    
    VillagerSup --> VillagerServer[Villager.Server]
    JobManagerSup --> JobManagerServer[JobManager.Server]
    
    classDef application fill:#e1f5fe
    classDef registry fill:#f3e5f5
    classDef supervisor fill:#e8f5e8
    classDef server fill:#fff3e0
    
    class App application
    class PlayerReg,KingdomReg,VillagerReg registry
    class WorldSup,PlayerSup,KingdomSup,VillagerSup,JobManagerSup supervisor
    class WorldServer,PlayerServer,VillagerServer,JobManagerServer server
```

## Process Communication

```mermaid
sequenceDiagram
    participant WS as World.Server
    participant PS as Player.Server
    participant JMS as JobManager.Server
    participant VS as Villager.Server
    
    WS->>PS: send(:tick)
    PS->>JMS: cast({:assign_jobs, villagers})
    JMS->>VS: cast({:assign_job, job})
    VS->>PS: call(:update_resources)
```

## Registries

- **PlayerRegistry**: `player_id → player_pid`
- **KingdomRegistry**: `kingdom_id → kingdom_pid`
- **VillagerRegistry**: `villager_id → villager_pid`
