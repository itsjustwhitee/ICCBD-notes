#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= CORBA, ADVANCED C/S MODELS, EVENTS AND MOM

#extra[
  Package: CORBA CS and Events and MOM - `6  - CORBA CS and Events and MOM 26.pdf`
]

This chapter deepens the distributed middleware model by examining *CORBA* (an industrial-strength DOC middleware), *advanced C/S interaction patterns*, *event-based systems*, *publish-subscribe*, the *tuple model*, *MOM* (Message Oriented Middleware) and concrete tools like *Kafka* and *MQTT*, ending with *group communication and multicast routing*.

// ─────────────────────────────────────────────────────────────
// PART 0: REMOTE REFERENCES AND PROXY
// ─────────────────────────────────────────────────────────────

== Remote References and the Proxy\ Pattern

Every distributed communication model (whether Client/Server or message-based) requires the initiator to *identify* its partner across network boundaries. A local variable or pointer cannot cross a machine boundary, instead, the #hl[middleware must provide a *non-local identifier* (a remote] #hl[reference) that can be resolved at runtime].

A *name server* (or any form of directory service) is the basic building block: it maps an abstract name or specification to a concrete remote reference. 
#extra[Examples: DNS for hostnames, CORBA Naming Service for object interfaces, a Trading service for attribute-based lookup.]

=== Proxy

Once a remote reference is obtained, the client still needs a local object to talk to. This is where the *proxy* pattern comes in:

#def("Proxy")[
  A #kw[proxy] is a *local intermediary* that stands in for a remote entity. From the client's perspective, calling the proxy looks identical to calling a local object: the proxy *transparently* handles all the communication details (marshalling arguments, sending the network request, unmarshalling the result).
]

In general, a communication can involve *two kinds of proxies*:
- #hl[*Client-side proxy (Proxy C)*: sometimes called *stub*. Located near the client], it translates local method calls into network messages. The client code calls the stub as if it were the real object.
- #hl[*Server-side proxy (Proxy S)*: sometimes called *skeleton* or *adapter*. Located near the server]; receives incoming network requests and #hl[translates them into real method calls on the servant].
- #hl[*Broker / Link Manager*]: a third possible #hl[intermediary between the two proxies], responsible for *dynamic binding* at runtime (e.g., routing the request to the right server when multiple servers implement the same interface).
#v(-0.7em)
#analogy("Proxy as a diplomatic interpreter")[
  Two delegations (client and server) speak different languages and are in different cities. Each sends a local translator (proxy) to the negotiation table. The translators handle the language and logistics: the delegations just talk normally. If an intermediary (broker) is added, it routes each delegation's message to the right counterpart even when the address is not known in advance.
]

#figure(
  image("../assets/proxy-stub-skel-broker.jpg", width: 35%),
  caption: [Proxy stub + skel + broker.]
)

#extra[Java RMI is a concrete realization of this pattern: it generates two proxies automatically (a stub on the client JVM and a skeleton on the server JVM) freeing the programmer from dealing with sockets. However, RMI still requires solving several practical problems: how to obtain the initial server reference (a name registry), where to find the ancillary classes, what happens if the server is not running, and whether two different references point to the same object.]

// ─────────────────────────────────────────────────────────────
// PART 1: CORBA
// ─────────────────────────────────────────────────────────────

== CORBA

#def("CORBA: Common Object Request Broker Architecture")[
  #kw[CORBA] is an OMG standard for *Distributed Object Computing (DOC)*: it provides an *Object Request Broker (ORB)* that mediates invocations between distributed objects written in different languages, running on different OS and hardware, without the client knowing the location or implementation of the server object.
]
#v(-1em)
#prop("Core CORBA Concepts")[
  - *Object*: any CORBA #hl[entity with a defined interface]. Has a *remote reference* (*IOR*, Interoperable Object Reference) that uniquely identifies it globally.
  - *Servant*: the #hl[concrete language implementation] of a CORBA object (e.g., a Java class). Created by the language environment, *not by CORBA itself*.
  - *Interface*: declared in IDL. Defines the #hl[contract]: attributes, methods, exceptions.
  - *ORB*: the #hl[middleware bus]. Routes requests from clients to the correct servant, transparently.
  - *POA* (Portable Object Adapter): on the server side, maps incoming requests to the correct servant instance.
]
#v(-1em)
#analogy("CORBA as an Object Phone Network")[
  Think of objects scattered across many machines as people in different cities with different languages. CORBA is the telephone operator: you give it a reference (phone number) and it routes your call to the right person, translating protocols and formats along the way. You never need to know where the person is or what language they speak internally.
]

#figure(
  image("../assets/corba-architecture.png",width: 50%),
  caption: [CORBA scheme.]
)

=== ORB: Object Request Broker

