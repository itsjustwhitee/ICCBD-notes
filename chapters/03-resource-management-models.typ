#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= RESOURCE MANAGEMENT MODELS
#extra[
  Package: Resource Management Models - `3-Resource Mngm Models 26.pdf`
]

Once an application is launched, it should ideally #hl[*run forever without interruption*]. In practice, systems need to be *observed* and *controlled* during execution. Resource management is the discipline of:

- #hl[*Monitoring *and* observing* the system to understand] resource usage and trends.
- #hl[*Controlling *and* changing* resources to correct problems] and maintain performance.

This chapter covers the fundamental models and strategies behind this runtime management.

== Quality of Service (QoS) <ch03-qos>

Every system must clearly define the *quality* of the services it offers. The notion of #kw[QoS] (Quality of Service) #hl[quantifies how well a service is delivered] and connects directly to the system lifecycle.

#def("Quality of Service (QoS)")[
  #kw[QoS] defines the *context of system operation* and *quantifies* the *observable features* of service delivery, from the provider's perspective toward its requestors. It spans the *entire life cycle* of the service while running.
]

Telco providers historically defined service levels via measurable indicators: throughput, latency, jitter, Mean Time Between Failures (MTBF), etc. Application service providers must extend these with *user-experience* indicators (KPIs, Key Performance Indicators).

#extra[The concept of "tag qualities" (telco-oriented measurable properties attached to the service) is the origin of modern QoS indicators.]

QoS must cover many dimensions:
- *Performance*
- *Scalability*
- *Correctness*
- *Reliability*
- *Security*

=== Functional vs. Non-Functional Properties

#table(
  columns: (auto, 1fr, auto),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header(
    [*Type*], [*Description*], [*Measurability*],
  ),
  [#hl[*Functional*]\ _(simple & objective)_], [#hl[Directly measurable]: _avg packet delay, bandwidth, packet loss rate, throughput_.], [#hl[Easy to quantify].],
  [#hl[*Non-Functional*]\ _(hard & subjective)_], [#hl[Hard to measure]: _long-term availability, security level, perceived video quality (Quality of Experience, QoE)_.], [#hl[Subjective or indirect].],
)
#v(-1em)
#note[
  #underline[Both] types must be considered. #hl[QoE is almost as important as QoS].
]

=== QoS Verification and Control

Once QoS is defined, the system must *verify* it at runtime and *act* when deviations occur. Two mechanisms are required:

1. #hl[*Monitoring support*] #swarrow collects fresh information on system state (logs, online metrics) to identify trends and anticipate problems.
2. #hl[*Control actions*] #swarrow allow interventions on the system to correct settings before a failure or degradation occurs.

=== The 3 Planes <ch03-three-planes>

To support an application execution, modern IT systems separate concerns into distinct planes:

#table(
  columns: (auto, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Plane*], [*Role*]),
  [*User Plane / Data Plane*], [Application execution and main data traffic #swarrow #hl[*Business logic*].\ The level where the application actually runs.],
  [#kw[Management Plane]], [Collects #hl[monitoring data, observes performance], provides *internal information* out.],
  [#kw[Control Plane] / *Signaling*], [#hl[Takes decisions on possible *changes*].\ Goal: avoid system blocks or downs. May induce system reconfiguration.],
)
#v(-1em)
#note[
  The control and managment planes introduce overhead, anyway they are needed.\
  Business logic (data plane) and control/steering are *separated*. Typically in microservices, these are interconnected by a service mesh (e.g., *Istio*).
]
#v(-1em)
#note[
  Network-level QoS protocols (IntServ/RSVP, DiffServ, SIP, SNMP, router scheduling) are covered in the #link(<ch14-qos>)[_*Network Quality of Service* chapter_].
]

#figure(
  image("../assets/control-planes.jpg", width: 40%),
  caption: "The 3 planes."
)

=== Service Level Agreement (SLA)
#def("SLA — Service Level Agreement")[
  An #kw[SLA] is a *clean *and* non-ambiguous contract*, a formal agreement between a service provider and its requestors that precisely defines *how the service has to be granted*: the quality targets to be met and the consequences if those targets are violated.
]

SLAs translate abstract QoS goals into concrete, verifiable commitments.

