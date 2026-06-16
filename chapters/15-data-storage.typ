#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= DATA STORAGE
#extra[
  Package: Data Storage - `11 - Data_storage 26.pdf`
]

Modern global systems need #hl[new tools for data storage of Big Data] with a renovated level of quality. We have seen distributed file systems (GFS, HDFS), but here we go further: #kw[NoSQL] distributed storage systems built on *new principles*. These tools are within the *NoSQL (Not only SQL) trend*: not only a query language, but modern *data support* serving as the entire inspired infrastructure.

== The NoSQL Movement

#def("NoSQL")[
  #kw[NoSQL] (Not only SQL) is a general trend in addressing modern very large-dimension and big data systems. NoSQL systems can provide almost-SQL languages extended to accommodate queries with modified data definitions (JSON) and specific optimized actions. The name does not mean "no SQL at all": it means *not only SQL*.
]

The movement emerged around 2010, building on earlier foundations (DHTs, P2P systems, MapReduce) and responding to the explosion of web-scale applications. All major proposals (Cassandra, MongoDB, DynamoDB, BigTable, HBase) started around that era.

=== NoSQL Motivations

Big data stores and infrastructures face a set of *novel requirements* that traditional RDBMS cannot efficiently serve:

- *Scalability*: handling billions of records across thousands of nodes.
- *Efficiency of services on large volumes of data*.
- *High availability and fault tolerance*: no Single Point of Failure (SPoF).
- #hl[*New data consistency strategies*: eventual consistency instead of strict ACID].
- *New way of data tagging*: no schema required.

To meet these, NoSQL systems ask for:
- More flexible, *schema-less data models*.
- *Weak consistency* toward high availability and correct configuration.
- *High replication in close storage* to avoid moving data around data centers.
- Clever use of *distributed indices, hashing, and caching*.
- Datacenter-friendly *partitioning across local and remote servers*.
- A *web-friendly access* through a simple client interface.

#why("Not Just RDBMS")[
  Relational databases (MySQL, PostgreSQL) are great, but they are mismatched with today's workloads:
  - Data is extremely *large and unstructured*.
  - Lots of *random reads and writes*.
  - Sometimes *write-heavy* operations.
  - *Foreign keys* rarely needed.
  - *Joins* are rare.

  Crucially, data and queries are often foreseeable: *you can prepare your data for the usage you want to optimize*: out-of-band preparation of data links. SQL forces you into a general join model even when you never need it.
]

=== Requirements of Today's Workloads

Beyond the motivations above, real deployments also demand *operational* efficiency:
- *Low TCO* (Total Cost of Operation).
- *Fewer system administrators* needed.
- *Incremental scalability*: scale out, not up.

#def("Scale Out vs. Scale Up")[
  - *Scale up* (vertical scalability): grow cluster capacity by replacing more powerful machines. Traditional approach; not cost-effective above the price curve sweet spot; requires replacing machines often.
  - *Scale out* (horizontal scalability): incrementally grow capacity by adding more *COTS machines* (Components Off The Shelf). Cheaper and more effective over time; used by most companies running datacenters and clouds today.
]

=== Different NoSQL Data Models

NoSQL encompasses several distinct data models:

- #kw[*Key-Value Stores*]: data managed as (key, value) pairs stored in efficient and scalable ways (typically as in DHT). 
  #extra[Examples: Redis, Oracle NoSQL, DynamoDB, Cosmos DB, *Cassandra*.]
- #kw[*Document Stores*]: extended key-value stores where the value is a document encoded in standard formats (XML, JSON, BSON).
  #extra[Examples: *MongoDB*, CouchDB, CosmosDB, Firebase.]
- #kw[*Wide-Column Stores*]: data in a tabular format of rows and column families stored per-column-family dynamically and flexibly.
  #extra[Examples: *Cassandra*, BigTable, HyperTable, HBase.]
- *Graph Stores*: graphs for storing data efficiently and providing more effective operations on connected data.
  #extra[Examples: Neo4j, Giraph, ArangoDB, Titan, AllegroGraph.]

#note[Cassandra appears in both Key-Value and Wide-Column categories: it is a column-based key-value store. The line between these categories is blurry.]

== Key-Value Abstraction

