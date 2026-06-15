#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= GROUP ISSUES AND POLICIES
#extra[
  Package: Group Issues and Policies - `8 - Group issues and policies 26.pdf`
]

== Partitioning and Groups

#def("Partitioning and Replication")[
  - *Partitioning*: several entities must be in charge of the whole function to grant *scalability* of services and support.
  - *Replication*: several entities must be in charge of the whole function to grant *availability* of services and support.

  The two aspects are strictly coupled and have both static and dynamic dimensions.
]

== Group Communication

#important("Communication Semantics")[
  *Semantics deeply depends on choices made about:*
  - #hl[*Global solicitation* vs. *Selective solicitation*] #swarrow whether the message is sent to all group members or a chosen subset.
  - #hl[*Positive confirmation* vs. *Negative confirmation*] #swarrow whether the system acknowledges successful delivery or only signals loss.
]
#v(-0.7em)
#why([*multicast matters*])[
  Multicast is essential whenever the same information must reach a group of processes:
  - *Fault tolerance*: replicated servers must all receive the same requests in the same order so they stay consistent.
  - *Object location*: locating a resource that may reside on any node in the group.
  - *Data replication and streaming*: pushing updates to all replicas efficiently with one send instead of N unicasts.
  - *Coordinated updates*: changing the state of multiple group entities atomically.
  - *Multiple concurrent senders*: several producers pushing events to the same consumer group.
]
#v(-0.3em)
The #kw[multicast] action could be made *atomic*, but implementations can associate different and more suitable meanings. The two aspects of multicast semantics can be untangled:

- #hl[*Reliability*: concerns whether individual group members receive a message]:
  - *Reliable* #swarrow guaranteed delivery
  - *Unreliable* #swarrow only 1 attempt (Chorus model)

- #hl[*Atomicity*: concerns whether *all* group members receive the message, possibly with consistent ordering] across multiple actions.

== Reliable Multicast

#def("Reliable Multicast")[
  Reliability *can be achieved* by tolerating: sender crash, receiver crash, or message omission - through fault *identification* and *recovery* via monitoring. Recovery requires checking every ongoing communication, performing retransmissions, removing failed components, and re-admitting recovered ones.
]

=== Implementation Decisions

Key implementation choices for reliable multicast:

- *Dispatch all messages* to group members support and *delay* before passing them to the application, introducing *timeout* and *retransmission* (_who checks the protocol?_).
- _*How long* to wait?_ #swarrow Problems with efficiency/latency.
- _*If controller fails?*_ #swarrow "Quis custodiet ipsos custodes?" (Juvenal/Giovenale)

#def("Hold-Back")[
  In the #kw[hold-back], the support holds a message until it is sure that all previous others reached the destination in order.
]
#v(-1em)
#note[ In *dense numbering*, a message is delayed until all previous ones appeared.
  #extra[#so message 3 must appear after message 2 (the order is kept but latency increases).]]
#v(-0.7em)
#def("Negative Acknowledgment (NAK)")[
  In #kw[negative acknowledgment], the support sends a *negative ack only in case of losses*, to identify those events in a selective way, avoiding unnecessary positive acks for every message.
]

== Multicast Ordering

Ordering policies for group multicast form a spectrum from cheapest (no ordering) to most expensive (atomic/total ordering).

=== No Ordering

#def("No Ordering")[
  #kw[No ordering] is exactly what states: multicast messages coming from any sending process to all receivers can present a different ordering in any copy. It is *very easy to support* and copies do not have to be synchronized in any way (they are free to operate on their own).
]

=== FIFO Ordering

#def("FIFO Ordering")[
  With #kw[FIFO ordering] from the *same sending process* to *all receivers*, a sequence of successive multicast messages is received in the same order. Two multicast messages from the *same sender* reach any group member in the same order.
]

