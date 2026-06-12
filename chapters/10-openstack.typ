#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= OPENSTACK
#extra[
  Package: OpenStack - `c - Openstack 26.pdf`
]

OpenStack is an open-source *cloud operating system* that pools physical hardware
resources into on-demand compute, storage, and network services exposed through
standardized APIs. It is the canonical example of an open-source *IaaS* platform,
and understanding its architecture reveals the fundamental design patterns behind
any large cloud infrastructure.

== Cloud Data Centres and IaaS

=== The Cloud Data Centre

A #kw[cloud data centre] is a large-scale facility, often federated with other
sites, that must simultaneously satisfy two contrasting requirements:

- *Real-time answering*: users must not wait; latency is a first-class metric.
- *Safety of data*: correctness and durability must not be sacrificed for speed.

In global deployments, data and computation are replicated across many
geographical locations to satisfy both goals.

=== NIST Cloud Reference Model

#def("NIST Cloud")[
  The #kw[NIST cloud model] defines a cloud by five essential characteristics,
  three service models, and two deployment models.
]

*Essential characteristics*:
- *On-demand self-service*: users provision resources without human interaction.
- *Broad network access*: resources are accessible over standard networks.
- *Resource pooling*: multi-tenant sharing of physical resources.
- *Rapid elasticity*: capacity appears unlimited and scales instantly.
- *Measured service*: usage is metered and billed.

*Service models*:
- *SaaS*: Software as a Service (application layer).
- *PaaS*: Platform as a Service (runtime/middleware layer).
- *IaaS*: Infrastructure as a Service (virtual machines, storage, networking).

*Deployment models*: Public cloud, Private cloud, Hybrid cloud.

=== Cloud Resource Virtualization

Building a cloud requires virtualizing resources in two successive steps:

*Step 1 - Server virtualization*: hypervisors (VMware ESX, KVM, Xen) partition
a physical host into multiple #kw[virtual machines] (VMs/instances), providing a
hardware-abstraction layer and dramatically improving resource utilization.

*Step 2 - Network and storage virtualization*: once servers are virtualized, the
network and storage are also pooled:

- *Compute pool*: virtualized servers.
- *Network pool*: virtualized networks.
- *Storage pool*: virtualized storage.

The result is a unified resource pool that offers flexibility and efficiency for
many simultaneous applications.

#analogy("Cloud as a Utility")[
  Just as the electrical grid abstracts the physical generators from the consumer,
  cloud resource virtualization abstracts physical hardware from application
  developers. Plugging in does not require knowing which power plant you are
  connected to.
]

== OpenStack Overview

=== History and Positioning

#def("OpenStack")[
  #kw[OpenStack] is an open-source *cloud operating system* (IaaS platform)
  founded by NASA and Rackspace in 2010, now maintained by a consortium of
  300+ companies. It is distributed under the Apache 2.0 licence with a
  six-month release cycle.
]

Key positioning facts:
- Open-source alternative to Amazon AWS, Microsoft Azure, VMware.
- Supports multiple hypervisors: KVM, Xen, XenServer, Hyper-V.
- Exposes Amazon-compatible and Rackspace-compatible APIs.
- Designed for both public and private cloud deployments.

=== High-Level Architecture

OpenStack is a *cloud operating system* that sits between applications and
physical hardware:

- *Upward*: it exposes RESTful APIs consumed by applications, admins, and users.
- *Downward*: it creates resource pools from physical servers and automates the
  network.
- *Internally*: it acts as a control plane: scheduling, orchestration, image
  management, identity, and metering.

=== Logical Layers

A cloud must handle three planes:

- *Resources*: raw compute (VMs), block volumes, and network.
- *Logic/Control*: orchestration, scheduling, policy, image registry, logging.
- *Presentation*: APIs for developers and operators, user dashboard, customer portal.

Cross-cutting concerns:
- *Integration*: billing and identity services.
- *Management*: monitoring and admin APIs.

