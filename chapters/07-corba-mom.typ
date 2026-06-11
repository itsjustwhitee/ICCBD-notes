#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= CORBA, ADVANCED C/S MODELS, EVENTS AND MOM

#extra[
  Package: CORBA CS and Events and MOM — `6  - CORBA CS and Events and MOM 26.pdf`
]

This chapter deepens the distributed middleware model by examining *CORBA* (an industrial-strength DOC middleware), *advanced C/S interaction patterns*, *event-based systems*, *publish-subscribe*, the *tuple model*, *MOM* (Message Oriented Middleware) and concrete tools like *Kafka* and *MQTT*, ending with *group communication and multicast routing*.

// ─────────────────────────────────────────────────────────────
// PART 1: CORBA
// ─────────────────────────────────────────────────────────────

== CORBA

#def("CORBA — Common Object Request Broker Architecture")[
  #kw[CORBA] is an OMG standard for *Distributed Object Computing (DOC)*: it provides an *Object Request Broker (ORB)* that mediates invocations between distributed objects written in different languages, running on different OS and hardware, without the client knowing the location or implementation of the server object.
]

#prop("Core CORBA Concepts")[
  - *Object*: any CORBA entity with a defined interface. Has a remote reference — an *IOR* (Interoperable Object Reference) — that uniquely identifies it globally.
  - *Servant*: the concrete language implementation of a CORBA object (e.g., a Java class). Created by the language environment, *not by CORBA itself*.
  - *Interface*: declared in IDL. Defines the contract — attributes, methods, exceptions.
  - *ORB*: the middleware bus. Routes requests from clients to the correct servant, transparently.
  - *POA* (Portable Object Adapter): on the server side, maps incoming requests to the correct servant instance.
]

#analogy("CORBA as an Object Phone Network")[
  Think of objects scattered across many machines as people in different cities with different languages. CORBA is the telephone operator: you give it a reference (phone number) and it routes your call to the right person, translating protocols and formats along the way. You never need to know where the person is or what language they speak internally.
]

=== ORB — Object Request Broker

The ORB is the central infrastructure piece. It does *not* create or move objects — it connects them.

#prop("ORB Functions")[
  - *Fully object interaction enabler*: proposes a default blocking synchronous interaction (but this can be changed).
  - *Limits its interaction responsibility* by delegating individual language environments to handle final execution.
  - *Not responsible for object creation and moving* — CORBA uses external remote references created by each language environment. Servants must define their service objects.
  - *Obtains remote references* via:
    - Conversion of *string references* and vice versa (_stringification_).
    - Use of an *objects directory* via name services (Trading and Naming services).
    - *Passing of reference parameters* to Servants or Clients.
]

#note[
  The ORB is a *bus*, not a server — it never holds objects. Remote references (IORs) point to servants on specific machines; the ORB simply routes the invocation there.
]

The communication flow is: Client #arrow *Stub* #arrow ORB #arrow network #arrow ORB #arrow *Skeleton* #arrow Servant. The stub and skeleton are generated automatically by the IDL compiler.

=== CORBA IDL

#def("IDL — Interface Definition Language")[
  #kw[CORBA IDL] is a purely *declarative, object-oriented language* (derived from C++) used to specify *data and method interfaces*, completely independently of any specific programming language.
]

#prop("IDL Capabilities")[
  - *Interface definition* (with multiple inheritance)
  - *Attribute* definition (accessed via auto-generated `_get` / `_set` operations)
  - *Exception* definition (with `completion_status`: `COMPLETED_YES`, `COMPLETED_NO`, `COMPLETED_MAYBE`)
  - Automatic management of *attributes mapping* across languages
  - *Module grouping* of interfaces (for logical aggregation)
]

#extra[
  Many other IDL-like languages exist (OSI ASN.1 / GMDO, ONC XDR for Sun RPC, Microsoft IDL) but they are *not compatible* with CORBA IDL — even syntax and naming differ. CORBA IDL is the only object-oriented one derived from C++.

  The *IDL compiler* generates stubs and skeletons automatically for different language targets.
]

