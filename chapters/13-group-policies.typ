#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= GROUP ISSUES AND POLICIES
#extra[
  Package: Group Issues and Policies — `8 - Group issues and policies 26.pdf`
]

In distributed systems, a fundamental challenge is managing *partitioned* and *replicated entities*. All systems must insist on both partitioning (for scalability) and replication (for availability) — and these two aspects are *strictly coupled*, with both static and dynamic dimensions.

== Partitioning and Groups

#def("Partitioning and Replication")[
  - *Partitioning* — several entities must be in charge of the whole function to grant *scalability* of services and support.
  - *Replication* — several entities must be in charge of the whole function to grant *availability* of services and support.

  The two aspects are strictly coupled and have both static and dynamic dimensions.
]

== Group Communication

When entities form a group, a key design question arises: which semantics should govern message delivery?

=== Communication Semantics

#important("Communication Semantics")[
  *Semantics deeply depends on choices made about:*
  - *Global solicitation* vs. *Selective solicitation* — whether the message is sent to all group members or a chosen subset.
  - *Positive confirmation* vs. *Negative confirmation* — whether the system acknowledges successful delivery or only signals loss.
]

How many times to retransmit? When? To how many receivers? These are all design choices whose answers shape the entire group communication protocol.

=== Multicast Semantics

The #kw[multicast] action could make the multiple group sending operations *atomic*, but implementations can associate different and more suitable meanings.

#why("")[
  *Motivations for multicast interest:*
  - Fault tolerance and dependability
  - Object copy location within a system
  - Use of data replication and streaming
  - Multiple changes on group entities
  - Even different senders can be involved
]

The two aspects of multicast semantics are intertwined but *can be untangled*:

- *Reliability* — concerns whether individual group members receive a message:
  - *Reliable* #arrow guaranteed delivery
  - *Unreliable* #arrow only 1 attempt (Chorus model)

- *Atomicity* — concerns whether *all* group members receive the message, possibly with consistent ordering across multiple actions.

#note[
  We must think not only to the semantics of any single action, but also to *message ordering in a multiple action occurrence* — and consider their synchronization.
]

== Reliable Multicast

#def("Reliable Multicast")[
  Reliability *can be achieved* if some occurrences cause no problems: sender crash, receiver crash, or message omission. Fault *identification* and *recovery* are required through monitoring of multicast and group actions.
]

Recovery requires:
- *Check of every ongoing communication*
- *Possible retransmissions*
- *Removal of failed components*
- *Protocol to re-enter in the group*

The additional costs for identification and recovery must be considered — #hl[they apply in case of failures].

=== Implementation Decisions

Key implementation choices for reliable multicast:

- *Dispatch all messages* to group members support and *delay* before passing them to the application — introducing *timeout* and *retransmission* (who checks the protocol?).
- *How long* to wait? Problems with efficiency.
- *If controller fails?* — "Quis custodiet ipsos custodes?" (Juvenal/Giovenale)

#def("Hold-Back")[
  The support holds a message until it is sure that all previous others reached the destination in order. In *dense numbering*, a message is delayed until all previous ones appeared — message 3 must appear after message 2.
]

#def("Negative Acknowledgment (NAK)")[
  The support sends a *negative ack only in case of losses*, to identify those events in a selective way — avoiding unnecessary positive acks for every message.
]

== Multicast Ordering

Ordering policies for group multicast form a spectrum from cheapest (no ordering) to most expensive (atomic/total ordering).

=== No Ordering

#prop("No Ordering")[
  Multicast messages coming from any sending process to all receivers can present a different ordering in any copy. *No ordering policy is very easy to support* and you do not have to synchronize copies in any way — they are free to operate on their own.
]

=== FIFO Ordering

#def("FIFO Ordering")[
  From the *same sending process* to *all receivers*, a sequence of successive multicast messages is received in the same order. Two multicast messages from the *same sender* reach any group member in the same order.
]

- (m1 and m2 from S1) and (m3 and m4 from S2) each reach everyone
- Respecting sending order of the two senders, many sequences are compatible: (m1 m2 m3 m4), (m1 m3 m2 m4), (m1 m3 m4 m2), …
- An easy way to achieve FIFO is *message numbering* for any specific sender.

=== FIFO Ordering Limitations

Compliance with FIFO guarantees that every message to the group from the same sender (and its requests) are received in the same order in which they are sent from the group — *only related with same sender multicasts*.

#note[
  If we consider more than one sender: A sends news Na; B receives the news and sends a response Nb; C receives first Nb then Na (Nb before Na); D receives first Na then Nb. We need to consider *cause/effect relationships* between different senders.
]

=== Causal Ordering

#def("Causal Ordering")[
  #kw[CAUSAL ordering] — events that are correlated with a cause-effect relationship outside the group must be acknowledged by the group and must achieve consistency about them (to be delivered to everyone). *First the cause, then the effect* (Cause before Effect).
]