#extra[
  #example("AWS S3 SLA")[
    Amazon S3 defines a Monthly Uptime Percentage commitment and ties it to refunds:
    #table(
      columns: (1fr, auto),
      align: (left, center),
      fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
        if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
      },
      stroke: 0.5pt,
      inset: 1em,
      table.header([*Monthly Uptime*], [*Service Credit*]),
      [$in [99.0%, 99.9%]$], [10%],
      [$in space.hair ]95.0%, 99.0%]$], [25%],
      [$< 95.0%$], [100%],
    )
  ]

  #example("Azure VM SLA")[
    Azure guarantees:
    - *99.99%* connectivity for VMs across ≥ 2 Availability Zones.
    - *99.95%* for VMs in the same Availability Set.
    - *99.9%* for a single VM with Premium/Ultra SSD.
    - *99.5%* for Standard SSD.
    - *95%* for Standard HDD.
  ]
]

== General Resource Management Models

Systems are extremely varied in requirements. There is no magic recipe. The design of resource management is split into two phases:

- #hl[*Static (out-of-band)*]: decisions taken *before* execution. Complex algorithms are feasible here (no runtime cost).
- #hl[*Dynamic (in-band)*]: decisions taken *during* execution. #hl[Must be fast and lightweight] to not interfere.

Concurrency among services and management actions can introduce overhead, but also allows *load balancing* that improves average performance.

=== Preventive vs. Reactive Models

#table(
  columns: (auto, 1fr, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header(
    [], [*Preventive (Pessimistic)*], [*Reactive (Optimistic)*],
  ),
  [*Idea*], [Avoid undesired events *a priori*.], [React *after* an undesired event occurs.],
  [*Cost*], [Fixed cost, *always paid* (even when nothing is happening).], [Lower cost if bad events are rare. Works well if the system is *far from saturation*.],
  [*Applicability*], [When failures are too costly to tolerate.], [When failures are rare or recoverable.],
)
#v(-1em)
#note[
  Both are required. The key is to have #hl[the more static decisions, so the overhead is less] #hl[at runtime].
  #extra[#swarrow Define as much as possible before execution (static/preventive), and keep a reactive layer for the rest.]
]

=== Static vs. Dynamic Models

#table(
  columns: (1fr, 1fr),
  align: (left, left),
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header(
    [*Static Models* (#so predefined)], [*Dynamic Models*],
  ),
  [User number predefined and fixed before run.], [Users can be added and deleted during execution.],
  [Process number predefined and fixed before run.], [Processes can be added and deleted during execution.],
  [Node numbers predefined before run.], [Processors can be added and deleted during execution.],
  [Client traffic predefined and limited.], [Client traffic can vary during execution.],
  [Services predefined and fixed.], [Services can be added and modified during execution.],
)
#v(-1em)
#note[#hl[Modern systems are mostly *dynamic*]. Static models are simple but inflexible, the trend is toward dynamic systems with *orchestrators* that handle the variability *automatically*.]

== Application Deployment

Any application must be *deployed* onto real physical resources. This requires two decisions:

1. #hl[*Partitioning*]: divide the application into constituent components (P1, P2, ..., P9). These are components/partitions that work on data.
2. #hl[*Mapping*]: decide on which physical node each partition runs.

Application resources include: processes, components, objects, classes.\
System resources include: processors, networks, clusters, cloud nodes.

#extra[Manual deployment requires answering: *who is in charge*? The application designer? The support? The middleware? This is why automation and declarative deployment exist.]

=== Process Allocation

Placing processes on processors involves a *cost model* that considers per-processor:

- Memory $m_i$
- Execution capacity $x_i$
- Bandwidth $b_i$

Each processor is conceptually a *bucket* to be filled. *Communication is not as easy*, the communication cost is *non-linear* (depends on reachability), making exact placement NP-complete. Linear models exist but even those can be complex.

- *Static allocation*: out-of-band, permits expensive exact algorithms or heuristics (genetic, Tabu search).
- *Dynamic allocation*: in-band, must use *simple policies* with minimal overhead.

=== Static vs. Dynamic Resources in Applications

Applications contain two kinds of resources:

- #hl[*Static resources*] #swarrow known before run, easy to allocate at deployment time.
- #hl[*Dynamic resources*] #swarrow created *during execution*, may not even exist in every run.

In dynamic systems, you can also create *non-forecasted dynamic resources* and think about *reallocating existing resources* (migration) — settings can change during execution. *Resources re-allocation can be heavy.*

=== Allocation Strategies

#table(
  columns: (auto, 1fr, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header(
    [*Strategy*], [*Pros*], [*Cons*],
  ),
  [*Static*], [Allocation cost paid before execution.], [*Inflexible*: no adaptation at runtime.],
  [*Dynamic*], [*Adapts* to current situation; allocated only when needed (on-need).], [Allocation *cost* impacts execution time.],
)

#hl[Dynamic systems can also *reallocate* already-running resources (*migration*)], but migration is expensive and must be carefully managed.

=== Allocation Decision Models

- *Explicit* (user-driven) #swarrow User specifies the mapping for each resource before execution.
- *Implicit* (automatic) (data centers) #swarrow The system handles mapping, both at deployment and at runtime.
- *Hybrid* #swarrow System applies a default policy to both static and dynamic resources, including initial allocation of new resources and possible migration during run. User hints can refine decisions.

=== Deployment Support

- *Manual* #swarrow User passes each object to a node with explicit commands.
- *Script-based* #swarrow User writes shell/Python/Perl scripts specifying configuration steps and dependencies by phases.
- *Model-driven* / *Declarative* #swarrow Automatic configuration through declarative languages.\ _For Cloud: Ansible, Chef, Puppet, Salt, SmartFrog, Radia, Terraform, CloudFormation._

=== Modern Deployment: Application + Configuration Together

Traditional approach: define *how* to configure for the #underline[specific] environment.

Novel approach (Docker/microservices): *ship the #hl[application together with its required configu-] #hl[ration]*, so it can be ported to any support environment. The orchestrator then automates all management operations.

#extra[
  Docker and Kubernetes are covered in dedicated chapters. Here, the key idea is that modern deployment *inverts* the traditional model: instead of adapting the application to the environment, you bring a self-contained unit that describes its own needs.
]