#example("IDL: Stock Example")[
  ```idl
  module Stock {
    exception Invalid_Stock {};
    exception Invalid_Index {};
    const long length = 100;

    interface Quoter {
      attribute float quote;
      readonly attribute float quotation;
      long get_quote(in string stock_name) raises (Invalid_Stock);
    };

    interface SpecialQuoter: Quoter {
      attribute float quotehistory[length];
      readonly int index[length];
      long get_next(in string stock_name) raises (Invalid_Index);
      long get_first(in string stock_name) raises (Invalid_Index);
    };

    interface CancelQuoter: SpecialQuoter {
      long cancelhistory(out float cancelledquote[length]);
    };
  }
  ```
]

#example("IDL: BankAccount Example")[
  ```idl
  module BankAccount {
    struct transaction { string data; float amount; };
    exception RossoException { string message; };
    typedef sequence <actions> list_ops;

    interface Account {
      float balance(in string cc);
      list_ops bankStatement(in string cc);
      void withdrawal(in string cc, in float balance,
                      out float balance) raises(RossoException);
      Account accountTwin(); // returns an object (the interface itself)
    };
  }
  ```
  Objects are *returned by reference* (the interface), not by value. Parameters use `in`, `out`, and `in out` modes.
]

=== Data Types in CORBA IDL

#prop("Type System")[
  - *Object references*: references to CORBA objects or interfaces — passed by reference.
  - *Exceptions*: not values but signaled conditions.
  - *Basic values*: short, long, ushort, ulong, float, double, char, string, boolean, octet, enum, `Any`.
  - *Constructed values*: Struct, Sequence, Union, Array.
  - *`Any`*: a generic type that can hold any primitive or any CORBA interface — analyzable at runtime (used to dynamically carry the current type).
]

#important("Object by Value (CORBA 3)")[
  Objects passed *by value* (`valuetype`) are copied from one environment to another — they *cannot* be accessed remotely. Used to overcome heterogeneity when no remote reference is possible. This is the only case where objects cross the wire as data.
]

=== Language Mapping

CORBA defines interfaces but code must run in concrete languages. *Language mapping* is the process of translating IDL constructs into specific programming language constructs.

#prop("Language Mapping Responsibilities")[
  - *Strategy for consistency* of concrete language types with the CORBA model.
  - *Transformation functions* to manage types automatically — putting structures together simply.
  - Additional support functions: *naming, trading, suggested development methodologies*.
  - Each language provides a *Helper* and a *Holder* utility class.
]

#def("Holder (Java)")[
  In Java, `out` and `in out` parameters cannot be passed directly (Java is pass-by-value for primitives). A #kw[Holder] is a *container object* whose internal value changes but whose identity remains fixed. After the invocation, the holder contains the result.

  ```java
  public final class BalanceHolder {
    public float value;
    public BalanceHolder() {}
    public float _read() { return value; }
    public void _write(float value) { this.value = value; }
  }
  ```
]

#def("Helper (Java)")[
  A #kw[Helper] maps between the CORBA `Object` type (`org.omg.CORBA.Object`) and the specific concrete type. Functions include:
  - *Narrowing*: casting from a generic CORBA Object to the specific interface type.
  - *Reading and writing* a type on an object stream — treating type dynamically.
  Every language must guarantee interoperability with CORBA through such helpers.
]

#note[
  The *cost of CORBA is very high* — both in terms of developer learning curve and runtime performance overhead. This is a core limitation acknowledged even by its proponents. Despite this, it was widely used (Orbix/IONA, Visibroker/Borland, JacORB as open source).
]

// ─────────────────────────────────────────────────────────────
// PART 2: ADVANCED C/S MODELS
// ─────────────────────────────────────────────────────────────

== Advanced Client/Server Interaction Models

The classic C/S model is *synchronous blocking* — the client sends a request and waits. This is too rigid for real distributed applications.

#prop("Novel C/S Variants")[
  - *Pull* (synchronous non-blocking): the client gets the result afterwards, without waiting for it immediately.
  - *Push* (synchronous non-blocking): the server gives the result to the client afterwards — the client does not wait for it.
  - *Delegation*: a delegate waits for the result on behalf of the client (synchronous non-blocking for the client). The delegate holds the result and notifies.
  - *Notification*: for the result — the delegate notifies the client when a result arrives.
  - *Events* (typically asynchronous, non-blocking): an event is generated by a producer and advertised to consumers.
  - *Provisioning*: other parties can be interested in the call chain, apart from the direct C/S pair.
]

