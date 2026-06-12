#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= MIDDLEWARE AND CLOUD MODELS
#extra[
  Package: Middleware & Cloud Models - `Middleware and Cloud 25.pdf`
]

This chapter covers two deeply connected topics:
+ *Middleware* #swarrow the software layer that glues distributed applications to heterogeneous infrastructure.
+ *Cloud computing* #swarrow which is, in large part, what middleware has evolved into at industrial scale.

// ─────────────────────────────────────────────────────────────
// PART 1: MIDDLEWARE
// ─────────────────────────────────────────────────────────────

== What is Middleware?

#def("Middleware")[
  #kw[Middleware] is the *software layer* that sits *between applications and low-level support* (hardware, local OS, network technology). It provides a *uniform access API* to intrinsically heterogeneous local functions, allowing applications to be designed, deployed, and evolved independently of the underlying infrastructure.
]

The term goes back to *1968*, coined at a NATO school on Software Engineering. It became significant in the *1990s* when distributed systems became widespread.

#why("Middleware exists")[
  - *Hide component and resource physical distribution*: make the split of an application across different machines transparent.
  - *Hide heterogeneity*: abstract over different hardware, OSes, protocols, and data formats.
  - *Provide common interfaces*: allow legacy parts to be composed and reused without modification.
  - *Provide basic services*: naming, discovery, fast storage, parallel processing, security.
  - *Grant availability and QoS*: manage the system's quality properties at runtime.
]
#v(-1em)
#analogy("Middleware as a Universal Adapter")[
  Heterogeneous systems are like devices with different plugs from different countries.
  Middleware is the universal adapter: you plug in whatever device you have,
  and the adapter takes care of the conversion. Without it, every integration
  requires a custom cable, transformer,...
]

#extra[
  Another definition: middleware is a *decoupling layer* among all system layers. It allows a *continuous simplified design* of any application part, and also of the support part itself, by allowing any overcoming of intrinsic heterogeneity.
]

=== Middleware Support Functions

#prop("What Middleware Supports")[
  - *Presentation Management*: print, graphics, GUI, user interaction.
  - *Computation*: common procedures, character services, sorting, parallelization, fast access, internationalization.
  - *Information Management*: file manager, record manager, database manager, log manager.
  - *Communication*: messaging, RPC, message queues, mail, electronic data interchange.
  - *Control*: thread manager, scheduler, transaction manager, activity planning.
  - *System Management*: accounting, configuration, security, performance, fault management, event handling.
]

== Middleware in a Layered View

Middleware is not a single monolithic layer but a #hl[*stack* of four sub-layers], from bottom to top:

#figure(
  image("../assets/middleware-layers.svg", width: 60%),
  caption: "The four middleware layers, from host infrastructure to domain-specific services."
)

=== #text(fill: purple.darken(10%))[Host Infrastructure Middleware]

The lowest layer. It #hl[*encapsulates* and *prepares common services*] to support distribution and ease communication.\
It #hl[provides *portability*]: some APIs are unified toward a single support across different environments.
#extra[Examples: *JVM*, .NET, other local runtime models.]

=== #text(fill: orange.darken(10%))[Distribution Middleware]

This layer provides the *programming models for distribution* and eases applications in configuring and managing distributed resources.

It allows an #hl[easier *communication* and *coordination*] of all nodes in the system by introducing:
- A #hl[*resource model*: a conceptual model for naming and accessing distributed resources].
- *Communication #hl[APIs]*: proposing and enforcing a new conceptual model.
- Other basic functions: *name support, discovery, fast storage and access, parallel processing*.

#extra[Examples: RPC, RMI, *CORBA*, DCOM, .NET, SOAP.]

=== #text(fill: yellow.darken(10%))[Common Middleware Services]

*Added-value services*, typically higher-level, to facilitate the duties of the designer and enforce a component-oriented perspective.

Several #hl[additional services can be added at any time depending on needs]:
*events, logging, streaming, security, fault tolerance*, ...
#extra[Examples: CORBA Services, J2EE, .NET Web Services.]