The ORB is the central infrastructure piece. It does #underline[*not* create or move] objects: it #hl[connects] (route) them, since it is a bus (not a server).
#v(-0.5em)
#prop("ORB Responsibilities")[
  - *Interaction Broker*: Acts as a #hl[communication bus], enabling object interaction. By default, it uses #hl[*synchronous blocking calls*, but supports *asynchronous*] patterns.
  - *Language Independence*: Delegates the final execution to specific language mappings, maintaining neutrality between client and servant environments.
  - #hl[*Separation of Concerns*]: Specifically avoids managing object creation or object migration, these tasks are delegated to the underlying *Servant* implementations.
  - *Reference Management*: #hl[Facilitates the discovery and resolution of remote objects] (IORs), acting strictly as a #hl[routing layer] between the client and the target servant.
]
#v(-1em)
#note[
  The ORB does not host objects, it routes invocations. To locate a target, it uses:
  - *Stringification*: Converting IORs into human-readable strings and back.
  - *Directory Services*: Utilizing Name or Trading services to resolve service names into specific remote addresses.
  - *Parameter Passing*: Dynamically passing references as arguments during method invocations.
]

The communication flow is:\
#hl[Client #arrow *Stub* #arrow ORB #arrow network #arrow ORB #arrow *Skeleton* #arrow Servant].\
#v(-0.7em)
#note[
  The stub and skeleton are generated automatically by the IDL compiler.
]

=== Object Management Architecture (OMA)

The ORB is the core of a broader framework called the *Object Management Architecture (OMA)*, defined by OMG.

#def("OMA: Object Management Architecture")[
  #kw[OMA] organizes the full CORBA environment in layers around the ORB:
  - *Object Services (CORBA Services)*: fundamental services any distributed application needs (naming, trading, events, lifecycle, transactions, security, ...).
  - *Common Facilities (CF)*: horizontal features shared across many applications (UI, system management, information management).
  - *Domain Interfaces (DI)*: vertical, industry-specific interfaces standardized per sector (manufacturing, finance, healthcare, ...).
  - *Application Interfaces*: non-standard, application-specific interfaces defined by individual projects.
]

OMA explains why CORBA comes with a Naming Service, Trading Service, Event Service and so on: these are not add-ons but integral parts of the standard.

=== Static vs Dynamic Invocation

CORBA supports two invocation paths, which can coexist in the same system:
#v(-0.7em)
#prop("Static vs Dynamic Invocation")[
  - *SII (Static Invocation Interface)*: the default. The IDL compiler pre-generates a *stub* on the client side and a *skeleton* on the server side. Calls go through these fixed proxies. Fast, but requires the interface to be known at compile time.
  - *DII (Dynamic Invocation Interface)*: the client builds and sends a request *at runtime* without a pre-generated stub. Supports blocking, oneway (fire-and-forget), and deferred-synchronous (send now, retrieve result later) invocation modes. Useful for gateways and generic tools operating on unknown interfaces.
  - *DSI (Dynamic Skeleton Interface)*: the server-side counterpart of DII. A server can accept requests for *any* interface without a pre-generated skeleton, inspecting the incoming request *dynamically*.
]

=== Repositories and Inter-ORB Protocols

#prop("Interface and Implementation Repositories")[
  - *IR (Interface Repository)*: a runtime catalogue of IDL interface descriptions. While stubs embed type information statically, the IR allows it to be discovered *at runtime*, enabling DII and generic introspection tools.
  - *IMR (Implementation Repository)*: tracks where servants are actually deployed. Enables *on-demand activation*: servants do not need to run continuously, the ORB consults the IMR to start them when needed.
]
#v(-1em)
#prop("GIOP and IIOP")[
  Different ORB implementations interoperate via standard wire protocols:
  - *GIOP (General Inter-ORB Protocol)*: defines a *binary message format* and *CDR* (Common Data Representation) encoding so that ORBs from different vendors exchange data consistently.
  - *IIOP (Internet Inter-ORB Protocol)*: GIOP carried over TCP/IP. This is what makes CORBA a truly open standard: a client compiled against one vendor's ORB can invoke objects hosted on any other vendor's ORB.
]
#v(-1em)
#note[POA, repositories, and the DII/DSI request objects are *pseudo-objects*: they have IDL-described interfaces but exist only locally and cannot be invoked remotely.]

=== CORBA IDL

#def("IDL - Interface Definition Language")[
  #kw[CORBA IDL] is a purely #hl[*declarative, object-oriented language*] (derived from C++) used to specify *data *and* method interfaces*, completely independently of any specific programming language.
]
#v(-1em)
#prop("IDL Capabilities")[
  - #hl[*Interface definition*] (with multiple inheritance).
  - *Attribute* definition (accessed via auto-generated `_get` / `_set` operations).
  - *Exception* definition (with `completion_status`: `COMPLETED_YES`, `COMPLETED_NO`, `COMPLETED_MAYBE`).
  - Automatic management of *attributes mapping* across languages.
  - *Module grouping* of interfaces (for logical aggregation).
]