=== Delegation Patterns

In a synchronous non-blocking model, an intermediate entity handles result delivery:

#def("Poll Object")[
  A #kw[Poll Object] is an intermediate entity the client periodically queries. Used for *short operations* with bounded response time.
  Flow: Sender #arrow Request #arrow Receiver; Sender polls Poll Object; Poll Object returns response.
]

#def("Call-Back Object")[
  A #kw[Call-Back Object] is an intermediate entity that is *notified by the server* when the result is ready and then invokes the client-specified callback. Allows even *long operations independent of client life cycle*.
  The code to handle the response is executed when the response arrives.
]

#analogy("Call-Back as a Concierge")[
  You order food delivery (request to server). Instead of waiting at the door, you give the concierge (call-back object) instructions: "When the delivery arrives, bring it to my table." You go about your business. The concierge calls you (executes callback) when ready.
]

// ─────────────────────────────────────────────────────────────
// PART 3: MESSAGE EXCHANGE
// ─────────────────────────────────────────────────────────────

== Message Exchange

#def("Message Exchange")[
  #kw[Message exchange] is a flexible but primitive communication model. Sometimes messages carry *only synchronization signals* (no data) — the message itself is the trigger.
]

#prop("Message Exchange Properties")[
  - *Synchronous / non-synchronous*: does the sender receive a reply?
  - *Symmetric / asymmetric*: does both sides know each other?
  - *Direct / indirect*: is there an intermediate entity?
  - *Blocking / non-blocking*: is the sender blocked during transmission?
  - *Buffered / unbuffered*: are messages queued?
  - *Reliable / unreliable*: with or without message loss guarantee?
  - Models with *multiple receivers*: group messages (multicast, MX) and broadcast (BX).
]

=== Modes of Message Exchange

#prop("Three Communication Modes")[
  - *Rendez-vous*: one-to-one, synchronous, blocking, symmetric, unbuffered, *coupled* (more constrained than C/S). Both parties must be present.
  - *With one intermediate entity* (channel, socket, queue): typically asynchronous, non-blocking, asymmetric, *buffered, decoupled*. This is MOM.
  - *With intermediate entity and group of receivers* (events): typically asynchronous, non-blocking, asymmetric, decoupled and *many-to-many*.
]

=== Coupling and Decoupling

#def("Coupling")[
  #kw[Coupling] constraints imposed by communication tools can limit flexibility in three dimensions:
  - *Space*: interacting entities must know each other and be co-located.
  - *Time*: interacting entities must be present at the same time.
  - *Synchronization*: interacting entities must wait for each other.
]

#important("Why Decoupling Matters")[
  *Decoupling* enables greater flexibility and leverages the potential distribution of load. The less coupled the components, the easier it is to scale, replace, and evolve them independently.
  MOM systems decouple in all three dimensions simultaneously.
]

// ─────────────────────────────────────────────────────────────
// PART 4: EVENTS AND PUBLISH-SUBSCRIBE
// ─────────────────────────────────────────────────────────────

== Events and Publish-Subscribe

=== From Local to Distributed Events

*Local events* (e.g., Windows GUI events) already reverse control: the user process registers a handler and the framework calls it back when the event occurs. Responses from the framework are called *backcall* or *upcall*.

*Distributed event systems* go further — designed *without any locality constraints* (no coupling). Their strength is the *non-locality* of interacting entities.

#important("Key Design Principle")[
  Constraining events to co-residence (same node, producer and consumer on the same machine) contradicts the event model's purpose. That is one of the worst misuses of the technology.
]

#prop("Event System Design Indicators")[
  - *Cost* in distributing events: to limit.
  - *Performance*: to optimize.
  - *Scalability*: to keep high.
  - *Latency*: to limit in time.
  - *Pervasivity* of provided services: high.
  - *Independent development* and *execution*: high.
  - *Fault tolerance*: maximal possible.
  Implementing event systems grants *viability*: all indicators keep acceptable (possibly constant) values as the system scales.
]

=== Evolution of Events

| Generation | Properties |
|---|---|
| *Primitive events* | On/off signals, no content — interrupt events and low-level signals |
| *Events with contents* | Some events carry information and filters based on interest about specific information (e.g., RSS feeds) |
| *Events with QoS* | Differentiated service for different users; persistent events; event priority |