== Resource Services and Agent Management

A #hl[resource exposes its services through a *simple interface*] (ideally following the SOA principle):

- *Service request model* (C/S): the client explicitly asks the server. #extra[Good for a *small number of clients*, direct and simple, but does not scale to many concurrent requestors.]
- *Distributed File System (DFS) / Middleware model*: a transparent, allocation-invisible service. The middleware in the middle makes the service available and users are freed from knowing where the resource lives.

#hl[*Transparency* simplifies the interaction]: users do not need to know which node provides the service.

=== Agent-Based Management (DFS)

In distributed deployments, *agents* coordinate among themselves to provide a unified service:

- The deployment is a *coordinate agent system* providing unique service for generally distributed actions.
- Agents *negotiate* and *coordinate* to give the best result. #swarrow Any kind of negotiation is possible among agents, including refusing a service.
- #hl[Each node hosts an agent that manages local resources and communicates with peer] agents.

#extra[The middleware in the middle makes the service available and allocation transparent.]

#figure(
  image("../assets/agents-DFS.jpg", width: 50%),
  caption: "Agent-based management."
)

== Load Sharing and Load Balancing

#extra[
  Load sharing is formal (literature, frameworks, ...), instead load balancing is more practical. In real modern deployments, dynamic load balancing is the norm.
]

- #kw[Load Sharing] (static, out-of-band) #swarrow #hl[Best possible allocation plans] defined *#underline[before] the run*. Resource allocation without moving any resource once allocated. No migration after initial allocation, actuated eventually at resource creation.

- #kw[Load Balancing] (dynamic, in-band) #swarrow #hl[*Migrates* already-running, active resources during execution] depending on load, to obtain better global efficiency (dynamic allocation).
  #v(-1em)
  #problem[
    I/O is the problem when moving thing, because  you can loose where things are, link and whatever.
  ]
  #v(-1em)
  #note[
    In Unix, luckily, persistent communication elements are used\ #so VMs can be migrated without this problem😄, but if the intermediate migrates how will we re-establish communication?😨
  ]

The static case can use more precise algorithms (out-of-band), while dynamic must compete with the running application.

=== The Farm Pattern

A common and widely used pattern for load distribution:

#def("Farm Pattern")[
  A #kw[Farm] consists of one *Master* that distributes tasks to multiple *Workers* that execute in parallel and return results. The master handles input decomposition and result aggregation.
]

#extra[
  Apache Spark uses a Farm pattern: the *Spark driver* is the master, distributing data partitions to executor nodes that search or process them in parallel.
]

#figure(
  image("../assets/master-worker.png", width: 30%),
  caption: [Farm Pattern.]
)
#note[
  This approach i widely used, also out of this context and often the terms can vary with similar meaning words (such as Master-Slaves, Main-Workers, White-Blacks).
  #extra[It is a matter of ethics/discrimination..\. 🙃]
]

=== Static Load Sharing Strategies

When processes are created, the system must find a suitable processor. Three classic static strategies:
- *Logical ring* #swarrow static,
- *Logical hierarchy* #swarrow static,
- *worm* #swarrow dynamic.

==== Logical Ring

In the *Logical Ring* (Token Bus) the processors form a #hl[*ring*. A *token* circulates.] The token holder becomes the current strategy maker, broadcasts a load-state request, and distributes the new process. The token is passed after a maximum permanence in a node. \
If a #hl[node crashes] it is excluded and #hl[token regeneration] is needed. If load is low the #hl[election] strategy is activated. It is #hl[easy to maintain and fast to recover in case of fault].
#v(-1em)
#note[
  2 connections per node (economic) but communication takes time (predecessor/successor). 
]
#v(-1em)
#note[
  Token circulation is *pessimistic*, cost is always paid.
]

#figure(
  image("../assets/token-ring.jpg",width: 35%),
  caption: [Token bus. 4 crashed #so excluded.]
)

==== Logical Hierarchy (MICORS)

In *MICROS* (Logical Hierarchy) nodes form a #hl[*hierarchical Farm*]: Workers (computing #swarrow slave) and Managers (handling/controlling). #hl[Allocation is only on workers]. Level number depends on workers. #hl[*Multiple managers* provide fault tolerance]. The #hl[hierarchy can shrink and expand dynamically].
#v(-0.8em )
#note[If a manager fails, the workers (under) are lost #so duplication of connections.]
#figure(
  grid(
    columns: (1fr, 1.3fr),
    crop(
      image("../assets/micros-logical-hierarchy.jpg", width: 70%),
      bottom: 150%,
      left: 40%,
      top: 15%,
    ),
    crop(
      image("../assets/micros-logical-hierarchy.jpg", width: 70%),
      top: 127%
    ),
  ),
  caption: [Logical Hierarchy (Farm pattern).]
)

==== Worm
*Worm* is used in small-size systems (\<100 nodes). It is *#underline[dynamic]*. A *worm* is a #hl[set of multiple segments], each executing a process, who can communicate for load-sharing. *Segments expand* by sending *probes* to discover free close nodes and cloning there (one copy only). There is not a predefined topology since the discovery of nodes is dynamical. 
#extra[ It is inspired by the informatics *virus worm*.]

== Load Balancing: Process Migration

#def("Migration")[
  #kw[Migration] is the act of *moving an already-running process* (or even VM) from one node to another during execution, *#underline[transparently]* to the user, to achieve *better resource utilization*.
]

Goals of transparent migration:
- Better and more efficient resource usage.
- Balancing of computational and communication load.
- Dynamic decisions and long-term policies.

Requirements:
- *Performance* ⟸ use resources at the best.
- *Efficiency* ⟸ limited overhead.
- *Continuous operation* ⟸ minimal intrusion.

=== Internal Migration Problems

When a #hl[process migrates], it #hl[must prepare the *mobility phase* and manage] all previously available #hl[resources]. This involves an *environment change* of the mobile resource (files, sockets...).

Before and during mobility, the process state must be carefully frozen, managed, and transferred through these sequential phases:

1. *State Identification* #swarrow Identify which #hl[internal resources to carry on] to the new location, determining their exact runtime state (code, data, and visible resources).
2. *Process Blocking* (before mobility) #swarrow #hl[Freeze the process execution]. One part of the execution state may be *not transportable*, so specific cleanup is required before moving.
3. *Manage Last Wishes* #swarrow Close local files or code to be managed.
4. *Resource Storing* #swarrow Serialize and store all transportable resources so they can be sent and safely re-enabled on the target node.
5. *Transfer & Synchronization* #swarrow #hl[Move the resources through nodes]. During the transient phase, *two copies exist* (old and new) and require data synchronization.
6. *Activity Activation* #swarrow Complete the activity on the old node, trigger the activation mechanisms on the new node, and de-activate the temporary movement infrastructures.