#extra[
#example("IDL - Stock Example")[
  _```cpp
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
  ```_
]
#v(-1em)
#example("IDL - BankAccount Example")[
  _```cpp
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
  ```_
  Objects are *returned by reference* (the interface), not by value. Parameters use `in`, `out`, and `in out` modes.
]
]

=== Data Types in CORBA IDL


  - *Object references*: references to CORBA objects or interfaces, passed by reference.
  - *Exceptions*: not values but signaled conditions.
  - *Basic values*: short, long, ushort, ulong, float, double, char, string, boolean, octet, enum, `Any`.
  - *Constructed values*: Struct, Sequence, Union, Array.
  - *`Any`*: a generic type that can hold any primitive or any CORBA interface, analyzable at runtime (used to dynamically carry the current type).
#v(-0.7em)
#important("Object by Value (CORBA 3)")[
  Objects passed *by value* (`valuetype`) are copied from one environment to another: they *cannot* be accessed remotely. Used to overcome heterogeneity when no remote reference is possible. This is the only case where objects cross the wire as data.
]

=== Language Mapping

CORBA defines interfaces but code must run in concrete languages. #hl[*Language mapping*] is the process of #hl[translating IDL constructs into specific programming language constructs].

#prop("Language Mapping Responsibilities")[
  - *Strategy for consistency* of concrete language types with the CORBA model.
  - *Transformation functions* to manage types automatically: putting structures together simply.
  - Additional support functions: *naming, trading, suggested development methodologies*.
  - Each language provides a *Helper* and a *Holder* utility class.
]
#v(-1em)
#example("Holder (Java)")[
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
#v(-1em)
#example("Helper (Java)")[
  A #kw[Helper] maps between the CORBA `Object` type (`org.omg.CORBA.Object`) and the specific concrete type. Functions include:
  - *Narrowing*: casting from a generic CORBA Object to the specific interface type.
  - *Reading and writing* a type on an object stream: treating type dynamically.
  Every language must guarantee interoperability with CORBA through such helpers.
]
#v(-1em)
#note[
  The #hl[*cost of CORBA is very high*]: both in terms of developer learning curve and runtime performance overhead. This is a core limitation acknowledged even by its proponents. Despite this, it was widely used (Orbix/IONA, Visibroker/Borland, JacORB as open source).
]

// ─────────────────────────────────────────────────────────────
// PART 2: ADVANCED C/S MODELS
// ─────────────────────────────────────────────────────────────

== Advanced Client/Server Interaction Models

The classic C/S model is *synchronous blocking*: the client sends a request and waits. This is too rigid for real distributed applications.

#prop("Novel C/S Variants")[
  - *Pull* (synchronous non-blocking): the client gets the result afterwards, without waiting for it immediately.
  - *Push* (synchronous non-blocking): the server gives the result to the client afterwards: the client does not wait for it.
  - *Delegation*: a delegate waits for the result on behalf of the client (synchronous non-blocking for the client). The delegate holds the result and notifies.
  - *Notification*: for the result: the delegate notifies the client when a result arrives.
  - *Events* (typically asynchronous, non-blocking): an event is generated by a producer and advertised to consumers.
  - *Provisioning*: other parties can be interested in the call chain, apart from the direct C/S pair.
]

=== Delegation Patterns

In a synchronous non-blocking model, an intermediate entity handles result delivery:

#def("Poll Object")[
  A #kw[Poll Object] is an *intermediate* entity the client periodically queries. Used for *short operations* with bounded response time.\
  Flow: Sender #arrow Request #arrow Receiver.\
  Sender polls Poll Object and Poll Object returns response.
]
#v(-1em)
#def("Call-Back Object")[
  A #kw[Call-Back Object] is an *intermediate* entity that is *notified by the server* when the result is ready and then invokes the client-specified callback. Allows even *long operations independent of client life cycle*.
  The #hl[code to handle the response is executed when the response arrives].
]

#figure(
  image("../assets/delegation-poll-callback-objects.jpg", width: 70%),
  caption: [Poll object (left) vs. Callback object (right).]
)

// ─────────────────────────────────────────────────────────────
// PART 3: MESSAGE EXCHANGE
// ─────────────────────────────────────────────────────────────

== Message Exchange

#def("Message Exchange")[
  #kw[Message exchange] is a flexible but primitive communication model. Sometimes messages carry *only synchronization signals* (no data): the message itself is the trigger.
]
#v(-1em)
#prop("Message Exchange Properties")[
  - *Synchronous / non-synchronous*: does the sender receive a reply?
  - *Symmetric / asymmetric*: do both sides know each other?
  - *Direct / indirect*: is there an intermediate entity?
  - *Blocking / non-blocking*: is the sender blocked during transmission?
  - *Buffered / unbuffered*: are messages queued?
  - *Reliable / unreliable*: with or without message loss guarantee?
  - Models with *multiple receivers*: group messages (multicast, MX) and broadcast (BX).
]

