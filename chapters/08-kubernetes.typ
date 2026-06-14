#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= KUBERNETES
#extra[
  Package: Kubernetes - `b - Kubernetes.pdf`
]

Kubernetes is the industry-standard platform for running containerised applications at scale.
Where Docker solves the problem of *packaging* a single service, Kubernetes solves the
problem of *operating thousands of containers* across a fleet of machines: scheduling them,
keeping them healthy, connecting them to each other, and exposing them to the outside world.

== What is Kubernetes

#def("Kubernetes (k8s)")[
  #kw[Kubernetes] (k8s) is an open-source #hl[container *orchestration system*] originally
  designed by Google for automating application deployment, scaling, and management
  inside a cluster.\
  Its main goal is to *hide the complexity* of managing a fleet of containers by
  providing users a REST *API* (CRUD operations on abstract resources).\
  Kubernetes is *portable*: it runs on public or private clouds (AWS, Azure, OpenStack,
  Apache Mesos) without change.
]

=== From Docker to Kubernetes

Docker #hl[communicates between its CLI, daemon, and container runtime via HTTP/JSON] messages
following the OpenAPI v3 contract. Kubernetes exploits the *same principle*: it talks
directly to the container runtime through the CRI (Container Runtime Interface),
bypassing Docker entirely.

#extra[
  #why([*Docker Compose #arrow Kubernetes*])[
    Docker and Docker Compose already offer isolation, immutable infrastructure, portability,
    fast deployments, and versioning, but they do not handle:
    - *Networking* across multiple hosts.
    - *Deployment* and rolling updates at cluster scale.
    - *Service Discovery*: dynamically finding where each service is running.
    - *Auto Scaling*: adjusting the number of replicas under load.
    - *Persisting Data* with distributed storage.
    - *Logging* and *Access Control* at scale.
    #underline[Kubernetes addresses all of these].
  ]
]
#v(-1em)
#prop("Kubernetes Key Features")[
  - *Multi-container* application deployment.
  - #hl[*Automatic and dynamic scaling* of application replicas].
  - #hl[*Rolling updates* that preserve service availability] during changes.
  - *Computation, network, and storage resources* with built-in service discovery.
  - *Infrastructure independence*: the same manifest runs on any conformant cluster.
]
#v(-1em)
#important("Long-term payoff")[
  Kubernetes requires significant upfront investment in configuration and operations.\
  The payoff comes over time: a more manageable, resilient, and self-healing application infrastructure that would otherwise require extensive custom tooling.
]

== Cluster Architecture

#def("Kubernetes Cluster Architecture")[
  Kubernetes uses a *Master–Worker* (control plane/data plane) architecture.
  The cluster consists of:
  - *Master node(s)*: run the control plane components. Recommended odd number for quorum via RAFT.
  - *Worker nodes*: run actual application workloads (*Pods*).
]

#figure(
  image("../assets/k8s-cluster.svg", width: 70%),
  caption: "Kubernetes cluster: control plane components and worker nodes with Pods and sidecar proxy."
)

=== Control Plane

#def("Control Plane")[
  The #kw[control plane] makes *global decisions* about the cluster: scheduling,
  detecting and responding to cluster events (e.g., a Pod dying).\
  #extra[It is the "brain" of Kubernetes.]
]

Control plane components:

- #hl[#kw[etcd]: the *only stateful component*] of the infrastructure. A distributed
  *key-value store* that holds the entire cluster state and configuration.
- *kube-#kw[apiserver]*: the *front door* of Kubernetes. #hl[All components communicate
  exclusively through the] #hl[API server].
- *kube-controller-manager*: runs the core *control loops* that keep actual state
  converging toward desired state.
- *kube-scheduler*: decides *which node* a newly created Pod should run on.
- *cloud-controller-manager* (optional): integrates with the cloud provider's API
  (load balancers, node lifecycle, storage) at a pace independent of the main project.

=== Worker Node Components

Each worker node runs:

- #kw[kubelet]: the #hl[primary *node agent*. It watches the API server for PodSpecs
  assigned] to its node and ensures the described containers are running and healthy.
- #kw[kube-proxy]: the *network proxy*. It runs on every node, reflects Services
  defined in the Kubernetes API, and programs the data plane (iptables/IPVS) to
  forward traffic.