In OpenStack these map directly to named services (see next section).

=== Design Guidelines

All OpenStack services share a common architectural philosophy:

#prop("OpenStack Design Principles")[
  - *Horizontal scalability*: scale out by adding nodes, not scaling up.
  - *Minimal dependencies*: services are designed to be loosely coupled; each replicates its core components to avoid single points of failure.
  - *Shared-nothing*: each service stores all needed information internally; no global shared state between services.
  - *Asynchronous, pub/sub communication*: services communicate through a message queue (AMQP/RabbitMQ) rather than synchronous RPC, making the system resilient and decoupled.
]
#v(-1em)
#why("Why asynchronous messaging?")[
  In a cloud, a single user request may trigger actions across many services (compute,
  networking, storage, image). If each call were synchronous, one slow service would
  block the entire chain. Message queues decouple the sender from the receiver:
  requests are queued and processed when the service is ready, improving resilience
  and enabling horizontal scaling of any individual service.
]

=== Common Service Architecture

Every OpenStack service is built from the same four internal building blocks:

- *pub/sub messaging service*: AMQP-based (RabbitMQ by default, Qpid supported).
- *One or more core components*: the actual service logic.
- *RESTful API component*: the external face of the service, interoperable with clients.
- *Local database component*: stores internal service state (MySQL, MongoDB, SQLAlchemy, HBase depending on requirements).

== OpenStack Core Services

#def("OpenStack Main Services")[
  The seven canonical OpenStack services are:
  - *Horizon*: Dashboard (web UI)
  - *Keystone*: Identity and authentication
  - *Nova*: Compute (VM lifecycle)
  - *Neutron* (formerly Quantum): Networking
  - *Glance*: Image service
  - *Swift*: Object storage
  - *Cinder*: Block storage

  Additional services: *Ceilometer* (telemetry/metering), *Heat* (orchestration).
]

All services communicate through Keystone for authentication and through the
message queue for internal coordination. The Dashboard (Horizon) provides a
unified graphical interface across all services.

#figure(
  image("../assets/openstack-architecture.svg", width: 95%),
  caption: "OpenStack core services: Horizon on top, Keystone and RabbitMQ as cross-cutting infrastructure, and the five resource services above the physical hardware layer."
)

== Nova - Compute Service

=== What Nova Does

#def("Nova")[
  #kw[Nova] is OpenStack's compute service. It provisions and manages large
  pools of virtual machine instances across a cluster of hypervisor nodes.
]

- Provides *on-demand virtual servers* (instances).
- Manages large networks of VMs.
- Designed to *horizontally scale* on standard commodity hardware.
- Supports multiple hypervisors: KVM, XenServer, VMware, Hyper-V.
- Exposes compute resources via *REST APIs*, web interface, and CLI.

=== Nova Internal Components

Nova is itself a distributed system, with dedicated daemons for each function:

- *nova-api*: RESTful API gateway (supports OpenStack, EC2, and admin APIs). All client commands arrive here.
- *nova-compute*: runs on every hypervisor node; communicates with the underlying hypervisor (libvirt, XenAPI, etc.) to start/stop/manage VM instances.
- *nova-scheduler*: coordinates all services and determines *placement* of new VM requests: which physical host gets the new VM.
- *nova-conductor*: mediates database access from nova-compute to avoid direct DB connections from untrusted compute nodes.
- *nova database*: stores build-time and run-time state of the cloud infrastructure (typically MySQL).
- *Queue (RabbitMQ)*: the message bus that connects all Nova services. Requests are enqueued, enabling async processing and decoupling.
- *nova-console / nova-novncproxy / nova-consoleauth*: provide proxied console access to VM instances.

#note[
  `nova-network` (network configuration) and `nova-volume` (persistent storage)
  are legacy components. Their responsibilities have been moved to *Neutron* and
  *Cinder* respectively in modern deployments.
]

=== Nova General Interaction Pattern

The request flow for any Nova operation follows this pattern:

+ Client sends a request to *Nova API*.
+ Nova API validates credentials with *Keystone* and writes initial state to *MySQL*.
+ Nova API forwards the request to *Nova Scheduler* via *RabbitMQ*.
+ Nova Scheduler confirms resource availability and selects a host; publishes back.
+ The target *Nova Service* (nova-compute) polls RabbitMQ, receives the message, and executes the action.
+ Both Scheduler and Service update *MySQL* with the final state.

#analogy("Nova as a Dispatcher")[
  Nova behaves like a taxi dispatch center: the API is the phone line (receives
  requests), the scheduler is the dispatcher (decides which driver handles the job),
  and nova-compute nodes are the individual drivers. RabbitMQ is the radio network
  connecting dispatch to drivers.
]

=== VM Provisioning Workflow (Multi-Service)

Launching a VM involves coordinating Nova, Keystone, Glance, and Swift:

+ Client asks Nova API to launch a VM.
+ Nova API authenticates with *Keystone*.
+ Nova Scheduler picks a compute host and schedules the VM.
+ Nova API requests the *boot image* from *Glance API*.
+ Glance Registry looks up image metadata; Glance API fetches the actual image from *Swift*.
+ Nova Compute receives the image and starts the VM on the hypervisor.

This end-to-end flow illustrates how every service relies on Keystone for auth
and how image delivery flows through Glance/Swift.

== Swift - Object Storage

=== What Swift Does

#def("Swift")[
  #kw[Swift] is OpenStack's *distributed object storage* service. It stores and
  retrieves unstructured data objects (files, images, backups, archives) via
  HTTP/REST, without requiring a traditional filesystem hierarchy.
]
#v(-1em)
#important("Swift is not a filesystem")[
  Swift is not a POSIX filesystem or a block device. It stores *objects* (arbitrary
  byte sequences + metadata) identified by a hierarchical name
  (account / container / object). Mutations create new objects rather than
  modifying existing ones; this is what enables concurrent reads and efficient
  replication (only changed chunks need to be transferred).
]

- Provides *scalability, redundancy, and durability* through replication.
- No central point of control, inherently distributed.
- Stores static data: VM images, photo storage, email storage, backups.
- Accessed via APIs or integrated directly inside applications.

=== Object Storage Data Model

Objects in Swift are organized in a three-level hierarchy:

- *Account*: top-level namespace (like a user or project).
- *Container*: a named bucket within an account (like a directory, but flat).
- *Object*: the actual data blob + metadata (name, size, content-type, custom headers).

When an object changes, its metadata is updated and only the changed chunks need
to be replicated, making replication efficient.

=== Swift Components

- *swift-proxy*: the entry point; handles all incoming requests (uploads, metadata modifications, container creation) and routes them internally.
- *Account server*: manages account-level metadata defined through the storage service.
- *Container server*: maps containers (buckets) within the object storage service.
- *Object server*: manages the actual file data on storage nodes.

The proxy is the only publicly exposed component; the storage servers form
an internal ring accessed only through the proxy.

== Cinder - Block Storage

=== What Cinder Does

#def("Cinder")[
  #kw[Cinder] is OpenStack's *block storage* service. It manages persistent
  storage volumes that can be attached to VM instances, analogous to a cloud
  version of a SAN or network-attached disk.
]
#v(-1em)
#analogy("Cinder as a USB drive")[
  A Cinder volume is like a USB drive in the cloud: it can be formatted and
  mounted into a running VM, and later detached and re-attached to a different VM.
  The data persists independently of the VM lifecycle.
]

- Creates, attaches, and detaches *volumes* to/from VM instances.
- Supports protocols: iSCSI, NFS, FC, RBD (Ceph), GlusterFS.
- Supports backends: Ceph, NetApp, Nexenta, SolidFire, Zadara, and more.
- Allows creating *snapshots* of volumes for backup or cloning.

=== Cinder Components

