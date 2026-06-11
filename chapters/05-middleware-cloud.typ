#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= MIDDLEWARE AND CLOUD MODELS
#extra[
  Package: Middleware & Cloud Models — `Middleware and Cloud 25.pdf`
]

This chapter covers two deeply connected topics. First, *middleware* — the software layer that glues distributed applications to heterogeneous infrastructure. Then *cloud computing* — which is, in large part, what middleware has evolved into at industrial scale.

// ─────────────────────────────────────────────────────────────
// PART 1: MIDDLEWARE
// ─────────────────────────────────────────────────────────────

// Middleware

== What is Middleware?

#def("Middleware")[
  #kw[Middleware] is the *software layer that sits between applications and low-level support* (hardware, local OS, network technology). It provides a *uniform access API* to intrinsically heterogeneous local functions, allowing applications to be designed, deployed, and evolved independently of the underlying infrastructure.
]

The term goes back to *1968*, coined at a NATO school on Software Engineering. It became significant in the *1990s* when distributed systems became widespread.

#prop("Why Middleware Exists")[
  - *Hide component and resource physical distribution*: make the split of an application across different machines transparent.
  - *Hide heterogeneity*: abstract over different hardware, OSes, protocols, and data formats.
  - *Provide common interfaces*: allow legacy parts to be composed and reused without modification.
  - *Provide basic services*: naming, discovery, fast storage, parallel processing, security.
  - *Grant availability and QoS*: manage the system's quality properties at runtime.
]

#analogy("Middleware as a Universal Adapter")[
  Heterogeneous systems are like devices with different plugs from different countries.
  Middleware is the universal adapter — you plug in whatever device you have,
  and the adapter takes care of the conversion. Without it, every integration
  requires a custom cable.
]

#extra[
  Another definition: middleware is a *decoupling layer* among all system layers. It permits a *continuous simplified design* of any application part — and also of the support part itself — by allowing any overcoming of intrinsic heterogeneity.
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

Middleware is not a single monolithic layer but a *stack of four sub-layers*, from bottom to top:

=== 1. Host Infrastructure Middleware

The lowest layer. It *encapsulates and prepares common services* to support distribution and ease communication. Examples: JVM, .NET, other local runtime models.

It provides *portability*: some APIs are unified toward a single support across different environments.

=== 2. Distribution Middleware

This layer provides the *programming models for distribution* and eases applications in configuring and managing distributed resources.

It allows an easier *communication and coordination* of all nodes in the system by introducing:
- A *resource model* — a conceptual model for naming and accessing distributed resources.
- *Communication APIs* — proposing and enforcing a new conceptual model.
- Other basic functions: *name support, discovery, fast storage and access, parallel processing*.

Examples: RPC, RMI, CORBA, DCOM, .NET, SOAP.

=== 3. Common Middleware Services

*Added-value services*, typically higher-level, to facilitate the duties of the designer and enforce a component-oriented perspective.

Several additional services can be added at any time depending on needs:
*events, logging, streaming, security, fault tolerance*, …

Examples: CORBA Services, J2EE, .NET Web Services.

=== 4. Domain-specific Middleware Service

A set of application tools and services *grouped according to specific domains*, defined by task forces within standards bodies (OMG). Always defining standards.

Examples: Electronic Commerce TF, Finance/Fintech TF, Life Science TF, Boeing Bold Stroke (flight transport), Syngo Siemens Medical Engineering.

== Taxonomy of Middlewares

#def("Taxonomy")[
  The main middleware families are:
  - *RPC / RMI*: Remote Procedure/Method Call — synchronous client-server.
  - *MOM*: Message Oriented Middleware — asynchronous message exchange.
  - *DOC*: Distributed Object Computing — object-oriented distribution.
  - *DTP Monitor*: Distributed Transaction Processing — ACID distributed transactions.
  - *DB Middleware*: Database integration and access.
  - *Adaptive & Reflective*: self-adapting to the application context.
  - *Self-\* Middleware*: autonomic systems (self-configuring, self-optimizing, self-healing, self-protecting).
]

=== RPC / RMI Middleware

#def("RPC — Remote Procedure Call")[
  #kw[RPC] exposes remote services as if they were local function calls. The client uses an *IDL* (Interface Definition Language) to define the contract; a *stub* on the client side serializes the call; the server-side skeleton deserializes and invokes the real function.
]

#prop("RPC Properties")[
  - *Synchronous*: the client blocks waiting for the result from the server.
  - *Heterogeneous data handling*: stubs serialize/deserialize across different representations.
  - *Binding* often static — the server endpoint must be known upfront.
]