- (m1 and m2 from S1) and (m3 and m4 from S2) each reach everyone
- Respecting sending order of the two senders, many sequences are compatible: (m1 m2 m3 m4), (m1 m3 m2 m4), (m1 m3 m4 m2), …
  #extra[This means that single sender messages have to be ordered between them, but every other message from other sender can be in the middle of the sequence in any position/order. The important is to keep a relative logical order (similar concept of lamport clocks).]
- An #hl[easy way to achieve FIFO is *message numbering* for any specific sender].
#v(-0.3em)
#note[
  FIFO only constrains ordering from the *same sender*. With multiple senders: A sends Na; B reads it and sends Nb; C may receive Nb before Na. We need to also consider *cause/effect relationships across different senders* - which FIFO alone cannot capture.
]

=== Causal Ordering

#def("Causal Ordering")[
  #kw[CAUSAL ordering]: events that are correlated with a cause-effect relationship outside the group must be delivered to everyone in the right order. *First the cause, then the effect* (Cause before Effect).
]

In case of causal ordering, two multicast messages in the *causal relationship* must be considered in the right order from everyone: (m1 and m2 from S1), (m3 and m4 from S2, m1 causes m3). They must reach copies respecting both FIFO and CAUSAL ordering. Many sequences are compatible: (m1 m2 m3 m4), (m1 m3 m2 m4), but *NOT* (m3 m1 m4 m2).

#note[
  *Causal ordering limitations:* Compliance with causal ordering does not catch real-world Internet (USENET) situations. Example: A requests Na; B requests Nb - these actions are unrelated. C receives first Nb then Na; D receives first Na then Nb: so copies have different internal decisions of scheduling. Causal ordering still does not impose a *total* order among unrelated messages.
]

=== Atomic Ordering

#def("Atomic Ordering")[
  No external relations impose a scheduling, but *the group should act in a coordinated and reasonable way*, where all group members operate in the same order. Atomic ordering guarantees that *all messages are received in the same order by all group members* (so related actions can occur in the same order in all copies).
]

Often *no predetermined order* exists, so there is no need for previous agreement - it is only necessary to *dynamically agree on one*: and that order must be the same for all.

#note[
  If a copy C decides to receive first Nb then Na, then *all copies must follow that decision*. #extra[Example: Nb may ask to compute on a bank account; Na intends to make a withdrawal. Obviously many different atomic orderings exist that we can consider with group operations.]
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
  [*No Ordering*], [Each member works freely; no synchronization needed.], [Minimum (free)],
  [*FIFO*], [Messages from same sender arrive in send order. Easy via message numbering.], [Low (partial)],
  [*Causal*], [Cause-effect relationships from different senders respected.], [Medium (partial)],
  [*Atomic*], [All messages received in the same order by all group members. Total/global ordering.], [High (total)],
)
#v(-0.7em)
#note[
  FIFO and CAUSAL are *partial orderings* - enforced only for some events. ATOMIC is a *total ordering* - enforced on every event. Costs for atomic orderings vary widely: some atomic orderings also satisfy causal and FIFO, others satisfy only one or neither.
]

== Synchronization

#def("Synchronization")[
  *Synchronization* means to impose *orderings on events*: typically constraints on temporal ordering of some events inside a distributed system, to provide a *consistent view* to the entire set of communicating processes.
]

=== Clock Synchronization

The classical approach uses *physical time* and *physical clock*, but in distributed environments a unique global clock is neither feasible nor reliable. High accuracy implies high overhead and is prone to clock drift.