=== Modes of Message Exchange

#prop("Three Communication Modes")[
  - *Rendez-vous*: one-to-one, synchronous, blocking, symmetric, unbuffered, *coupled* (more constrained than C/S). Both parties must be present.
  - *With one #hl[intermediate entity]* (channel, socket, queue): typically asynchronous, non-blocking, asymmetric, *buffered, decoupled*. This is #hl[MOM].
  - *With intermediate entity and group of receivers* (events): typically asynchronous, non-blocking, asymmetric, decoupled and *many-to-many*.
]

=== Coupling and Decoupling

#def("Coupling")[
  #kw[Coupling] constraints imposed by communication tools can limit flexibility in three dimensions:
  - *Space*: interacting entities must know each other and be co-located.
  - *Time*: interacting entities must be present at the same time.
  - *Synchronization*: interacting entities must wait for each other.
]
#v(-1em)
#important("Why Decoupling Matters")[
  *Decoupling* enables greater flexibility and leverages the potential distribution of load. #hl[The less coupled the components, the easier it is to scale, replace, and evolve them independently].
  #hl[MOM systems decouple in all three dimensions simultaneously].
]

// ─────────────────────────────────────────────────────────────
// PART 4: EVENTS AND PUBLISH-SUBSCRIBE
// ─────────────────────────────────────────────────────────────

== Events and Publish-Subscribe

=== From Local to Distributed Events

*Local events* (e.g., Windows GUI events) already reverse control: the user process registers a handler and the framework calls it back when the event occurs. Responses from the framework are called *backcall* or *upcall*.

*Distributed event systems* go further: designed *without any locality constraints* (no coupling). Their strength is the *non-locality* of interacting entities.
#v(-0.3em)
#extra[
  #note[
    Constraining events to co-residence (same node, producer and consumer on the same machine) contradicts the event model's purpose. That is one of the worst misuses of the technology.
  ]
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

#table(
  columns: (auto, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 0.8em,
  table.header([*Generation*], [*Properties*]),
  [*Primitive events*], [On/off signals, no content: interrupt events and low-level signals.],
  [*Events with contents*], [Some events carry information and filters based on interest about specific information (e.g., RSS feeds).],
  [*Events with QoS*], [*Differentiated* service for different users, *persistent* events, event *priority*.],
)

*Persistent events*: users not online do not lose any event, delivered as soon as they reconnect.

=== Publish-Subscribe

#def("Publish-Subscribe")[
  In a #kw[publish-subscribe] system, *producers* generate events freely (publish/PUB) without worrying about delivery. *Consumers* register their interest (subscribe/SUB) in specific events, *topics*, or types. The *event support infrastructure* handles delivery.\
  Producers and consumers are *#underline[not] required to be present at the same time*.
]
#v(-1em)
#prop("Message Filtering in PUB-SUB")[
  - *Topic-based*: based on a predefined topic/channel (e.g., RSS on a specific feed).
  - *Content-based*: based on message contents (keywords or more complex relationships).
  - *Type-based*: based on message type.
  - #hl[*QoS*: persistency, priority, guaranteed maintenance and duration].
]
#v(-1em)
#prop("PUB-SUB Operations")[
  - *Producers* (publishers) provide events. They may declare intent via `publishIntent`.
  - *Consumers* (subscribers) first `subscribe`, then receive `notify` callbacks.
  - The infrastructure holds: storage and management of subscriptions, subscribe/unsubscribe/notify operations.
  - 2 management operations + 2 content operations #so *symmetric model*.
]

#figure(
  image("../assets/pub-sub.png", width: 70%),
  caption: [PUB/SUB model.]
)

// ─────────────────────────────────────────────────────────────
// PART 5: TUPLE MODEL (LINDA)
// ─────────────────────────────────────────────────────────────

== Tuple Model: Linda (Gelernter)

#def("Tuple Space")[
  A #kw[tuple space] is a *shared memory abstraction* combined with communication. It is a set of structured relationships organized as a *container for attributes and values*. Tuples can be *deposited* (Out) or *extracted* (In) as high-level information without any interference or incorrectness.
  No duplication is allowed in the space.
]

#kw[Linda] is an implementation of *tuple model*. A tuple example could be `(to, from, message)`
#v(-0.7em)