#def("Key-Value Store")[
  A #kw[key-value store] is a dictionary data structure organized for easing operations by *key I/O*. Given the key, you get the content fast via `insert`, `lookup`, and `delete`. The main property is the requirement of being *distributed in deployment* and *scalable*.
]

Key insight: *elements are #underline[immutable]* (there is not mostly modification; changing also tags key-insert). This is why key-value stores reuse many techniques from *Distributed Hash Tables (DHT)* in P2P systems and from tuple spaces.

#example("Key-Value in the Real World")[
  - *twitter.com*: Tweet id #arrow information about tweet
  - *amazon.com*: Item number #arrow information about it
  - *kayak.com*: Flight number #arrow information about flight availability
  - *yourbank.com*: Account number #arrow information about account
]

=== Key-Value / NoSQL Data Model vs. RDBMS

#table(
  columns: (auto, 1fr, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Feature*], [*RDBMS*], [*NoSQL Key-Value*]),
  [Schema], [Strict schema, all rows complete], [Unstructured: columns may be missing from some rows],
  [Relationships], [Foreign keys, joins supported], [Do not always support joins or foreign keys],
  [Tables], [Flat tables], [More data models, including nested tables],
  [Queries], [SQL (Structured Query Language)], [API: `get(key)` / `put(key, value)` + CQL extensions],
  [Index tables], [Supported], [Supported (column families in Cassandra, collections in MongoDB)],
  [Consistency], [Strong ACID], [Eventual consistency (BASE)],
)

=== Column-Oriented Storage

Traditional RDBMS store an *entire row together* on disk. NoSQL systems typically *store one column (or group of columns) together*.

#why("Column-Oriented Storage")[
  Range searches *within a column* are fast: you do not need to fetch the entire database.
  #extra[For example: "Get all blog\_ids from the blog table updated in the past month": search the `last_updated` column, fetch corresponding `blog_id` column, without touching other columns. This dramatically reduces I/O for analytical workloads.]
]
#side-note(color: rgb("#002fff"))[
  💯 #text(fill: rgb("#002fff"))[*Prof. Question*]: #text(fill: rgb("#002fff").lighten(50%))[_Difference between a column-oriented and a document-oriented database?_]\
  *Column-oriented* (Cassandra) stores columns together, so reading one column touches only that column, ideal for *column range queries* and *write-heavy* loads. *Document-oriented* (MongoDB) stores a whole entity in one BSON/JSON document, so a *single read* returns it with no joins, ideal for *retrieving complete documents*. Both avoid joins.
]

== Cassandra

#def("Apache Cassandra")[
  #kw[Cassandra] is a distributed *column-based key-value store* intended to run in a datacenter (and across multiple DCs). Originally designed at Facebook, open-sourced later, and today an Apache project. It offers an *easy-to-use setting* for Cloud support over several datacenters.
]

#extra[Used in production by IBM, Adobe, HP, eBay, Ericsson, Symantec, Twitter, Spotify, PBS Kids, Netflix (to track viewing position), and many others.]

=== Cassandra Data Center Model

Cassandra organizes infrastructure in a core hierarchy:

- *Cluster*: the set of all possible servers in all data centers.
- *DataCenter (DC)*: the set of all servers in one DC, organized as a ring and the base for replication.
- *Rack*: the set of local servers in all DCs; at least one rack must be present as the configuration unit.
- *Server*: the instance present on one physical server, which can contain several virtual entities.
- *Virtual Node (VNode)*: a VNODE normally controlled automatically by Cassandra with a load factor C > 1.2; the goal is better distribution of elements inside partitions (more #so better partition balance).

The #hl[configuration is *automatic and dynamic*]. When there is a re-partition, a new node is created: the update changes structure so it is lighter.

#figure(
  image("../assets/cassandra-organization.jpg", width: 80%),
  caption: [Cassandra model.]
)

=== Cassandra Architecture

Cassandra's layered architecture:

- *Cassandra API* (top): to retrieve data.
- *Tools*: for data managing across the infrastructure.
- *Storage Layer*: creation and storage of data, with in-memory caching and R/W operation support.
- *Partitioner*: creates multiple partitions (sub-tables) #so multiple points of consistency but also higher time for retrieve (more lookups).
- *Replicator*: handles replication, membership, consistency level.
- *Failure Detector*: detects failed nodes. 
- *Cluster Membership*: tracks which nodes are alive.
- *Messaging Layer* (bottom): for all message exchange across clusters.


