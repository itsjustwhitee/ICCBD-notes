#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= GOALS, BASICS, MODELS
#extra[
  Package: Initial Models and Issues - `2-InitialModels26.pdf`
]

== Modern Distributed Systems
Modern distributed systems are *complex* but extremely *widespread*. They are interesting precisely because many problems remain *unsolved*, _which is why studying them matters_.

A good middleware must handle several fundamental challenges at runtime:

- *Partial failure* #swarrow Components can fail independently, and the system must keep working.
- *Heterogeneity* #swarrow Different hardware, OS, languages, and protocols must coexist.
- *Integration and standards* #swarrow Components from different vendors must work together.
- *Changing conditions* #swarrow The system must adapt while staying online.

Beyond those challenges, three macro-requirements define what a large distributed system must provide:

1. #hl[*Scalability and safe answers*] #swarrow The system must *scale* and *always respond correctly*.
2. #hl[*Predictability and performance control*] #swarrow Behavior must be measurable and controllable.
3. #hl[*Maintainability, operability, and simplicity*] #swarrow The system must be easy to operate and evolve.

== ICCBD Approach: Resources and APIs

Understanding an IT system means understanding its *resources*: what they are, how they are defined, and how they behave internally.

#hl[Every system also exposes an *external interface*] to its users, that is a set of functions called #kw[APIs] (Application Programming Interfaces). APIs allow clients to request services without knowing internal details.

Two complementary perspectives are always needed:

- #hl[*External view* (*black box*): understand the system from its visible APIs] and infer what services it offers. #so *#hl[Transparency]*
- #hl[*Internal view* (*open box*): understand the internal design, components, and mechanisms]. #so #hl[*Visibility*]
Both perspectives are valuable and often used together in a gradual approach starting abstract, then going deeper. <black-open-box>

== Properties of Large Systems