=== #text(fill: green.darken(15%))[Domain-specific Middleware Service]

A set of application tools and services *grouped according to specific domains*, defined by task forces within standards bodies (OMG). Always defining standards.

#extra[Examples: Electronic Commerce TF, Finance/Fintech TF, Life Science TF, Boeing Bold Stroke (flight transport), Syngo Siemens Medical Engineering.]

== Taxonomy of Middlewares

#def("Taxonomy")[
  The main middleware families are:
  - *RPC / RMI*: Remote Procedure/Method Call, *synchronous client-server*.
  - #kw[MOM] (Message Oriented Middleware): *asynchronous message exchange*.
  - #kw[DOC] (Distributed Object Computing): *object-oriented* distribution.
  - _*DTP Monitor* (Distributed Transaction Processing): *ACID* distributed transactions._
  - _*DB Middleware*: Database integration and access._
  - #underline[*Adaptive *&* Reflective*]: self-adapting to the application context.
  - *Self-\* Middleware*: autonomic systems (self-configuring, self-optimizing, self-healing, self-protecting).
  Special-purpose:
  - *Mobile* & *QoS* Middleware
  - *Agent-based* Middleware
]

=== RPC / RMI Middleware

#def("Remote Procedure Call")[
  #kw[RPC] exposes *remote services* as if they were local function calls. The client uses an *IDL* (Interface Definition Language) to define the contract. A *stub* on the client side serializes the call while the server-side *skeleton* deserializes and invokes the real function.
]
#v(-1em)
#prop("RPC Properties")[
  - #hl[*Synchronous*]: the client blocks waiting for the result from the server.
  - *Heterogeneous data handling*: stubs serialize/deserialize across different representations.
  - *Binding* often static: the server endpoint must be known upfront.
]
#v(-1em)
#important("RPC Limitations")[
  The RPC model is *too #hl[rigid, not scalable, and not replicable with QoS]*:
  - The server design must be explicit, any provisioning must be explicitly defined.
  - No easy sharing of private and public resources.
  - Not flexible enough as services grow and evolve.
  - *RMI evolves into "in-the-large"*, RPC stays "in-the-small".
]

=== MOM

#def("Message Oriented Middleware")[
  #kw[MOM] distributes data and code via *message exchange* between *logically separated entities*. Messages can be typed or untyped, synchronous or asynchronous. A *broker* manages delivery with different strategies and QoS levels.
]
#v(-1em)
#prop("MOM Properties")[
  - *Wide autonomy* between components: #hl[sender and receiver are fully *decoupled*].
  - #hl[*Asynchronous* and *persistent* actions]: messages survive sender/receiver disconnections.
  - *Handler/broker* with configurable strategies and QoS.
  - Easy #hl[support for *multicast, broadcast, publish/subscribe*].
]
#v(-1em)
#note[
  Persistent messages are useful even when not explicitly requested: messages are not lost if the receiver is temporarily unavailable. Non-persistent messages are dropped if the receiver is absent.
]
#extra[Examples: MQSeries (IBM), MSMQ (Microsoft), JMS (Sun), DDS, MQTT, RabbitMQ, ActiveMQ.]

=== DOC / OO Middleware

#def("Distributed Object Computing")[
  #kw[DOC] distributes data and code via *operation requests* and *replies between clients and remote servers*, using object-oriented languages. A #hl[*framework* and a *broker* act as intermediaries] for operation object handling.
]
#v(-1em)
#prop("DOC Properties")[
  - The *object model* simplifies design.
  - The *broker* provides base services and can automate some operations completely.
  - *System integration* is easier and effective.
  - Usually *open source*, implementations can be very *scalable and available*.
]
#v(-1em)
#note[
  DOC #hl[clients and servers *block* during the call] (clients wait for the server to complete the request). The broker mediates so that clients do not need to know the server's physical location.
]
#v(-1em)
#note[
  Typically #hl[*server* is *stateless*, clients keep the state].
]
#extra[Examples: *CORBA*, COM, .NET, Java Enterprise.]