In case of causal ordering, two multicast messages in the *causal relationship* must be considered in the right order from everyone: (m1 and m2 from S1), (m3 and m4 from S2, m1 causes m3). They must reach copies respecting both FIFO and CAUSAL ordering. Many sequences are compatible: (m1 m2 m3 m4), (m1 m3 m2 m4), but *NOT* (m3 m1 m4 m2).

#note[
  *Causal ordering limitations:* Compliance with causal ordering does not catch real-world Internet (USENET) situations that we implicitly take for granted in case of more than one operation. Example: A requests an action to Na; B requests an action to Nb; these actions are not related. C receives first Nb then Na; D receives first Na then Nb — so copies have different internal decisions of scheduling.
]

=== Atomic Ordering

#def("Atomic Ordering")[
  No external relations impose a scheduling, but *the group should act in a coordinated and reasonable way*, where all group members operate in the same order. Atomic ordering guarantees that *all messages are received in the same order by all group members* (so related actions can occur in the same order in all copies).
]

Often *no predetermined order* is likely, so no need of previous agreement, but it is necessary to *dynamically agree on one* — and that order should be the same for all.

#note[
  If a copy C decides to receive first Nb then Na, then *all copies must follow that decision*. Example: Nb may ask to compute on a bank account; Na intends to make a withdrawal. Obviously many different atomic orderings exist that we can consider with group operations.
]

=== Cost of Orderings

#table(
  columns: (auto, 1fr, auto),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Ordering*], [*Description*], [*Cost*]),
  [*No Ordering*], [Each member works freely; no synchronization needed.], [Minimum — free],
  [*FIFO*], [Messages from same sender arrive in send order. Easy via message numbering.], [Low — partial],
  [*Causal*], [Cause-effect relationships from different senders respected.], [Medium — partial],
  [*Atomic*], [All messages received in the same order by all group members. Total/global ordering.], [High — total],
)

#note[
  In a distributed environment, *enforcing orderings is expensive* (coordination between group entities or numbering support) and we tend to enforce it only when necessary.
  - *No ordering* #arrow each group member works in a free and independent way.
  - *FIFO and CAUSAL ordering* are constraints we tend to enforce for some specific events — *partial orderings*.
  - *ATOMIC ordering* is one we tend to enforce on every event within the group — *total or global ordering*.
]

Among many atomic orderings, some can follow CAUSAL and FIFO ordering, some only FIFO, some only CAUSAL, and some of other none of them. *Costs for atomic orderings can be very different*.

== Synchronization

#def("Synchronization")[
  *Synchronization* means to impose *orderings on events* — typically constraints on temporal ordering of some events inside a distributed system. It is necessary to provide a *consistent view* of the system to the entire set of communicating processes.
]

Communication and synchronization are often correlated:
- Synchronizing sender/receiver of a message
- Check on cooperating activities
- *Serialization of access to shared resources*
- N processes in access to a resource (mutually exclusive)

So, *ordering on important events must be enforced*.

=== Clock Synchronization

The classical approach uses *physical time* and *physical clock* — typical on one local environment only. Unique time can be determined if either a unique clock is available on every node, or one clock for any node all in perfect sync. *This is perfectly admissible in concentrated or limited systems, but absolutely not feasible and difficult to be granted in distributed and global environments.*

#def("UTC — Universal Coordinated Time")[
  #kw[UTC] is based on the transmission of the value and on local correction. Some systems are based on a *coordination clock* — a node verifies the time of all group members, computes the average, and distributes it to all as the group time (*Berkeley time*).
]

#def("NTP — Network Time Protocol")[
  #kw[NTP] introduces a protocol based on UTC and on synchronization to achieve an *agreement on clocks*. NTP tries to overcome possible transmission delay of the common time through *statistical filtering policies* based on historic behavior of servers.
  - Starts with a higher *server hierarchy*, where every node transmit time to *lower-level neighbors* (its subtree).
  - The *primary* nodes are more accurate and going farther from the root, accuracy decreases.
]

#note[
  The problem that can occur, by using clocks not perfectly in sync: an event that happened afterwards may be labeled and considered before an event that precedes it in time — this may produce a *wrong time synchronization*.
]

=== Synchronization in Large Systems

Synchronization via physical time clashes with the difficulties of guaranteeing syncing of clocks — high accuracy implies a high overhead and is also prone to errors.

#note[
  *Precision required* to coordinate continuously the clocks, and it is *impossible to avoid conflicts and clock drifting* with limited overhead.
]

Typically, distributed synchronization is *not based on complex algorithms of physical clock agreement* but based on *different strategies* that sync the requirements, focusing only on a *subset* of global system events.

- The idea is to *work on a subset of events* (considering only some *interesting events*) and to create an agreement only on them.
- The assumption of a limiting focus and a reduced group can *limit the overhead and protocol cost*.

=== Synchronization Strategies

Several Distributed Synchronization Methods:

- *Ordering of logical time of Lamport* — use timestamps (time indicator) to label relevant events and to order them #arrow logical clocks and "happened before" relationship.
- *Token passing LeLann ring strategies* — use authorizations and the token can pass in a logical ring to order events.
- *Events based on priority* — use process priority to order correlated events. Used in real-time systems and unfair (*special-purpose systems*).