#prop("Properties of Large Systems")[
  Large IT systems are expected to have a #hl[*#underline[long] life cycle*]. This brings specific requirements:
  - *#hl[Abstraction]* #swarrow Hide complexity, focus on what matters at each level.
  - *#hl[Transparency]* #swarrow Hide implementation details from users.
  - *Granularity* #swarrow Choose the right size for components and resources.
  - *QoS* (Quality of Service) #swarrow Meet agreed performance and reliability targets.
  - *Staticity*\/*Dynamicity* #swarrow Balance between stable and changeable parts.
  - *Observability*\/*Explainability* #swarrow The system must be monitorable and understandable.
]

=== Abstraction
#kw[Abstraction] is a fundamental guideline in any complex system. It means #hl[focusing on the right] #hl[level of detail, ignoring what is not relevant] at that level.

#example("Abstraction: The underground Map")[
  A good analogy is the *London Underground map*: the geographic map is accurate but overwhelming. The simplified tube map hides distances and curves, but is perfectly useful for navigating the network. Abstraction is not about being inaccurate #swarrow it is about being *appropriately* simplified for the task at hand.
  #figure(
    grid(
      columns: (1fr, 1fr),
      gutter: 0pt,
      image("../assets/london-map.png", width: 80%),
      image("../assets/london-map-abs.png", width: 100%)
    ),
    caption: "Abstraction example: the London Underground map."
  )
]

=== Transparency vs Visibility
#kw[Transparency] means #hl[hiding details] so that the user does not need to know about them. It is the opposite of #kw[visibility] (where internal details are exposed). Those two properties are the incarnation of the *black box* and *open box* perspectives (respectively, #link(<black-open-box>)[_see here_]).

#side-note(color: gray)[
  Common forms of transparency in distributed systems:
- *Access* #swarrow Local and remote resources are accessed the same way.
- *Allocation* #swarrow Resources are allocated independently of their physical location.
- *Name* #swarrow Names do not reveal where a resource is hosted.
- *Execution* #swarrow Local and remote execution feel the same.
- *Performance* #swarrow No perceivable difference between using local or remote services.
- *Fault* #swarrow The system continues to work even if some components fail.
- *Replication* #swarrow Multiple copies of a resource improve QoS without the user noticing.
]
#v(-0.6em)
#note[
  Transparency is not always the best choice. *Location-awareness* (knowing where things are) is sometimes essential.
  #extra[
    For example, when providing services that depend on the user's physical position. Always consider both perspectives: when to hide details and when to expose them.
  ]
]

== TINA-C
*TINA-C* (_Telecommunications Information Networking Architecture Consortium_) is a middleware framework for telcom systems.

Historically, traditional telecom systems had tightly coupled hardware and software. TINA-C was created to overcome this limitation by treating networks as distributed computing environments. It is considered an excellent reference model because it #hl[implements a strict *Separation of Concerns*], decoupling telecommunication services from the physical network infrastructure.

=== Roles and Views
TINA-C defines multiple parties to clearly separate who manages the infrastructure from who provides the service:
- *Initiating User* and *Responding User*: the end users.
- *Service Provider*: Manages user access, service logic and features.
- *Network Provider*: Manages the transport network (the physical routing of data).
\
Two complementary views are defined to understand the system from different perspectives:
- #hl[*User view*]: what the user sees (access points and service interactions).  It treats the #hl[underlying] network #hl[as a black box].
- #hl[*Interaction view*]: how providers, clients, and third-party applications connect and negotiate resources behind the scenes.

#analogy("TINA-C")[
    Consider a modern VoIP call (e.g., Skype over a TIM connection).
    - *Roles:*
      - *Initiating/Responding Users*: the callers.
      - *Service Provider*: Skype (manages the directory and call logic).
      - *Network Provider*: TIM (manages the physical fiber/cables).
    - *Views:*
      - *User view*: the user merely opens the app and starts a call.
      - *Interaction view*: the system maps out how Skype's servers communicate with TIM's routing infrastructure to guarantee bandwidth and deliver the packets.
]

TINA provides several fundamental architectures separated and interacting and many models for computing, service, management, network architectures.

=== Architectural Layer View

Each node in the system is organized in layers (bottom to top). This stratification prevents developers from having to deal directly with hardware specifics.

- #hl[*Hardware resources*] #swarrow The physical components (machines, cables, routers, ...).
- #hl[*NCCE*] (_Native Computing and Communication Environment_) #swarrow The local #hl[OS and hardware abstraction] layer. This layer introduces system #hl[heterogeneity].
- #hl[*DPE*] (_Distributed Processing Environment_) #swarrow The middleware layer that makes nodes work together as a unified distributed system.
- #hl[*TINA applications*] #swarrow The actual services and apps running on top.
The #hl[*DPE* is the key layer: it hides the heterogeneity of the underlying] hardware and OS, providing a uniform programming model.

#figure(
  image("../assets/tina-c-arc.jpg", width: 70%),
  caption: "TINA-C architectural layers."
)
#extra[
  #note[
  Without the DPE layer, developers would need to write different versions of a telecommunication service for every specific type of router or server (e.g., one version for Cisco hardware, one for Huawei, one for Linux). The #hl[DPE acts as an intermediate]: applications are written once for the DPE, which then translates the instructions for the specific underlying hardware, unifying the entire global network into a single virtual computing platform.
  ]
]

=== Transparent vs. Non-Transparent Architecture
- *Transparent view*: applications work with logical entities (*Services*, *Resources*, and *Elements*) without knowing on which physical machine they run.

- *Non-transparent view*: exposes DPE, Inter-DPE interfaces, and NCCE, used during *design and development* phases, when visibility of the full stack is needed.

#figure(
  grid(
    columns: (1fr, 1fr),
    gutter: 0pt,
    image("../assets/tina-c-transparent.jpg", width: 89%),
    image("../assets/tina-c-non-transparent.jpg", width: 100%),
    ),
  caption: "TINA-C transparent vs non-transparent architecture."
)

==  Monitoring and Observability

#important("Monitoring vs. Observability")[
  Modern IT systems separate concerns into three planes (User / Management / Control), the full model is covered in the #link(<ch03-three-planes>)[_*Resource Management Models* chapter_].

  - #hl[*Monitoring*] = *gathering* metrics (what is happening now: CPU, memory, latency, error rate).
  - #hl[*Observability*] = *analyzing* those metrics to *understand why* and *react* (tuning resources, rerouting traffic, scaling).

  Monitoring feeds data, observability acts on it.
]

#def("Monitoring")[
  #kw[Monitoring] is a critical support function that #hl[*collects* information about the *current state* of] #hl[the system] (processor load, resource usage, network bandwidth) #hl[to allow *control* and *adaptation*.]
]

Method of data collection:
- *Periodic sampling* #swarrow observe all values at fixed intervals.
- *Statistical/historical data* #swarrow summarize past behavior.
- *Event-based* #swarrow collect data only when something notable happens (discretization).

#important("Continuity")[
  Monitoring relies on the key assumption of #hl[*continuity*] (*natura non facit saltum* #swarrow nature does not make jumps). This means that the #hl[*current load* can be used to forecast *near-future behavior*], because applications tend to behave consistently over short intervals.
]

=== Minimal Intrusion Principle
In general-purpose systems, the monitoring infrastructure *competes for the same resources* as the application it is monitoring. This leads to a fundamental design principle:

#def("Minimal Intrusion Principle")[
  Any support function must *#underline[minimize]* its *resource consumption*, so that it interferes as little as possible with the application.
]

#extra[
  In other words, monitoring must do its job while "stealing" as few resources as possible from the application (_typically \~5-10%, not more_).
]

== Granularity
#def("Granularity")[
  #kw[Granularity] refers to the *size* of the *units* (resources, components, services) used to build and manage the system.
]

Two extremes:

- #kw[Fine-grained]: many small units #so *detailed control*, but *high management overhead* and many interactions.
- #kw[Coarse-grained]: fewer large units #so *easier to manage*, but harder to update and *less flexible*.
#v(-0.6em)
#note[
  Neither extreme is universally better. The right choice depends on the use case (as we will see 😌).
]
#v(-0.8em)
#analogy("Granularity")[
  Think of granularity like building a model house.
  - *Very fine-grained (Processes)* is like using thousands of grains of sand: you can mold any shape perfectly (max detail), but it's a nightmare to manage and keep together.
  - *Coarse-grained (Monolithic)* is like buying a pre-molded, solid plastic house: it's incredibly easy to handle, but if you want to add a window, you can't.
  - *Microservices* are like Lego bricks: they are small enough to give you flexibility, but large enough to be easily managed.
]

#example("Granularity in History")[

  The industry has historically oscillated to find the perfect balance:

  #table(
    columns: (auto, auto, 1fr),
    align: (x, y) => if y == 0 { center } else { left },
    fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
      if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
    },
    stroke: 0.5pt,
    inset: 1em,
    table.header(
      [*Entity*], [*Granularity*], [*Characteristics & Slide Notes*],
    ),
    [OS Processes], [Very Fine], [Too many to handle, unbounded scope. Nightmare to manage at scale.],
    [Monolithic Components], [Coarse], [Clean boundaries but too large. Hard to scale independently.],
    [Early Web Services], [Medium/Coarse], [Good separation of concerns, but often bulky and prone to failure cascades.],
    [Microservices], [Fine/Medium], [Fast adoption. Solves the "process" issue by grouping logic into manageable, bounded contexts.],
    [Serverless (Functions)], [Very Fine], [Back to fine-grained, but this time, the cloud provider manages the complexity.],
  )
]

\
== Service-Oriented Architecture (SOA)

#def("Service-Oriented Architecture (SOA)")[
  #kw[SOA] is a design paradigm centered on the delivery of *#underline[services]*. It enables *platform-independent* communication and *interoperability* by *decoupling* the service implementation from its interface (defined by a *contract*), allowing heterogeneous systems to integrate, *reuse* logic, and evolve independently.
]

#def("Service")[
  A #kw[service] is an abstraction of any business process, resource, or application:
- with a *standard interface* (API),
- *published* and discovered by others,
- *reusable*,
- *black box* defined.
]

#prop("Properties of Services")[
  - *Reusability* #swarrow the service can be used in any context.
  - *Formality* of interface #swarrow Interface is unambiguous and clear.
  - *Loose coupling* #swarrow Platform-independent.
  - *Autonomy* #swarrow Do not depend on external context, they are self-managing.
  - *Stateless* #swarrow Minimize internal state, the *client* maintains it.
  - *Discoverability* #swarrow Any service can be found through naming/discovery.
  - *Composability* #swarrow Existing services can be combined to create new ones.
]

=== The 3 Actors of SOA
SOA defines three roles:

1. #hl[*Service Provider* implements and exposes the service.]
2. #hl[*Service Requestor (Client)* discovers and uses services.]
3. #hl[*Discovery Agency* is a registry] where providers publish their services and clients look them up.

#figure(
  image("../assets/SOA-components.png", width: 50%),
  caption: [SOA components and flow.]
)

The #hl[client-server relationship is between Requestor and Provider]. Discovery Agencies act as intermediaries for finding the right provider. The key agreement is on the *common interface*.
#analogy("SOA and the Internet")[
  The Internet itself is a natural SOA implementation:
  - Discovery Agency #swarrow DNS (translates names to addresses).
  - Service Provider #swarrow Server (hosts and exposes the service).
  - Service Requestor #swarrow Client (looks up and consumes the service).
]

The classic *Client/Server (C/S)* model is an SOA implementation, but without discovery agencies. In C/S:
- The client *knows the server* directly.
- Interaction is *synchronous* (client waits for result) and *blocking*.
- It uses *tight coupling*: both parties must be available at the same time.
C/S has known weaknesses (rigidity, tight coupling), typically addressed by small tailored variations.

=== Granularity problem
In SOA the question is if it is better to have coarse grained services or fine grained components. The former (coarse) are harder to manage but grant higher abstraction level, the latter, instead, have augmented fragmentation and limited internal interaction.

Initially the choice was for coarse-grained entities, more compact and easier to move and manage. Sooner, fine grained resources were adopted for dynamicity and runtime changes.

#extra[
  #side-note(color: gray)[
  Some examples:
  - Web started coarse grained.
  - Components started middle-sized (processes were too fine grained).
  - Microservices are fine grained.
  ]
]

== Enterprise Application Integration (EAI)

Large companies run many different IT applications (CRM, ERP, SCM, Finance, HR, DMS, CMS, and more). These systems often evolved independently and are heterogeneous.

*EAI* (Enterprise Application Integration) aims to build a *unified integrated environment* where all business applications work together synergically, including both:

- *Legacy components*, existing systems that must be reused.
- *New components*, newly designed systems that must integrate quickly.
A key benefit of complete integration is *observability*: you can monitor the performance of any part of the business in real time, get fresh data, and react quickly to changes.

=== Traditional vs SOA-oriented Architecture

*Traditional approach*: each system (CRM, ERP, Financial) is isolated with its own database. Processes like Sales, Delivery, and Accounting talk to their own silo.

*SOA-oriented approach*: a shared *Enterprise Level Services* layer exposes fine-grained services (e.g., `GetCustId`, `CreateOrder`, `UpdateStock`, `MakeInvoice`) that all business processes can call. Data sources (Orders, Stock, Customer, Accounts) are accessed through this service layer, not directly.

== Technology Life Cycles: The Gartner Hype Cycle
Every technology follows a predictable pattern of adoption, described by the *Gartner Hype Cycle*:

1. *Technology Trigger* #swarrow the technology emerges.
2. *Peak of Inflated Expectations* #swarrow excessive hype, unrealistic expectations.
3. *Trough of Disillusionment* #swarrow reality sets in, failures are publicized.
4. *Slope of Enlightenment* #swarrow real use cases are understood.
5. *Plateau of Productivity* #swarrow mainstream adoption with realistic expectations.

#figure(
  image("../assets/gartner-life-cycle.png", width: 50%),
  caption: [Gartner (Tech) Life Cycle.]
)

Both *Cloud* and *SOA* are on the Plateau of Productivity: they are mature, widely adopted technologies.

== Resources in Distributed Systems
#def("Resource")[
  A #kw[resource] is *any component* (hardware, software or both) needed during execution to produce any visible result in a distributed system.
]

=== Classification of resources
#table(
  columns: (auto, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header(
    [*Dimension*], [*Examples*],
  ),
  [Low-level vs. Application], [#extra[CPU/RAM vs. Web server, app service]],
  [Physical vs. Logical], [#extra[Real CPU vs. virtual CPU, thread]],
  [Physical vs. Virtualized], [#extra[Physical NIC vs. virtual network]],
  [Static vs. Dynamic], [#extra[Fixed hardware vs. auto-scaled VMs]],
)

#extra[
  Resources in a distributed system include:
- Physical memory (RAM)
- Disk (persistence)
- CPU (computing)
- I/O and network
- Sensors, actuators (IoT devices)
- OS services, virtual machines, virtualized networks
- Application services (web servers, databases, custom apps)
]

Managing all of these efficiently, especially at the application level, is one of the hardest problems in distributed systems.

== Objects, Components, and the Path to Services

=== From Objects to Components

*Objects* (_Java, C++, etc._) are the basic unit in OO programming. They encapsulate data and expose operations. But objects are:
- *Fine-grained* #swarrow there can be thousands of them.
- *Loosely bounded* #swarrow they can interact in hidden ways (e.g., via shared memory).
- Tightly tied to their language/runtime environment.
For distributed systems, this is problematic. A better abstraction is needed.

#kw[Components] are a *coarser-grained*, more disciplined unit:

#def("Component")[
  A #kw[component] is a *static abstraction* of a confined entity with a defined interface for communicating with the external world via *ports*.
]
#v(-1em)
#analogy("")[
Think of a component as "an object in a tuxedo" (Michael Feathers): software that is packaged and ready to interact with the world in a clean, predictable way.
]

#prop("Component Properties")[
  - *Staticity* #swarrow has its #hl[own lifecycle], independent of any specific application run.
  - *Abstraction* #swarrow internal structure is hidden, #hl[only ports are visible].
  - *Port-based communication* #swarrow the only interactions with the outside world go through declared *IN ports* (incoming requests) and *OUT ports* (outgoing requests)
  - *Self-containment*
]

Effects of the component model (vs. object):
- *Better reusability* #swarrow no hidden interactions, so components can be moved between environments easily.
- *Substitutability* #swarrow one implementation can be replaced by another without changing the container (*dynamic replacement*).

=== Interfaces vs. Classes
Distributed systems separate:
- *Interfaces*, the contract (what a component offers).
- *Classes/implementations*, the actual code (how it works).
Multiple implementations can satisfy the same interface (e.g., different QoS levels). The #hl[interface is stable, implementations can change]. Middleware systems are designed around interfaces, not classes (typically).

== Containers
#def("Container")[
A #kw[container]  is a server-side environment that *hosts components* and provides them with many support services, so that the components themselves only need to implement business logic.
]
#v(-0.6em)
#prop("Container Properties")[
  A container provides:
  - *Lifecycle management* #swarrow activates, deactivates components as needed.
  - *Resource sharing* #swarrow manages shared resources.
  - *Composition* #swarrow helps combine components into new services.
  - *Activity support* #swarrow manages interactions between components.
  - *Control* #swarrow monitors and handles components.
  - *Mobility* #swarrow can extract and move components between environments.
]

#figure(
  image("../assets/component+container.jpg",width: 80%),
  caption: [Components composition #so Container.]
)

The *only* way to #hl[access a component from outside is *through its container*]. Inside the container, component interactions are *disciplined and checkable*. The container can make autonomous management decisions.
#v(-0.7em)
#note[
  The term *container* is used with many names in the literature: engine, middleware, support environment. They all refer to the same idea: a managed runtime that supervises hosted components.
]

=== Container Delegation

A container relieves components of cross-cutting concerns by providing them *automatically*, so that the component(s) only implements business logic:

- *Lifecycle support*: activates/deactivates servants on demand, maintains state, handles persistence (interface with DB).
- *Name system support*: discovery of servants and services.
- *Federation* with other containers.
- *QoS support*: fault tolerance, selection among deployments, monitoring and control of negotiated QoS.

#extra[
  J2EE (Java 2 Enterprise Edition) and EJB (Enterprise Java Beans) are classic examples: a container hosts EJBs and automatically provides lifecycle management, naming, transactions, and persistence, the developer writes only the business logic.
]

== DevOps <ch02-devops>

#def("DevOps")[
  #kw[DevOps] (*Development* + *Operations*) is a methodology that couples the application development phase with the infrastructure/operations phase, enabling *continuous* and *rapid* deployment of changes #underline[without disrupting the running system].
]

#figure(
  grid(
    columns: (1fr, 1fr),
    align: center,
    image("../assets/devops.png",width: 88%),
    image("../assets/agile.png", width: 65%)
  ),
  caption: [DevOps vs. Agile.]
)

The core motivation is that #hl[large systems require *frequent updates*] (new releases, bug fixes, scaling adjustments) and doing so safely while the system is live is a first-class engineering requirement.

#prop("DevOps CI/CD Cycle")[
  The #hl[cycle is *continuous* and *agile*]:
  - *Build* (Plan, Design, Develop) #swarrow develop the new version of the component.
  - *Deploy* #swarrow package and push to the target environment.
  - *Test* #swarrow validate behavior in isolation and in integration.
  - *Release* #swarrow promote to production, rolling out with no downtime.
  The two #hl[key practices are *CI* (Continuous Integration) and *CD* (Continuous Deployment)].
]

#table(
  columns: (auto, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Stage*], [*Description*]),
  [*Continuous Integration*], [Build → Test → Merge: developers integrate frequently; automated tests run on every merge.],
  [*Continuous Delivery*], [Automatically release to a repository: a deployable artifact is always ready.],
  [*Continuous Deployment*], [Automatically deploy to production: every passing change goes live.],
)

#extra[
  Updates are *rolled out gradually* (blue/green or canary deployments), ensuring old clients are still served until the new version is validated.
]
#v(-1em)
#important("Twin System Principle")[
  DevOps enables the *coexistence of production and test systems*: the new version is deployed and tested in a shadow environment, while the current version keeps serving users. Once validated, the switch is made cleanly #so *zero-downtime* upgrades become achievable.
]

== Microservices

#def("Microservice")[
  A #kw[microservice] is a *fine-grained*, independently deployable *component* that implements one specific business function and communicates with others over *web interfaces* (typically REST or gRPC).
]

Microservices are essentially a modern answer to the granularity problem: they are #hl[*small enough*] #hl[to be independently deployable and scalable, but *bounded enough* to be manageable].

#prop("Microservices Properties")[
  - *Fine-grained* #swarrow each service is small and focused on a single responsibility.
  - *Independently deployable* #swarrow one service can be updated without touching the rest.
  - *Scalable in isolation* #swarrow only the overloaded (micro)service needs more replicas.
  - *Composable* #swarrow the application is assembled from many cooperating microservices.
  - *Container-native* #swarrow designed to run inside containers, making them portable.
]

#figure(
  image("../assets/microervices-vs-monolith.png", width: 60%),
  caption: [Monolith vs. Microservices.]
)

#why("Microservices succeeded")[
  _Traditional monolithic applications are *hard to update at scale*: touching one part risks breaking others. Microservices solve this by separating concerns into independently releasable units. Combined with DevOps and containers, you get an architecture where #hl[*each service can evolve at its own pace*] without coordination overhead._
]
#v(-1em)
#analogy("Microservices vs. Monolith")[
  A monolithic application is like a *large ship*: powerful, but any change requires dry-docking the whole vessel. Microservices are like a *fleet of small speedboats*: each can be repaired, upgraded, or replaced independently while the fleet keeps sailing.
]
#v(-1em)
#note[
  Microservices are *not a new idea*: the underlying principles (small components, web interfaces, independent deployment) existed long before the term. What changed is the *tooling* (containers, orchestrators) that made them practical at scale.

  The full microservice decomposition, trade-offs, hosting problems, and Docker are covered in the #link(<ch04-microservices>)[_*Components, Microservices, and Containers* chapter_].
]

== Docker and Modern Containers

The rise of microservices created the need for a lightweight, portable way to package and run components. #hl[*Docker* became the de-facto standard].

#def("Docker")[
  #kw[Docker] is a set of tools for Linux-based containers that allows to *design, host, control, and optimize* services, both statically (at deployment time) and dynamically (at runtime). It #hl[packages an entire application together with its minimal support and dependencies into a single portable] #hl[unit].
]

=== Docker Architecture

Docker is organized around three elements:

- #kw[Registry] (Docker Hub or private): a *repository* of images to pull and share.
- #kw[Client]: the CLI that issues commands to the Docker daemon.
- #kw[Target Nodes]: the machines on which containers actually run, managed by a *container engine*.

#figure(
  image("../assets/docker-clinet-server-registry.png", width: 80%),
  caption: [Docker Architecture.]
)

=== Docker Containers vs. Virtual Machines

#table(
  align: (x,y) => {if y == 0 { center} else { left }},
  fill: (x,y) => {if y == 0 { accent.lighten(45%) } else { if calc.rem(y,2) == 0 { gray.lighten(70%) } else { white }}},
  columns: (1fr, 1fr),
  stroke: 0.5pt,
  inset: 0.8em,
  [*Container*], [*Virtual Machine*],
  [#hl[Shares the host OS *kernel*]], [Has its own *Guest OS*],
  [Starts in milliseconds], [Starts in seconds/minutes],
  [#hl[Lightweight] (MBs)], [Heavy (GBs)],
  [Process-level isolation], [Full hardware-level isolation],
  [Ideal for microservices], [Ideal for strong isolation],
)

#extra[
  #note[Containers are *not weaker* or worse than VMs, they are a different trade-off. Many deployments run containers *inside* VMs to get both portability (containers) and strong security boundaries (VMs).]
]

#figure(
  image("../assets/virtualization-containerization.jpg",width: 90%),
  caption: [Virtualization vs. Containerization vs. Hybrid.]
)

=== Docker Container Lifecycle

#prop("Docker Container Operations")[
  A container is *created from an image* and then managed through its lifecycle:
  - *Deploy* #swarrow instantiate from an image.
  - *Run* #swarrow execute the self-contained application.
  - *Stop / Start* #swarrow pause and resume.
  - *Move* #swarrow migrate to a different host.
  - *Delete* #swarrow remove permanently.
]

Docker exposes an API (used by its own CLI) that allow to execute commands to manage and control containers and to exec commands inside the containers.

The #hl[#kw[Dockerfile] describes how an image has to be] (its *layers*), in a *standard*, *uniform* way. From *images* containers are built. The #hl[image is *static* and *immutable*].
#v(-0.8em)
#note[
  The full Docker engine internals (images, layered filesystem, networks, Dockerfile instructions, Docker Compose) are covered in the #link(<ch04-docker>)[_*Components, Microservices, and Containers* chapter_].
]

#important("Container as an Application Platform")[
  A Docker container:
  - Includes *all the details* for running a self-contained application.
  - Acts as an *isolated *and* safe security boundary*. Every container is mapped as a separated process.
  - Is organized like a *directory* internally.
  - Is created from a *Docker image* (the static template).
  Containers are the *executing components* of Docker, images are the blueprint.
]

=== Kubernetes

When microservices scale to hundreds or thousands of containers, manual management becomes impractical. #kw[Kubernetes] is the dominant *container orchestrator*: it automates deployment, scaling, load balancing, and self-healing across a cluster of nodes (one master + several workers).

#extra[
  Kubernetes will be covered in depth in a dedicated chapter. Here, the key idea is that Docker solves the *packaging and portability* problem, while Kubernetes solves the *large-scale orchestration and lifecycle management* problem.
]
