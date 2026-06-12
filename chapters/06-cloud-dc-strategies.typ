#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= CLOUD AND DATA CENTER GLOBAL STRATEGIES
#extra[
  Package: Cloud and Data Center Global Strategies - `Cloud and DC Global Strategies.pdf`
]

A Cloud is not just a collection of servers: it is a *big data center (DC), federated with other ones*, capable of giving *good and fast answers* to users. Two contrasting requirements must be balanced simultaneously:

- *Speed*: users expect very fast answers; the system must never make them wait too long.
- *Safety/Correctness*: answers must be correct and data must be persistent.

In globally distributed environments, #hl[many copies of data reside in many geographical locations], making these requirements even harder to satisfy together.

== Cloud Data Center Architecture

The Cloud DC serves users through a *two-level architecture*. The two levels have very different responsibilities and trade-offs.

=== Level 1: Cloud Edge

#def("Cloud Edge (Level 1)")[
  The #kw[Cloud Edge] is the layer very close to the client, responsible for *fast answers* to user needs. It handles many possible client requests, including concurrent ones with user reciprocal interaction. Its first requirement is *velocity*.
]

- *Read operations*: replication makes parallel reads easy, no problem.
- *Write operations*: updates are tricky; the edge uses a *guessing model*: try to forecast the update outcome and answer fast, but operate on the update in the background with level 2.

#why("Why a guessing model?")[
  Waiting for all replicas to confirm a write would make the response slow. Instead, the edge *optimistically predicts* the result and sends the answer immediately, then reconciles asynchronously. If the guess is wrong, corrections happen later.
]

=== Level 2: Cloud Internal

#def("Cloud Internal (Level 2)")[
  The #kw[Cloud Internal] layer is responsible for *stable, correct answers* to queries given to level 1. It is hidden from users and focused on *deep data management*, replication, and consistency. It is in charge of replicating data and keeping caches to favor user answers.
]

- Replication policies do *not* require replicating everything: only *significant parts* (called #kw[shards]) are replicated, dynamically decided based on usage.
- The second level optimizes data in terms of smaller pieces called #kw[shards] and also supports many forms of *caching services* (memcached, Dynamo, Bigtable, ...).

#analogy("Two levels as front-office and back-office")[
  Level 1 is the front desk: it must answer immediately, even if it does not have the most up-to-date information yet. Level 2 is the back office: it processes everything carefully, keeps the real records, and eventually reconciles the front desk's guesses.
]

=== Two-Level Replication

Both levels replicate, but with different goals:

- *Edge (Level 1)*: resources are replicated for user demands and to answer within the negotiated SLA. Replication is tailored to user needs, transparent to the final user.
- *Internal (Level 2)*: replication supports user long-term strategies and mutual replication across areas. The whole load drives decisions, not individual users. Data is split into *shards* that are small enough not to clog the system.

#important("Dynamic Replication")[
  Any level replicates *in a dynamic way, according to current necessity*. A piece of data that becomes critical gets replicated in more and more copies. A piece operated upon by several processes concurrently may be sharded to avoid bottlenecks.
]

== Sharding

#def("Shard")[
  A #kw[shard] is a smaller, well-defined piece of data that is the *unit of replication and management*. The system identifies the proper pieces to replicate (shards) to achieve *high availability* and *increased performance*.
]

Sharding rules:
- Shards must be *dynamically decided*: usage patterns change.
- Not too small: avoid fragmentation management overhead.
- Not too large: avoid making coordination too hard.
- Shards can be *local* or *coordinated with other data centers* to grant consistency.

The most requested pieces are replicated most; those operated upon by concurrent processes are sharded along their access pattern to allow parallelism.

#extra[
  *AWS* uses sharding in DynamoDB and RDS. *Microsoft Azure* uses it in Azure SQL Database and Cosmos DB. *Google Cloud* uses it in Cloud Spanner and Bigtable.
]

== Consistency vs. Speed: The Core Tension

=== Critical Paths and Asynchronous Effects

Fast answers are *difficult when working synchronously with subservices*. If a service calls multiple slow subservices, the total response time is the *critical path*: the longest chain of dependent calls. With replicas and parallelism, reads can be served quickly; but *write operations* involving multiple replicas introduce asynchronous effects:

- Replicas receiving operations in a different schedule #arrow their final state can differ (inconsistency).
- If some replicas fail, the given answer may be incorrect.
- Agreements between different copies must be reached *eventually*.

All these issues contribute to #hl[inconsistency that clashes with safety and correctness].

=== Is Inconsistency Always Bad?

#why("Inconsistency is not always the devil")[
  In small confined machines, strict consistency is natural. But in Cloud environments, ask: *do we really need strict consistency at all times?*
  - YouTube video counters: is it a real issue if the view count differs by a few?
  - Amazon "units available" counters: small variations are invisible to customers.

  *There are many cases in which you do not need a real correct answer, but only a good approximation*: the closer the better, but perfect is not required.
]

== The CAP Theorem

#def("CAP Theorem (Eric Brewer, 2000)")[
  You can have *at most two* of the three properties:
  - *Strong Consistency (C)*: all clients see the same view, even in the presence of updates.
  - *High Availability (A)*: all clients can find at least one replica anytime, even in the presence of failures.
  - *Partition Tolerance (P)*: system properties hold even when the system is partitioned and must keep working.
]
#v(-1em)
#note[
  Since *availability* is paramount for fast answers, and transient faults often make it impossible to reach all copies, caches must be used even if they are stale. The CAP conclusion is to *weaken consistency for faster response*: choosing AP and neglecting C.
]

#figure(
  image("../assets/cap-theorem.svg", width: 50%),
  caption: "CAP Theorem: pick any two. Cloud systems typically choose AP."
)

The three CAP combinations:
- *CA* (Consistency + Availability): single-site or clustered databases. When a partition occurs, no work can go on and reconnection must be awaited.
- *CP* (Consistency + Partition Tolerance): consistent even during partitions, but some requests may not get answers.
- *AP* (Availability + Partition Tolerance): #hl[the Cloud choice]. Work during partitions, reconcile afterwards. DNS, web caches, and most internet-scale systems follow this.

=== Consistency: Two Perspectives

#table(
  columns: (auto, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Viewpoint*], [*Position*]),
  [*Academic / Pessimistic*\ (e.g. ACID)], [Clean abstractions, strong semantics, formally provable. Correctness above all.],
  [*User / Optimistic*\ (e.g. Internet)], [Systems that work most of the time, that scale well. Consistency is not important per se.],
)

== ACID Properties <ch06-acid>

#def("ACID")[
  The #kw[ACID] properties define *maximum consistency* for database transactions:
  - *Atomicity*: either all operations commit or none (abort).
  - *Consistency*: database goes from one consistent state to another.
  - *Isolation*: concurrent transactions are invisible to each other (serializability via locking).
  - *Durability*: once committed, updates cannot be lost or rolled back.
]

A "serial" ACID execution runs at most one transaction at a time. *Serializability is the illusion of serial execution*, but with increasingly heavy costs.

Two extreme cases:
- *Embarrassingly easy*: transactions that never conflict at all (Facebook updates by a single owner).
- *Conflict-prone*: transactions that interfere and can leave replicas in conflicting states: *scalability here is terrible*.

#important("ACID Cost in the Cloud")[
  The costs of transactional ACID on replicated global data can be surprisingly high. Solutions must involve ad-hoc mechanisms such as *sharding* and *coding ad-hoc transactions*. Brewer's CAP theorem states: *"you cannot use transactions at large scale in the cloud"*.

  Cloud systems do use transactions, but only in the *back end*, shielded away from users as much as possible to avoid overload and not create bottlenecks.
]

=== Nested Transactions and Two-Phase Commit

In distributed systems, one transaction may contain others at *different nesting levels*. Effects must be visible only when the whole transaction has been agreed upon and committed.

#def("Two-Phase Commit (2PC)")[
  #kw[2PC] is the standard protocol to achieve ACID quality for distributed transactions. One coordinator manages multiple participants via *4(N-1) messages*:
  - *Phase 1 (Vote collection)*: coordinator sends Prepare to all participants; each votes Yes or No.
  - *Phase 2 (Decision)*: if all vote Yes, coordinator sends Commit; otherwise sends Abort. Participants acknowledge.
]