#extra[Files, sockets, resources move through nodes. So "Where is the process? The context?" this is the fundamental challenge of transparent migration.]

=== External Migration Problems

After the migration, old references to the process must be updated #so change of name of mobile resources.

3 alternative approaches:

- *Message Redirection* (pessimistic/proactive) #swarrow #hl[Old node keeps track and *forwards* all messages] to the new location. Forwarding #hl(color: danger)[chains can grow] for mobile processes.
- *Requalifying of Allocation* (pessimistic/proactive) #swarrow Old node forwards during transfer only, #hl[clients receive new location reference afterward].
- *Client Recovery* (optimistic/reactive) #swarrow Old node takes no action, #hl[failing clients must find] the #hl[new location themselves].

=== Migration Policies

Migration involves three steps:

1. *V (#hl[Valuation])* #swarrow evaluate local load vs. global load to #hl[decide *if* migration is needed].
2. *T (#hl[Transfer])* #swarrow decide #hl[*which* process to transfer and *when*] to do it. In heterogeneous systems, maybe some resources are *NOT movable to specific nodes* (such as in heterogeneous systems).
3. *L (#hl[Location])* #swarrow decide #hl[*where* to migrate] the process.

#extra[Those actions are taken at runtime, so they should be *simple*. T & L are often intertwined and interdependent.]

T and L are often interdependent and must integrate with local scheduling.

#table(
  columns: (auto, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Policy type*], [*V / T / L details*]),
  [*Static* (low cost)], [- V: fixed threshold. 
  - T: move the newest process. 
  - L: fixed to a predefined sink node.],
  [*Semi-Dynamic* (limited cost)], [- V: variable threshold (probabilistic). 
  - T: cyclic identification.
  - L: cyclic sink node.],
  [*Dynamic* (higher cost)], [- V: comparison with neighbors (dynamic avg load). 
  - T: process state information.
  - L: discover sink via probing messages in the neighborhood.],
)

Migration policies can use *probes* (messages sent to neighbors to ascertain possibility of moving) probing (T & L together), using conditioned/unconditioned acceptance, bidding strategies.

=== Sender vs. Receiver Initiative

Migration requires a sender (overloaded) and a receiver (underloaded):

- *Sender initiative*: the overloaded node seeks a receiver #swarrow more suitable for *low system load*.
- *Receiver initiative*: the underloaded node seeks work #swarrow more suitable for *medium-high system load*.
- *Mixed solutions* combine both.

=== Centralized vs. Decentralized Migration

#table(
  columns: (auto, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Approach*], [*Description*]),
  [*Centralized*], [Unique entity controls migration. High cost in transporting data, long time to actuate control. #hl[Only works well with small systems.]],
  [*Decentralized*], [Coordination of many different entities. Implicit or explicit collection of distributed state info (*piggybacking*). *Favors* *local* movements in a neighborhood. #hl[Fresh data locally available and fast decisions], but typically local strategies and not optimal values.],
)

=== Key Lesson from Migration

#important("Migration Lesson")[
  Migration has a cost... but it may be very effective.
  - Even #hl[*simple policies* yield significant improvements] over no-migration.
  - More sophisticated policies do *not* give significantly better results in general, and cannot be generally applied apart from very specific (not so common) situations.
  - Goals: #hl[*stability* (avoid thrashing), *efficiency*] (simple to compute), *sub-optimality* (optimality is not a real goal), #hl[*minimal intrusion*].
]

#important("Separation of Policies and Mechanisms")[
  Mechanisms (_how do things_) are system-tailored and should be kept *immutable* (if possible). Policies (_what to do/what strategy to choose_) are general-purpose and should be kept separate, able to vary under user control.\ 
  #hl[*Always keep strategies and mechanisms separated.*]
]
#extra[
  *Examples of Separation:*
  - *CPU:* Mechanism = Context Switch (how to swap) | Policy = Round Robin/FIFO (who is next).
  - *Migration:* Mechanism = Freeze & Network Transfer (how to move) | Policy = Load Balancing (when/where to move).
  - *Storage:* Mechanism = Block Write/Caching (how to store data) | Policy = RAID level / Replication factor (how redundant it must be).
]