- *Container Runtime*: the software that actually runs containers (containerd, CRI-O...).
#v(-0.7em)
#analogy("The Airport Analogy")[
  The API server is the airport's central hub. Every passenger (request) must pass
  through it. etcd is the database of all flight bookings: the one source of truth.
  Controllers are ground crew teams each responsible for one type of task
  (gate changes, baggage, refuelling). The scheduler is the dispatcher who assigns
  planes to gates. Kubelets are pilots on each plane, ensuring their specific
  aircraft is operational.
]

== The Declarative Model

#def("Declarative Model")[
  In Kubernetes you *declare the #underline[desired] state* of your application in a *manifest*
  file (JSON or YAML). You post the manifest to the API server and Kubernetes is
  responsible for making reality match the declaration and keeping it that way.
]

The workflow is:

+ *Declare* the desired state of your microservices in a manifest.
+ *Post* it to the Kubernetes API Server.
+ K8s *stores* the desired state in etcd.
+ K8s *implements* the desired state on the cluster.
+ K8s *implements control loops* via the controller-manager to ensure the
  current state never drifts from the desired state.
#v(-0.7em)
#note[
  The #hl[*only state Kubernetes cares about is the desired one*], not the current one.
  This is the fundamental insight behind the declarative model.
]
#v(-0.4em)
#extra[
  #why([*desired state*])[
    Imperative commands ("start 3 replicas") are one-shot: if a replica crashes,
    nothing restarts it. Declaring desired state ("there should always be 3 replicas
    running") hands that #underline[responsibility to Kubernetes]. The system becomes *self-healing*
    automatically: no operator needs to be paged at 3 a.m.
  ]
]

=== Kubernetes Resources

Kubernetes manages different kinds of #kw[resources]:

- *Workloads*: applications running on Kubernetes:
  Deployment, ReplicaSet, StatefulSet, DaemonSet, Job, CronJob.
- *Services, Load Balancing, Networking*: networking resources that enable
  communication between workloads:
  Service, Ingress, IngressController, EndpointSlices, Gateway API, Network Policies.
- *Configurations*: dynamic configuration injected into workloads:
  Secrets, ConfigMaps.
- *Storage*: PersistentVolumes, PersistentVolumeClaims, StorageClasses.
- *Custom Resources* (CRDs): user-defined resource types that extend the API.

== Controllers and the Control Loop

#def("Controller")[
  A #kw[controller] is a *non-terminating control loop* that watches the shared
  state of the cluster (via the API server) and makes changes attempting to move
  the *current state* towards the *desired state*.
]

#figure(
  image("../assets/k8s-observe-analyze-act.jpg", width: 50%),
  caption: [Kubernetes controller Observe–Analyze–Act.]
)

The loop follows the *Observe–Analyze–Act* cycle:

+ *Observe* (watch) the actual state of the cluster.
+ *Analyze* the difference between actual and desired state.
+ *Act* (update) by making API calls to reconcile the difference.
+ Repeat forever.

#hl[State is persisted in *etcd*], which also provides the *synchronisation* mechanism
(*distributed locks*) used when multiple controller replicas run for fault tolerance.
#v(-0.7em)
#note[
  #hl[Controllers adopt *microservice principles*]: it is better to have many simple,
  independent controllers than one monolithic control block. Controllers can fail,
  and Kubernetes is designed to tolerate that.
]

=== Controller–ETCD Interaction

The interaction flow between a controller and etcd:

+ External changes to Resources are saved directly into etcd via the API server.
+ The #hl[Controller *subscribes* to change notifications] for a particular resource in
  etcd (pub/sub pattern).
+ #hl[On notification, the Controller fetches the new state and acts on it].
+ The Controller also schedules #hl[periodic reconciliation] tasks to catch any divergence
  that might have been missed.

#extra[
  Multiple controller replicas coordinate via *distributed locks* in etcd.
  When a controller acquires a lock, it becomes the *leader* and is the only one
  that actually acts. This prevents duplicate actions while still allowing fast
  failover when the leader dies.
]
#v(-1em)
#note[
  #hl[Every Controller always pass through the API to communicate with ETCD].
]
#v(-1em)
#note[
  Pub/sub is not implemented with the classical broker. ETCD is just a key-value store. The API sets a long-live connection when controllers demand to watch for updates and always the API server, as a gatekeeper, updates controllers after ETCD is updated.
]