== Lamport Relationship

In distributed systems, Lamport aims at *ordering some events (not all of them)*, by *excluding physical time*. Only *some events* are considered in the distributed system, with a scenario constituted by processes that have their internal history and can exhibit a behavior based on two kinds of events:

1. *local*: local events
2. *remote*: interprocess events, generated by sending messages from one process to another process (*send / receive events*)

#note[
  The ordering must consider only some 'relevant' events and aims at creating a simple *ordering policy*, on which to eventually establish a *correct synchronization* with *adequate costs* and *not very expensive to implement*.
]

=== Happened-Before Relationship

#def("Happened-Before (#so)")[
  Events ordering for a *set of processes that communicate through message passing* based on cause-effect relationship introduced by process actions:
  1. If a and b are events of the same process and a occurs before b, then *a #so b* (*local order*)
  2. If a is the sending of a message of one process and b the receiving event within another process, then *a #so b* (*communication interprocess order*)
  3. If a #so b and b #so c, then *a #so c* (*transitivity*)

  The relation #so introduces a *partial ordering* in systems events and it exists only among some systems events and not assumed among all events. *Two events are concurrent* iff *not* a #so b and *not* b #so a.
]

#example("Happened-Before Examples")[
  With processes Pa, Pb, Pc and events a1, a2, a3, b1, b2, b3, c1, c2:
  - a1 #so a2, a1 #so a3
  - a1 #so b1, a1 #so b2, a1 #so b3
  - c1 #so c2
  - c1 #so b2, c1 #so b3, c1 #so a3
  - *Concurrent events*: a1 ‖ c1, a1 ‖ c2, a2 ‖ b2, a2 ‖ b3, …
]

The happened-before relationship allows to work in a distributed system in which only #so is enough for ordering. We do not assume a unique global clock (global time), but allow for a *set of local clocks (local time)*.

We assume to work in an *asynchronous environment*, that makes possible any transmission delay for messages, *variable and unlimited*, in principle so higher than any significant possible delay (but *messages are not lost*). We may need several *ordering strategies, also global or total* to synchronize. We organize a *logical time system* built on the #so relationship that is *based on logical clocks* and not on physical clocks.

=== Logical Clock and Timestamp

#def("Logical Clock TS(i)")[
  We need to construct a *clock system (system timestamp)* to assign a simple indicator, a 'number', to order events. The happened-before relationship is only *partial*. We define a function *TS(i)*, a logical time-based function (*timestamp*) that must assign a value to any relevant event.

  If a #so b in the system, then the logical timestamp of events must respect the law: *TS(a) < TS(b)*.
]

#def("Clock Condition (Logical Clock — LC)")[
  Given a and b, if a #so b, then *LC(a) < LC(b)*.

  *NOTE: it is not true that, if LC(a) < LC(b), then a #so b.*
]

Any process P_i has a logical clock LC_i(c) (an integer counter):

- *C1*: For all a and b, if a #so b inside the same process Pi, then LC_i(a) < LC_i(b)
- *C2*: For all a and b, if a is the sending of a message in the process P_i and b the reception in the process P_j, then LC_i(a) < LC_j(b)

Implementation rules:
- *I1*: Every process P_i increments LC_i between any two events
- *I2*: For any sending of a message in process P_i, the message contains a clock as timestamp TS = LC_i(a)
- *I3*: For any reception of a message in process P_j, the process puts the logical clock at the greater value between current clock and timestamp: *LC_j = max(TS_received, LC_current) + 1*

#note[
  *2 clock conditions* and *3 implementation practices*. These rules introduce a *partial order relationship*. There are many concurrent events a ‖ b with equal timestamp.
]

#note[
  "Who doesn't receive, doesn't update" — the #so relationship allows to order events according with a logical cause-effect relationship, but *the sender has initiative* and forces the update the logical clock of the receiver, not its own. It is the receiver that has to update clock to sender, with a transmission eventually.
]

=== Happened-Before is Partial

The #so relationship allows to catch cause-effect ordering of events. But it also makes you assume an ordering of events even not in the #so relationship — *concurrent events in real world* (such as c1 and b1) are considered one after the other … so in sequence.

#note[
  *Ordering and Reality:* The Lamport relationship is a *logical* one and it is *loosely connected with the real world*; it cannot be considered a physical world relationship. Those *who receive messages update their time*; those who do not receive messages may maintain a very low timestamps and are not forced to sync logical clocks (so their timestamps can be very favorable). *Causality problem in clocks*: Two events considered by Lamport in a causal relationship may not be related at all. *Hidden channel problem*: If a process can use an external and non mapped channel to communicate (*hidden channel*), that can lead to a situation that does not respect cause/effect relationship. The effect in real world can have a timestamp lower than the one of the cause.
]

=== Total Ordering

Sometimes it is necessary to introduce some *conventional total order relationship* among all process events in the system. These cases are dealt with by a *global order relationship* #so between all system events that is based on logical clock and on the partial ordering of #so.