== Scalability Problems: Orchestrators

When dealing with *many containers and microservices*, manual management becomes infeasible. Two complexity problems arise:

- Possible *too large a number* of containers and microservices.
- *Dynamic changes* #swarrow crashes, addition/deletion of items at runtime.

An *orchestrator* is a manager that can automate operations on all microservices, all containers, all nodes and any management action.

#extra[
  Available orchestrators: Docker Swarm, *Kubernetes*, MESOS, Amazon ECS, Google Container Engine, Azure Container Services, Cloud Foundry's Diego, CoreOS Fleet, Mesosphere Marathon.
]

=== Kubernetes

#def("Kubernetes")[
  #kw[Kubernetes] (K8s) is a Cloud Native Foundation *orchestrator* for containerized applications. It provides *application-centric management* in a loosely coupled infrastructure where any component is a separate unit.
]

Key features:
- #hl[*Auto-scalable infrastructure* and *Automated Scheduling*].
- #hl[*Horizontal Scaling* and *Load Balancing*].
- *Self-Healing* capabilities (to overcome crashes).
- Environment consistency across development, testing, and production.
- Automated rollouts and rollbacks.
- Provides higher density of resource utilization.
#v(-1em)
#note[
  K8s manages *state* *outside*, in just one component (*etcd*). This is the key design decision that makes K8s scalable.

  The full Kubernetes architecture (control plane, pods, services, networking, autoscaling, and RAFT consensus) is covered in the *Kubernetes* chapter.
]

== Modern Microservice Support: Service Mesh

With microservices, you have many user-specified services, each self-contained in its own container. *How can you manage them?* Orchestration helps, but a *service mesh* provides additional management functions:

#def("Service Mesh")[
  A #kw[service mesh] is a mesh of services that provides a dedicated infrastructure layer for handling service-to-service communication, providing functions for: *identification*, *discovery*, *interaction*, *monitoring*, *separation* (security), *composition*, *migrations*, *traffic management*, and more.
]

#extra[A large number of messages is needed between services. The service mesh *abstracts* and *manages* this communication *transparently*.]

Service areas covered by a service mesh:
- *Observation of service* (metrics, tracing, logs)
- *Traffic management* (routing, load balancing, versioning)
- *Composition and extensions* (add-ons, proxies)
- *Separation* (security, isolation)

Open source: *Istio*, *Envoy*.\
Proprietary: Mulesoft.\
Cloud-native: Azure, IBM, AWS have their own tools.

=== Istio

#def("Istio")[
  #kw[Istio] is an open-source service mesh that provides *observability*, traffic management, and security for microservices via *Envoy proxy* sidecars injected next to each service. A central control plane distributes configuration to all proxies.
]
#v(-1em)
#note[
  The full Istio architecture (traffic management policies, mTLS security, distributed tracing, and integration with Kubernetes) is covered in the #link(<ch08-service-mesh>)[_*Kubernetes* chapter_].
]

== Continuous DevOps (CI/CD)

An application can be *continuously upgraded while in execution* without disrupting current users. New versions are rolled out gradually (blue/green, canary deployments) so old clients are served until the new version is validated.
#v(-1em)
#note[
  The DevOps methodology, CI/CD pipeline stages (Integration, Delivery, Deployment), and the Twin System Principle are detailed in the #link(<ch02-devops>)[_*Goals, Basics, Models* chapter_].
]

== Infrastructure as Code (IaC)

In the DevOps direction, #kw[IaC] (Infrastructure as Code) allows managing the infrastructure with the same tools used for application code: *declaratively*, automatically, and reproducibly.

#def("Infrastructure as Code (IaC)")[
  #kw[IaC] is the practice of *managing and provisioning computing infrastructure using configuration files*, instead of manual hardware setups or interactive tools. 
  The core idea is to *treat infrastructure exactly like software application code*, allowing to version it, automate its deployment, and change it safely through declarative files.
]

#extra[
  The system changes configuration in order to adapt to some conditions, this is what distinguishes IaC from manual configuration management.
]