=== DTP Monitor

#def("Distributed Transaction Processing Monitor")[
  A #kw[DTP Monitor] is a middleware to declare and support *distributed transactions*, ensuring #underline[*ACID*] (Atomicity, Consistency, Isolation, Durability) guarantees across multiple distributed data stores.
]
#v(-1em)
#prop("DTP Features")[
  - *Specialized interface* for queries by lightweight clients.
  - *Standardized actions* and ad-hoc languages.
  - *Multi-level applications* adopting flexible RPC (beyond synchronous semantics).
  - *Efficiency* in the addressed applicative area.
]
#v(-1em)
#note[
  #hl[Cloud providers do *not* guarantee full ACID]: they typically offer #hl[eventual consistency] (*BASE*). DTP monitors are more suitable for on-premises deployments where strict consistency is required.
]

#extra[Examples: CICS (IBM), Lotus Notes, Tuxedo (BEA).]

=== DB Middleware

#def("Database Middleware")[
  #kw[DB Middleware] enables *integration and eased usage of information stored in heterogeneous and different databases*, hiding implementation-specific details behind standard interfaces.
]

The key standard is *ODBC* (Open DataBase Connectivity):
- Works *without requiring modification* to existing DBs.
- Emphasizes *data access* rather than optimization or transactions.
- *Only synchronous and standard operations*.
- Evolves toward *data mining*.

#extra[Examples: Oracle Glue, OLE-DB (Microsoft).]

=== Adaptive & Reflective Middleware

Middleware able to *self-adapt* to the specific application, also in a *dynamic, reactive, and radical way*.

- *Static variations*: typically component-dependent.
  #extra[
    #swarrow They adapt the middleware to the architectural structure and protocols of the application, typically frozen at deployment.
  ]
- *Dynamic variations*: typically system-dependent.
  #extra[
  #swarrow They react at runtime to fluctuating infrastructural conditions, such as network latency or CPU load.
  ]

Via *reflection*, action policies are expressed and visible in the middleware itself and can change as system components, obtaining *adaptation and flexibility at execution time*.
#extra[

  #note[
    Not yet widely deployed in production, but an active research area, especially relevant for cloud-edge continuum and IoT.
  ]
]

=== Self-\* Middleware

Inspired by modeling computing systems *as human bodies*: capable of taking care of themselves and changing accordingly to life-cycle variations.

Complex systems organize as *self-managing and self-administering* entities. Also termed *self-\** (related to computer agents):

- *self-configuration* #swarrow autonomy
- *self-optimization* #swarrow social ability and cooperation
- *self-healing* #swarrow reactivity
- *self-protection* #swarrow proactiveness

=== Specialized Middlewares

- *Mobility Middleware*: transparent allocation and re-allocation across layers (network to application).
- *Enterprise Middleware*: EAI (Enterprise Application Integration): rapid prototyping and integration of existing enterprise tools. 
  #extra[Examples: SAP (enterprise management), Websphere/Oracle (IT/resource management), *SOA*.]
- *Real-Time Middleware*: guarantees response times and deadlines for RT service development.
- *Ad-hoc Networking Middleware*: lightweight components for environments with limited resources and consumption capacities.

== Middleware Usage Scenarios

Middleware comes in three archetypes based on how it is used:
=== Scenario 1: Minimum Cost Middleware

This scenario focuses on driving the configuration of a single application according to a fixed, internal interaction model, entirely excluding dynamic runtime scenarios. The system operates in a closed, highly stable environment, prioritizing #hl[*minimal operational cost* and *low software intrusion*].

#def("Disappearing Middleware")[
      A #kw[disappearing middleware] is a lightweight, highly optimized middleware layer whose runtime footprint "disappears" because it avoids any dynamic management or discovery overhead.
      - *Static Architecture:* It defines a fixed, statically determined set of nodes and hardware resources at deployment time.
      - *Rigid Interaction:* Communication channels and interfaces are default, rigid, and non-adjustable, yet highly optimized for maximum performance.
      - *No Operational Overhead:* It lacks support for dynamic reconfiguration, runtime resource provisioning (turning on/off resources), or dynamic service registries.
]
#v(-1em)
#example("MOM")[
      Traditional MOMs fall into this category: they are deployed with predefined queues and static topologies to ensure predictable, low-overhead message routing.
]