#def("UTC: Universal Coordinated Time")[
  #kw[UTC] is the global reference time standard, maintained by atomic clocks. In a distributed system, nodes synchronize to UTC by receiving time broadcasts (radio, GPS, or internet servers). However, network delay introduces uncertainty: by the time the time value arrives, it is already slightly stale. The *Berkeley algorithm* handles this locally: a coordinator node polls the clocks of all group members, computes the average, and distributes correction offsets to each node, avoiding the need for any node to have an external time source.
]
#v(-1em)
#def("NTP: Network Time Protocol")[
  #kw[NTP] is the standard internet protocol for clock synchronization, designed to keep machines within a few milliseconds of UTC. It organizes servers in a *stratum hierarchy*:
  - *Stratum 0*: primary reference clocks (atomic clocks, GPS) - not on the network directly.
  - *Stratum 1*: servers directly wired to stratum-0 devices (most accurate).
  - *Stratum N*: servers synchronized from stratum N-1; accuracy degrades with each hop.

  The core problem is that a time value is already stale by the time it arrives over the network. NTP compensates by exchanging *4 timestamps*: *T1* (client sends request), *T2* (server receives it), *T3* (server sends reply), *T4* (client receives reply). From these it computes:
  - *Round-trip delay*: $(T 4 - T 1) - (T 3 - T 2)$
  - *Clock offset*: $(T 2 - T 1 + T 3 - T 4) \/ 2$

  NTP queries *multiple servers simultaneously* and applies statistical filtering to select the most reliable ones (discarding outliers with high jitter or inconsistent offsets). Clock corrections are applied *gradually (slewing)* - never as sudden jumps - to avoid disrupting running applications.
]
#v(-1em)
#note[
  When clocks are not perfectly in sync, an event that actually happened later may receive a lower timestamp, violating cause-effect ordering. This is precisely why *logical clocks* (Lamport, vector clocks) are preferred over physical clocks in distributed systems: they depend on message passing, not clock accuracy.

  Distributed synchronization is therefore *not based on physical clock agreement*, but on *different strategies* focusing only on a *subset of global events* - limiting overhead and coordination cost.
]

=== Synchronization Strategies

Several distributed synchronization methods:

- #hl[*Ordering of logical time of Lamport*: use logical timestamps to label relevant events] and to order them #arrow logical clocks and "happened before" relationship.
- #hl[*Token passing LeLann ring strategies*: use authorizations and the token can pass in a logical] #hl[ring to order events].
- *Events based on priority*: use #hl[process priority to order correlated events]. Used in real-time systems and unfair (*special-purpose systems*).

== Lamport Relationship

In distributed systems, Lamport aims at *ordering some events (not all of them)* by *excluding physical time*. Only *some events* are considered - local events and *remote* interprocess events (send / receive) - with the goal of creating a simple ordering policy at adequate cost.

=== Happened-Before Relationship

#def([Happened-Before (#so)])[
  #kw[Happened before] (#so) is based on cause-effect relationship introduced by process actions:
  1. If a and b are events of the same process and a occurs before b, then *a #so b* (*local order*)
  2. If a is the sending of a message of one process and b the receiving event within another process, then *a #so b* (*communication interprocess order*)
  3. If a #so b and b #so c, then *a #so c* (*transitivity*)

  The relation #so introduces a *partial ordering* in system events - it exists only among some events, not all. *Two events are concurrent* iff *not* a #so b and *not* b #so a.
]
#v(-1em)
#example("Happened-Before Examples")[
  With processes Pa, Pb, Pc and events a1, a2, a3, b1, b2, b3, c1, c2:
  - a1 #so a2, a1 #so a3
  - a1 #so b1, a1 #so b2, a1 #so b3
  - c1 #so c2
  - c1 #so b2, c1 #so b3, c1 #so a3
  - *Concurrent events*: a1 ‖ c1, a1 ‖ c2, a2 ‖ b2, a2 ‖ b3, …
]
#v(-0.7em)
We work in an *asynchronous environment* where transmission delays are *variable and unlimited* (but messages are not lost). We organize a *logical time system* built on the #so relationship, based on *logical clocks* rather than physical clocks.

=== Logical Clock and Timestamp