#def("Total Order Relationship #so")[
  Given a is an event in process Pi and b an event in process Pj, then *a #so b* iff:
  - R1: LC_i(a) < LC_j(b), or
  - R2: LC_i(a) = LC_j(b) and P_i < P_j

  The total ordering means that in case of events of the same logical clock, *there is an order between all process events*. It is possible to use #so to define a univocal and simple ordering to create synchronization upon.
]

#note[
  The #so relationship *orders any pair of events*. It makes possible to consider two events one after the other while they are instead concurrent in real world. Example: c2 and b2 are managed as in sequence, by considering first process Pb, then Pc. However, *Happened-before #so is only one way and not bidirectional* — given a and b, if a #so b, then LC(a) < LC(b), but it is not true that if LC(a) < LC(b), then a #so b. So you cannot infer that LC(a) < LC(b) means a #so b. Sometimes we need a closer relationship between Lamport model and reality, extending the clock models — toward a *two-way relationship* and *bidirectional ordering via some implementation*.
]

=== Vector Clock Ordering

There are other strategies — it is possible to consider *vector logical clocks* or *Vector Clocks* to order events in a process set.

#def("Vector Clock")[
  *Processes must maintain a vector of all known clocks of processes and use that in communication*. Every process keeps its timestamp and a vector V_i[k] of integers of a dimension of the number of processes. A vector clock element V_i[k] contains information on *what a process knows about the clocks* of other processes.

  The process P_i keeps:
  1. V_i[i] — its own timestamp (index i)
  2. V_i[k] — the timestamp of any other process P_k at its knowledge
]

=== Vector Clock Protocol

The Vector clock update protocol:
1. For every process P_i, *increments V_i[i]* between two events
2. For any sending of a message in process P_i, the message contains the *whole vector clock* at best knowledge of P_i after incrementing its own: *V_i[i] = V_i[i] + 1*
3. For any reception of a message in process P_j, the process P_j increments its own V_j[j] = V_j[j] + 1 and updates its vector according to: *V_j[k] = max(V_j[k], V_i[k])*

The receiver obtains information on the logical time of the sender process and also on time that it knows of all others. *Vectors clocks allow a better information propagation and permits a wider information exchange and diffusion* (sometimes matrices are used).

#note[
  The logical clocks of the receivers are updated when a message is received. The main cons is that events not in the #so relationship can be taken as if they were. The vector clock protocol instead *pays the cost* of the propagation of the entire vector at the receiver and *requires adjustment* of the entire vector at the receiver. *With vector clock algorithms*: the events in #so are recognized to be in *cause effect relationship*, and the events not in that relationship, i.e., concurrent events ‖, are recognized *not to be in the #so cause-effect sequence*.
]

#extra[
  With vector clocks we can identify if two events are *in a real cause-effect relationship*. Not only events in relationship are tagged and ordered, but other events that are not causes/effects are recognized as such. Concurrent events in real world (c1 and b1, a1 and c2, …) are *not considered* in the cause-effect relationship.
]

== Mutual Exclusion and Synchronization

The simplest synchronization case is a set of processes that have to access a *resource in a mutually exclusive way*. We assume that every process must access the resource for a limited time and must release it after usage.

*Objectives:*
- *Safety*: only one process at a time can have access to the resource
- *Liveness*: every process that has done a request receives the access after a limited delay
- *Fairness*: different requests must be managed by a fair policy

#note[
  We *exclude fixed priorities* that are unfair and can cause starvation.
]

=== Centralized Coordinator

An approach based on a single central *coordinator process*:
- An *approach completely centralized* considers a unique coordinator process known to all other processes (all participants must not know each others — C/S model, but they know the coordinator)
- Every process that intends to access the resource sends the request to the *coordinator* and after usage, *notifies it*
- The coordinator process decides the scheduling of resource accesses by using its policy to grant mutual exclusion (FIFO management or others)
- We assume that the coordinator receives all requests sent and queued in a reliable way (but with any delay)

=== Resource Coordinator Protocol

#def("Resource Coordinator Protocol")[
  1. A process when it intends to access to the resource *sends a request message* (_request_) to the coordinator
  2. The coordinator serves its request queue and it is free of deciding the request to reply to (*reply*). Obviously, it must send only one *reply* to one request at a time (typically FIFO)
  3. When receiving the *reply*, the process can use the resource and at the end, must send a *release message* to the coordinator, that can decide to reply to another request, etc., etc.

  *3 messages for every access to the critical section.*
]

#note[
  There are several *disadvantages* stemming from the centralized and unique role of the coordinator: the case of coordinator fault and of its potential unfairness; differentiated delays in reaching the coordinator.
]

=== Lamport Synchronization

#def("Lamport Synchronization")[
  Lamport proposes a *decentralized solution without single failure points*. A set of N processes that must access to a single resource in mutual exclusion, without assuming any centralized role and trying to grant that requests are served in order (in a *fair* way). Participant processes must *only examine their request queue*. Processes exchange messages between each others to obtain synchronization and must use *Lamport clock relationship* (up to #so relationship).
]

*Assumptions:*
- The connection between processes is *complete and direct*
- Messages between processes *must arrive in FIFO order*
- Messages can be delayed but *not lost*