=== Scenario 2: Middleware for Fast Applications

Targeted at highly streamlined and optimized applications that require rapid, efficient service provisioning. Instead of relying on a heavy, permanent infrastructure, applications cooperatively provide services to one another, and the #hl[middleware dynamically coordinates these currently active] #hl[components to self-adapt to the real-time usage] situation.

#def("On-Demand Integration Middleware")[
      An #kw[On-Demand Integration Middleware] is a flexible layer designed to facilitate straightforward cooperation and interoperability among running applications at execution time.
      - *On-Demand Deployment:* The middleware infrastructure is spun up strictly on demand when applications need to interact (e.g., via Distributed Object Computing - DOC).
      - *Tied Lifecycle:* The middleware's lifetime is tightly coupled to the lifecycle of the applications using it; it does not persist independently. When the last application exits, the middleware shuts down.
]
#v(-1em)
#example("Microsoft Component Middleware")[
      Classic Microsoft enterprise solutions (such as COM+ or early .NET components) exemplify this approach, where infrastructure services are loaded dynamically into the application process space on demand.
]

=== Scenario 3: Middleware for Continuity

This paradigm targets large-scale, mature, and comprehensive enterprise environments where the fundamental requirement is to #hl[extend the lifetime of services indefinitely], moving toward an *infinite lifecycle*.

#def("Evolving Ecosystem Middleware")[
      An #kw[Evolving Ecosystem Middleware] is a permanent, heavy-duty infrastructure that serves as a continuous, shared foundation for an organization's entire software ecosystem.
      - *Coarse-Grained Services:* It hosts a comprehensive catalog of high-level, coarse-grained features made readily accessible to streamline application development.
      - *Incremental Enrichment:* Rather than requiring reboots or redeployments, the middleware updates and enriches itself seamlessly over time; it is continuously *populated by different applications* that introduce new services at runtime.
      - *Continuous Availability:* it strictly maximizes system lifetime by exhibiting absolute zero downtime during upgrades or component modifications.
]
#v(-1em)
#example("CORBA & Enterprise .NET")[
      Architectures like CORBA or enterprise-grade .NET environments act as permanent corporate backbones, constantly running and accumulating new institutional capabilities over decades.
]

== Middleware Design Issues

As middleware grows in function set, several critical design tensions emerge:

- *Scalability*: the increasing set of functions (objects, resources, etc.) makes #hl[scalability very hard]. Middleware tends to introduce *indirect and dynamic mechanisms* (interception) to enable management, introducing *overhead* that must be minimized.
- #hl[*Management costs*]: require increasingly sophisticated monitoring, accounting, security, and control tools.
- *Mobile and dynamic devices*: need continuous adaptation to the current context and situation.

#important("Core Design Tension")[
  Every #hl[middleware must balance *functionality* against *intrusion*]. Adding more services improves expressiveness but consumes resources that compete with the application. *#hl[Minimizing overhead] is always a first-class requirement.*
]

// ─────────────────────────────────────────────────────────────
// PART 2: CLOUD COMPUTING
// ─────────────────────────────────────────────────────────────

== The Problem Space

The drivers behind cloud computing:
- *Explosion of data-intensive applications* on the Internet.
- *Fast growth of connected mobile devices*.
- *Skyrocketing #hl[costs]* of power, space, and maintenance in traditional data centers.
- *Advances in multi-core computer architecture*.

== A Brief History: Before the Cloud

#def("Grid Computing")[
  #kw[Grid computing] shares *heterogeneous resources* (compute, software, data, memory) in *highly distributed environments* to create a *virtual organization*. 
]
#v(-0.6em)
Interfaces are often too fine-grained, with low abstraction levels and non self-contained. Application areas are very limited and specific (parallel computation for scientific/engineering scenarios). *HPC is more research-oriented and not so likely to offer industrial services for free market.*