#def("Clock Condition (Logical Clock LC)")[
  Each process $P_i$ has a logical clock $"LC"_i$ (an integer counter). The *clock condition* states: if $a$ #so $b$, then $"LC"(a) < "LC"(b)$.

  *Note:* the converse is NOT true - $"LC"(a) < "LC"(b)$ does not imply $a$ #so $b$.

  *Conditions:*
  - *C1*: if $a$ #so $b$ inside the same process $P_i$, then $"LC"_i (a) < "LC"_i (b)$
  - *C2*: if $a$ is the sending of a message in $P_i$ and $b$ the reception in $P_j$, then $"LC"_i (a) < "LC"_j (b)$

  *Implementation rules:*
  - *I1*: every process $P_i$ increments $"LC"_i$ between any two events
  - *I2*: for any sending of a message in $P_i$, the message contains a clock as timestamp $"TS" = "LC"_i (a)$
  - *I3*: for any reception of a message in $P_j$: $"LC"_j = max("TS"_"received", "LC"_"current") + 1$
]
#v(-1em)
#note[
  These rules introduce a *partial order*: many concurrent events a ‖ b can share equal timestamps. *Who doesn't receive, doesn't update*: the sender forces a logical clock update on the receiver, not on itself - it is the receiver that must advance its clock upon receiving a message.

  *Limitations of Lamport clocks:* the #so relationship is *loosely connected with the real world*. Processes that never receive messages may maintain arbitrarily low timestamps. *Causality problem*: two events in a Lamport causal relationship may not be causally related at all. *Hidden channel problem*: an out-of-band channel can violate cause/effect ordering - the effect may carry a lower timestamp than the cause.
]

=== Total Ordering

#def("Total Order Relationship #so")[
  Given $a$ is an event in process $P_i$ and $b$ an event in process $P_j$, then $a$ #so $b$ iff:
  - R1: $"LC"_i (a) < "LC"_j (b)$, or
  - R2: $"LC"_i (a) = "LC"_j (b)$ and $P_i < P_j$

  The total ordering means that in case of events of the same logical clock, *there is an order between all process events*. It is possible to use #so to define a univocal and simple ordering to create synchronization upon.
]
#v(-1em)
#note[
  The #so relationship *orders any pair of events* - even concurrent ones in the real world.
  #extra[Example: c2 and b2 are managed as in sequence, by considering first process Pb, then Pc. However, *Happened-before #so is only one way and not bidirectional*: $"LC"(a) < "LC"(b)$ does not imply $a$ #so $b$. Sometimes we need a closer relationship between the Lamport model and reality - toward a *bidirectional relationship via vector clocks*.]
]

=== Vector Clocks

#def("Vector Clock")[
  *Processes must maintain a vector of all known clocks of processes and use that in communication*. Every process $P_i$ keeps a vector $V_i [k]$ of integers - one per process - representing *what $P_i$ knows about the clocks* of all others.

  *Protocol:*
  1. For every process $P_i$, increments $V_i [i]$ between two events
  2. For any sending of a message in $P_i$: $V_i [i] = V_i [i] + 1$, then attach the *whole vector clock* to the message
  3. For any reception of a message in $P_j$: update $V_j [k] = max(V_j [k], V_i [k])$ for all $k$, then $V_j [j] = V_j [j] + 1$
]
#v(-1em)
#note[
  *With vector clocks*, the #so relationship becomes bidirectional: events *in* the #so relationship are recognized as having a cause-effect dependency; events *not* in that relationship (i.e., concurrent ‖) are recognized as truly concurrent. This is what Lamport clocks cannot detect - concurrent events in the real world (c1 and b1, a1 and c2, …) are correctly identified as concurrent rather than forced into a sequence. The cost is propagating the *entire vector* with every message.
]

== Mutual Exclusion and Synchronization

The simplest synchronization case is a set of processes accessing a *resource in a mutually exclusive way*. Objectives: *Safety* (only one process at a time), *Liveness* (every requester eventually gets access), *Fairness* (no starvation - fixed priorities excluded).

=== Centralized Coordinator

#def("Resource Coordinator Protocol")[
  A unique coordinator is known to all processes:
  1. A process sends a *request* to the coordinator
  2. The coordinator queues requests (typically FIFO) and sends a *reply* when the resource is free
  3. The process uses the resource and sends a *release* to the coordinator

  *3 messages per critical section access.* Disadvantages: single point of failure, potential unfairness due to differentiated delays in reaching the coordinator.
]

