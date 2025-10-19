# Everstead Architecture

## OTP Supervision Tree

```mermaid
graph TB
    %% Application Level
    App[Everstead.Application]
    
    %% Core Infrastructure
    App --> Telemetry[EversteadWeb.Telemetry]
    App --> Repo[Everstead.Repo]
    App --> DNS[DNSCluster]
    App --> PubSub[Phoenix.PubSub]
    App --> Endpoint[EversteadWeb.Endpoint]
    
    %% Registries
    App --> PlayerReg[PlayerRegistry]
    App --> KingdomReg[KingdomRegistry]
    App --> VillagerReg[VillagerRegistry]
    
    %% Main Simulation Tree
    App --> WorldSup[World.Supervisor]
    
    %% World Level
    WorldSup --> WorldServer[World.Server]
    WorldSup --> PlayerDynSup[Player.DynamicSupervisor]
    
    %% Player Level (Dynamic)
    PlayerDynSup --> PlayerSup1[Player.Supervisor<br/>Player 1]
    PlayerDynSup --> PlayerSup2[Player.Supervisor<br/>Player 2]
    PlayerDynSup --> PlayerSupN[Player.Supervisor<br/>Player N]
    
    %% Individual Player Structure
    PlayerSup1 --> PlayerServer1[Player.Server<br/>Player 1]
    PlayerSup1 --> KingdomSup1[Kingdom.Supervisor<br/>Player 1]
    
    %% Kingdom Level
    KingdomSup1 --> VillagerSup1[Villager.Supervisor<br/>Player 1]
    KingdomSup1 --> JobManagerSup1[JobManager.Supervisor<br/>Player 1]
    
    %% Villager Level (Dynamic)
    VillagerSup1 --> Villager1[Villager.Server<br/>Villager 1]
    VillagerSup1 --> Villager2[Villager.Server<br/>Villager 2]
    VillagerSup1 --> VillagerN[Villager.Server<br/>Villager N]
    
    %% Job Manager Level
    JobManagerSup1 --> JobManager1[JobManager.Server<br/>Player 1]
    
    %% Styling
    classDef application fill:#e1f5fe
    classDef registry fill:#f3e5f5
    classDef supervisor fill:#e8f5e8
    classDef server fill:#fff3e0
    classDef dynamic fill:#fce4ec
    
    class App application
    class PlayerReg,KingdomReg,VillagerReg registry
    class WorldSup,PlayerSup1,KingdomSup1,VillagerSup1,JobManagerSup1 supervisor
    class WorldServer,PlayerServer1,JobManager1 server
    class PlayerDynSup,Villager1,Villager2,VillagerN dynamic
```

## Process Communication

```mermaid
sequenceDiagram
    participant WS as World.Server
    participant PDS as Player.DynamicSupervisor
    participant PS as Player.Server
    participant KS as Kingdom.Supervisor
    participant VS as Villager.Supervisor
    participant VServ as Villager.Server
    participant JMS as JobManager.Server
    
    Note over WS: Tick Event (1 second)
    WS->>PDS: send(:tick)
    PDS->>PS: send(:tick)
    PS->>JMS: cast({:assign_jobs, villagers})
    JMS->>VServ: cast({:assign_job, job})
    VServ->>PS: call(:get_state)
    PS->>VServ: call(:update_resources)
```

## Registry Architecture

```mermaid
graph LR
    subgraph "Process Discovery"
        PR[PlayerRegistry<br/>player_id → player_pid]
        KR[KingdomRegistry<br/>kingdom_id → kingdom_pid]
        VR[VillagerRegistry<br/>villager_id → villager_pid]
    end
    
    subgraph "Naming Convention"
        PR --> P1[player_123]
        KR --> K1[kingdom_player_123]
        KR --> K2[villagers_player_123]
        KR --> K3[jobmanager_player_123]
        VR --> V1[villager_456]
    end
```

## Error Handling

```mermaid
graph TD
    A[Process Crash] --> B{Supervisor Strategy}
    B -->|one_for_one| C[Restart Only Crashed Process]
    B -->|one_for_all| D[Restart All Children]
    B -->|rest_for_one| E[Restart Crashed + Following]
    
    C --> F[Isolated Failure]
    D --> G[Complete Restart]
    E --> H[Partial Restart]
    
    F --> I[Continue Operation]
    G --> J[Full Recovery]
    H --> K[Selective Recovery]
```

## OTP Supervision Tree

The following Mermaid diagram shows the complete OTP supervision tree structure:

```mermaid
graph TB
    %% Application Level
    App[Everstead.Application]
    
    %% Core Infrastructure
    App --> Telemetry[EversteadWeb.Telemetry]
    App --> Repo[Everstead.Repo]
    App --> DNS[DNSCluster]
    App --> PubSub[Phoenix.PubSub]
    App --> Endpoint[EversteadWeb.Endpoint]
    
    %% Registries
    App --> PlayerReg[PlayerRegistry]
    App --> KingdomReg[KingdomRegistry]
    App --> VillagerReg[VillagerRegistry]
    
    %% Main Simulation Tree
    App --> WorldSup[World.Supervisor]
    
    %% World Level
    WorldSup --> WorldServer[World.Server]
    WorldSup --> PlayerDynSup[Player.DynamicSupervisor]
    
    %% Player Level (Dynamic)
    PlayerDynSup --> PlayerSup1[Player.Supervisor<br/>Player 1]
    PlayerDynSup --> PlayerSup2[Player.Supervisor<br/>Player 2]
    PlayerDynSup --> PlayerSupN[Player.Supervisor<br/>Player N]
    
    %% Individual Player Structure
    PlayerSup1 --> PlayerServer1[Player.Server<br/>Player 1]
    PlayerSup1 --> KingdomSup1[Kingdom.Supervisor<br/>Player 1]
    
    %% Kingdom Level
    KingdomSup1 --> VillagerSup1[Villager.Supervisor<br/>Player 1]
    KingdomSup1 --> JobManagerSup1[JobManager.Supervisor<br/>Player 1]
    
    %% Villager Level (Dynamic)
    VillagerSup1 --> Villager1[Villager.Server<br/>Villager 1]
    VillagerSup1 --> Villager2[Villager.Server<br/>Villager 2]
    VillagerSup1 --> VillagerN[Villager.Server<br/>Villager N]
    
    %% Job Manager Level
    JobManagerSup1 --> JobManager1[JobManager.Server<br/>Player 1]
    
    %% Styling
    classDef application fill:#e1f5fe
    classDef registry fill:#f3e5f5
    classDef supervisor fill:#e8f5e8
    classDef server fill:#fff3e0
    classDef dynamic fill:#fce4ec
    
    class App application
    class PlayerReg,KingdomReg,VillagerReg registry
    class WorldSup,PlayerSup1,KingdomSup1,VillagerSup1,JobManagerSup1 supervisor
    class WorldServer,PlayerServer1,JobManager1 server
    class PlayerDynSup,Villager1,Villager2,VillagerN dynamic
```

### Supervision Tree Explanation

#### **Application Level**
- **Everstead.Application**: Root supervisor managing all system components
- **Infrastructure**: Telemetry, Database, DNS, PubSub, Web Endpoint
- **Registries**: Three specialized registries for process discovery

#### **World Level**
- **World.Supervisor**: Manages the global simulation state
- **World.Server**: Central tick coordinator (1-second intervals)
- **Player.DynamicSupervisor**: Manages dynamic player creation/removal

#### **Player Level** (Per Player)
- **Player.Supervisor**: Isolates each player's kingdom
- **Player.Server**: Manages player state and resources
- **Kingdom.Supervisor**: Manages kingdom-specific processes

#### **Kingdom Level** (Per Player)
- **Villager.Supervisor**: Dynamic supervisor for villager processes
- **JobManager.Supervisor**: Manages job assignment and tracking

#### **Entity Level** (Per Entity)
- **Villager.Server**: Individual villager AI and state
- **JobManager.Server**: Job queue and assignment logic

## Process Communication

### Communication Patterns

```mermaid
sequenceDiagram
    participant WS as World.Server
    participant PDS as Player.DynamicSupervisor
    participant PS as Player.Server
    participant KS as Kingdom.Supervisor
    participant VS as Villager.Supervisor
    participant VServ as Villager.Server
    participant JMS as JobManager.Server
    
    Note over WS: Tick Event (1 second)
    WS->>PDS: send(:tick)
    PDS->>PS: send(:tick)
    PS->>JMS: cast({:assign_jobs, villagers})
    JMS->>VServ: cast({:assign_job, job})
    VServ->>PS: call(:get_state)
    PS->>VServ: call(:update_resources)
```

### Message Types

1. **Synchronous Communication** (`GenServer.call/2`)
   - State queries and updates
   - Resource validation
   - Critical operations requiring confirmation

2. **Asynchronous Communication** (`GenServer.cast/2`)
   - Job assignments
   - Resource updates
   - Non-critical operations