#def("Utility Computing")[
  #kw[Utility computing] offers computational and storage capabilities *as a utility*, like energy or electricity, on a *pay-per-use* base. 
]
#v(-0.5em)
Other precursors:
- *Virtualization (2005+)*: VMware, Xen, and server farm virtualization.
- *Web 2.0*: AJAX-based asynchronous UIs, SaaS prototypes (Google Docs, Salesforce).
- *Microservices & Orchestrators (2015+)*: Docker, Kubernetes.

#important("Cloud Computing = Intersection")[
  Cloud Computing sits at the *intersection* of Grid Computing, Utility Computing, and Software-not-on-Premises. It inherits resource sharing from grid, pay-per-use from utility, and remote software delivery from SaaS.
]

== What is a Cloud?

#def("Cloud Computing")[
  A #kw[cloud] is an *IT service* that provides IT resources *as a Service*, delivered to users that have:
  - A *user interface* that makes the underlying infrastructure *transparent*.
  - *Massive scalability* on demand.
  - A *service-oriented management* architecture.
  - *Reduced incremental management costs* as additional IT resources are added.
  Services are available via *Web or REST interfaces*; user requirements may vary based on *geographical preferences, localization constraints* (e.g., low latency, local law compliance).
]
#v(-1em)
#prop("Cloud Keywords")[
  - *On demand*: resources provisioned as needed, immediately.
  - *Reliability*: cloud implies a reliable context with agreed service levels.
  - *Virtualization*: pools of virtualized compute resources.
  - *Provisioning*: rapid live provisioning while demanding.
  - *Scalability*: elastic architecture that scales with load.
]

=== How Cloud Differs from its Predecessors

- *vs. Software not on Premises*: a cloud is more than hosted software: it *manages* the resources (provisioning, workload balancing, monitoring) and sits on top of a data center for efficiency.
- *vs. Grid*: a cloud provides a *mechanism to manage* resources, not just share them.
- *vs. Utility Computing*: cloud users want to *neglect infrastructure*; the provider is in complete control. Grid/utility users want control over each server.

== The SaaS / PaaS / IaaS Model

The cloud is delivered as a *layered architecture* of service models:
#v(-0.7em)
#def("SaaS - Software as a Service")[
  In #kw[SaaS] resources are *simple applications* available via remote Web access. The user just uses the application, no infrastructure knowledge is needed.
]
#v(-0.2em)
#extra[Examples: Gmail, Google Docs, Salesforce CRM, Microsoft 365.]
#v(-0.5em)
#def("PaaS - Platform as a Service")[
  In #kw[PaaS] resources are *whole software platforms* available for remote execution: several programs capable of interacting with each other. Users can deploy and run their own applications on the platform.
  
]
#v(-0.2em)
#extra[Examples: Google App Engine, Azure App Service, Heroku.]
#v(-0.5em)
#def("IaaS - Infrastructure as a Service")[
  Resources are offered in a *wider and complete way*, from hardware platforms to operating systems, to support final user applications. The user may control *any resource configuration*.
]
#v(-0.2em)
#extra[Examples: AWS EC2, Google Compute Engine, Azure VMs, OpenStack.]
#v(-0.5em)
#important("Layered Architecture and Actors")[
  - *SaaS* #arrow End Users (highest value visibility).
  - *PaaS* #arrow Application Developers. #swarrow The most dangerous for *vendor lock-in*, developers build directly on proprietary platform APIs.
  - *IaaS* #arrow Network Architects (most control, lowest abstraction).
  The layers build on each other: IaaS provides compute/network/storage, PaaS adds components and services on top, SaaS adds the user interface.
]

=== Architecture Comparison: What the Customer Manages