=== Key-to-Server Mapping: The Ring

Cassandra uses a *Ring-based DHT* without finger tables or routing: a simple, elegant design.

#def("Cassandra Partitioner")[
  The #kw[Partitioner] decides the mapping of keys to server nodes. The ring assigns a range of hash values to each node. Each key is hashed and placed on the node owning that range. The *primary replica* is the first node clockwise on the ring; *backup replicas* follow clockwise.
]
#v(-1em)
#analogy("The Ring")[
  Think of a circular racetrack where each runner "owns" a section. A ball (key) thrown to any point on the track belongs to the runner whose section it lands in. Backups are just the next few runners clockwise.
]

Say the ring has $m = 7$ bits (128 positions). Key K13 maps to the first node clockwise with position ≥ 13. The Partitioner walks the ring until it finds that node, making it the *primary replica*. Subsequent replicas are placed on the next nodes clockwise.

#figure(image("../assets/cassandra-ring.svg", width: 90%), caption: "Cassandra ring.")

=== Cassandra Keyspaces

#def("KeySpace (KS)")[
  A #kw[KeySpace] is a namespace container that defines the *data replication on nodes* and how they contain tables, the *number of replicas*, and their *replica placement strategy*.
]

Key properties:
- *Replication Factor (RF)*: number of replicas per datacenter (it cannot exceed the number of nodes).
- Heavy replicas of partitions enable more concurrent readings.
- There is an overhead of updating copies to new updates: RF is a trade-off.
- When there is a re-partition, a new node is created: compaction and re-partition are the most expensive operations in a distributed DB.

=== Data Placement Strategy

Two replication strategies:

- *SimpleStrategy*: for single DC, with two partitioning options:
  - *RandomPartitioner*: Chord-like hash partitioning.
  - *ByteOrderedPartitioner*: Assigns ranges of keys to servers (easier for range queries, e.g., "Get all Twitter users starting with [a–b]").
- *NetworkTopologyStrategy*: for multi-DC deployments:
  - Supports two or three replicas per DC. First replica placed according to Partitioner, then go clockwise around the ring until hitting a *different rack*.

=== Snitches

#kw[Snitches] map IPs to racks and DCs (configured in `cassandra.yaml`):

- *SimpleSnitch*: unaware of topology (rack-unaware).
- *RackInferring*: assumes topology from IP address octets: `101.201.202.203 = x.<DC octet>.<rack octet>.<node octet>`.
- *PropertyFileSnitch*: uses a configuration file.
- *EC2Snitch*: EC2 region = DC, Availability Zone = rack.

=== Write Operations

Writes must be *lock-free and fast* (no reads or disk seeks).

The write path:

1. *Client sends write* to one coordinator node (per-key, per-client, or per-query).
2. *Coordinator uses Partitioner* to send write to all replica nodes responsible for the key.
3. *When X replicas respond*, coordinator returns acknowledgement to client (*X is the majority: quorum*).
#v(-0.7em)
#important("Hinted Handoff: Always Writable")[
  If one replica is down, the coordinator writes to all other replicas and keeps the write locally until the crashed replica comes back. When *all replicas are down*, the coordinator (front end) *buffers writes* for up to a few hours. This makes Cassandra *always writable*.
]

#figure(
  image("../assets/cassandra-writes.jpg", width: 40%),
  caption: [Writes on Cassandra, (local) cache as fallback.]
)


For multi-DC coordination, a #hl[per-DC coordinator is elected using *Zookeeper*], which implements distributed synchronization and group services (similar to JGroups reliable multicast).

=== Writes at a Replica Node

On receiving a write, each replica:

1. *Log it in a commit log* on disk (for failure recovery).
2. *Make changes to the appropriate Memtable*.
   - *Memtable*: in-memory representation of multiple key-value pairs; append-only datastructure (fast); cache searchable by key.
   - *Write-back cache* (as opposed to write-through).

When the Memtable is full or old, it is *flushed to disk*:
- *Data File*: an SSTable (Sorted String Table): list of key-value pairs.
- *SSTables are immutable* (once created, they never change).
- *Index file*: an SSTable of pairs (key, position in data SSTable).
- *Bloom filter*: for efficient existence checks.