Tools in this space:

#table(
  columns: (auto, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Tool*], [*Description*]),
  [*Ansible, Chef, Puppet, Salt*], [Configuration management tools for cloud and on-premises systems.],
  [*AWS CloudFormation*], [AWS-specific IaC: JSON or YAML templates that describe all AWS resources. Integrated with CloudWatch for observability. #extra[*Not portable ⇒ risk of vendor lock-in.* Completely integrated with AWS suite but cannot be used for multi-cloud.]],
  [*HashiCorp Terraform*], [Open, cloud-agnostic IaC: declarative language targeting any cloud provider. Supports multi-cloud and CI/CD integration. Actions automatically adapted for the target. Works across AWS, Azure, GCP, and more.],
)

== Computational Models for Parallelization

To reason about how well a problem scales across multiple processors, we use two formal indicators.

#extra[Algorithms have intrinsic complexity in time and results are about *that* (the algorithm's inherent complexity, not just the data). Both time complexity CT(N) (abbreviated T(N)) and space complexity CS(N) matter.]

=== Speed-up and Efficiency

Let $T(1, N)$ be the sequential time for problem size $N$, and $T(P, N)$ the parallel time with $P$ processors.

#def("Speed-Up")[
  #kw[Speed-up] $S_P (N)$ is the *potential* *improvement* factor over sequential indtroduced by $P$ using processor. It can be at most $P$ (ideal).
  $
    S_P (N) = (T_1(N)) / (T_P (N))
  $
]

#def("Efficiency")[
  #kw[Efficiency] $E_P (N)$ measures how effectively a parallel system utilizes its computational resources compared to the overhead introduced by parallelization. It can be at most 1 (ideal).
  $
    E_P (N) = (S_P (N)) / P = (T_1 (N)) / (T_P (N) dot P)
  $
]


=== Grosh Law and Loading Factor
#def("Loading Factor")[
  The #kw[loading factor] is the problem size per processor:
  $
    L = N / P
  $
]
#v(-0.7em)
#def("Grosh's Law")[
  The best deployment for a program is sequential execution using a unique processor (local/centralized machine is ideal).
  #extra[This is *never practically possible*.]
]
#v(-1em)
#note[
  In reality, when #hl[$N >> P$, the system can approach ideal speed-up and efficiency].
]

#extra[
  *The Hook behind Grosh's Law:*
  - *Historical Context (1950s):* Computer power scaled quadratically with cost ($text("Performance") = k dot text("Cost")^2$). Economically, it was cheaper to build one giant central mainframe ($P=1$) than multiple smaller interconnected machines.
  - *Modern Trade-off:* #hl[Today, microprocessors broke Grosh's law] (commodity hardware in parallel is cheaper than an ultra-powerful monolithic chip).
  - *The Architectural Link:* To beat Grosh's ideal centralized model, you must keep the loading factor high ($N >> P$). If $N$ is too small, processors spend more time talking over the network than computing, collapsing efficiency.
]


=== Amdahl's Law

#def("Amdahl's Law")[
  Any program can be split into a *(potentially) parallel part* and a *sequential part*. The sequential fraction sets the *hard limit* on achievable speed-up, regardless of the number of processors.
  $
  T_P (N) = T_"CompP" + T_"CompS" + T_"Comm"
  $
  #extra[where $"Comp" = $ computation and $"Comm" =$ communication.]
]
#v(-0.7em)
#example("Amdahl's Law")[
  A program with 100 operations: 80 parallelizable, 20 sequential.
  With any number of processors, speed-up cannot exceed *5* (the 20 sequential operations always dominate). Of course, it can become *worse than that* due to communication overhead.
]

In practice, at growing $P$:
- Speed-up first grows linearly, then flattens (limited by the sequential part).
- Efficiency first stays near 1, then drops as overhead grows.

#figure(
  image("../assets/speedup-efficiency.png", width: 75%),
  caption: [Speedup and Efficiency plots (depend on $P$, but also $N$).]
)

The *heavily-loaded limit* $T_"HL"(N) = inf_P T_P(N)$: the $P$ with which we get the least complexity. Optimum is typically when $N/P$ is very high #swarrow all processors are *very loaded*, with heavy load to carry out (considering the sequential limit).

=== Parallel Time Model