#prop("Linda Core Operations")[
  - *`out(tuple)`*: Atomically *inserts* a tuple into the tuple space, making it available for future matching. The tuple persists until it is explicitly consumed.
  - *`in(pattern)`*: Atomically *removes* a matching tuple from the space. If no tuple matches the pattern, the operation blocks (waits) until a suitable tuple is produced.\
    #swarrow *Non-Deterministic Selection*: If multiple tuples satisfy the pattern, the system selects one. The choice is *non-deterministic*.
]
#v(-1em)
#important("Non-Determinism")[
  The Linda model explicitly leaves the *implementation strategy free* in choosing which tuple to extract from multiple matches. This freedom allows the system to optimize for cost, locality, or load, at the price of not guaranteeing order.
]
#v(-1em)
#prop("Decoupling in Tuple Spaces")[
  - *In space*: consumers do not know producers. Only tuple contents matter: zero knowledge of other party.
  - *In time*: a producer deposits and leaves, the consumer arrives later and retrieves. No co-presence required.
  - *In quality (QoS)*: tuple spaces are *persistent*: tuples are safely deposited without limit (in memory and time). No preference for any specific process.
  Tuple spaces are available with *high-level operations* (closures, in-transaction semantics, partition replication) to support well-formed local communication.
]
#v(-1em)
#analogy("Tuple Space as a Corkboard")[
  Imagine a physical corkboard in an office. Anyone can pin notes (Out). Anyone can take a note matching their need (In). You don't need to be there when it was pinned, you don't need to know who pinned it: the corkboard is the mediator.
]

// ─────────────────────────────────────────────────────────────
// PART 6: MOM MIDDLEWARE
// ─────────────────────────────────────────────────────────────

== MOM: Message Oriented Middleware

#def("MOM")[
  #kw[Message Oriented Middleware (MOM)] organizes data communication and distribution via *message exchange* between logically separated entities, using point-to-point or group messages. It provides typed and untyped, asynchronous and synchronous message exchange with *wide autonomy* between components, *persistence*, and *broker* support for different strategies and QoS.
]

#extra[Examples: MQSeries IBM, MSMQ Microsoft, JMS Sun, OMG DDS, MQTT, RabbitMQ, ActiveMQ, Apache Kafka, ZeroMQ, NATS.]

#important("MOM's Role")[
  MOM is a *Disappearing / Glue / Thin service layer*: it keeps together different autonomous systems and organizes their specific interconnection in a *static way*. The MOM can plan better support for communications because the configuration can be known a priori: optimize support costs to the specified need.
]

=== MOM Deployment

The #hl[specific deployment and *interconnection graph (routing) is always static*] (no name services needed).
  - #hl[*Necessity of high-level Routing*] (as in ONs, but static).
  - *Data treatment* while communicating between different environments.
  - #hl[*Predefined and static participating entities*].


#prop("Two Extreme Deployment Models")[
  - *Centralized model*: MOM with a central node as *hub* (hub-and-spoke) responsible for supporting and passing messages between different clients. Typically *replicated* for availability.
  - *Distributed model*: MOM located on any client node forming a static overlay network, operating through *P2P communication* between nodes.
]

#figure(
  grid(
    columns: (1fr,1.5fr),
    gutter: 1.5em,
    image("../assets/mom-centralized.png"),
    image("../assets/mom-distributed.webp"),
  ),
  caption: [MOM centralized model (left) vs. distributed (right).]
)

=== MOM Infrastructure Components

#prop("MOM Building Blocks")[
  - *Queue managers*: guarantee the expected operation level and message forwarding. Applications interact via API RPC to put/extract messages from local queues.
  - *Inbound and outbound queues*: on interested machines, connected univocally.
  - *Routing system*: connects different queues (as overlay networks do for application-level routing).
  - *Relay*: intermediate entities that allow the implementation to scale and organize high-level routing for scalability.
  - *Message Broker*: entity able to support message content transfer between environments with *different representations*: can modify formats, organize routing based on contained information, work on application data to specify action sequences.
]
#v(-1em)
#analogy("MOM as a Postal Service")[
  You drop a letter (message) in a mailbox (local queue). The postal service (MOM) picks it up, routes it through sorting centers (relays), possibly translates the address format for international delivery (broker), and delivers to the recipient's mailbox. Neither sender nor recipient need to be present simultaneously.
]

=== MQSeries IBM

MQSeries by IBM is a widely used MOM implementation.

#prop("MQSeries IBM Architecture")[
  - *Queue manager* controls the static routing via routing tables defined at configuration time.
  - *Message Channel Agents (MCAs)*: handle all delivery details: different delivery policies, message type, duration, maximum allowed state, persistence, etc.
  - *MCA coordination* via primitives enabling flexible coordination and QoS.
  - Organization is *decentralized*: Relay, MCA, and Broker are local entities; each application location has its own entities.
  - An *MQ Broker* can operate on messages by: modifying formats, organizing routing based on contained information, working on application information to specify action sequences.
]

#figure(
  image("../assets/MQSeries-ibm.jpg", width: 75%),
  caption: [MQSeries MOM IBM scheme.]
)