#important("RPC Limitations")[
  The RPC model is *too rigid, not scalable, and not replicable with QoS*:
  - The server design must be explicit; any provisioning must be explicitly defined.
  - No easy sharing of private and public resources.
  - Not flexible enough as services grow and evolve.
  - *RMI evolves into "in-the-large"*; RPC stays "in-the-small".
]

=== MOM — Message Oriented Middleware

#def("MOM")[
  #kw[MOM] distributes data and code via *message exchange between logically separated entities*. Messages can be typed or untyped, synchronous or asynchronous. A *broker* manages delivery with different strategies and QoS levels.
]

#prop("MOM Properties")[
  - *Wide autonomy* between components — sender and receiver are fully decoupled.
  - *Asynchronous* and *persistent* actions: messages survive sender/receiver disconnections.
  - *Handler/broker* with configurable strategies and QoS.
  - Easy support for *multicast, broadcast, publish/subscribe*.
]

#note[
  Persistent messages are useful even when not explicitly requested — messages are not lost if the receiver is temporarily unavailable. Non-persistent messages are dropped if the receiver is absent.
]

Examples: MQSeries (IBM), MSMQ (Microsoft), JMS (Sun), DDS, MQTT, RabbitMQ, ActiveMQ.

=== DOC / OO Middleware

#def("DOC — Distributed Object Computing")[
  #kw[DOC] distributes data and code via *operation requests and replies between clients and remote servers*, using object-oriented languages. A *framework* and a *broker* act as intermediaries for operation object handling.
]

#prop("DOC Properties")[
  - The *object model* simplifies design.
  - The *broker* provides base services and can automate some operations completely.
  - *System integration* is easier and effective.
  - Usually *open source*; implementations can be very *scalable and available*.
]

#note[
  DOC clients and servers block during the call (clients wait for the server to complete the request). The broker mediates so that clients do not need to know the server's physical location.
]

Examples: CORBA, COM, .NET, Java Enterprise.

=== DTP Monitor

#def("Distributed Transaction Processing (DTP) Monitor")[
  A #kw[DTP Monitor] is middleware to declare and support *distributed transactions*, ensuring *ACID* (Atomicity, Consistency, Isolation, Durability) guarantees across multiple distributed data stores.
]

#prop("DTP Features")[
  - *Specialized interface* for queries by lightweight clients.
  - *Standardized actions* and ad-hoc languages.
  - *Multi-level applications* adopting flexible RPC (beyond synchronous semantics).
  - *Efficiency* in the addressed applicative area.
]

#note[
  Cloud providers do *not* guarantee full ACID — they typically offer eventual consistency (BASE). DTP monitors are more suitable for on-premises deployments where strict consistency is required.
]

Examples: CICS (IBM), Lotus Notes, Tuxedo (BEA).

=== DB Middleware

#def("Database Middleware")[
  #kw[DB Middleware] enables *integration and eased usage of information stored in heterogeneous and different databases*, hiding implementation-specific details behind standard interfaces.
]

The key standard is *ODBC* (Open DataBase Connectivity):
- Works *without requiring modification* to existing DBs.
- Emphasizes *data access* rather than optimization or transactions.
- *Only synchronous and standard operations*.
- Evolves toward *data mining*.

Examples: Oracle Glue, OLE-DB (Microsoft).

=== Adaptive & Reflective Middleware

Middleware able to *self-adapt* to the specific application, also in a *dynamic, reactive, and radical way*.

- *Static variations*: typically component-dependent.
- *Dynamic variations*: typically system-dependent.

Via *reflection*, action policies are expressed and visible in the middleware itself and can change as system components — obtaining *adaptation and flexibility at execution time*.

#note[
  Not yet widely deployed in production, but an active research area — especially relevant for cloud-edge continuum and IoT.
]

=== Self-\* Middleware

Inspired by modeling computing systems *as human bodies*: capable of taking care of themselves and changing accordingly to life-cycle variations.

Complex systems organize as *self-managing and self-administering* entities. Also termed *self-\** (related to computer agents):

- *self-configuration* #arrow autonomy
- *self-optimization* #arrow social ability and cooperation
- *self-healing* #arrow reactivity
- *self-protection* #arrow proactiveness

=== Specialized Middlewares

- *Mobility Middleware*: transparent allocation and re-allocation across layers (network to application).
- *Enterprise Middleware*: EAI (Enterprise Application Integration) — rapid prototyping and integration of existing enterprise tools. Examples: SAP (enterprise management), Websphere/Oracle (IT/resource management), *SOA*.
- *Real-Time Middleware*: guarantees response times and deadlines for RT service development.
- *Ad-hoc Networking Middleware*: lightweight components for environments with limited resources and consumption capacities.