- If *anyone disagrees*: global undo (rollback).
- If the *coordinator fails*: participants are blocked waiting: this is the fundamental weakness of 2PC.
- *Concurrent coordinators* over the same data: one of the two must abort.

#note[
  2PC guarantees atomicity but is expensive and has a single point of failure (the coordinator). In large-scale cloud environments with many replicas across different data centers, 2PC creates serious performance bottlenecks.
]

== BASE Properties <ch06-base>

#def("BASE")[
  #kw[BASE] is the "opposite" of ACID, reflecting experience with real cloud applications:
  - *Basically Available*: fast response even if some replicas are slow or crashed. Partitioning faults are mapped to crash failures, forcing isolated machines to reboot: but rapid responses are still needed.
  - *Soft State Service*: the first tier cannot store any permanent data and restarts in a "clean" state after a crash. To maintain data, either replicate in memory in enough copies or pass to another service that keeps "hard state".
  - *Eventual Consistency*: send "optimistic" answers to the external client; could use cached data without checking for staleness; could *guess* at the outcome of an update; might skip locks hoping no conflicts; later correct any inconsistencies with an *offline cleanup activity* (reconciliation).
]
#v(-1em)
#analogy("BASE as the eBay philosophy")[
  eBay researchers found that programmers with a transactional mindset built applications that did not scale well on their cloud. BASE was designed to guide those programmers: *embrace the reality that big distributed systems are inherently uncertain*, and design around it rather than fighting it.
]

=== BASE Effect in Practice

With BASE:
- Code is *more concurrent*, hence faster.
- *Locking is eliminated*, making end-user experience snappy and positive.
- *Weird behavior may occasionally appear* when looked at hard: but the achieved speed is worth the behavioral change.

#example("eBay Auction")[
  In a fast-running eBay auction, does every single bidder necessarily see every bid? And in the same order? Clearly everyone needs to see the *winning bid*, but slightly different bidding histories should not hurt much: and that makes eBay *10x faster*.
]

=== ACID vs. BASE Summary

#table(
  columns: (1fr, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*ACID*], [*BASE*]),
  [Strong consistency: highest priority], [Availability and scaling: highest priorities],
  [Availability less important], [Weak consistency],
  [Pessimistic], [Optimistic],
  [Rigorous analysis], [Best effort],
  [Complex mechanisms], [Simple and fast],
)

== Consistency Spectrum

There is no single definition of "consistency": it is a spectrum:

- *Strict consistency*: updates happen instantly everywhere. A read must return the result of the latest write. Not realistic with instantaneous propagation.
- *Linearizable*: updates appear to happen instantaneously at some point in time, ordered by a global clock. Used for formal verification of concurrent programs.
- *Sequential*: every client sees its writes in the same order. Order of writes from different clients may differ. Equivalent to Atomicity + Consistency + Isolation.
- *Eventual consistency*: when all updating stops, eventually all replicas converge to the identical values. #hl[Equivalent to CAP's AP choice.]

=== Eventual Consistency Implementation

Write propagation in two phases:
1. *Epidemic stage*: final local propagation spreads an update quickly, tolerating incomplete coverage for reduced traffic overhead.
2. *Correcting omissions*: a final phase grants that all replicas that were not updated during the first stage get the update.

Writes are written to a *log* and applied in the same order at all replicas (timestamps and "undo-ing").

=== Technology Examples and CAP Position

#table(
  columns: (auto, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Technology*], [*CAP / consistency notes*]),
  [Memcached], [No special guarantees],
  [Google GFS], [File is current if locking is used],
  [BigTable], [Shared key-value store with many consistency properties],
  [Dynamo], [Eventual consistency (Amazon shopping cart)],
  [Databases], [Snapshot isolation with log-based mirroring (ACID-like)],
  [MapReduce], [Functional computing model with very strong guarantees],
  [Zookeeper], [Yahoo! file system with sophisticated properties],
  [PNUTS], [Yahoo! database, sharded data, spectrum of consistency options],
  [Chubby], [Locking service: very strong guarantees],
)

== eBay Principles: Five Commandments for Internet Scale

At internet scale (eBay: 276M users, 2B photos, \$2040/second in trade, >48 billion SQL executions/day), standard transactional thinking fails. Randy Shoup described the *eBay Five Commandments*: design principles that push toward high scalability, availability, low latency, high manageability, and low cost.