=== Lamport Protocol

Use of logical clocks and Lamport relationship. Every process has a *local queue* of received messages, in which messages are *queued in order of timestamps* (#so). For every process, the local queue initially contains the message T_0:P_0, lesser than every clock in the system (clock is considered a logical time, specified by the couple of an integer and the process identity that owns it). Every message has a timestamp that depends on both components (*process and logical clock*) to allow fair total ordering.

A process that decides to access to a resource must execute a *global coordination protocol*. Every process must know any other one and faults are not expected (N processes in order of index compose a *static group*).

*Protocol for the group:*
1. The process P_i sends the *request message* T_m:P_i to every process (even in its own queue) to signal its intention to access to the resource
2. At message T_m:P_i reception (already in its queue), the process P_j sends a reply with its updated timestamp (Lamport #so)
3. The process P_i can use the resource *if in its local queue*:
   - It has the *request T_m:P_i ordered before any other request* of other processes (#so relationship)
   - It has at least *one message coming from any other process with a timestamp successive* to T_m:P_i
   At the release, P_i removes the messages from its queue and sends a *release message* with its timestamp to every process
4. Every process P_j receives the release request and removes the request message from its queue

=== Lamport Synchronization Properties

That solution grants that every process that executes the protocol can receive the resource with a limited time delay, *if every process respects the constraints*. Let us note that the process that has requested to access, enforces and waits a coordination with any other participant.

- *Every request sent message requires a response from all others*
- While waiting for messages from one process, requests may come from other processes that may precede the concurrent one. Once they arrive, they are queued and sorted by timestamp
- Every process queue is ordered, and so a process can pass only when 'previous' requests have been served already
- At least (N-1) messages sent and the same number received before entering — *(N-1)* to exit

*Synchronization worst case:* when all processes want to access the resource at the 'same' time — in case two processes make a request, they separately agree on the fact that first to enter is the one with the lower timestamp so there cannot be conflicts. The algorithm occurs *without centralization*, but in a *completely distributed way*.

For every action on the critical section, the number of exchanged messages is (considering a possible broadcast as N-1 messages, unless you can obtain lower cost): *Number of messages 3 \* (N-1) or N-1 and 2 broadcasts*. We have a *high cost* due to decentralization. Heavy assumptions on the *static group and no faults*.

=== Ricart-Agrawala Protocol

#def("Ricart-Agrawala (R.A.) Protocol")[
  1. Process P_i sends the *request message* T_m:P_i to any process (even in its queue) to signal its intention to access to the resource
  2. At message T_m:P_i reception the process P_j:
     - *Sends an immediate approval reply* if it does not *need the resource* or if the requester has a *higher priority*
     - *Delays its approval reply* if it is *using the resource* or it has already asked to enter and it has a higher priority
  3. Process P_i accesses the resource only if it receives N-1 *approval messages*
  4. At release, process P_i must send approval to all arrived requests
  5. *The requests (and replies) are deleted after approval*

  Only one process can have N-1 approval responses and only one process can access the resource at a time.
]

For every action in the critical section, the number of exchanged messages is (a possible broadcast costs as N-1 messages): *Number of messages 2 \* (N-1)*. So, there are N-1 messages from requester and N-1 from everyone else. Difficult to foresee a coordination at lower cost.

These algorithms are based on *variations of Lamport relationship*:
- Are *completely distributed* (no unique manager)
- Are *fair* and *free from deadlock* and *starvation*
- They *may* have *high costs* in terms of exchanged messages for coordination
- Heavy assumptions of messages *not lost* and *static group* without faults

== Atomic Multicast

Distributed implementation of *atomic multicast* can be less centralized than the obvious one with a unique coordinator.

#def("CATOCS")[
  #kw[CATOCS] (*CAusal and Totally Ordered Communication operations Support*) based on a by-need dynamic *coordination of a set of managers* that decide internally the request order. The group *does not* have a *unique central manager*, but coordinates on need and creates a unique vision: it is possible to have a manager selected for every request that negotiates with others and obtains all the requests to synch with others.
]

*Realization* is not so scalable and *implementations* of different efficiency (?) or *at least efficient only in specific cases*. Availability of a *broadcast at a low level* can solve many implementation problems and *enhance efficiency* (we also need a support that grant the assumption of not losing messages, connecting all processes, etc.).

=== ISIS — Atomic Multicast

#extra[
  *ISIS* appeared in the 90s for CATOCS in UNIX. ISIS is system based on groups with *active replication* and with necessity of a vision with *different degrees of coordination* of group components. The system obtains coordination *with many different forms of group multicast (called broadcast) for the same group*.

  Many different *multicast forms* are available (BCast):
  - *FBCast* (FIFO BCast)
  - *CBCast* (Causal BCast)
  - *ABCast* (Atomic BCast)
  - *GBCast* (Group BCast)

  Providing also support to the case of no copy coordination. Any operation need a manager, typically *dynamically chosen* according to any kind of policy (vicinity, rotation, …).
]

=== ISIS ABCast