=== The Operator Pattern

#def("Kubernetes Operator")[
  A #kw[Kubernetes Operator] extends the controller pattern to *domain-specific
  operational knowledge*. An operator consists of:
  - A *Custom Resource Definition (CRD)* that introduces a new resource type
    (e.g., `MongoDB`, `Prometheus`).
  - A *custom controller* (the operator pod) that watches changes to that CRD
    and reconciles the actual cluster state accordingly.
]

The operator lifecycle:

+ The user creates or modifies a Custom Resource (e.g., a `MongoDB` object with
  `replicas: 3`).
+ The operator detects the change event.
+ The operator *reconciles*: creates/modifies/deletes native Kubernetes resources
  (Pods, PVCs, Services) to realise the desired state.
+ In case of error, the reconcile loop retries.

#figure(
  image("../assets/k8s-conciliation-pattern.jpg", width: 70%),
  caption: [Kubernetes operator pattern.]
)

#example("Prometheus Operator")[
  The Prometheus Operator introduces CRDs such as `Prometheus`, `AlertManager`,
  `ServiceMonitor`, and `PodMonitor`. Defining a `ServiceMonitor` resource
  automatically configures Prometheus to scrape the matching services: the
  operator handles the complex Prometheus configuration file generation, reloads,
  and certificate management.
]

#extra[
  Operator frameworks and the OperatorHub.io registry provide a growing ecosystem
  of pre-built operators for databases (MongoDB, PostgreSQL, Redis), messaging
  (Kafka, RabbitMQ), monitoring (Prometheus), and more.
]

== etcd and RAFT

=== etcd

#def("etcd")[
  #kw[etcd] (*distributed etc directory*) is a *strongly consistent*, distributed
  key-value store that implements the RAFT algorithm. In Kubernetes it stores
  *all cluster data and configuration*: the single source of truth.
]
#v(-0.7em)
Properties:
- #hl[*Strongly consistent*]: every read returns the most recently written value.
- #hl[*Fault tolerant*]: replicates data across N nodes #so tolerates $⌊(N−1)/2⌋$ failures.
- *Implements #hl[locking]*: controllers use etcd's distributed locking to coordinate.

=== RAFT

Raft is the core of etcd's distributed nature.
#v(-0.7em)
#def("RAFT")[
  #kw[RAFT] is a *consensus algorithm* designed to be *easy to understand*. It allows a cluster of servers to agree on a sequence of values even when some servers fail.
]
#v(-0.7em)
RAFT decomposes the consensus problem into three relatively independent subproblems:

*Leader Election*
- One server is selected as *leader* at any time.
- If the leader crashes, a new leader is elected.
- Each server gives only *one vote per term* (term: logical clock increment on each election).
- #hl[*Majority* required to win #swarrow only servers with up-to-date logs can become leader].
- Randomised timeouts prevent split votes and work well when timeout >> broadcast time.
#v(-0.7em)
#how([*an election starts*])[
  Servers know when an election is needed because  the actual leader periodically broadcasts heartbeats to followers.
]

*Log Replication* (normal operation)
- The #hl[leader accepts commands from clients, appends them to its log].
  #extra[In kubernetes, the client is the API server.]
- The leader #hl[sends `AppendEntries` RPCs with the log to all followers].
- #hl[Once a majority acknowledges, the entry is *committed*].
- The leader executes the command, returns the result, and notifies followers.
- Crashed or slow followers: the leader retries until they succeed.
- Optimal performance: *one successful RPC to any majority*.

#figure(
  image("../assets/raft.jpg",width: 60%),
  caption: [RAFT log replication.]
)

*Safety*
- #hl[Logs are kept consistent across the cluster].
- Only servers with up-to-date committed logs can become leader.
- Leader is *stateless* between terms: it rebuilds state from the log.
  #extra[
    #note[
      Leader is stateless between terms (not in general) because every replica is equal, no-one has an internal state that state it is the leader or not. Obviously, since etcd is the only one stateful component, it has a state, also every replica has and that is the log.
    ]
  ]