#figure(
  image("../assets/cassandra-writes2.jpg", width: 50%),
  caption: [Cassandra writes in distributed architecture.]
)


=== Bloom Filter

#def("Bloom Filter")[
  A #kw[Bloom filter] is a compact bit-table that hints for location. It compacts the way of representing a set of items so that *checking for existence in the filter is cheaper* than searching directly. There may be some probability of *false positives* but *very low probability of false negatives*.
]

#figure(
  image("../assets/bloom-filter.jpg",width: 40%),
  caption: [Bloom-filter.]
)

#how("bloom filter works")[
  On insert, all hashed bits are set. On "check-if-present", return true if all hashed bits are set. With m=4 hash functions, 3200 bits, 100 items: false positive rate ≈ 0.02%.
]
#v(-1em)
#analogy("Bloom Filter")[
  Think of a bouncer with a list of VIPs. The bouncer occasionally lets in impostors (false positive), but *never* turns away a real VIP (no false negative). It is a probabilistic early rejection layer.
]
#side-note(color: rgb("#002fff"))[
  💯 #text(fill: rgb("#002fff"))[*Prof. Question*]: #text(fill: rgb("#002fff").lighten(50%))[_How does data storing work in Cassandra?_]\
  A distributed *column-oriented* store, *in-memory first*, with *no single point of failure*. Keys map to nodes on a *ring-based DHT* (consistent hashing). A write goes to the *commit log*, then the in-memory *Memtable*, later flushed to an *immutable SSTable* on disk (sorted by key). A *Bloom filter* avoids disk reads for absent keys. Consistency is *BASE* (eventually consistent), not ACID.
]

=== Compaction

As data updates accumulate over time, SSTables and logs need to be compacted:

- *Compaction merges SSTables* by merge-sorting updates for a key.
- *Runs periodically and locally* at each server.
- Old logs are kept until the update is entirely done (in case of failure, can restart); once done, tables are deleted.
- The merged result is a new SSTable with a fresh Index file and Bloom filter.

*Deletes* are handled specially: Cassandra does not delete items right away. Instead, it adds a *tombstone* to the log. Eventually, when compaction encounters a tombstone, it deletes the item (eventually after compaction).

=== Read Operations

Reads are *similar to writes*, except:

- *Coordinator contacts X replicas* (e.g., in the same rack).
- Coordinator sends read to replicas that responded *quickest* in the past.
- When X replicas respond, coordinator returns the *latest-timestamped value* from those X.
- Coordinator also fetches value from *other replicas* in the background, checking consistency: initiating a *read repair* if any two values differ.
- This mechanism seeks to *eventually bring all replicas up to date*.

#figure(
  image("../assets/cassandra-read.jpg", width: 50%),
  caption: [Cassandra read flow.]
)

At a replica: reads look at *Memtables first*, then SSTables. A row may be split across multiple SSTables, so *reads touch multiple SSTables* #arrow reads are slower than writes (but still fast).

=== Cluster Membership and Failure Detection

Any server in the cluster could be the coordinator, so *every server maintains a list of all other servers* currently in the cluster.

*Gossip-based membership*:
- #hl[Nodes periodically gossip their membership list].
- On receipt, the local membership list is updated.
- If any heartbeat is older than Tlast, node is marked as failed.

*Accrual Failure Detector*:
- Adaptively sets the timeout based on underlying network and failure behavior.
- Outputs a value *PHI ($Phi$)* representing suspicion.
- $Phi(t) = -log("CDF or Probability"(t_("now" - t_("last")))) / log(10)$.
- $Phi$ determines the detection timeout, taking into account historical inter-arrival time variations for gossiped heartbeats.
- In practice, $Phi = 5$ → 10–15 second detection time.

=== Eventual Consistency and ACID vs. BASE

#def("Eventual Consistency")[
  If all writes stop to a key, then all its values (across replicas) will *converge eventually*. If writes continue, the system always tries to keep converging: a moving "wave" of updated values lagging behind the latest values sent by clients, but always trying to catch up. May still return *stale values* to clients (e.g., if many back-to-back writes). Works well when there are periods of low writes; system converges quickly.
]