=== Lamport Synchronization

#def("Lamport Synchronization")[
  Lamport proposes a *decentralized solution without single failure points*. N processes access a single resource in mutual exclusion, with no centralized role. Each process maintains a *local queue* of requests sorted by Lamport timestamp $(T_m, P_i)$. Assumptions: complete mesh, FIFO channels, no message loss, static group.
]

*Protocol:*
1. $P_i$ sends *request* $T_m:P_i$ to every process (and enqueues it locally)
2. On receiving $T_m:P_i$, $P_j$ replies with its current timestamp
3. $P_i$ enters the critical section when: (a) its request is *first in its local queue* (#so before all others), and (b) it has received *at least one message from every other process* with a timestamp later than $T_m$
4. On exit, $P_i$ sends a *release* to all; each $P_j$ removes $P_i$'s request from its queue

*Cost:* $3 times (N-1)$ messages per critical section (or $N-1$ + 2 broadcasts). Fully distributed and fair, but heavy assumptions on static group and no faults.

=== Ricart-Agrawala Protocol

#def("Ricart-Agrawala (R.A.) Protocol")[
  Optimizes Lamport by eliminating the release message. On receiving request $T_m:P_i$, process $P_j$:
  - *Immediately replies* if it does not need the resource, or if $P_i$ has higher priority (lower timestamp, or equal timestamp but lower pid)
  - *Delays its reply* if it is currently using the resource, or if its own pending request has higher priority - the reply is sent when $P_j$ releases

  $P_i$ enters the critical section only after receiving $N-1$ approvals. On exit, sends all queued approvals.

  *Cost:* $2 times (N-1)$ messages per critical section. Same assumptions (no faults, static group, FIFO channels).
]
#v(-0.7em)
#note[
  Both algorithms are *completely distributed*, *fair*, *deadlock-free* and *starvation-free*. High coordination cost and heavy assumptions (no message loss, static group) are the main limitations.
]

== Atomic Multicast

Distributed implementation of *atomic multicast* can be less centralized than using a unique coordinator.

#def("CATOCS")[
  #kw[CATOCS] (*CAusal and Totally Ordered Communication operations Support*) coordinates a *set of managers* that dynamically decide the internal request order. The group has no unique central manager but coordinates on demand, with one manager selected per request that negotiates the ordering with others.
]

*Realization* is not highly scalable and is efficient only in specific cases. Low-level broadcast support and reliable message delivery (no loss, full connectivity) significantly enhance efficiency.

=== ISIS: Atomic Multicast

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
- *Labels it as final* with the received highest timestamp
- *Resends the message with the final timestamp* to all others to communicate the final decision

All members have finalized messages in the same order in their queues and execute in that order. Group members cannot operate on a request until it is sure that the message *has been seen by everyone* and *has been ordered with respect to all others*. *Problems: delay and overhead, cost in messages of 3 \* (N-1)*.

=== ISIS CBCast

#def("ISIS CBCast (Causal BCast)")[
  CBCast is a *partial ordering*. It considers only *some external events* to be *ordered with one another*; all other events can be ordered differently by group components (limiting costs and coordination).

  ABCast imposes an order based on timestamping decided *inside the receiver group* (internal event ordering strategy). CBCast requests a behavior *decided outside the receiver group* that must detect *cause-effect relationships* by inferring it from *timestamps arriving from outside* (external event ordering).

  The Causal Broadcast assumes a coordination between senders that must update their "logical clock" and send information to receivers (requests queued by *sender timestamps*). Group members must respect that external ordering.

  *If a cause would not reach the group before processing the effect? Either undo or error are necessary (!!).*
]

=== ISIS GBCast