// ─────────────────────────────────────────────────────────────
// PART 7: KAFKA
// ─────────────────────────────────────────────────────────────

== Apache Kafka

#def("Kafka")[
  #kw[Apache Kafka] is a general-purpose *distributed pub/sub system and streaming middleware* with many additional features. 
]
#extra[Developed at LinkedIn in 2010 (in Scala), widely adopted by big techs for *scalability* (Netflix, Uber, LinkedIn).]
#v(-1em)
#prop("Kafka Requirements")[
  - #hl[*Fault-tolerant*]
  - #hl[*Horizontally scalable*]
  - #hl[*High throughput*] of data arriving and ingested (billions of messages)
  - #hl[*Processing*] of data, not only messaging
]

=== Kafka Pub/Sub Model

Kafka organizes #hl[messages in *topics*]. A topic is a repository #hl[where many producers can publish] and many consumers can subscribe.

- *Producers*: publish messages to a Kafka topic.
- *Consumers*: subscribe to topics and process the published message feed.

=== Topics, Partitions, and Brokers

#def("Topic")[
  A #kw[topic] defines the set on which messages are published. The Kafka cluster maintains a *partitioned log* for each topic: an #hl[*append-only*, *totally-ordered* sequence of records, ordered by time].
]
#v(-1em)
#def("Partition")[
  A topic is split into a pre-defined number of #kw[partitions]: the unit of parallelism of the topic. Each partition is an *ordered, numbered, immutable sequence of records*, similar to a log. Each record has a *monotonically increasing sequence number* called the *offset*. Partitions are replicated across brokers.
]
#v(-1em)
#def("Broker")[
  A #kw[broker] is a Kafka cluster server. The cluster maintains a distributed log of data over many servers called brokers. Each partition has one *leader* (handles read and write requests) and may have *followers* (replicate the leader passively). #underline[Each broker is a leader for some partitions and a follower for others].
]

  - *Producers* send data directly to the broker *leader* of the target partition (using round-robin or key-based strategy).
  - *Consumers* fetch data from brokers using a *pull-based* model (optimizes throughput, reduces broker burden).
  - *ZooKeeper*: hierarchical, distributed key-value store used by Kafka for coordination metadata (list of brokers, list of consumers and their offsets, list of producers).
  - *Consumer Group*: a logical subscriber entity. Each partition is assigned to *exactly one consumer* within the group, parallelizing consumption without conflicts. If a consumer fails, the group rebalances automatically, assigning the orphaned partitions to remaining members. Adding more consumers than partitions leaves the extras idle.

#figure(
  image("../assets/kafka-pub-sub.jpg", width: 55%),
  caption: "Apache Kafka architecture: producers push to broker partitions, consumers pull independently per group, ZooKeeper coordinates metadata."
)
#v(-0.7em)
#analogy("Sorting Facility")[
  To understand why each partition is assigned to exactly one consumer, imagine a large-scale sorting facility:
  
  - *The Conveyor Belt (Topic)*: A massive, high-speed stream of packages arriving simultaneously.
  - *The Lanes (Partitions)*: The belt is split into parallel lanes to handle the volume. 
  - *The Staff (Consumer Group)*: You have a team of workers. If you let all workers pick from the same lane, they would collide, duplicate work, and lose the order of the packages.
  
  *The Kafka Approach*:
  You assign specific lanes to specific workers. Each worker processes only their assigned lane(s) in complete isolation. This provides two key benefits:
  1. *Zero Coordination*: No locks, no mutexes, and no communication between consumers are required.
  2. *Ordered Processing*: Since a single worker processes the lane, the original sequence of packages (the offset order) is strictly preserved.
  
  *Scaling Rule*: The maximum degree of parallelism is defined by the number of partitions. Adding more consumers than partitions results in idle resources, as Kafka cannot assign a partition to more than one consumer within the same group.
]

=== Kafka QoS

#prop("Ordering Guarantees")[
  - Producers append to specific *topic partitions* in the order sent.
  - Consumers see records in the order stored within a partition.
  - *Total order within a partition*, not across partitions.
  - *Per-partition ordering* combined with key-based partitioning is sufficient for most applications.
]
#v(-1em)
#prop("Replication and Fault Tolerance")[
  - Each partition is *replicated* over a predefined number of brokers (*passive replication*): one leader, zero or more followers.
  - The *leader* handles all read and write requests for that partition. Followers replicate the leader passively and act only as backups.
  - Each broker is a *leader for some of its partitions and a follower for others*, distributing the load evenly across the cluster.
]
#v(-1em)
#important("Message Visibility Pipeline")[
  A message written by a producer is *not immediately available* to consumers. The pipeline is:

  *Producer writes to leader* #arrow *followers replicate* #arrow *followers send ack to leader* #arrow *message becomes readable by consumers*

  Only after *all followers have acknowledged* the write does the leader mark the message as available. This guarantees that even if the leader crashes immediately after a write, a follower promoted to leader already has the message. The cost is *latency between write and read*.

  If this strong guarantee is not needed, the default can be relaxed: a producer can request ack from the leader only (or even no ack), trading consistency for lower write latency.
]
#v(-1em)
#prop("Retention and Replay")[
  - Kafka *retains messages for a configurable period* (not until consumed): old messages are not deleted immediately after being read.
  - Consumers track their own *offset*, and can reset it to *replay* past messages, e.g., to recover from a crash or reprocess data.
]