#table(
  columns: (auto, 1fr, 1fr),
  align: (x, y) => if y == 0 { center } else { left },
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Property*], [*ACID (RDBMS)*], [*BASE (NoSQL)*]),
  [*A*], [Atomicity], [Basically Available],
  [*C*], [Consistency], [Soft-state],
  [*I / E*], [Isolation], [Eventual Consistency],
  [*D*], [Durability], [-],
  [*Priority*], [Consistency over availability], [*Availability over consistency*],
)

=== Cassandra Consistency Levels

Cassandra allows clients to *choose a consistency level per operation* (any read/write):

- *ANY*: any server (may not be replica): fastest; coordinator caches write and replies quickly.
- *ALL*: all replicas: slowest, but ensures strong consistency.
- *ONE*: at least one replica: faster than ALL, but cannot tolerate a failure.
- *QUORUM*: quorum across all replicas in all DCs: global consistency, but still fast.
- *LOCAL\_QUORUM*: quorum in coordinator DC: faster, only waits for quorum in first DC client contacts.
- *EACH\_QUORUM*: quorum in every DC: lets each DC do its own quorum, supports hierarchical replies.

=== Quorums in Detail

#def("Quorum")[
  A #kw[quorum] is a majority: > 50% of replicas. Any two quorums *intersect*: this guarantees that at least one node in each quorum has seen the latest write, so a read quorum always finds the most recent value.
]

Two necessary conditions for correct quorum operation:
1. *W + R > N* (write count + read count > total replicas)
2. *W > N/2* (write majority)

Usage patterns:
- (W=1, R=1): very few writes and reads
- (W=N, R=1): great for read-heavy workloads
- (W=N/2+1, R=N/2+1): great for write-heavy workloads
- (W=1, R=N): great for write-heavy workloads with mostly one client writing per key

=== Performance: Cassandra vs. MySQL

#example("Cassandra vs. MySQL on Large Data (> 50 GB)")[
  - *MySQL*: Writes 300 ms avg, Reads 350 ms avg
  - *Cassandra*: Writes 0.12 ms avg, Reads 15 ms avg

  Cassandra is *orders of magnitude faster*.\
  The catch: you lose ACID guarantees, strict consistency, and join support. Cassandra is a *BASE* system.
]

== MongoDB

#def("MongoDB")[
  #kw[MongoDB] is a *document-oriented NoSQL* database. Open source (written in C++), it provides in-memory access to data (data is stored on disk always/optionally, but loaded in memory for performance), native replication toward reliability and high availability (CAP), and *collection partitioning* by using a sharding key to keep information fast, available, and replicated.
]

=== MongoDB Data Model

MongoDB is based on *collections of documents*:
- A *collection* is a group of related documents with a shared common index.
- Stores data in form of *BSON* (Binary JSON: Binary JavaScript Object Notation) documents.
- BSON optimizes JSON (like trimming spaces, carriage return...): kind of a zip format.

```json
{
  name: "travis",
  salary: 30000,
  designation: "Computer Scientist",
  teams: [ "front-end", "database" ]
}
```
#v(-0.7em)
Documents are schema-less: each document can have different fields.

=== MongoDB Queries

MongoDB uses a chainable query API:

- *Find*: `db.employee.find({salary:{$gt:18000}}, {name:1}).sort({salary:1})`: query all employees with salary > 18000, sorted ascending. The result of the query is a JSON array.
- *Insert*: `db.employee.insert({ name: "sally", salary: 15000, designation: "MTS", teams: ["cluster-management"] })`
- *Update*: `db.employee.update({salary:{$gt:18000}}, {$set:{designation:"Manager"}}, {multi:true})`: multi-option allows multiple document update
- *Remove*: `db.employee.remove({salary:{$lt:10000}})`: can accept a flag to limit the number of documents removed
#v(-0.7em)
#note[Indexes speed up queries but slow down writes (every write updates all indexes associated with the collection; done in real time).]

=== MongoDB Distributed Architecture

MongoDB uses a *sharded cluster* architecture:

- *Router (mongos)*: accepts and routes incoming requests, coordinating with Config Server.
- *Config Server*: stores collection-level metadata (which chunks are on which shards).
- *Shard*: stores data. Each shard is a *replica set* (typically 3 mongod servers that are mirrors of each other: one primary, others secondaries).