*Persistent events*: users not online do not lose any event — delivered as soon as they reconnect.

=== Publish-Subscribe

#def("Publish-Subscribe")[
  In a #kw[publish-subscribe] system, *producers* generate events freely (publish/PUB) without worrying about delivery. *Consumers* register their interest (subscribe/SUB) in specific events, topics, or types. The *event support infrastructure* handles delivery.
  Producers and consumers are *not required to be present at the same time*.
]

#prop("Message Filtering in PUB-SUB")[
  - *Topic-based*: based on a predefined topic/channel (e.g., RSS on a specific feed).
  - *Content-based*: based on message contents (keywords or more complex relationships).
  - *Type-based*: based on message type.
  - *QoS*: persistency, priority, guaranteed maintenance and duration.
]

#prop("PUB-SUB Operations")[
  - *Producers* (also called publishers) provide events. They may declare intent via `publishIntent`.
  - *Consumers* (subscribers) first `subscribe`, then receive `notify` callbacks.
  - The infrastructure holds: storage and management of subscriptions, notify/subscribe/unsubscribe/notify operations.
  - 2 management operations + 2 content operations #arrow symmetric model.
]

// ─────────────────────────────────────────────────────────────
// PART 5: TUPLE MODEL (LINDA)
// ─────────────────────────────────────────────────────────────

== Tuple Model — Linda (Gelernter)

#def("Tuple Space")[
  A #kw[tuple space] is a *shared memory abstraction* combined with communication. It is a set of structured relationships organized as a *container for attributes and values*. Tuples can be *deposited* (Out) or *extracted* (In) as high-level information without any interference or incorrectness.
  No duplication is allowed in the space.
]

A possible relationship format: `message(from, to, body)`.

#prop("Linda Operations")[
  - *`Out`*: inserts one tuple into the space. The `Out` operation *emits a tuple* on the space available for a match with an `In` request. The tuple stays until consumed.
  - *`In`*: extracts *one matching tuple* from the space. Waits if no match exists. The match is based on pattern on attribute values.
  - If multiple tuples match an `In` request, only one is *non-deterministically extracted* (not FAIR / not FIFO) — the implementation chooses to optimize cost.
]

#important("Non-Determinism")[
  The Linda model explicitly leaves the *implementation strategy free* in choosing which tuple to extract from multiple matches. This freedom allows the system to optimize for cost, locality, or load — at the price of not guaranteeing order.
]

#prop("Decoupling in Tuple Spaces")[
  - *In space*: consumers do not know producers. Only tuple contents matter — zero knowledge of other party.
  - *In time*: a producer deposits and leaves; the consumer arrives later and retrieves. No co-presence required.
  - *In quality (QoS)*: tuple spaces are *persistent* — tuples are safely deposited without limit (in memory and time). No preference for any specific process.
  Tuple spaces are available with *high-level operations* (closures, in-transaction semantics, partition replication) to support well-formed local communication.
]

#analogy("Tuple Space as a Corkboard")[
  Imagine a physical corkboard in an office. Anyone can pin notes (Out). Anyone can take a note matching their need (In). You don't need to be there when it was pinned, you don't need to know who pinned it — the corkboard is the mediator.
]

// ─────────────────────────────────────────────────────────────
// PART 6: MOM MIDDLEWARE
// ─────────────────────────────────────────────────────────────

== MOM — Message Oriented Middleware

#def("MOM")[
  #kw[Message Oriented Middleware (MOM)] organizes data communication and distribution via *message exchange* between logically separated entities, using point-to-point or group messages. It provides typed and untyped, asynchronous and synchronous message exchange with *wide autonomy* between components, *persistence*, and *broker* support for different strategies and QoS.
]

Examples: MQSeries IBM, MSMQ Microsoft, JMS Sun, OMG DDS, MQTT, RabbitMQ, Active MQ, Apache Kafka, ZeroMQ, NATS.

#important("MOM's Role")[
  MOM is a *Disappearing / Glue / Thin service layer*: it keeps together different autonomous systems and organizes their specific interconnection in a *static way*. The MOM can plan better support for communications because the configuration can be known a priori: optimize support costs to the specified need.
]

=== MOM Deployment