#v(-0.7em)
#analogy("RAFT as a Parliament")[
  RAFT's leader is like a Parliament's Speaker: only one can chair a session
  at a time. A bill (log entry) only passes when a majority of members vote for
  it. If the Speaker is absent, members elect a new one, but only a member
  who has read all previous bills can stand for election.
]

== Nodes, Pods, and Workloads

=== Nodes

#def("Node")[
  A #kw[node] is a *computational resource* (physical or virtual machine) that
  runs workloads. Each node communicates with the control plane through gRPC calls.\
  Node components: `kube-proxy`, `kubelet`, Pods.
]

=== Pods

#def("Pod")[
  A #kw[Pod] is the *atomic unit* of deployment in Kubernetes: the smallest
  deployable object. A Pod represents a group of *one or more containers* that
  share:
  - A *network namespace* (same IP address and port space).
  - *Volumes* (shared storage).
  - A common lifecycle (co-scheduled, co-located, co-terminated).
]

Key Pod properties:

- Pods are #hl[*mortal and unreliable*: if a Pod terminates, Kubernetes starts a new one]
  (with a different IP) rather than restarting the old one.
- #hl[Pods are the minimum unit of *scaling*]: never scale individual containers,
  scale Pods.
- When a Deployment creates Pods, each Pod is *scheduled* (tied to a Node), but if that
  Node fails, identical Pods are scheduled on other available nodes.
#v(-0.7em)
#why([*a group of containers*])[
  Some services consist of tightly-coupled helper processes that must share localhost
  (e.g., a web server + a log collector sidecar). Grouping them in a Pod guarantees
  co-location and shared networking without full container merging. For most workloads,
  one container per Pod is the norm.
]

=== Scheduler

#def("Scheduler")[
  The #kw[scheduler] watches for newly created Pods that have no node assigned,
  and selects the *best node* to host each Pod.
]

Scheduling algorithm:
+ Filter all nodes down to *Feasible Nodes* by checking constraints
  (resource requests, node selectors, affinity/anti-affinity rules, taints/tolerations).
+ *Score* each feasible node by running a set of scoring functions.
+ #hl[Assign the Pod to the node with the highest score] (*binding*).
+ #hl[If no feasible node exists, the Pod remains *unschedulable*].
#v(-0.7em)
#note[
  #hl[*Labels* are key for scheduling]: they let targeting workloads to specific machine
  pools (e.g., GPU nodes, high-memory nodes) #hl[using node *affinity rules*].
]

=== Kubelet

#def("Kubelet")[
  The #kw[kubelet] is the primary *node agent* running on each worker node.
  It takes a set of PodSpecs provided through the API server and ensures that
  the containers described in those PodSpecs are running and healthy.
]
#v(-1em)
#note[
  The kubelet acts like a node-level Operator, but its state is local to the 
  worker node while the source of truth (etcd) resides on the Master plane.\
  Because state updates (Pod statuses) and heartbeats must travel over 
  the network to the API Server, network latency and overhead naturally create 
  windows of *temporary inconsistency* (stale state).\
  *Observability is key.*
]


=== Workload Resources

==== Deployment and ReplicaSet

#def("ReplicaSet")[
  A #kw[ReplicaSet] ensures that a *specified number of Pod replicas* are running
  at any time. If Pods die, the ReplicaSet creates replacements. If too many run,
  it deletes the excess.
]
#v(-1em)
#def("Deployment")[
  A #kw[Deployment] wraps a ReplicaSet and adds *rolling update* and *rollback*
  capabilities. It is the recommended way to manage stateless applications.
  A single Deployment can manage only a single type of Pod.
]

#hl[Deployments use a second ReplicaSet during rolling updates: the new ReplicaSet
scales up while] #hl[the old one scales down, ensuring zero downtime].

==== StatefulSet

#def("StatefulSet")[
  A #kw[StatefulSet] runs a group of Pods and maintains a *sticky identity* for each.
  Unlike Deployments, StatefulSets give each Pod:
  - A stable, *unique network identifier* (predictable DNS name).
  - Stable, *persistent storage* (each Pod's PVC is not destroyed on reschedule).
  - *Ordered, graceful deployment and scaling*.
  - *Ordered, automated rolling updates*.
]
#v(-0.7em)
StatefulSets are used for applications that require persistent storage or stable network
identity, such as databases, message brokers, distributed caches.

==== DaemonSet