#def("ISIS GBCast (Group BCast)")[
  The group of processes can *dynamically change in cardinality*, so it is possible to join or to leave the group for different reasons (possible group inconsistencies and problems). For every concurrent multicast, the message arrives in two states:
  - To every member *before* group changing
  - To every member *after* a group changing

  For a consistent ordering of any BCast, *either before or after* we need to define a new operation for tracking the dynamic behavior of the group. GBCast makes possible to order all BCasts: any *GBCast message must be either received after every previous BCasts* in the processes (or before, in a consistent way).

  The GBCast was introduced to design a correct *dynamic grouping*, with no need to stop and reconfigure and work no stop with no problems. GBCast requires an *automatic monitoring support* for *group variation events* (any insertion and extraction trigger one GBCast). When anyone detects a failure of a copy (or a new copy to be inserted), the *GBCast is issued to all copies* to make them aware of the reconfiguration. The *group support* is in charge of invoking it. Every group member uses a *table* for other members: that table is updated by any GBCast (so all other BCasts can be aware of it and consistently ordered).
]

=== JGROUPS: Reliable Multicast in Java

#extra[
  *JGROUPS*: Java Support for reliable multicast and for group concept (Designed in Java and with user defined proprieties). JGROUPS starts with a *transport level*, either not connected or connected, and it is also possible to work with JMS (Java Message Service) for message specifications. The goal of JGROUPS is *group and message delivery ordering*: it proposes a *reliable* implementation, intended as delivery with *message retransmission*, with most common different ordering: *Atomic, FIFO, Causal*, etc. For the group property, groups are dynamic and managed in membership: *every group element benefits from group messages*, both from outside that from inside the group. Possibility of security, like encryption and other secure support protocols.
]

== Apache ZooKeeper

ZooKeeper is a *Distributed Coordination Service*: it provides group services (synchronization, configuration, naming) leveraging *replication over several znodes* with ordering semantics (*FIFO, Atomic, Causal*). This makes it a natural building block for the CATOCS-style coordination described in this chapter.
#v(-0.7em)
#note[
  The full ZooKeeper architecture (znodes, leader election via majority voting, passive replication, reads/writes model, and how it is used as a coordination backbone such as in Kafka) is covered in the #link(<ch12-zookeeper>)[_*Replication for Dependability* chapter_].
]

== Token-Based Synchronization

#def("Token Ring")[
  The nodes are organized in a *logical ring* where every node knows its successor and predecessor. The node owning the *token* acts as the group manager for Mutual Exclusion: it holds the token for a bounded time period, uses it to access resources, then passes it to the next node. *N* messages are needed for a complete token turn.
]

*Protocol*: the token holder verifies it is the expected recipient, uses the resource for a maximum detention period, then forwards the token. Since only one process holds the token at a time: no conflicts, no starvation. *The scheme is proactive: the token circulates even when no requests occur.* The main risk is token loss on node failure.

=== Recovery in a Ring

The ring architecture allows *very simple recovery* for *single faults without token loss*: any node detecting a neighbor failure shortcuts the ring and re-establishes the local topology. Each node must know its further predecessor/successor for this.

=== Token Recovery

If the token is *lost* (failure of the holding node) or *duplicated*, it must be regenerated. Every node maintains a *timeout* reset on each token pass. On timeout expiry, a *recovery procedure* starts. Multiple nodes may start simultaneously, *node priority* (index) resolves the conflict.

== Election Protocols

#def("Election Protocols")[
  The *election protocols* are used any time an *agreement among participants must be found without a predefined policy*. They are typically necessary in case of *fault* and *recovery* in a group to obtain distributed and easy agreement on a decision. In many cases, it is based on a *potential static order of participants*.
]

=== Bully Algorithm

Three message types: *Election* (announcing candidacy), *Answer* (blocking a lower-priority candidate), *IAmCoordinator* (winner announcement).

#def("Bully Protocol")[
  Any process $P_i$ can start an election at any time. It sends *Election* to all processes with higher priority. If no reply arrives within timeout, $P_i$ declares itself coordinator and broadcasts *IAmCoordinator* to all lower-priority processes. If a higher-priority process replies with *Answer*, it blocks $P_i$ and starts its own election. Several rounds can run concurrently. 
]
#extra[Example: 4 starts, blocked by 5 and 6 answering; 5 then blocked by 6; 6 wins.]