The specific deployment and *interconnection graph (routing) is always static* (no name services needed).

#prop("MOM Defines a Network Overlay")[
  - *Necessity of high-level Routing* (as in ONs, but static).
  - *Data treatment* while communicating between different environments.
  - *Predefined and static participating entities*.
]

#prop("Two Extreme Deployment Models")[
  - *Centralized model*: MOM with a central node as *hub* (hub-and-spoke) responsible for supporting and passing messages between different clients. Typically replicated for availability.
  - *Distributed model*: MOM located on any client node forming a static overlay network, operating through *P2P communication* between nodes.
]

=== MOM Infrastructure Components

#prop("MOM Building Blocks")[
  - *Queue managers*: guarantee the expected operation level and message forwarding. Applications interact via API RPC to put/extract messages from local queues.
  - *Inbound and outbound queues*: on interested machines, connected univocally.
  - *Routing system*: connects different queues (as overlay networks do for application-level routing).
  - *Relay*: intermediate entities that allow the implementation to scale and organize high-level routing for scalability.
  - *Message Broker*: entity able to support message content transfer between environments with *different representations* — can modify formats, organize routing based on contained information, work on application data to specify action sequences.
]

#analogy("MOM as a Postal Service")[
  You drop a letter (message) in a mailbox (local queue). The postal service (MOM) picks it up, routes it through sorting centers (relays), possibly translates the address format for international delivery (broker), and delivers to the recipient's mailbox. Neither sender nor recipient need to be present simultaneously.
]

=== MQSeries IBM

A widely used MOM implementation. Key characteristics:

#prop("MQSeries IBM Architecture")[
  - *Queue manager* controls the static routing via routing tables defined at configuration time.
  - *Message Channel Agents (MCAs)*: handle all delivery details — different delivery policies, message type, duration, maximum allowed state, persistence, etc.
  - *MCA coordination* via primitives enabling flexible coordination and QoS.
  - Organization is *decentralized*: Relay, MCA, and Broker are local entities; each application location has its own entities.
  - An *MQ Broker* can operate on messages by: modifying formats, organizing routing based on contained information, working on application information to specify action sequences.
]

// ─────────────────────────────────────────────────────────────
// PART 7: KAFKA
// ─────────────────────────────────────────────────────────────

== Apache Kafka

#def("Kafka")[
  #kw[Apache Kafka] is a general-purpose *distributed pub/sub system and streaming middleware* with many additional features. Developed at LinkedIn in 2010 (in Scala), widely adopted by big techs for *scalability* (Netflix, Uber, LinkedIn).
]

#prop("Kafka Requirements")[
  - *Fault-tolerant*
  - *Horizontally scalable*
  - *High throughput* of data arriving and ingested (billions of messages)
  - *Processing* of data, not only messaging
]

=== Kafka Pub/Sub Model

Kafka organizes messages in *topics*. A topic is a repository where many producers can publish and many consumers can subscribe.

- *Producers*: publish messages to a Kafka topic.
- *Consumers*: subscribe to topics and process the published message feed.

=== Topics, Partitions, and Brokers

#def("Topic")[
  A #kw[topic] defines the set on which messages are published. The Kafka cluster maintains a *partitioned log* for each topic: an append-only, totally-ordered sequence of records, ordered by time.
]

#def("Partition")[
  A topic is split into a pre-defined number of #kw[partitions] — the unit of parallelism of the topic. Each partition is an *ordered, numbered, immutable sequence of records*, similar to a log. Each record has a *monotonically increasing sequence number* called the *offset*. Partitions are replicated across brokers.
]

#def("Broker")[
  A #kw[broker] is a Kafka cluster server. The cluster maintains a distributed log of data over many servers called brokers. Each partition has one *leader* (handles read and write requests) and may have *followers* (replicate the leader passively). Each broker is a leader for some partitions and a follower for others.
]

#prop("Kafka Architecture Summary")[
  - *Producers* send data directly to the broker leader of the partition (using round-robin or key-based strategy).
  - *Consumers* pull data from brokers (pull model: better scalability, lower broker burden).
  - *Zookeeper*: hierarchical, distributed key-value store for Kafka's coordination metadata — list of brokers, consumers and their offsets, producers.
  - *Consumer Group*: set of consumers sharing a common group ID. Each group defines a logical subscriber. A consumer group consists of multiple consumers for scalability and fault tolerance. Only one consumer per group reads each partition subset.
]