#def("DaemonSet")[
  A #kw[DaemonSet] ensures that *all (or some) nodes run a copy of a Pod*.
  As nodes are added to the cluster, Pods are added to them; as nodes are removed,
  those Pods are garbage collected.
]
#v(-0.7em)
Typical uses:
- Running a *cluster storage daemon* on every node (e.g., Longhorn, Ceph).
- Running a *log collection daemon* on every node (e.g., Fluentd).
- Running a *node monitoring daemon* on every node (e.g., Prometheus Node Exporter).

==== Jobs and CronJobs

#def("Job")[
  A #kw[Job] creates one or more Pods and ensures that a *specified number of
  them successfully terminate*. Jobs are for finite, batch workloads.
]
#v(-1em)
#def("CronJob")[
  A #kw[CronJob] runs a Job on a repeating schedule (cron syntax).
]

== Storage

#def("Kubernetes Volume")[
  A #kw[volume] in Kubernetes is a *directory accessible to containers in a Pod*.
  It solves the problem of data sharing between containers in a Pod and data
  persistence across container restarts.
]

Two fundamental types:
- #hl[*Ephemeral volumes*: lifetime tied to the Pod]. When the Pod ceases to exist,
  Kubernetes destroys ephemeral volumes.
- #hl[*Persistent volumes*: exist beyond the lifetime of a Pod. Data is preserved]
  across container restarts, Pod replacements, and node failures.


#extra[
  Common volume uses:
- Populating configuration from a ConfigMap or Secret.
- Providing temporary scratch space for a Pod.
- Sharing a filesystem between two containers in the same Pod.
- Sharing a filesystem between two different Pods (even on different nodes, via
  distributed storage).
- Durably persisting data across Pod restarts/replacements.
]
#v(-0.7em)
#note[
  The declarative approach allows to claim a volume of a certain class
  without caring about the underlying implementation.
]

== Networking

=== The Kubernetes Network Model

#prop("Kubernetes Network Fundamentals")[
  - #hl[Every Pod gets its own *unique cluster-wide IP address*].
  - A Pod has its own *private network namespace* shared by all its containers:
    containers within a Pod communicate via `localhost`.
  - The *pod network* (cluster network) handles communication between Pods.
  - #hl[*All Pods can communicate with all other Pods* on any node, without NAT or
    proxies], whether they are on the same node or different nodes.
]
#v(-0.3em)
#extra[
  #why([*flat networking without NAT*])[
    NAT creates hidden address translations that complicate service discovery and
    debugging. A flat model where every Pod has a real, routable IP simplifies
    the programming model enormously: you can treat any Pod like a local process.
  ]
]

#figure(
  crop(
    image("../assets/k8s-network.webp",width: 70%),
    bottom: 25%, top: 10%
  ),
  caption: [Kubernetes network scheme.]
)

=== Kube-Proxy

#def("Kube-Proxy")[
  #kw[kube-proxy] is a *network proxy that runs on each node*.
  It reflects Services defined in the Kubernetes API and implements forwarding
  (via iptables, IPVS, or eBPF) so that traffic sent to a Service IP/port is
  correctly forwarded to one of the backend Pods.
]

=== CNI Plugins

The *Container Network Interface (CNI)* is a standard for how Kubernetes
communicates with the network plugin. Popular plugins:

- *Flannel*: simple overlay network using VXLAN tunnelling between nodes.
  Each node gets a subnet (e.g., `10.244.1.0/24`); Flannel tunnels
  inter-node Pod traffic through the underlay.
- *Canal*: extends Flannel with *Calico* network policy enforcement
  (BGP, IPIP, VXLAN, UDP options; policy enforcement via Calico).
- *Cilium*: modern approach using *eBPF* in the kernel, bypassing iptables
  entirely. Provides higher throughput, lower latency, and deep observability.
  #figure(
    image("../assets/eBPF-vs-Standard.jpg", width: 75%),
    caption: [eBPF vs. standard k8s.]
  )

=== Services

#def("Kubernetes Service")[
  A #kw[Service] is an *abstraction* that defines a logical set of Pods and a
  policy by which to access them. It provides a stable, long-lived *IP address*
  or *hostname* for a set of backend Pods that may come and go.
]
#v(-0.7em)
Kubernetes #underline[automatically] manages `EndpointSlice` objects to track the set of
Pods currently backing a Service. A service proxy implementation monitors these
objects and programs the data plane accordingly.
#v(-0.7em)
#note[
  A Service is *domain-specific deployment*: it decouples the consumer from the
  producer. Consumers address the Service, Kubernetes handles load balancing
  across the Pods.
]