#important("eBay Five Commandments")[
  1. *Partition Everything*
  2. *Use Asynchrony Everywhere*
  3. *Automate Everything*
  4. *Remember: Everything Fails*
  5. *Embrace Inconsistency*
]

Consistency is viewed as *a spectrum, not a specific position*: some operations (bids, purchases) require immediate consistency; others (search results, preferences) can tolerate eventual or no consistency.

=== 1 — Partition Everything

*Pattern: Functional Segmentation* — segment processing into pools, services, and stages. Segment *data along usage boundaries* (Selling, Search, View Item, Bidding, Checkout, Feedback are separate). No large components to keep consistent.

*Pattern: Horizontal Split* — all servers created equal within a pool. Split (shard) data along primary access path (range, modulo of one key, lookup, etc.) in the Data Access Layer.

Corollaries:
- *No Database Transactions*: no client-side transactions, no two-phase commit. Auto-commit for the vast majority of DB writes.
- *No Session State*: user session flow moves through multiple application pools. No session state in the application tier: sharding only.

=== 2 — Asynchrony Everywhere

Move as much processing as possible to *asynchronous flows*, integrating disparate components asynchronously.

Benefits:
- *Scalability*: scale components independently.
- *Availability*: decouple availability state and retry operations.
- *Latency*: improve user-experience latency at cost of execution latency.
- *Cost*: spread peak load over time.

Patterns:
- *Event Queue / Streams decoupling*: primary use-case produces events transactionally (e.g., ITEM.NEW, ITEM.SOLD); consumers subscribe to events with at-least-once delivery and idempotency.
- *Message Multicast*: Search Feeder publishes item updates from primary database via Scalable Reliable Multicast; nodes listen to assigned subsets of messages and update in-memory indexes in real time.
- *Periodic Batch*: scheduled offline batch processes for infrequent, periodic, or non-incremental computation (import third-party data, generate recommendations, process end-of-auction items).

=== 3 — Automate Everything

Prefer *adaptive/automated systems* over manual systems:
- *Scalability*: scale via machines without human intervention.
- *Availability/Latency*: fast adaptation to changing environment.
- *Cost*: machines are far less expensive than humans and learn/improve over time.
- *Functionality*: explore solution space more thoroughly and quickly.

Patterns:
- *Adaptive Configuration*: define SLA for a given logical consumer (e.g., 99% of events processed in 15 seconds); dynamically adjust configuration to meet the defined SLA.
- *Machine Learning*: dynamically adapt search experience; determine best inventory and assemble optimal page for that user and context. Feedback loop: collect user behavior → aggregate and analyze offline → deploy updated metadata → decide and serve appropriate experience.

=== 4 — Everything Fails

Design assuming failures happen constantly.

Patterns:
- *Failure Detection*: servers log all requests (all application activity, DB and service calls on a multicast message bus — more than *2 TB* of log messages per day); listeners automate failure detection and notification.
- *Rollback*: absolutely no changes to the site that cannot be undone. The system does not take any action if irreversible actions are to be taken. Every feature has an on/off state driven by central configuration. Features can be deployed "wired-off" to unroll dependencies.
- *Graceful Degradation*: application marks down an unavailable or distressed resource. Non-critical functionality is removed or ignored. Critical functionality is retried or deferred: retried until completed in case of failure.

=== 5 — Embrace Inconsistency

*Choose Appropriate Consistency Guarantees*:
- According to Brewer's CAP Theorem, prefer *eventual consistency* to immediate consistency.
- To guarantee availability and partition-tolerance, trade off immediate consistency.

*Avoid Distributed Transactions*:
- No two-phase commit.
- Minimize inconsistency through *state machines and careful ordering of operations*.
- Achieve eventual consistency through *asynchronous event or reconciliation batch*.

#important("Consistency as a Spectrum")[
  The final commandment is not "be inconsistent" but rather *release consistency*: look at it as a spectrum and not a specific position. Choose the right consistency level per operation:
  - *Immediate consistency*: bids, purchases.
  - *Eventual consistency*: search engine, billing systems.
  - *No consistency required*: user preferences.

  The key insight is that *the appropriate consistency level depends entirely on the application area*. There is no single right answer.
]