=== Kafka QoS

#prop("Ordering Guarantees")[
  - Producers append to specific *topic partitions* in the order sent.
  - Consumers see records in the order stored within a partition.
  - *Total order within a partition* — not across partitions.
  - *Per-partition ordering* combined with key-based partitioning is sufficient for most applications.
]

#prop("Replication and Fault Tolerance")[
  - Each partition is *replicated* over a predefined number of brokers (passive replication).
  - A message is available for consumers only after *all followers acknowledge the leader* a successful write.
  - Usual tradeoff: *consistency over availability* — but the default behavior can be relaxed for availability.
  - Kafka *retains messages for a specified period of time* and can *replay* messages in case of consumer crash (consumers track their own offset).
]

=== Kafka Producers and Consumers

#prop("Producers Responsibilities")[
  - Publish data to topics of their choice.
  - Send data directly to the broker leader of the partition.
  - Be responsible for *strategies*: which partition to assign records to (random or key-based).
  - Decide to which partition to write.
]

#prop("Consumers — Pull Model")[
  Kafka uses a *pull approach* for consumers: consumers use the offset to track which messages have been consumed. Messages can be replayed using the offset.
  - *Push model* (broker pushes to consumers): broker must deal with different consumer types.
  - *Pull model* (Kafka's choice): better scalability (less burden on broker), more flexibility — *con*: if broker has no data, consumers may end up busy waiting.
]

// ─────────────────────────────────────────────────────────────
// PART 8: MQTT AND OPC UA
// ─────────────────────────────────────────────────────────────

== MQTT — Message Queue Telemetry Transport

#def("MQTT")[
  #kw[MQTT] is a pub/sub messaging protocol designed for *sensors and edge devices* (IoT). A *broker* manages the pub/sub; *sensors* are the producers; *clients* can register (subscribe) to receive information from producers (publish).
]

The broker is in charge of maintaining messages and filtering for the interested receiver consumers. Used in constrained environments — low bandwidth, low power (HTTPS and/or MQTT transport).

== OPC UA — Open Platform Communications Unified Architecture

OPC UA is used in *plants and manufacturing* (Industry 4.0). Supports both:
- *Client-Server* model: adopted in very demanding industrial environments where low-level application require precise, direct communication.
- *Pub-Sub* model: for event notification flows.

The architecture stacks: Use-Case Protocol Mappings #arrow Information Model Access (Browse, Data/Event Notifications) #arrow Information Model Building Blocks (Meta Model) #arrow Core + Companion Information Models #arrow Vendor-Specific Extensions.

// ─────────────────────────────────────────────────────────────
// PART 9: GROUP COMMUNICATION AND MULTICAST
// ─────────────────────────────────────────────────────────────

== Group Communication and Multicast

=== Group Communication Semantics

Broadcasting and multicasting introduce new *semantic problems*:
- How to cope with *answers* (if any)?
  - *No wait* — asynchronous operations.
  - Wait for *one answer only*.
  - Wait for *some answers only* (how many? how long?).
  - Wait for *all answers* (how many? how long? when to stop?).
- How to send general messages to *all currently present processes* or to a *subset* (a group)?

On a *single LAN*, broadcast is easy. On *different networks and locations*, it is hard: expressive incapacity, excess overhead, lack of QoS.

=== IP Group Communication

#prop("IP Multicast vs Broadcast")[
  - *IP Broadcast*: limited and directed — inside local network only.
  - *IP Multicast*: heavier duty with a dedicated protocol. Uses *class D addresses*. Internet uses *IGMP* (Internet Group Management Protocol, RFC 1112 & 2236) since 1989 to implement local multicast.
  - The protocol often operated only on local subnetworks and was implemented in different, incompatible forms.
]

=== IGMP — Local Group Management

#def("IGMP")[
  #kw[IGMP] (Internet Group Management Protocol) allows sending a unique packet to multiple receivers in the same locality, using class D names to identify a group. Every local network must have at least an *IGMP router* capable of managing local incoming and outgoing traffic and controlling the group with IGMP messages.
]