- *On-premises (Private Cloud)*: customer manages everything: applications, data, OS, virtualization, servers, storage, networking.
- *IaaS*: provider manages servers, storage, networking. Customer manages OS upward.
- *PaaS*: provider manages up through the runtime. Customer manages applications and data only.
- *SaaS*: provider manages everything. Customer just uses the application.

#figure(
  image("../assets/cloud-service-models.svg", width: 80%),
  caption: "Cloud service models comparison."
)

== XaaS: Anything as a Service

#def("XaaS")[
  #kw[XaaS] (Anything as a Service): all Cloud stakeholders provide the richest set of services for any possible user request, accompanying users toward the best choices (Storage as a Service, Container as a Service, and more).
]

Key extensions:

- *#hl[FaaS] (Function as a Service)*: the user specifies only functions. The provider activates them when triggering events occur, and can operate and support composition and results: the #hl[foundation of *serverless computing*].
- *BaaS (Backend as a Service)*: the user is *not aware of all resources* needed. All services are provided as coordinated *-aaS*: storages of different kinds (block and object), configuration of all services, accessory services (intelligent tools).
- *MaaS (Metal as a Service)*: gives only *native machines* to users who build on them. Adds all services for virtualization, storage, processing, backend, and interconnection design: but in the direction of *visibility* (the user sees and controls low-level details).

== The NIST Cloud Definition Framework

#extra[
  The *National Institute of Standards and Technology (NIST)* provides the reference classification:

  *Essential Characteristics*:
  - On Demand Self-Service
  - Broad Network Access
  - Resource Pooling
  - Rapid Elasticity
  - Measured Service

  *Common Characteristics*:
  - Massive Scale, Geographic Distribution
  - Homogeneity, Resilient Computing
  - Virtualization, Service Orientation
  - Low Cost Software, Advanced Security

  *Service Models*: SaaS, PaaS, IaaS.
]

*Deployment Models*:
#v(-0.8em)
#def("Deployment Models")[
  - #kw[Private cloud]: enterprise owned or leased, the infrastructure available only to the single organization.
  - #kw[Community cloud]: shared infrastructure for a specific community (e.g., government, academic consortia).
  - #kw[Public cloud]: sold to the public, mega-scale infrastructure (AWS, Azure, GCP).
  - #kw[Hybrid cloud]: composition of two or more clouds (private + public): a company uses an internal data center coupled with one or more external clouds.
  - #kw[Multi-cloud]: an organization uses offerings from *many different providers* to optimize costs, scalability, efficiency, flexibility, and geographic constraints, and crucially to *reduce lock-in*. As of 2020, 93% of enterprises use multi-cloud strategies.
]

== QoS-Related Properties

These *non-functional properties* are crucial to solution acceptance, especially on the long term:

- *Correctness*: consistency, stability, timeliness.
  #v(-0.2em)
  #extra[In the sense of giving/getting the expected result.]
- *Efficiency*: common procedures, optimal usage of resources, prompt answer.
- *Scalability*: dynamic usage of resources, limited operating costs.
- *Robustness*: fault tolerance, replication, availability, reliability.
- *Security*: thread manager, scheduler, transaction manager.

#extra[
  A cloud provider going out of business has contracts with others that give them resources.
  *Availability* in the context of cloud means the system continues to operate even when components fail: the provider's infrastructure absorbs the failure transparently.
]

== Cloud Architecture

In Cloud, resources must be considered in a more flexible way than traditional systems. You can define and command:
- *Logical resources*: already considered in classical distributed systems.
- *Physical resources*: already considered.
- *Virtual resources*: not only machines, but *any kind*: virtual networks, virtual storage, virtual functions.

You decide how to *map logical components over virtual resources*, and then how to *map virtual resources over physical ones*. The degree of freedom is very large, and so are the architectural choices and their impact on final behavior.

=== Data Center Organization

#hl[Cloud is typically organized in *different remote Data Centers*] that host the storage and compute. They must be organized carefully to #hl[favor *local intra-DC organization* and the *inter-DC infrastructure*]:

- Any family of data must be #hl[based on *replication widely localized*]: several copies in different DCs and several ones in any of them.
- Any DC must optimize access to its copies and have *mechanisms to ease the access* (key-values, DHT, local ring configuration, ...).
- Some policies for *configuration* must be decided and actuated *out-of-band* (before data access) and also data #hl[operations must be *monitored and controlled during execution*] (in-band monitoring, dynamic reconfiguration).

=== Data Center Network Topology

The DC does not use a flat network but typically *hierarchical interconnect machines* that can be optimized by exploiting specific dynamic connections.

#def("Fat-Tree Topology")[
  A #kw[Fat-Tree] topology adds *more connections in layers*: more expensive but making traversal shorter, more fault-tolerant, and with enhanced bandwidth. Organized in *Pods*, each with Edge, Aggregation, and Core layers.
]
#figure(
  image("../assets/fat-tree.jpg", width: 75%),
  caption: [Fat tree scheme.]
)

#def("Clos Network")[
  A #kw[Clos network] achieves the same goal as Fat-Tree: more connections in layers, shorter traversal paths, better fault tolerance, and enhanced bandwidth. Used in modern DC spine-leaf architectures.
]
#v(-0.7em)
#figure(
  crop(
    image("../assets/clos-network.png", width: 85%),
    top: 4%, bottom: 4%, left: 4%, right: 4%,
  ),
  caption: [Fat tree scheme.]
)

The larger the DC, the more interconnected (and expensive) it must be. The hierarchy is the standard model.

== Cloud Management and Monitoring

=== Remote Management for QoS

In remote/outsourced environments, it is *compulsory to ascertain the current state* of the remote installation: not only for accounting but for actual management. A rich management interface must allow:

- *Access* to all user-related resources (processing, memory, persistent data, network, any *-aaS*).
- #hl[*Control* of consumption of any user-related resource] (current state, history, peaks, trends, user-defined indicators).
- #hl[*Discovery*] of new services and new available resources (off-the-shelf ready-to-use solutions).
- *Installation* of special user settings and environments (new service developed from composing available ones).
- *Enlargement* to *federated environments* for resource integration.

=== Areas of Cloud Management

- *Provisioning and Orchestration*
- *Service Enablement*
- *Inventory and Classification*
- *Monitoring and Observability*
- *Identity, Security and Compliance*
- *Cloud Migration, Backup and DR*
- *Cost Management and Resource Optimization*
- *Automation*
- *Life Cycle management*

=== Cloud Monitoring

Cloud *monitoring* is available at two levels:

- #hl[*Infrastructure (internal)*: physical and virtual resource monitoring] with many-to-many communication for #hl[fine-grained] local monitoring. Cloud nodes publish status via a Data Distribution Service, subscribers feed schedulers and status monitors.

- *Customer-facing*: evolved monitoring functions to control customer expenditures.\ Common features across all platforms:
  - Build your own dashboard.
  - Define your own alarms.
  - Define your retained state.
  - Define data collections and analytics.
  #extra[
    Key platforms: *Amazon CloudWatch*, *Google Cloud Monitoring*.
  ]

== Middleware for Cloud

#important("Cloud from the Provider Perspective")[
  From the *user perspective*: provisioning of virtualized resources obtained in an elastic and fast way, in any phase of user request.\
  From the *provider perspective*: provide services (*-aaS*) according to agreed SLA, following two principles:
  - *Efficiency*: respond to all users.
  - *Effectiveness*: carefully use available resources.
  Every provider uses its resources and finds the best mapping of configurations and QoS for better services.
]

The key scenarios going forward are *many-to-many*:
- *Customers* interested not only in one provider's resources but in *balancing* across multiple providers in accordance with internal policies.
- *Federation* between Cloud providers to exchange resources and services.
- *Cloud as integrator* of software resources (*full stack or IPaaS* #swarrow Integration Platform as a Service).

#note[
  Standardization is unavoidable: clear roles and responsibilities, open source standards and implementations, integration with existing protocols (mobile access), supports for sustainability, and global/local legal clarity.
]