=== Election in a Ring

*Election protocol* to decide who must become the manager (with a unique new token) based on *static priority of processes*:
- At timeout, the process creates an *election token* (ET) with his name and enters an *election state* until the token returns
- If the process receives the normal token before the generated ET is back, the election is considered useless and terminated (*ET destroyed at return*)
- If the process receives an ET from another process, it is registered on an *election list* together with *identity of process* that generated it, and the ET is passed forward in the ring
- If it has already generated an ET token, it verifies the *static priority* and decides who has *highest priority* in the election
- If the process receives its ET, it removes it and verifies the registration list. The process generates a new token, only if it is the node with *minimum index (top priority)* inside the registration list

== Global State

In a distributed system it is sometimes necessary to record a *global state* associated with the current situation, to use it as a *checkpoint for recovery* or for distributed garbage collection. The main challenge is composing a *consistent view* from locally-recorded partial states, without stopping the system.

The global state stems from the *private states of participant processes* plus the *messages currently in transit* between them. We assume an *asynchronous model*: processes on different nodes exchange messages via *one-way channels* (#so bidirectional channel are separated into two). Any node must be reachable from any other (*no partitions*). Nodes have In and Out queues.

=== Global States Consistency

#def("Consistent Cuts")[
  A *cut* is a partition of all events into "before" and "after". A cut is *consistent* if: whenever an event $e$ is in the cut, every event that *happened-before* $e$ is also in the cut, or, equivalently, no message is received without also having been sent.

  - *Consistent cuts* represent a safe, replayable global state.
  - *Inconsistent cuts* produce unreasonable states #swarrow a replay would either lose or duplicate messages.
]
#v(-1em)
#example("Consistent vs Inconsistent Cut")[
  *Consistent Cut - Message m3 from P1 to P2*: the sending state is included in P1's snapshot, so the arrival must be *recorded within P3's state*: input messages must be saved.

  *Inconsistent Cut - Message m2 from P2 to P3*: the arrival is recorded in P3's state, but the sending was not yet recorded in P2's state. In case of replay, the sender would resend the message causing a *double reception* in the receiver - an unsafe behavior to avoid.
]

=== Global State via Snapshot

#def("Distributed Global Snapshot (Chandy-Lamport)")[
  One node initiates a snapshot. Each node records its *local state* (checkpoint) and the *state of its input channels* (in-transit messages). Nodes continue normal execution during the snapshot.

  *Marker propagation algorithm* (requires FIFO channels):
  1. A process decides to snapshot (or receives the first marker): saves its local state, sends one *marker* on every OUT channel, starts recording all messages arriving on input channels
  2. On receiving a marker on input channel $C$: stop recording $C$ (save buffered messages as $C$'s state); if not yet snapshotted, do so and forward markers
  3. When markers received on *all* input channels: *local snapshot complete* (process state + all channel states)

  *Global snapshot* = union of all local process states + all channel states.
]

#extra[
  Messages in a channel can be classified by the color of sender and receiver at snapshot time:
  - *bb* (white sender, white receiver): sent and received before snapshot #swarrow already captured in local states.
  - *rr* (red sender, red receiver): sent and received after snapshot #swarrow irrelevant to this snapshot.
  - *br* (white sender, red receiver): sent before snapshot but received after #swarrow these *must be recorded* in the channel state (the receiver records them while its channel is open).
  - *rb* (red sender, white receiver): sent after snapshot but received before #swarrow a potential *inconsistency*. The protocol avoids this by construction: the marker always precedes any post-snapshot message (FIFO channels), so the receiver turns red before any red-sender message arrives.
]
#v(-0.7em)
#note[
  Each process that completes its local snapshot can send the state to the initiator or to a designated collection node for eventual replay. Snapshots are rare events due to cost. Open questions: how to run concurrent snapshots? How to distinguish and compose them?
]