- *cinder-api*: accepts user requests and dispatches them to cinder-volume.
- *cinder-volume*: executes read/write operations; interacts with the database and message queue to maintain consistency.
- *cinder-scheduler*: selects the best storage backend/node to create a new volume.
- *cinder database*: maintains the state of all volumes (available, in-use, error, etc.).

== Glance - Image Service

=== What Glance Does

#def("Glance")[
  #kw[Glance] is OpenStack's *image service*. It handles discovery, registration,
  and delivery of disk images and virtual server snapshots.
]

- Allows storing images on *different storage backends* (filesystem, Swift, Amazon S3, HTTP).
- Supports multiple disk formats: Raw, qcow2, VMDK, VHD, ISO, etc.
- Images are typically stored in *Swift*; Glance acts as a metadata catalog and
  API layer on top of the actual storage.

=== Glance Components

- *glance-api*: handles API requests to discover, store, and retrieve images.
- *glance-registry*: stores, processes, and retrieves image *metadata* (dimensions, format, owner, etc.).
- *glance database*: the metadata store.

#note[
  Glance itself does not store image bits; it delegates that to an external
  repository (Swift, S3, filesystem). It is a metadata registry + delivery proxy.
]

== Horizon - Dashboard

#def("Horizon")[
  #kw[Horizon] is OpenStack's *web-based dashboard*. It provides a modular,
  graphical interface for administrators and users to access and manage all
  other OpenStack services.
]

Actions available through Horizon:
- Launch and terminate instances.
- Assign floating IP addresses.
- Upload VM images.
- Define security groups and access policies.
- Manage volumes, networks, and object storage.

Horizon is purely a *presentation layer*: it calls the same REST APIs that any
other client would use. It adds no new functionality but greatly lowers the
barrier to using OpenStack.

== Keystone - Identity Service

=== What Keystone Does

#def("Keystone")[
  #kw[Keystone] is OpenStack's *identity service*. It provides centralized
  *authentication* and *authorization* for every other OpenStack service.
]

- Creates *users*, *groups* (also called *tenants/projects*).
- Manages *permissions* and role-based access control (RBAC).
- Issues *tokens* that replace password authentication after initial login.
- Maintains an *endpoint catalog* so services can discover each other's URLs.

=== Keystone's Four Sub-Services

- *Identity*: user information and authentication.
- *Token*: after login, replaces the password with a time-limited token for subsequent API calls.
- *Catalog*: endpoint registry: maps service type (compute, image, etc.) to URLs.
- *Policy*: rule-based authorization engine.

=== Keystone Request Flow

+ Client sends a request with credentials to Keystone.
+ Keystone authenticates and returns a *token* (+ tenant/role information).
+ Client forwards the token with its request to the target OpenStack service.
+ The target service *validates the token with Keystone* before processing the request.
+ Unauthorized requests are rejected at step 2 or step 4.

#important("Keystone is the security perimeter")[
  Every OpenStack service call must carry a valid Keystone token. Keystone is
  therefore the single, centralized trust anchor for the entire cloud. If Keystone
  is unavailable, no authenticated operation in the cloud can proceed.
]

== Neutron - Networking Service

=== What Neutron Does

#def("Neutron")[
  #kw[Neutron] is OpenStack's *networking service* (formerly called Quantum).
  It provides *Network as a Service (NaaS)*: pluggable, scalable, API-driven
  management of networks and IP addresses.
]

Key properties:
- *Multi-tenancy*: full isolation and abstraction per tenant; each tenant has its own virtual networks.
- *Technology-agnostic*: APIs define the *service*, vendor plug-ins provide the *implementation*. Vendor-specific extensions are supported.
- *Loose coupling*: Neutron is a standalone service, not exclusive to OpenStack.

=== Logical vs. Physical View

#prop("Neutron Abstraction")[
  Neutron *decouples* the logical view of the network from the physical view.
  Tenants see isolated virtual networks; the physical data-centre network is
  hidden behind the abstraction.
]