#figure(
  crop(image("../assets/mongodb-architecture.png", width: 50%), top: 25%, bottom: 12%),
  caption: [MongoDB architecture.]
)

*Sharding*:
- Data split into *chunks* based on shard key (≈ primary key).
- Either use hash or range partitioning.
- A shard is assigned to a replica set.
- Shards are virtual: multiple shards can be on the same physical node (many techniques).

*Pros*: adding/removing shards, automatic balancing.\
*Cons*: max document size 16 MB; sharding and re-sharding are costly operations.
#v(-0.7em)
#note[MongoDB uses *ETCD* (*Raft*) to keep consistency through routers: via metadata server. The real difference from Cassandra: Raft has a single leader while MongoDB has a leader per shard.]

=== MongoDB Replication

Uses an *oplog (operation log)* for data sync:
- Oplog maintained at primary; delta transferred to secondaries continuously/every once in a while.
- When needed, leader *Election Protocol elects a master* (Raft algorithm).
- Some MongoDB servers do not maintain data but can vote: called *Arbiters*.

=== MongoDB Read Preferences and Write Concern

*Read Preferences* determine where to route read operations:
- *Primary* (default): read from primary (strongly consistent).
- *Primary-preferred*: primary if available, else secondary.
- *Secondary*: read from secondary (may return stale data: eventually consistent).
- *Nearest*: lowest latency (useful to collocate application and DB on the same physical node; access in RAM).

*Write Concern* determines the guarantee MongoDB provides on write success:
- *Acknowledged* (default): primary returns answer immediately.
- *Journaled*: write-ahead logging to an on-disk journal for durability.
- *Replica-acknowledged*: quorum with a value of W.

*Weaker write concern #so faster write time*.

=== MongoDB Balancing and Consistency

*Balancing*: Over time chunks may grow larger than others:
- *Splitting*: upper bound on chunk size; when hit, chunk is split.
- *Balancing*: migrates chunks among shards if there is an uneven distribution.

*Consistency*:
- *Strongly Consistent*: Read Preference is Primary.
- *Eventually Consistent*: Read Preference is Secondary (or Tertiary).
- *CAP Theorem*: with Strong Consistency, under partition, MongoDB becomes write-unavailable (thereby ensuring consistency).
#side-note(color: rgb("#002fff"))[
  💯 #text(fill: rgb("#002fff"))[*Prof. Question*]: #text(fill: rgb("#002fff").lighten(50%))[_What happens if a partition grows too large in MongoDB? Is it a problem?_]\
  MongoDB *shards* by a shard key. When a *chunk* grows too big it is handled automatically: *Splitting* (the chunk is split in two) and *Balancing* (the balancer migrates chunks from overloaded shards to lighter ones). It becomes a *problem* if the *shard key is poor* (e.g. a monotonic timestamp sends every new chunk to one shard, a hot-spot) or if balancing floods the network. The shard key *cannot be changed* after the collection is sharded.
]

== ACID vs. BASE: A Fundamental Trade-Off

The key architectural trade-off in distributed data storage is between *ACID* (correctness-first, RDBMS) and *BASE* (availability-first, NoSQL): NoSQL systems prefer availability over strict consistency, accepting stale reads that converge eventually.
#v(-0.7em)
#note[
  The full treatment of _#link(<ch06-acid>)[ACID properties]_ (atomicity, 2PC, nested transactions) and #link(<ch06-base>)[_BASE_] (basically available, soft-state, eventual consistency), including the CAP theorem and eBay's internet-scale principles, is in the *Cloud and Data Center Global Strategies* chapter.
]

== Big Data Infrastructure Properties

The resource management taxonomy (runtime/static issues, technical and user-facing requirements) is shared across all Big Data infrastructure and is consolidated in the Data Batching chapter.

#extra[
  TiKV (a distributed key-value store used in TiDB) represents an advanced evolution in this space:
  - ACID guarantees
  - RAFT distributed for leader election #arrow quorum
  - Geographic distribution
  - Key-value with sequential keys #arrow fragmentation
  - Region: partitioning on nodes (continuous key intervals), automatic via PD (Placement Driver): single thread, possible bottleneck with many regions
  - CAP: Consistency and Partitioning chosen
  - Two-phase commit
]