#prop("IGMP Versions")[
  - *IGMPv1*: only two messages — `IGMPQUERY` (router periodically verifies existence of hosts in a specific IP D address) and `IGMPREPORT` (node signals state change: *join only, no leave*). Only one report per node per network.
  - *IGMPv2*: adds support for explicit `leave`. Nodes that leave the group must notify the manager. More MX routers can be in charge (interference settled by IP numbers order).
]

#prop("TTL-Based Scoping for IP Groups")[
  | TTL | Scope |
  |---|---|
  | 0 | Local send only |
  | ≤ 32 | Local area |
  | ≤ 64 | Local region |
  | ≤ 128 | Local continent |
  | > 128 | Global |
]

#note[
  IGMP implementations offer only *best-effort* semantics — we do not know whether messages were *all delivered to all recipients* and in *which order*.
]

=== Global Multicast Routing

For *global multicast*, routing must create and maintain a *distribution tree* from sender to receivers, minimizing overhead.

#important("Global Multicast Principles")[
  - *Single sender* support.
  - *Variable number of receivers* (up to N) that can be added or removed dynamically.
  - Maximize *sharing*: send only 1 copy of a message instead of N different unicasts.
  - Protocols identify a *central tree* from sender to current receivers with *optimal shared paths*.
  - The goal: *employ the most shared hops possible from root to leaves*.
  - The tree is *extremely dynamic* — must consider only currently active receivers.
]

=== Multicast Spanning Tree

Building the multicast routing tree requires *two control phases*:

#prop("Phase 1 — Root to Leaves (Forward)")[
  - Build a *spanning tree* connecting root to known leaf nodes.
  - Use *unicast routing* information to organize and aggregate paths.
  - Send a *flooding message* toward every possible recipient — main objective: create a *bone multicast*.
  - Root identifies shortest paths from replies.
  - Some receiver nodes are reached through *multiple paths* — second phase must choose one.
]

#prop("Phase 2 — Leaves to Root (Upward/Backward)")[
  - *Reverse Path Broadcast (RPB)*: leaves send broadcasts toward the root during normal routing.
  - *Minimal path messages* are sent backward from leaves to root; only some paths are selected.
  - Root can *reorganize the tree*, aggregating sub-paths to produce an optimal tree.
  - Routing info is *soft-state* (not persistent): re-calculated dynamically since it is a dynamic scenario.
]

=== Pruning and Grafting

#def("Pruning")[
  #kw[Pruning]: cutting branches of the multicast tree from configuration a) to b). Networks with no members are cut — routers with no connected receivers are excluded with 'cut' messages.
]

#def("Grafting")[
  #kw[Grafting]: reinserting parts of the tree from b) back to a) when new receivers join. Done without reorganizing the tree from scratch (explicit graft from the bottom).
]

*Reverse Path Multicasting (RPM)* is performed autonomously by leaves. State is kept for a limited and predefined time (*SOFT-STATE*) — the definition of the RPM time interval is critical.

=== Multicast Protocols

#prop("Key Multicast Routing Protocols")[
  - *DVMRP* (RFC 1075) — Distance Vector Multicast Routing Protocol: employs RPM based on a modified version of RIP. Very used in MBONE (multicast backbone). Updates sent via special paths (tunnel) using only some nodes.
  - *MOSPF* (RFC 1584) — Multicast Open Shortest Path First: extends link-state, suitable for big networks, based on RPM and soft-state. Starts from networks map, calculates shortest path to every single destination, removes unused paths.
  - *PIM* (RFC 2117) — Protocol Independent Multicast: uses any unicast protocol to suit different systems.
    - *Scattered* (low density of multicast nodes): removes most intermediate routers to simplify tree structure.
    - *Dense* (many neighbor routers): use of flooding and prune, simplified with regard to DVMRP.
  - *CBT* (RFC 2201) — Core Based Trees: organization based on core routers chosen by the group. Defines a *core backbone* where some nodes are fixed (core) and *trees are unified* without defining a per-sender or per-group state. Sub-optimal tree organizations to avoid reorganizing connection for every multicast reconfiguration (used by streaming providers: clients connect to the nearest node).
]

#note[
  All these protocols are *incompatible* with each other — even in competition between themselves and supported by different communities. In practice, ISPs and streaming providers rely on CBT-like approaches where clients connect to the nearest (core) nodes.
]