*Logical concepts*:
- *Network*: an isolated virtual Layer-2 domain (logical switch).
- *Subnet*: an IPv4 or IPv6 address block assignable to VMs or routers.
- *Port*: a logical switch port; defines the MAC and IP addresses of a virtual interface (VIF).

=== Neutron Components

- *neutron-server*: accepts API requests and forwards them to the appropriate plugin.
- *Plugins and Agents*: perform real actions: connecting/disconnecting ports, creating networks and subnets, managing routing rules (iptables, Open vSwitch, etc.).
- *Message queue*: decouples neutron-server from the agents running on hypervisor nodes.
- *neutron database*: persists network state for plugins that require it.

=== Neutron Agents

- *DHCP agent*: provides DHCP services to virtual networks.
- *Plugin agent*: runs on each compute node and performs local vSwitch configuration (OpenVSwitch, Cisco, Brocade, etc.).
- *L3 agent*: provides L3/NAT forwarding for external network access.

#note[
  OpenStack created *OpenFlow* support so VMs can send packets to each other
  without double IP/MAC translation. This avoids the performance overhead of
  NAT traversal and enables near-native packet forwarding rates.
]

=== Tenant Networks

Tenant networks are isolated, user-created networks. Neutron supports several
types:

- *Flat*: all instances on one shared network; no VLAN tagging.
- *Local*: instances confined to a single compute node; fully isolated from external networks.
- *VLAN*: each tenant network maps to an 802.1Q VLAN ID in the physical network. Requires 802.1Q-capable switches; supports up to 4096 tenant networks.
- *VXLAN / GRE*: overlay tunnels that carry tenant traffic over the physical network. Allow many more isolated networks than VLAN (no 4096 limit) and avoid reconfiguring physical switches.

#why("Why VXLAN over VLAN for large clouds?")[
  VLAN is limited to 4096 IDs. A large public cloud may have thousands of tenants
  each needing multiple isolated networks. VXLAN uses a 24-bit segment ID (16 million
  possible networks) and encapsulates traffic in UDP, allowing tenant isolation to
  be implemented entirely in software without modifying the physical switching fabric.
]

A *Neutron router* is required to route traffic between tenant networks or to
reach external networks (including the Internet).

== Ceilometer and Heat

=== Ceilometer - Telemetry

#def("Ceilometer")[
  #kw[Ceilometer] is OpenStack's *telemetry service*. It collects usage statistics
  from all other OpenStack services for metering, monitoring, and billing.
]

Ceilometer integrates with every core service (compute, network, storage, image)
through the message bus, collecting counters without modifying those services.
The data drives both operational monitoring and customer billing.

=== Heat - Orchestration

#def("Heat")[
  #kw[Heat] is OpenStack's *orchestration service*. It allows defining an entire
  cloud application stack: compute, networking, storage, and their inter-dependencies,
  in a single declarative template.
]

Heat templates describe *stacks*: collections of OpenStack resources that are
created, updated, and deleted as a single unit. Heat integrates with all other
services and provides a CloudFormation-compatible API, easing migration from AWS.

== Putting It All Together

The full OpenStack architecture has multiple layers of interaction:

- *Command-line interfaces* (nova, swift, neutron, ...) and *GUI tools* (Dashboard, Cyberbook, iPhone client) speak to the same REST APIs.
- *Cloud management tools* (Rightscale, Enstratius) sit above the APIs.
- Each service cluster (Identity, Compute, Image, Block Storage, Networking, Object Storage) is internally composed of API frontends, schedulers, workers, databases, and message queues, all following the same shared-nothing, async-messaging pattern.
- *Keystone* (Identity API) is the backbone: every inter-service call traverses it for authorization.

#important("OpenStack as a Cloud OS")[
  OpenStack is best understood as an *operating system for the data centre*:
  just as an OS abstracts hardware resources from applications, OpenStack abstracts
  physical servers, switches, and disks from cloud tenants: scheduling, isolating,
  and metering their usage through a unified set of open APIs.
]