== Middleware Usage Scenarios

Middleware comes in three archetypes based on how it is used:

=== Scenario 1: Minimum Cost Middleware

*Drives the configuration of an application* with an internal interaction model, without dynamic scenarios. The application works in a closed way, *with very low cost and very low intrusion*.

#kw[Disappearing middleware]: defines a fixed set of nodes and provides specific architectural components with *default interaction, rigid and non-adjustable* but *optimized*. No service names, no dynamic reconfiguration, no turn-on/turn-off of resources.

=== Scenario 2: Middleware for Fast Applications

*Streamlined and optimized applications* that require services and get them quickly. Applications provide services to each other — middleware uses its functions and currently available applications dynamically.

#kw[Microsoft Middleware] is within this category: installed on demand for applications that can interact in various ways (DOC) with other active applications at runtime. *Middleware lifetime is tied to the application life cycle*.

=== Scenario 3: Middleware for Continuity

Middleware that needs to *extend the lifetime of service without limit*. Services are the set of all features an organization makes available for coarse-grained and facilitated applications.

#kw[CORBA, .NET]: the middleware *upgrades and enriches itself by operating* — it is initially installed and is also *populated by different applications*, enriching through the introduction of new services, incrementally and seamlessly. *Must maximize life-time* (exhibiting no downtime).

== Middleware Design Issues

As middleware grows in function set, several critical design tensions emerge:

- *Scalability*: the increasing set of functions (objects, resources, etc.) makes scalability very hard. Middleware tends to introduce *indirect and dynamic mechanisms* (interception) to enable management — introducing *overhead* that must be minimized.
- *Management costs*: require increasingly sophisticated monitoring, accounting, security, and control tools.
- *Mobile and dynamic devices*: need continuous adaptation to the current context and situation.

#important("Core Design Tension")[
  Every middleware must balance *functionality* against *intrusion*. Adding more services improves expressiveness but consumes resources that compete with the application. *Minimizing overhead is always a first-class requirement.*
]

// ─────────────────────────────────────────────────────────────
// PART 2: CLOUD COMPUTING
// ─────────────────────────────────────────────────────────────

// Cloud Computing

== The Problem Space

#extra[
  "It starts with the premise that the *data services and architecture should be on servers*. We call it *cloud computing* — they should be in a 'cloud' somewhere. And that if you have the right kind of browser or the right kind of access, it doesn't matter whether you have a PC or a Mac or a mobile phone or a BlackBerry — you can get access to the cloud."
  — Dr. Eric Schmidt, Google CEO, August 2006
]

The drivers behind cloud computing:
- *Explosion of data-intensive applications* on the Internet.
- *Fast growth of connected mobile devices*.
- *Skyrocketing costs* of power, space, and maintenance in traditional data centers.
- *Advances in multi-core computer architecture*.

== A Brief History: Before the Cloud

#def("Grid Computing")[
  #kw[Grid computing] shares *heterogeneous resources* (compute, software, data, memory) in *highly distributed environments* to create a *virtual organization*. Interfaces are often too fine-grained, with low abstraction levels and non self-contained. Application areas are very limited and specific (parallel computation for scientific/engineering scenarios). *HPC is more research-oriented and not so likely to offer industrial services for free market.*
]

#def("Utility Computing")[
  #kw[Utility computing] offers computational and storage capabilities *as a utility*, like energy or electricity — on a *pay-per-use* base. The idea was articulated by John McCarthy at MIT in 1961: "Computing may someday be organized as a public utility." Key properties: metered billing and a simple-to-use interface.
]

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

#prop("Cloud Keywords")[
  - *On demand*: resources provisioned as needed, immediately.
  - *Reliability*: cloud implies a reliable context — agreement on service levels.
  - *Virtualization*: pools of virtualized compute resources.
  - *Provisioning*: rapid live provisioning while demanding.
  - *Scalability*: elastic architecture that scales with load.
]

=== How Cloud Differs from its Predecessors

- *vs. Software not on Premises*: a cloud is more than hosted software — it *manages* the resources (provisioning, workload balancing, monitoring) and sits on top of a data center for efficiency.
- *vs. Grid*: a cloud provides a *mechanism to manage* resources, not just share them.
- *vs. Utility Computing*: cloud users want to *neglect infrastructure*; the provider is in complete control. Grid/utility users want control over each server.

== The SaaS / PaaS / IaaS Model

The cloud is delivered as a *layered architecture* of service models:

#def("SaaS — Software as a Service")[
  Resources are *simple applications* available via remote Web access. The user just uses the application; no infrastructure knowledge is needed.
  Examples: Gmail, Google Docs, Salesforce CRM, Microsoft 365.
]

#def("PaaS — Platform as a Service")[
  Resources are *whole software platforms* available for remote execution — several programs capable of interacting with each other. Users can deploy and run their own applications on the platform.
  Examples: Google App Engine, Azure App Service, Heroku.
]

#def("IaaS — Infrastructure as a Service")[
  Resources are offered in a *wider and complete way*, from hardware platforms to operating systems, to support final user applications. The user may control *any resource configuration*.
  Examples: AWS EC2, Google Compute Engine, Azure VMs, OpenStack.
]

#important("Layered Architecture and Actors")[
  - *SaaS* #arrow End Users (highest value visibility).
  - *PaaS* #arrow Application Developers. *Warning: PaaS is the most dangerous for vendor lock-in* — developers build directly on proprietary platform APIs.
  - *IaaS* #arrow Network Architects (most control, lowest abstraction).
  The layers build on each other: IaaS provides compute/network/storage; PaaS adds components and services on top; SaaS adds the user interface.
]

#why("Why PaaS is the scariest for lock-in")[
  With IaaS you rent machines — you can move VMs between providers with effort.
  With SaaS you use applications — switching means migrating data.
  With PaaS you *build on* the platform's APIs, queues, databases, and services.
  Every line of code that calls a platform-specific API is a line that must be rewritten to migrate.
  #so PaaS creates the deepest technical coupling.
]

=== Architecture Comparison: What the Customer Manages

- *On-premises (Private Cloud)*: customer manages everything — applications, data, OS, virtualization, servers, storage, networking.
- *IaaS*: provider manages servers, storage, networking. Customer manages OS upward.
- *PaaS*: provider manages up through the runtime. Customer manages applications and data only.
- *SaaS*: provider manages everything. Customer just uses the application.

== XaaS — Anything as a Service

#def("XaaS")[
  #kw[XaaS] (Anything as a Service): all Cloud stakeholders provide the richest set of services for any possible user request, accompanying users toward the best choices — Storage as a Service, Container as a Service, and more.
]

Key extensions:

- *FaaS (Function as a Service)*: the user specifies only functions. The provider activates them when triggering events occur, and can operate and support composition and results — the foundation of *serverless computing*.
- *BaaS (Backend as a Service)*: the user is *not aware of all resources* needed. All services are provided as coordinated *-aaS*: storages of different kinds (block and object), configuration of all services, accessory services (intelligent tools), …
- *MaaS (Metal as a Service)*: gives only *native machines* to users who build on them. Adds all services for virtualization, storage, processing, backend, and interconnection design — but in the direction of *visibility* (the user sees and controls low-level details).

== The NIST Cloud Definition Framework

The *National Institute of Standards and Technology (NIST)* provides the reference classification:

*Essential Characteristics*:
- On Demand Self-Service
- Broad Network Access
- Resource Pooling
- Rapid Elasticity
- Measured Service

*Common Characteristics*:
- Massive Scale — Geographic Distribution
- Homogeneity — Resilient Computing
- Virtualization — Service Orientation
- Low Cost Software — Advanced Security

*Service Models*: SaaS, PaaS, IaaS.

*Deployment Models*:

#def("Deployment Models")[
  - #kw[Private cloud]: enterprise owned or leased — infrastructure available only to the single organization.
  - #kw[Community cloud]: shared infrastructure for a specific community (e.g., government, academic consortia).
  - #kw[Public cloud]: sold to the public — mega-scale infrastructure (AWS, Azure, GCP).
  - #kw[Hybrid cloud]: composition of two or more clouds (private + public) — a company uses an internal data center coupled with one or more external clouds.
  - #kw[Multi-cloud]: an organization uses offerings from *many different providers* to optimize costs, scalability, efficiency, flexibility, and geographic constraints — and crucially to *reduce lock-in*. As of 2020, 93% of enterprises use multi-cloud strategies.
]

== Cloud Business Roles (NIST 2011)

New business roles stemming from Cloud usage:

- *Cloud Consumer*: a person or organization that maintains a business relationship with, and uses services from, Cloud Providers.
- *Cloud Provider*: a person or entity responsible for making a service available to Cloud Consumers.
- *Cloud Auditor*: a party that can conduct independent assessment of cloud services — information system operations, performance, and security.
- *Cloud Broker*: an entity that manages the use, performance, and delivery of cloud services, and negotiates relationships between Cloud Providers and Cloud Consumers (service intermediation, aggregation, arbitrage).
- *Cloud Carrier*: the intermediary that provides *connectivity and transport* of cloud services from providers to consumers.