#def("ISIS ABCast (Atomic BCast)")[
  ABCast cost: *3\*(N-1)*. CATOCS uses a queue for every corresponding component of the group and Lamport relationship. Messages are tagged with an *initial arriving timestamp* and are only considered (and processed) if labeled *as final* in the *right order for Lamport* relationship.

  *Every arrived message requests a coordination phase of the manager* (and hold-back) to determine the final timestamp to be used by all copies to execute in the correct order. A group should be capable of *operating with all the ordering policies for any request*.
]

The coordinator receives the message:
- *Labels it and sends it to all others* (with its timestamp). Anyone else labels the answer with its timestamp based on its time (clock) and sends the answer back with its timestamp.
- *Labels it as final* with the received highest timestamp (is that choice and policy necessary?)
- *Resends the message with the final timestamp* to all others to communicate the final decision

Any in the group has all finalized messages in the same order in its queue so it can drive in the same order the execution. *Problems: delay and overhead — cost in messages of 3 \* (N-1)*.

ISIS ABCast achieves the *total ordering of messages* for a group toward a *coherent group vision*:
- The group must reach an *internal agreement* that can also be *not compliant with the external timestamping* (not respected)
- Group members cannot operate on one request until it is sure that the message:
  - *Has been seen also by everyone else* (arrived to anyone)
  - *Has been ordered with respect to any other message* for the group (arrival order)

The group is achieving consistency in operation ordering and, so, *atomicity and global order is guaranteed*. And if we must guarantee causal multicast? How do we do that? It is more or less complex.

=== ISIS CBCast

#def("ISIS CBCast (Causal BCast)")[
  CBCast is a *partial ordering*. CBCast tends to consider only *some external events* that are to be *ordered with one another*; all other events can be ordered differently by group components (so limiting costs and coordination).

  ABCast tends to impose an order based on timestamping decided *inside the receiver group* (internal event ordering strategy). CBCast requests a behavior *decided outside the receiver group* that must detect *cause-effect relationships* by inferring it from *timestamps arriving from outside* (external event ordering).

  The Causal Broadcast assumes a coordination between senders that must update their "logical clock" and send information to receivers (requests queued by *sender timestamps*). Group members must respect that external ordering.

  *If a cause would not reach the group before processing the effect? Either undo or error are necessary (!!).*
]

=== ISIS GBCast

#def("ISIS GBCast (Group BCast)")[
  The group of processes can *dynamically change in cardinality*, so it is possible to join or to leave the group for different reasons (possible group inconsistencies and problems). For every concurrent multicast, the message arrives in two states:
  - To every member *before* group changing
  - To every member *after* a group changing

  For a consistent ordering of any BCast, *either before or after* we need to define a new operation for tracking the dynamic behavior of the group. GBCast makes possible to order all BCasts: any *GBCast message must be either received after every previous BCasts* in the processes (or before — in a consistent way).

  The GBCast was introduced to design a correct *dynamic grouping*, with no need to stop and reconfigure and work no stop with no problems. GBCast requires an *automatic monitoring support* for *group variation events* (any insertion and extraction trigger one GBCast). When anyone detects a failure of a copy (or a new copy to be inserted), the *GBCast is issued to all copies* to make them aware of the reconfiguration. The *group support* is in charge of invoking it. Every group member uses a *table* for other members: that table is updated by any GBCast (so all other BCasts can be aware of it and consistently ordered).
]

=== JGROUPS — Reliable Multicast in Java

#extra[
  *JGROUPS* — Java Support for reliable multicast and for group concept (Designed in Java and with user defined proprieties). JGROUPS starts with a *transport level*, either not connected or connected, and it is also possible to work with JMS (Java Message Service) for message specifications. The goal of JGROUPS is *group and message delivery ordering*: it proposes a *reliable* implementation, intended as delivery with *message retransmission*, with most common different ordering: *Atomic, FIFO, Causal*, etc. For the group property, groups are dynamic and managed in membership: *every group element benefits from group messages*, both from outside that from inside the group. Possibility of security, like encryption and other secure support protocols.
]

== Apache ZooKeeper

ZooKeeper is a *Distributed Coordination Service*: it provides group services (synchronization, configuration, naming) leveraging *replication over several znodes* with ordering semantics (*FIFO, Atomic, Causal*). This makes it a natural building block for the CATOCS-style coordination described in this chapter.
#v(-0.7em)
#note[
  The full ZooKeeper architecture (znodes, leader election via majority voting, passive replication, reads/writes model, and how it is used as a coordination backbone such as in Kafka) is covered in the #link(<ch12-zookeeper>)[_*Replication for Dependability* chapter_].
]

== Token-Based Synchronization

To overcome the problem of one *central coordinator*, the synchronization can be deployed by changing the role of the coordinator and varying the responsibility. The synchronization is *associated with a token*, dynamically passed between N different participants.

#def("Token Ring")[
  The nodes are organized in a *logical ring* (ON), where every node knows the next one (successor and predecessor). Every node acts as the group manager when it owns the *token* that must keep for a while, then must pass to the next one. The token *circulates among* the N different participants (*time of comparison of token*).
]