=== Kafka Producers and Consumers

#important("Producers Responsibilities")[
  - *Publish* data to topics of their choice.
  - Send data directly to the broker *leader* of the partition.
  - Be responsible for *strategies*: which partition to assign records to (random or key-based).
  - Decide to which partition to write.
]
#v(-1em)
#important("Consumers: Pull Model")[
  Kafka uses a #hl[*pull approach* for consumers]: consumers use the offset to track which messages have been consumed. Messages can be replayed using the offset.\
  The *pull model* (Kafka's choice) grants better scalability (less burden on broker), more flexibility. But if broker has no data, consumers may end up busy waiting.
  #extra[Instead, *push model* (broker pushes to consumers): broker must deal with different consumer types. #swarrow CORBA choice.]
]

// ─────────────────────────────────────────────────────────────
// PART 8: MQTT AND OPC UA
// ─────────────────────────────────────────────────────────────

== MQTT: Message Queue Telemetry Transport

#def("MQTT")[
  #kw[MQTT] is a pub/sub messaging protocol designed for *sensors and edge devices* (IoT). A *broker* manages the pub/sub, *sensors* are the producers, *clients* can register (subscribe) to receive information from producers (publish).
]

The broker is in charge of maintaining messages and filtering for the interested receiver consumers. Used in constrained environments: low bandwidth, low power (HTTPS and/or MQTT transport).

== OPC UA: Open Platform Communications Unified Architecture

OPC UA is the industrial successor to the original OPC (OLE for Process Control) standard, designed for *modern manufacturing and Industry 4.0* environments. It is platform-independent (unlike the original OPC which was Windows-only) and supports both secure connectivity and rich data modelling.

OPC UA supports two communication models:
- *Client-Server*: used in demanding industrial environments where a control system needs precise, synchronous, low-latency access to sensor or actuator values. A client sends a read/write request and the server responds immediately.
- *Pub-Sub*: used for broadcast-style event notification flows where many subscribers need to react to state changes, without polling. Suitable for higher-level monitoring, dashboards, and historian systems.

The architecture is layered: vendor-specific extensions sit on top of core and companion information models (standard device and process object models), which are accessed via a rich Information Model Access layer (browse, data access, event notifications), mapped finally onto one of several protocol bindings (UA TCP, HTTPS, MQTT, AMQP).

#extra[OPC UA is the standard backbone for Industry 4.0 interoperability: it lets different machines, PLCs, sensors, and MES/ERP systems talk to each other using the same semantic model, regardless of manufacturer.]

#figure(
  image("../assets/opc-ua-layers.webp", width: 60%),
  caption: [OPC-UA layers architecture.]
)

// ─────────────────────────────────────────────────────────────
// PART 9: GROUP COMMUNICATION AND MULTICAST
// ─────────────────────────────────────────────────────────────

== Group Communication and Multicast

=== Group Communication Semantics

Broadcasting and multicasting introduce new *semantic problems*:
- How to cope with *answers* (if any)?
  - *No wait*: asynchronous operations.
  - Wait for *one answer only*.
  - Wait for *some answers only* (how many? how long?).
  - Wait for *all answers* (how many? how long? when to stop?).
- How to send general messages to *all currently present processes* or to a *subset* (a group)?

On a *single LAN*, broadcast is easy. On *different networks and locations*, it is hard: expressive incapacity, excess overhead, lack of QoS.

=== IP Group Communication

#prop("IP Multicast vs Broadcast")[
  - *IP Broadcast*: limited and directed, inside local network only.
  - *IP Multicast*: heavier duty with a dedicated protocol. Uses *class D addresses*. Internet uses *IGMP* (Internet Group Management Protocol, RFC 1112 & 2236) since 1989 to implement local multicast.
  - The protocol often operated only on local subnetworks and was implemented in different, incompatible forms.
]

=== IGMP: Local Group Management

#def("IGMP")[
  #kw[IGMP] (Internet Group Management Protocol) allows sending a unique packet to multiple receivers in the same locality, using class D names to identify a group. Every local network must have at least an *IGMP router* capable of managing local incoming and outgoing traffic and controlling the group with IGMP messages.
]
#v(-1em)
#prop("IGMP Versions")[
  - *IGMPv1*: only two messages: `IGMPQUERY` (router periodically verifies existence of hosts in a specific IP D address) and `IGMPREPORT` (node signals state change: *join only, no leave*). Only one report per node per network.
  - *IGMPv2*: adds support for explicit `leave`. Nodes that leave the group must notify the manager. More MX routers can be in charge (interference settled by IP numbers order).
]