#figure(
  crop(
    image("../assets/k8s-service.png", width: 55%),
    top:24%
  ),
  caption: [Service in kubernetes.]
)

=== Ingress

#def("Ingress")[
  An #kw[Ingress] exposes *HTTP/HTTPS routes from outside the cluster* to Services
  within the cluster. Traffic routing is controlled by rules defined on the
  Ingress resource (host-based and path-based routing).
]

- A #hl[cluster can host multiple Ingress implementations sharing the same interface].
- Each implementation has a custom *Ingress Controller* that manages the lifecycle
  of the ingress and translates rules into configuration for the underlying
  load balancer (NGINX, Traefik, HAProxy, cloud LBs...).
#v(-0.7em)
#analogy("Ingress as Hotel Reception")[
  An Ingress is like a hotel receptionist: external guests (clients) arrive at the
  hotel front door (Ingress). The receptionist inspects the guest's name or room
  number (hostname/path) and directs them to the correct floor and room (Service
  and Pod).
]
#v(-1em)
#figure(
  image("../assets/k8s-ingress.png", width: 65%),
  caption: [Ingress in kubernetes.]
)

== Load Balancing and Autoscaling

=== Horizontal Pod Autoscaler (HPA)

#def("Horizontal Pod Autoscaler")[
  The #kw[HPA] automatically updates a workload resource (Deployment, StatefulSet)
  by *scaling the number of Pod replicas* to match observed demand.\
  It is implemented as a Kubernetes API resource and a controller.
]

The HPA controller #hl[runs in the control plane] and periodically queries metrics.
It computes the desired replica count using:

$ "desiredReplicas" = ceil( "currentReplicas" times "currentMetricValue" / "desiredMetricValue" ) $

Configurable parameters:
- *Min/Max replicas*: hard bounds on the replica count.
- *Percent of replicas* that can be concurrently scaled up or down.
- *Stabilisation windows*: prevents flapping by requiring the metric to stay
  above/below a threshold for a configurable duration before scaling.

Observed metrics can be:
- Per-pod resource metrics (CPU, memory).
- Per-pod custom metrics.
- External metrics (e.g., queue depth from a message broker).

#figure(
  image("../assets/k8s-HPA.jpg",width: 70%),
  caption: [HPA.]
)

=== KEDA: Kubernetes Event-Driven Autoscaling

#def("KEDA")[
  #kw[KEDA] (Kubernetes Event-Driven Autoscaling) extends the HPA mechanism to
  support *event-driven scaling* based on the number of events needing to be
  processed. Key properties:
  - *Lightweight and flexible*: runs as a single deployment.
  - *Built-in scalers* for 50+ platforms (databases, cloud queues, messaging systems).
  - *Scale to zero*: can optionally reduce a workload to 0 replicas when idle.
]

#extra[
  Custom or third-party schedulers can also be deployed alongside the default
  scheduler if the default scoring functions are insufficient for your workload.
]

== Service Mesh <ch08-service-mesh>

=== What is a Service Mesh?

#def("Service Mesh")[
  A #kw[service mesh] is an *overlay infrastructure layer* that manages
  communication between microservices in a distributed application.\
  It simplifies complex service-to-service communication by providing
  managed and configurable:
  - *Traffic Management*
  - *Observability*
  - *Security*
  - *Dev/Ops* capabilities (fault injection, canary releases...)
]
#v(-0.3em)
#extra[
  #why([*a service mesh*])[
    In a modern microservice deployment with dozens or hundreds of services,
    each service needs to handle retries, timeouts, circuit breaking, mTLS,
    load balancing, and distributed tracing. Implementing this logic in every
    service is error-prone and creates duplication. A service mesh moves all
    of this to the *infrastructure layer*, keeping business logic clean.
  ]
]

#figure(
  image("../assets/service-mesh.webp", width: 60%),
  caption: [Service mesh.]
)

=== Service Mesh Architecture

A Service Mesh has two macro layers:

- #hl[*Data Plane*: realises secure, monitored, and reliable execution and communication.]
  The main component is the #hl[*Service Mesh Proxy* installed as a *sidecar*] in the same
  Pod as each hosted service. The sidecar acts as the unique point of access for all
  communication and implements monitoring and security strategies inside the Pod.
- *Control Plane*: a Kubernetes Controller that acts as registry for configuration of
  proxies: realises observability, traffic management, and security features.

#example("Istio")[
  In Istio, the control plane component is called *Istiod*. It provides:
  - *Traffic Management*: converts high-level routing rules into proxy-specific
    configuration and propagates them to the sidecars at runtime.
  - *Secure Communication*: acts as a Certificate Authority (CA) and generates
    certificates to allow secure *mTLS* communication in the data plane.
]

#figure(
  image("../assets/service-mesh-traffic.svg", width: 85%),
  caption: "Istio service mesh: Envoy sidecars in the data plane, Istiod in the control plane."
)

=== Traffic Management

Service Mesh manages network requests between services. Because traffic flows
through the *local sidecar proxy*, the mesh can implement at infrastructure level:

- *Request Routing*: path-based and header-based routing rules.
- *Load Balancing*: round-robin, least connections, consistent hashing.
- *Fault Mitigation*: retries, timeouts, circuit breaking.
- *Traffic Shifting*: canary releases (e.g., 5% to new version, 95% to stable).
- *Traffic Mirroring*: shadow traffic to test new versions without user impact.
- *Content-based traffic steering*: route by `User-Agent`, cookies, or request headers.
- *Locality-aware load balancing*.
- *Ingress/Egress abstractions*.
#v(-0.7em)
#note[
  #hl[Traffic splitting is *decoupled from infrastructure scaling*]: the proportion of
  traffic routed to a version is independent of the number of instances supporting
  that version.
]

#figure(
  image("../assets/traffic-mngmt.jpg"),
  caption: "Traffic management examples."
)

=== Observability

Service Mesh enables deep observability of the entire fleet:

- *Logs*: agents (proxies) installed in each Pod and node collect service and
  infrastructure logs.
- *Monitoring*: agents actively collect metrics on running services (request rate,
  latency, error rate).
- *Traces*: communication among services is tracked to generate dependency graphs,
  monitor performance, and find bottlenecks or root causes of failures.

=== Security

Service Mesh supports security at the infrastructure level:
- *Automatic Service Certificate Management*: get, verify, and renew certificates.
- *Authentication* and *Authorization*.
- *Secure Communication establishment* (mTLS between all services).
- *D-DOS protection* and *rate limiting*.

=== Dev/Ops Capabilities

- *Fault Injection*: deliberately inject failures to test resilience.
- *Circuit Breaking*: stop sending traffic to a failing service automatically.
- *Canary Release*: gradually shift traffic to a new version.
- *A/B Testing*.
- *Test Performance Collection*.
- *Connection Replication*.
- *Production/Test Environment Setup*.

=== Service Mesh at Meta (Case Study)

#extra[
  #example("Meta's Hyperscale Service Mesh")[
    Meta operates at hyperscale with hundreds of millions of concurrent requests and
    many distributed services across geo-distributed regions. They evaluated multiple
    L7 router implementations and chose different approaches depending on context:

    - *Sidecar-Proxy* load balancing (standard).
    - *Dedicated Load Balancers* (centralized).
    - *Lookaside Load Balancers*: a centralized lookup service that clients query.
    - *Embedded Routing Libraries*: routing logic compiled into the client itself.

    Their architecture relies on three components:
    - *RIB (Routing Information Base)*: a strongly consistent key-value store replicated
      across five geographic regions for high availability. Uses thousands of RAFT
      learner replicas to ensure read throughput and availability even when disconnected.
    - *RIBDaemon*: runs on each machine; maintains a `miniRIB` that caches only the
      service metadata needed by the RPCs on that machine.
    - *SRLib*: a language-specific library that acts as interface to other services,
      providing the same functionality as a sidecar proxy without a separate process.
  ]

  The key lesson from Meta's work: there is *no single best architecture* for a
  service mesh. The trade-off between sidecar, lookaside, dedicated, and embedded
  approaches depends on latency requirements, operational complexity, and the
  consistency vs. availability needs of the specific service.
]