=== Synchronization in a Ring

A *logical RING* connects all N participants and the token current owner is the manager of Mutual Exclusion.

*Protocol to access the resource*: who has the token:
- Verifies that it is the expected recipient
- *Uses the token* for a time period with a maximum detention (it manages ME to access resources for all N nodes)
- After detention, forwards it to the following node

If the token moves in the ring in *one direction* only:
- *Only one process at a time can access ME resources*
- *No conflicts can arise*
- *Starvation is not possible*

Number of messages *N* for a complete token turn in the ring. *The working scheme is typically proactive: the token must circulate even no requests occur.* Problem if the token is lost (*failure of the node that has it*).

=== Recovery in a Ring

The RING architecture allows to execute *very simple recovery algorithms* in case of *single fault with no token problem*. Obviously, any node must execute some local neighbor correctness checks to *re-create the ring and overcome failure in case of neighbor failure* (node 5 shortcut). Any node must also know the further following/preceding node.

#note[
  Node 4 and 6 check its successor or predecessor and re-establish the local situation of the ring. No problem to the token is caused.
]

=== Token Recovery in a Ring

The case of losing *the token* or having *more than one* must be avoided (since they are unsafe for ME):
- In case of *failure of the node that holds* the token, it is necessary to *regenerate it*
- *Token loss must be prevented* (due to fault on manager node)

Every node, taking part in the ring, activates a *timeout interval* that is reset at token return. In case the *timeout* is triggered, the node starts a *recovery procedure* to regenerate the token. Note that *more than one node can start the recovery procedure*.

=== Token Regeneration Election

The RING architecture shows very simple recovery strategies in case of potential token loss. Obviously, any node is in charge of monitoring and attempting to start a recovery token protocol. Several timeouts may trigger the attempts of several nodes: use of *node priority* for the decision (*Election protocol*).

In this case, the token can be regenerated only by the node with highest priority among the considered ones (here the number 1). The *election token* becomes the new token.

== Election Protocols

#def("Election Protocols")[
  The *election protocols* are used any time an *agreement among participants must be found without a predefined policy*. They are typically necessary in case of *fault* and *recovery* in a group to obtain distributed and easy agreement on a decision. In many cases, it is based on a *potential static order of participants* (COST of the ELECTION PROTOCOLS?).
]

=== Bully Algorithm

Every participant P_i that detects necessity of an election (event local to a recovery toward a management role can do it). Three types of messages are considered:
- message *Election*
- answer *Answer*
- announcement *IAmCoordinator*

*How many phases there are in election protocols?*

#def("Bully Protocol")[
  Every participant can start the *election at any time*, triggered by some timeout events. It sends an *election message* to *processes with higher priority* (Election). In case of election message from a lower priority process, sends an *answer* to block and *a new election is started*.

  After some time, coordination messages from superior nodes can arrive. If they arrive, the low priority process stops. If *no message arrives* from higher priority processes, it becomes a coordinator and signals its presence with the message *IAmCoordinator* to lower priority nodes that are advised.

  Every participant can start the election and *several rounds can go on*. Example: 4 starts (not to all), blocked by 5 and 6 OK answer, then 5 goes on blocked by 6, 6 wins.
]

=== Election in a Ring

*Election protocol* to decide who must become the manager (with a unique new token) based on *static priority of processes*:
- At timeout, the process creates an *election token* (ET) with his name and enters an *election state* until the token returns
- If the process receives the normal token before the generated ET is back, the election is considered useless and terminated (*ET destroyed at return*)
- If the process receives an ET from another process, it is registered on an *election list* together with *identity of process* that generated it, and the ET is passed forward in the ring
- If it has already generated an ET token, it verifies the *static priority* and decides who has *highest priority* in the election
- If the process receives its ET, it removes it and verifies the registration list. The process generates a new token, only if it is the node with *minimum index (top priority)* inside the registration list

#note[
  The election token becomes the new token. Election in a ring shows very simple recovery strategies in case of potential token loss.
]

== Global State

In a distributed system it is sometimes necessary to coordinate and support a *global state associated with the current situation*. The state can be successively used to *replay the system from a previous point and restart execution in a safe situation*.

The main point is to *locally coordinate the event of single component parts* to compose a *unique consistent view*, without paying too much for the coordination.

#def("Global State Use Cases")[
  - *Checkpoint for recovery, distributed garbage collector*
  - Let us assume an *asynchronous model* with processes on different nodes that reciprocally can send messages (*channels are only one-way communication between processes*). Processes can execute *locally* and *exchange messages* via channels that must grant that any node must reach any other one, via hops (*no partitioning*).
]

Nodes have both *In queues* and *Out queues*. The interconnection must make possible the *reachability of any node from any other one* (no split) — *NO PARTITIONs*.

=== Global States Composition

The *global state* stems from the *private states of participant processes*, but also should keep into account *exchanged messages (currently in exchange)* between different processes. The main point is to record *only the whole needed information* to avoid a situation in which you are losing any content. *The snapshot must be taken while processes are running, so it must minimally intrude in the normal execution and be safe*.