$T_P(N) = T_"CompP" + T_"CompS" + T_"Comm"$

The *heavily-loaded limit* (HL) is the minimum $T_P$ over all $P$: ideally achieved when $N/P$ is large and all processors carry a heavy load.

=== Overhead Time

#def("Total Overhead")[
  The *total overhead* $T_0(N, P) = P dot T_P (N) - T_1(N)$ represents the *wasted work* (time spent on coordination, synchronization, and communication) rather than useful computation. $T_0$ indicates the *lost work*.
]

$T_P (N) = (T_0(N) + T_1(N)) / P$

Efficiency can be rewritten as:

$E_P(N) = (T_1(N)) / (T_0(N) + T_1(N)) = 1 / ((T_0(N)) / (T_1(N)) + 1)$

A higher overhead lowers efficiency. To keep efficiency constant as $P$ grows, $N$ must grow proportionally.

#side-note(color: gray)[
  === Case Study: Sum of N Integers

Processors arranged in a *binary tree* (leaves receive values, root produces the sum).

*Identity size* ($N approx P$)\
Data Flow Architecture:
- $T_P(N) = O(log_2 N)$
- $S_P(N) = O(N \/ log_2 N) = O(P \/ log_2 P)$
- $E_P(N) = O(1 \/ log_2 N) = O(1 \/ log_2 P)$ #so efficiency *goes to zero* → *low efficiency*: processors are idle most of the time.

#extra[Instead, a *pipe* is good if there is no idle time due to *continuous data flow*. If data keeps arriving and processors are always busy, efficiency is recovered.]

*Independent size* ($N >> P$, each processor sums $L = N/P$ values locally, then communicates):
- $T_P(N) approx N\/P + 2 log_2 P$ (exact, instead of O notation)
- $S_P(N) = N P \/ (N + 2P log_2 P)$
- $E_P(N) = N \/ (N + 2P log_2 P)$
- As $N >> P$: speed-up $-> P$ and efficiency $-> 1$ #so *ideal behavior*.

The lesson: *keeping processors heavily loaded* (high $L$) is essential for good efficiency. The $T_0$ overhead (for the tree case) $approx 2P log_2 P$ — depends mostly on the *number of engaged processors*, as coordination grows with P.
]

=== More Real Indicators

In practice, the real speed-up is *not exactly the reference* due to communication or other overheads. The typical behavior:

- Initial *linear zone* at P growing (speed-up growing).
- Then *constant speed-up* with *lowering efficiency* — paying the cost of synchronizing more CPUs.
- *Target stays constant* (Amdahl's limit).

#extra[Speed-up is usually *constrained because of the overhead* #swarrow we cannot maintain an ideal speed-up for long. The real speed-up curve bends down from the ideal diagonal.]

#figure(
  image("../assets/real-indicator-speedup.jpg",width: 40%),
  caption: [Real speedup.]
)

=== Iso-Efficiency

#def("Iso-Efficiency Factor $K$")[
  The iso-efficiency factor $K = T_0(N, P) \/ T_1(N)$ measures how well a parallel system maintains *same efficiency with different numbers of processors*. If $K$ is constant and small, the system is *scalable*. If $K$ grows with $P$, the system loses efficiency at scale.

  $T_0(N, P) = K dot T_1(N)$

  Goal: *keep efficiency constant* $E_P (N,P) = 1 \/ (K + 1)$ as $P$ varies.
]
#v(-0.7em)
#side-note(color: gray)[
  For the binary tree sum: $K approx 2 P log_2 P \/ N$ — depends on both $P$ and $N$.

- If $K$ is small #so *high scalability possible*.
- If $K$ is high #so *less scalable system*.
- $K$ non-constant #so *non-scalable systems* (mostly all real systems).

#extra[For the tree case, K is $2P log_2 P / N$ — so the system is *scarcely scalable*.]
]

#important("Scalability Conclusion")[
  *When the #hl[problem is compute-bound, it's scalable]*. But when we deal with communication, it is *not* (because of idle time). \
  In general, #hl[*all real systems are non-scalable*]. The goal is to keep #hl[$K$ as small as possible] by #hl[maximizing the loading factor $L = N/P$], ensuring all processors are *heavily loaded* at all times. \
  A *heavily loaded limit* is a good target.
]