== QoS-Related Properties

These *non-functional properties* are crucial to solution acceptance — especially on the long term:

- *Correctness*: consistency, stability, timeliness.
- *Efficiency*: common procedures, optimal usage of resources, prompt answer.
- *Scalability*: dynamic usage of resources, limited operating costs.
- *Robustness*: fault tolerance, replication, availability, reliability.
- *Security*: thread manager, scheduler, transaction manager.

#extra[
  A cloud provider is going out of business — it has contracts with others that give them resources.
  *Availability* in the context of cloud means the system continues to operate even when components fail — the provider's infrastructure absorbs the failure transparently.
]

== Cloud Architecture

In Cloud, resources must be considered in a more flexible way than traditional systems. You can define and command:
- *Logical resources*: already considered in classical distributed systems.
- *Physical resources*: already considered.
- *Virtual resources*: not only machines, but *any kind* — virtual networks, virtual storage, virtual functions.

You decide how to *map logical components over virtual resources*, and then how to *map virtual resources over physical ones*. The degree of freedom is very large — and so are the architectural choices and their impact on final behavior.

=== Data Center Organization

Cloud is typically organized in *different remote Data Centers* that host the storage and compute. They must be organized carefully to favor *local intra-DC organization* and the *inter-DC infrastructure*:

- Any family of data must be based on *replication widely localized*: several copies in different DCs and several ones in any of them.
- Any DC must optimize access to its copies and have *mechanisms to ease the access* (key-values, DHT, local ring configuration, …).
- Some policies for *configuration* must be decided and actuated *out-of-band* (before data access) and also data operations must be *monitored and controlled during execution* (in-band monitoring, dynamic reconfiguration).

=== Data Center Network Topology

The DC does not use a flat network but typically *hierarchical interconnect machines* that can be optimized by exploiting specific dynamic connections.

#def("Fat-Tree Topology")[
  A #kw[Fat-Tree] topology adds *more connections in layers* — more expensive but making traversal shorter, more fault-tolerant, and with enhanced bandwidth. Organized in *Pods*, each with Edge, Aggregation, and Core layers.
]

#def("Clos Network")[
  A #kw[Clos network] achieves the same goal as Fat-Tree: more connections in layers, shorter traversal paths, better fault tolerance, and enhanced bandwidth. Used in modern DC spine-leaf architectures.
]

The larger the DC, the more interconnected (and expensive) it must be. The hierarchy (Mesh → Border leaf → Spine → Leaf → Servers) is the standard model.

== Cloud Management and Monitoring

=== Remote Management for QoS

In remote/outsourced environments, it is *compulsory to ascertain the current state* of the remote installation — not only for accounting but for actual management. A rich management interface must allow:

- *Access* to all user-related resources (processing, memory, persistent data, network, any *-aaS*).
- *Control* of consumption of any user-related resource (current state, history, peaks, trends, user-defined indicators).
- *Discovery* of new services and new available resources (off-the-shelf ready-to-use solutions).
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

Cloud monitoring is available at two levels:

*Infrastructure (internal)*: physical and virtual resource monitoring with many-to-many communication for fine-grained local monitoring. Cloud nodes publish status via a Data Distribution Service; subscribers feed schedulers and status monitors.

*Customer-facing*: evolved monitoring functions to control customer expenditures. Key platforms: *Amazon CloudWatch*, *Google Cloud Monitoring*. Common features across all platforms:
- Build your own dashboard.
- Define your own alarms.
- Define your retained state.
- Define data collections and analytics.

== Middleware for Cloud

#important("Cloud from the Provider Perspective")[
  From the *user perspective*: provisioning of virtualized resources obtained in an elastic and fast way, in any phase of user request.
  From the *provider perspective*: provide services (*-aaS*) according to agreed SLA, following two principles:
  - *Efficiency*: respond to all users.
  - *Effectiveness*: carefully use available resources.
  Every provider uses its resources and finds the best mapping of configurations and QoS for better services.
]

The key scenarios going forward are *many-to-many*:
- *Customers* interested not only in one provider's resources but in *balancing* across multiple providers in accordance with internal policies.
- *Federation* between Cloud providers to exchange services and resources.
- *Cloud as integrator* of software resources (*full stack or IPaaS — Integration Platform as a Service*).

#note[
  Standardization is unavoidable: clear roles and responsibilities, open source standards and implementations, integration with existing protocols (mobile access), supports for sustainability, and global/local legal clarity.
  Ties with *Big Data, Open Data, IoT data*, and *Smart City* make cloud a central element of the digital infrastructure.
]