3. **Direct Message Passing** (`send/2`)
   - Tick events
   - Emergency notifications
   - Broadcast messages

## Registry Architecture

### Registry Hierarchy

```mermaid
graph LR
    subgraph "Process Discovery"
        PR[PlayerRegistry<br/>player_id → player_pid]
        KR[KingdomRegistry<br/>kingdom_id → kingdom_pid]
        VR[VillagerRegistry<br/>villager_id → villager_pid]
    end
    
    subgraph "Naming Convention"
        PR --> P1[player_123]
        KR --> K1[kingdom_player_123]
        KR --> K2[villagers_player_123]
        KR --> K3[jobmanager_player_123]
        VR --> V1[villager_456]
    end
```

### Registry Usage Patterns

- **PlayerRegistry**: Maps player IDs to player server PIDs
- **KingdomRegistry**: Maps kingdom-related process names to PIDs
  - `kingdom_<player_id>` → Kingdom.Supervisor
  - `villagers_<player_id>` → Villager.Supervisor
  - `jobmanager_<player_id>` → JobManager.Server
- **VillagerRegistry**: Maps villager IDs to villager server PIDs

## Error Handling Strategy

### Supervision Strategies

```mermaid
graph TD
    A[Process Crash] --> B{Supervisor Strategy}
    B -->|one_for_one| C[Restart Only Crashed Process]
    B -->|one_for_all| D[Restart All Children]
    B -->|rest_for_one| E[Restart Crashed + Following]
    
    C --> F[Isolated Failure]
    D --> G[Complete Restart]
    E --> H[Partial Restart]
    
    F --> I[Continue Operation]
    G --> J[Full Recovery]
    H --> K[Selective Recovery]
```

### Error Recovery Mechanisms

1. **Process Crashes**: Supervisors restart crashed processes
2. **Stale Jobs**: JobManager detects and reassigns orphaned jobs
3. **Resource Validation**: All operations validate resources before execution
4. **Circuit Breakers**: Cross-process communication includes error handling
5. **Graceful Degradation**: System continues operating with reduced functionality

## Scalability Considerations

### Horizontal Scaling

```mermaid
graph TB
    subgraph "Node 1"
        App1[Application]
        World1[World.Server]
        Players1[Player.DynamicSupervisor]
    end
    
    subgraph "Node 2"
        App2[Application]
        World2[World.Server]
        Players2[Player.DynamicSupervisor]
    end
    
    subgraph "Shared Resources"
        DB[(Database)]
        PubSub[Phoenix.PubSub]
    end
    
    App1 --> DB
    App2 --> DB
    App1 --> PubSub
    App2 --> PubSub
```

### Performance Characteristics

| Component | Process Count | Memory per Process | Communication Pattern |
|-----------|---------------|-------------------|----------------------|
| World.Server | 1 | ~1KB | Broadcast |
| Player.Server | N (players) | ~5KB | Call/Cast |
| Villager.Server | M (villagers) | ~2KB | Call/Cast |
| JobManager.Server | N (players) | ~3KB | Cast |

### Bottleneck Analysis

1. **World Server**: Single point of failure for tick coordination
2. **Registry Scanning**: O(n) complexity for broadcasting
3. **Memory Growth**: Process proliferation with many villagers
4. **Cross-Process Calls**: Potential latency in job assignment

## Performance Optimizations

### Current Optimizations

- **Process Isolation**: Prevents cascade failures
- **Asynchronous Communication**: Non-blocking operations
- **Registry Caching**: Efficient process discovery
- **Batch Operations**: Grouped villager updates

### Recommended Improvements

1. **Phoenix.PubSub Broadcasting**: Replace Registry.select for broadcasting
2. **Process Pooling**: Group simple villagers into fewer processes
3. **Circuit Breakers**: Add resilience to cross-process communication
4. **Monitoring**: Implement comprehensive telemetry

## Future Architecture Considerations

### Planned Enhancements

1. **Clustering Support**: Multi-node deployment
2. **Process Migration**: Move players between nodes
3. **Advanced Monitoring**: Real-time performance metrics
4. **Event Sourcing**: Audit trail for game state changes

### Modding Architecture

The current architecture supports future modding through:

- **Plugin System**: Add new building types
- **Custom Jobs**: Create new job types
- **Seasonal Events**: Add special seasonal occurrences
- **Resource Types**: Introduce new resource types

---

This architecture provides a solid foundation for a scalable, fault-tolerant kingdom simulation game while maintaining the flexibility to grow and evolve with new features.