*Distributed snapshot:* compose the needed local information in a unique meaningful state but acquiring with a *distributed perspective* with a minimal coordination. Recall that we must grant a *safe global vision* in a consistent way. We have to assume a network connecting all processes with channels in such a way that there are *no partitions and any node can reach (via routing) any other node*.

=== Global States Consistency

#def("Consistent Cuts")[
  *Consistent cuts* in a distributed system — not all states are admissible and safe for snapping the shot.
  - *Consistent cuts (a)* represent a safe global state
  - *Inconsistent cuts (b)* produce an unreasonable global state and should be avoided

  Consistent cuts in distributed system *exclude unreasonable situations* from the operation point of view (losing messages or duplicating them).
]

#example("Consistent vs Inconsistent Cut")[
  *Consistent Cut — Message m3 from P1 to P2*: In case of the m3 message, where we included the sending state in the snapping of P1, we must *record the arrival within the state* of the receiving node P3 — input messages must be saved.

  *Inconsistent Cut — Message m2 from P2 to P3*: In case of messages where we record the arrival in the state of the receiver node, but the sending in the sender node was not recorded yet. This type of recording or cut is *inconsistent*, because it embeds the message in the receiver state, but the message has not been recorded in the sender state. In case of replay, the sender will forcedly resend the message that causes the effect of a *double reception* in the receiver and an *unsafe behavior* (this event must be avoided).
]

=== Global State via Snapshot

#def("Distributed Global Snapshot")[
  *One node starts a global snapshot*. All nodes play a local algorithm to organize the local savings. The global snapshot consists of all saved states by all nodes. Any node keeps its *internal state* (checkpoint) and the exchanged relevant *compatible messages (channels state)*. *Nodes do the snapshot while normally working*.

  *OBJECTIVE*: to propagate a state *snapshot wave* from processes that individually record the local state; the wave expands to cover the entire system (*assumption of complete reachability*). The global snapshot is saved on any node when the wave has propagated to all nodes, so to be re-started you need a similar propagation for replay.
]

Every process is characterized by:
- *IN and OUT channels* in FIFO mode and enough connections (every bidirectional channel #arrow is separated into two channels)
- A *state and a color*: no snapshot, snapshot on (or over)
  - *white* — initial state (before snapshot)
  - *red* — successive state (doing snapshot or completed)

*A marker management algorithm*: markers are messages to produce the snapshot propagation. Every process receiving a marker or deciding a snapshot makes a *local state save* and sends *one marker message* via any OUT channels. The process that receives the marker becomes *red*. *The markers pass through channels in FIFO message ordering*.

=== Distributed Global Snapshot Algorithm

Any node has (more) input and (more) output channels. One node starts the snapshot and all nodes makes the same decentralized algorithm while normally going on executing.

Every process is characterized by IN and OUT channels in FIFO mode and enough connections. A state and a color: no snapshot, snapshot on (or over) — white = initial state (before snapshot); red = successive state (doing snapshot or completed).

*Every process receiving a marker or deciding a snapshot* makes a local state save and sends one marker message via any OUT channels. The process that receives the marker becomes red. The markers pass through channels in FIFO message ordering.

Steps:
- *a) After a)*
- *b) The process Q sends out new markers to output queues and start recording all incoming messages from open input channels*. These messages are meanwhile processed and consumed.
- *c) The process Q receives a marker on a specific input channel (except the one where it arrived first that is already closed)*
- *d) The process Q closes the registration for that channel* (but messages continue to be served)

When a process ends the snapshot on all input channels, it has *completed the node snapshot* (state plus all messages saved from input channels).

=== State as Union of Local State

*Distributed Global Snapshot summary*:
- Every process can start a snapshot (checkpoint of local state) and must send the marker on every out channel
- The snapshot global state result composed by:
  - *Local states* of every process
  - *State of input connection channels* (messages sent by senders and recorded by receiver)
  - For the *process state*, it is created when a process starts the snapshot or receives a marker

Every process that receives the marker makes the *checkpoint* of its local state and sends a *marker message* in any output queue. For the *channel state*, every incoming message is recorded until that channel gets a marker that *signals the end of the information* to be recorded for that channel. The registration in that channel can then be closed (*checkpoint*).

The *global state* is composed by:
- *Local state* of every process
- *State of connection channels* (messages sent)
- *bb* messages before and *rr* messages after the snapshot
- *br messages to be recorded in the channel state*
- *rb messages not consistent* (avoided by the protocol since the marker will pass before other messages and makes the node red before the reception of other message)
- Messages as rb are avoided by protocol construction

=== Distributed Snapshot Management

The process P can start a snapshot and request the collaboration of every other process that record their processor states and channel states. *How it is all recorded and where?* Every process that ends can send the state to the process that started the snapshot or to a defined node P devoted to management collection and eventual replay (can also keep in at its own site).

*About snapshots management:* At first snapshots are intended as rare events inside the system because of the cost.

#note[
  Open questions: What happens if *more snapshots are executed together*? How is it possible to execute more snapshots concurrently and to distinguish them? Are they compatible and how?
]