#prop("TTL-Based Scoping for IP Groups")[
  #table(
    columns: (auto, 1fr),
    align: (center, left),
    fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
      if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
    },
    stroke: 0.5pt,
    inset: 0.8em,
    table.header([*TTL*], [*Scope*]),
    [0], [Local send only],
    [≤ 32], [Local area],
    [≤ 64], [Local region],
    [≤ 128], [Local continent],
    [\> 128], [Global],
  )
]
#v(-1em)
#note[
  IGMP implementations offer only *best-effort* semantics: we do not know whether messages were *all delivered to all recipients* and in *which order*.
]

=== Global Multicast Routing

For *global multicast*, routing must create and maintain a *distribution tree* from sender to receivers, minimizing overhead.

#important("Global Multicast Principles")[
  - *Single sender* support.
  - *Variable number of receivers* (up to N) that can be added or removed dynamically.
  - Maximize *sharing*: send only 1 copy of a message instead of N different unicasts.
  - Protocols identify a *central tree* from sender to current receivers with *optimal shared paths*.
  - The goal: *employ the most shared hops possible from root to leaves*.
  - The tree is *extremely dynamic*: must consider only currently active receivers.
]

=== Multicast Spanning Tree

Building the multicast routing tree requires *two control phases*:

#prop("Phase 1: Root to Leaves (Forward)")[
  - Build a *spanning tree* connecting root to known leaf nodes.
  - Use *unicast routing* information to organize and aggregate paths.
  - Send a *flooding message* toward every possible recipient. The main objective is to create a *bone multicast*.
  - Root identifies shortest paths from replies.
  - Some receiver nodes are reached through *multiple paths*: second phase must choose one.
]
#v(-1em)
#prop("Phase 2: Leaves to Root (Upward/Backward)")[
  - *Reverse Path Broadcast (RPB)*: leaves send broadcasts toward the root during normal routing.
  - *Minimal path messages* are sent backward from leaves to root, only some paths are selected.
  - Root can *reorganize the tree*, aggregating sub-paths to produce an optimal tree.
  - Routing info is *soft-state* (not persistent): re-calculated dynamically since it is a dynamic scenario.
]

=== Pruning and Grafting

#def("Pruning")[
  #kw[Pruning]: cutting branches of the multicast tree. Networks with no members are cut: routers with no connected receivers are excluded with 'cut' messages.
]
#v(-1em)
#def("Grafting")[
  #kw[Grafting]: reinserting parts of the tree when new receivers join. Done without reorganizing the tree from scratch (explicit graft from the bottom).
]

*Reverse Path Multicasting (RPM)* is performed autonomously by leaves. State is kept for a limited and predefined time (*SOFT-STATE*): the definition of the RPM time interval is critical.

=== Multicast Protocols

#prop("Key Multicast Routing Protocols")[
  - *DVMRP* (RFC 1075): Distance Vector Multicast Routing Protocol. Builds the distribution tree using a multicast version of RIP (distance-vector).\
    It uses Reverse Path Multicasting (RPM): flood first, then prune branches with no interested receivers. Historically used in the MBONE (multicast backbone), tunneling multicast traffic through unicast-only routers.
  - *MOSPF* (RFC 1584): Multicast extension of OSPF (link-state). Each router has a complete map of the network topology and computes the shortest-path tree from each source on demand. More accurate than DVMRP but scales poorly to large networks because every router must store per-source state.
  - *PIM* (RFC 2117): Protocol Independent Multicast. Unlike the above, PIM does not maintain its own routing tables, it reuses whatever unicast routing protocol is already in place. It has two modes:
    - *Dense mode*: suitable for networks where most routers have interested receivers. Uses flooding-and-prune like DVMRP.
    - *Sparse mode*: suitable for low-density deployments. Nodes explicitly join a shared *Rendezvous Point (RP)* tree rather than flooding the whole network.
  - *CBT* (RFC 2201): Core Based Trees. Rather than building a separate tree per sender, CBT builds a single shared tree rooted at one or more *core* routers. All senders send data toward the core. Receivers join the shared tree from below. The tree is suboptimal in path length but avoids per-sender state, making it practical for large groups. Widely used by streaming providers: clients connect to the nearest core node.
]
#v(-1em)
#note[
  All these protocols are *incompatible* with each other and were historically championed by different vendor communities. In modern practice, *PIM Sparse Mode with a Rendezvous Point* dominates in enterprise networks, while large streaming providers use CDN-style architectures (which achieve the same goal via application-level replication at edge nodes) rather than relying on IP multicast at all.
]
