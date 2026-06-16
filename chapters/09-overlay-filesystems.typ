#import "@preview/justwhitee-notes:0.2.2": *

#pagebreak()

= OVERLAY NETWORKS AND FILE SYSTEMS
#extra[
  Package: Overlay Networks and File Systems - `10 - ON   File systems 26 (2).pdf`
]

Many situations require a #hl[*logical connection among different, geographically distributed entities*] spread over different locations and networks. The solution is an #kw[Overlay Network (ON)]: a network built *at the application level* that connects all those entities and makes them behave as a group.

Overlay networks may have *very different goals* but share core requirements:
- *Efficiency*: minimize overhead
- *Dynamicity*: handle nodes joining and leaving at any time
- *Scalability*: work at large scale
- *QoS*: grant agreed service levels

#def("Overlay Network (ON)")[
  An #kw[Overlay Network] is a *logical network built at the application level* on top of an existing physical/IP network. It groups a set of distributed entities so that they can *freely communicate as if they had a real network connection*, using an *application neighborhood* defined by overlay edges, not physical links.
]
#v(-1em)
#analogy("VPN as Overlay")[
  A Virtual Private Network (VPN) is the classic ON example: geographically dispersed branch offices, traveling employees, and home users all appear to be on the same corporate LAN, even though the underlying connections go through the public internet. The *overlay edge* is the IPSec/SSL tunnel, invisible to the IP layer.
]

== Classification of Overlay Networks

There are two fundamentally different kinds of overlay networks, distinguished by how new nodes are admitted:

- #kw[Unstructured overlays]: new nodes choose the neighbor to use *randomly*. The network topology is arbitrary and grows freely. Worst cases and bottlenecks can appear. 
#extra[Examples: Napster, Gnutella, Kazaa, BitTorrent.]
- #kw[Structured overlays]: there is a *precise strategy* to let nodes join, to *organize the architecture*, and to react to failures and discontinuities. 
#extra[Examples: Chord, Pastry, CAN.]
#v(-0.7em)
#note[ONs are used not only for P2P applications but also for Message Oriented Middlewares (MOMs), social networks, and cloud infrastructure coordination, wherever scalable, self-organizing discovery of distributed resources is needed.]

=== Overlay Network Usage and Node Lifecycle

A good overlay network makes *operations among the group of current participants efficient* while answering specific requirements. All participants share a *common goal of exchanging information*: files in P2P, messages in social nets, etc.

Every node in an ON follows a lifecycle:
+ *Get in*: join the network
+ *Make its actions*: participate, serve queries
+ *Help actions of others*: route, replicate, forward
+ *Get out*: leave (gracefully or by failure)

=== Key Management Requirements

Running an overlay network is harder than running a static network because the membership changes constantly. Every practical ON must address:

- *Maintaining edge links*: each node keeps a routing table of (virtual) neighbor IP addresses. These must be kept fresh as nodes move or change address.
- *Favoring insertion*: when a new node joins, it must find and connect to appropriate neighbors quickly, without disrupting the existing structure.
- *Checking liveness*: #hl[nodes periodically ping their neighbors (heartbeats)] to detect silent failures before they affect routing.
- *Identifying and recovering from faults*: when a neighbor fails, its edges must be detected as stale and replaced with alternative paths.
- *Handling churn*: #hl[nodes join and leave (or crash) continuously]. A well-designed ON restructures itself after each event in O(log N) operations, not O(N).
- #hl[*Maintaining structure under failures*]: even when multiple nodes are absent simultaneously, the overlay must remain connected and correctly routed.
- *Robustness to omissions*: message losses should be tolerable, the overlay should use redundant paths so that the failure of one route does not silence a node.

#prop("Two Fundamental ON Properties")[
  - *Dynamicity* of supporting nodes: nodes can get in and out at any time, even by crashes
  - *Replication* of resources: data must be available independently of any event pattern on the ON
]

== Unstructured Overlays

=== Napster (1991): Centralized Lookup

#kw[Napster] was the first large-scale P2P file-sharing system. It used a *non-structured* approach with a *centralized directory*:

- Any node connects to a Napster server and uploads its file list.
- Search is handled by the centralized server (lookup in the central index).
- File exchange is done *peer-to-peer*, only lookup is centralized.
- The "best" correct answers are selected and announced via ping messages.

#important("Napster Bottleneck")[
  Centralized lookup = *single point of failure* and congestion. The central directory becomes the performance bottleneck, leading to *low scalability*. This was the fundamental weakness that led to fully decentralized designs.
]

=== Gnutella (2000): Flooding-Based Unstructured ON

#kw[Gnutella] is the main representative of *unstructured ONs*: providing a *fully distributed* approach with no central coordinator.

- Any node entering Gnutella tries to connect to some others locally available
- *Fully decentralized* organization and lookup
- Nodes have *different degrees* of connections (high-degree vs. low-degree nodes)
- High-degree nodes may receive and control more links

==== Gnutella Join and Search Protocol

*Step 0: Join the network* #swarrow contact any known node.

*Step 1: Determine who is on the network:*
- A "Ping" packet announces your presence
- Other peers respond with a "Pong" packet containing: IP address, port number, amount of data shared
- Pong packets return via the same route as Ping

*Step 2: Search:*
- Gnutella "Query" asks other peers (N = 7 typically) for desired files.\
  #extra[#swarrow A Query packet asks: "Do you have any matching content with the string 'Volare'?"]
- Peers check for matches and respond (send "QueryHit" if matched), forwarding to connected peers if not (N = 7 typically) #swarrow *flooding*.
- The TTL (Time-To-Live) field limits the number of hops a packet can traverse (typically 10).

*Step 3: Downloading:*
- Peers respond with a "QueryHit" containing contact information
- File transfer uses direct *HTTP* GET connection

#important("Gnutella Scalability Problem")[
  Flooding-based search is extremely *wasteful in bandwidth*:
  - Enormous number of *redundant messages*
  - A large (linear) part of the network is covered irrespective of hits found, *without taking into account actual needs*
  - All users search in parallel: local load grows *linearly with system size*
]

==== Gnutella: Scale-Free Networks and Topology Control

The Gnutella network exhibits a *scale-free* topology following a *power law* (or exponential law) degree distribution: a *few nodes are highly connected* and many nodes have low degree. This is very different from a random network.

#def("Scale-Free Network")[
  A #kw[scale-free graph] is a graph whose degree distribution follows a *power law* $P(k) tilde k^(-tau)$ with $tau approx 2.07$ in real Gnutella deployments. A few *hub nodes* have a very large neighborhood of low-degree ones. Hub nodes can store an index for a large portion of the network.
]

*Degree-biased random walk:*
- Select *highest degree (hub) nodes* that have not been visited.
- Walk first climbs to highest degree nodes, then climbs down into the vicinity.
- Optimal coverage can be *formally proved*.

#figure(
  image("../assets/scale-free-net.jpg",width: 50%),
  caption: [Scale-free network (right) vs. randomly connected network (left).]
)

==== Gnutella Replication

To improve search hit rates, #hl[objects are replicated across multiple nodes]. Three strategies exist, each with different trade-offs:

- *Owner replication*: the original owner creates a number of replicas proportional to $q_i$ (the query frequency for object $i$). Popular objects get more copies; rare objects stay rare. Simple but requires the owner to know global demand.
- *Path replication*: every node along the query path that returns a hit stores a copy. The number of replicas grows proportionally to $sqrt(q_i)$, naturally placing copies near where demand is coming from. More balanced than owner replication.
- *Random replication*: same replication factor as path replication ($sqrt(q_i)$), but replicas are placed on randomly chosen nodes rather than the query path. Easier to implement but less locality-aware.

#note[*rare objects remain difficult to find* regardless of which strategy is used: in an unstructured overlay, a query for an object with very few copies must traverse many nodes before hitting one. This is the fundamental scalability limitation of Gnutella-like systems.]

== Structured Overlays: Distributed Hash Tables

Unstructured P2P networks allow resources to be placed at any node spontaneously but suffer from bottlenecks and unpredictable behavior. *Structured P2P networks* simplify resource location and load balancing by defining a *topology* and *rules for resource placement*, enabling efficient search even for rare objects.

The key technology: #kw[Distributed Hash Table (DHT)].

#def("Distributed Hash Table (DHT)")[
  A #kw[DHT] uses hash principles to enable *efficient retrieval of data content and values in a distributed setting*. The hash function maps keys (hashed data) to nodes in the overlay:
  - `put(key, value)`: store a key-value pair
  - `value = get(key)`: retrieve by key
  The key insight: *partitioning the whole key space* over available nodes in a ring-like structure, where each node is responsible for a contiguous range of keys.
]
#v(-1em)
#analogy("DHT as a Distributed Dictionary")[
  A regular hash table assigns array slots via `h(key)`. A DHT does the same but the "array" is *spread across thousands of machines*. Instead of an array slot, `h(key)` tells you *which node* is responsible for storing that key-value pair. Nodes can join and leave, so the mapping is dynamic: that's the hard part.
]
#extra[
  In other words, for every data is created the respective hash and to every node is assigned a "range" of hashes #so every hash falls into a pre-assigned machine, and is efficiently retrievable from the DHT. hash/data #sym.arrow.l.r.double node 
]

=== Key DHT Principles

- *Partitioning*: the #hl[whole key space is divided into ranges, each assigned to a node].
- *Replication*: entries are replicated on multiple neighbor nodes to increase availability.
- *Load balancing*: when nodes change, re-map keys (only $O(1/N)$ fraction of keys move).
- *Self-organization*: nodes cooperate to maintain the structure without any central coordinator.


=== Chord

#def("Chord")[
  #kw[Chord] (2001) is a DHT built on a *consistent-hashing ring*. Both *keys *and* nodes* are hashed (SHA-1) to *160-bit IDs* on a circle from $0$ to $2^160 - 1$. A key is stored on its *successor*: the first node clockwise whose ID is $>=$ the key's ID. So each node *owns the arc of IDs* between its predecessor and itself.
]

#figure(
  image("../assets/chord-dht.svg", width: 70%),
  caption: "Chord DHT ring: nodes placed on a 160-bit ID circle; each key is stored at its clockwise successor. Finger table shortcuts give O(log N) lookup."
)

==== Chord Primitive Lookup

The simplest lookup just *forwards the query around the ring in one direction*:
- Lookup query arrives from any node, forwarded to successor in one direction
- In the worst case, *O(N)* forwarding is required (full traversal of ring)
- By using both directions: O(N/2), still linear

==== Chord Efficient Lookup: Finger Tables

#def("Finger Table")[
  Each node keeps a *finger table* of $m$ shortcuts ($m$ = ID bit length). Finger $i$ points to the *successor of* $("nodeID" + 2^i)$, so the fingers reach nodes at *exponentially growing distances* around the ring ($2^0, 2^1, 2^2, dots, 2^(m-1)$).

  To look up a key, a node forwards the query to the *farthest finger that does not pass the target*. That jump always covers at least *half* of the remaining distance, so every hop *halves the gap to the target* (just like binary search). A lookup therefore needs only *O(log N)* hops and *O(log N)* state per node.
]
#v(-1em)
#example("Chord lookup (64-ID ring)")[
  Locate Key $"K54"$ starting from Node $"N8"$ with $m=6$ (max   64 IDs).

  - *Finger Steps:* $8 + 2^i$ for $i in [0, 5] arrow {9, 10, 12, 16, 24, 40}$
  - *Resolution on Graph:* 
    - $"Successor"(24) = "N32"$
    - $"Successor"(40) = "N42"$
  - *Routing Decision:* Since $40 <= 54$, $"N8"$ uses its farthest valid finger and fires the query directly to $"N42"$ (because it $"N40"$ is not assigned/on #so the node that have the range i $"N42"$), clearing the majority of the ring distance in a *single hop*.\
  So then we are in $"N42"$ and apply the same method #so to finger $"N51"$ #so to finger $"N56"$. $"N51"$ delivers the query to $"N56"$.
  - *Total Cost:* $3$ hops instead of the linear $8$ hops.
  #figure(
    image("../assets/chord-example.jpg", width: 40%),
    caption: [Example of chord.]
  )
]

When a node joins, it builds its own finger table *and nearby nodes refresh theirs*. This coordination costs *O(log N)* per join.

==== Chord Consistent Hashing Properties

- *Randomized*: all nodes receive roughly an equal share of load.
- *Local*: adding or removing a node involves an *O(1/N) fraction* of keys getting new locations, minimal disruption.
- Cost of lookup via finger tables: Chord needs to know only O(log N) nodes in addition to successor and predecessor to achieve *O(log N) message complexity* for lookup.

==== Chord Node Join and Stabilization

*Node join:*
- A new node finds its *successor*, then stabilizes.
- The node joins immediately (lookup already works), then modifies the structure lazily.
- Stabilization: *each node periodically runs the stabilization routine* and *refreshes its fingers* by re-running `find_successor(nodeID + 2^i)` for each $i$.
- Periodic cost: *O(log N)* per node due to finger refresh.

*Failure handling:*
- Instead of one successor, each node keeps *R successors* (replication).
- More robust to node failure (can find new successor if old one failed).
- In robust DHTs, keys *replicate on the R successor nodes* of any node.
- *Alternate paths while routing*: if a finger does not respond, take the previous finger or replicas if close enough.

=== Pastry

#def("Pastry")[
  #kw[Pastry] (2001) is a DHT on a ring of *128-bit IDs* (nodes and objects, uniform random). Two differences from Chord: the owner of a key is the *numerically closest* node (not the clockwise successor), and routing works by *prefix matching*. Each ID is read as a string of *base-$2^b$ digits* (with $b = 4$, hex digits), and every hop moves to a node that shares *one more leading digit* with the target key.
]

Each node keeps two structures, nested by prefix:

#prop("Routing Table and Leaf Set")[
  - *Routing table* (prefix neighborhood): $log_(2^b) N$ rows. *Row $r$* holds nodes that share your *first $r$ digits* but differ in digit $r+1$, with one entry per possible value of that digit. This is what lets a single hop fix one more digit toward any target.
  - *Leaf set* (numeric vicinity): the handful of nodes with the *numerically closest* IDs, just above and below yours. It handles the *last hop* of a lookup and is the *replication* set.
]

==== Pastry Routing

A #hl[lookup for key $X$ is forwarded hop by hop to a node whose ID shares a *longer prefix* #underline[with $X$]] (one more digit each time). Once $X$ falls inside the current node's *leaf set*, the numerically closest node is known directly and the lookup ends. This takes $< log_(2^b) N$ hops (so $log_(16) N$ with hex) and *O(log N)* state per node.
#v(-0.7em)
#example("Prefix routing")[
  To route the hex key `65A1...`, the query hops to a node starting with `6`, then one starting with `65`, then `65A`, matching one digit per hop until the leaf set pins the exact owner.
]
#v(-0.7em)
#note[
  Pastry routes in *two spaces at once*: the *ID space* gives correctness (the matched prefix always grows), while *network proximity* gives efficiency (among the candidates that fix the next digit, the *topologically closest* one is chosen). Each hop is a smaller numeric jump but a useful physical step.
]

#figure(
  image("../assets/pastry-routing.jpg", width: 40%),
  caption: [Pastry routing.]
)

==== Pastry Join and Failures

- *Join*: the new node routes toward its own ID, collects state from the nodes along that path, and builds its tables from them.
- *Leaf-set repair (eager)*: leaf-set members exchange keep-alives, and a failed neighbor is replaced from the same side of the set.
- *Routing-table repair (lazy)*: a dead entry is fixed on demand by asking a live node in the same row (then higher rows) for a replacement with the same prefix.

=== DHT Applications in Practice

#extra[
  DHTs are used widely:
  - *P2P file sharing*: Napster, Gnutella, Kazaa, BitTorrent
  - *Social networks*: MSN, Skype, Social Networking Support (fast user discovery)
  - *Cloud infrastructure*: for internal and federated discovery - *Cassandra* and *ZooKeeper* are Chord-based (Cassandra) or DHT-inspired (ZooKeeper uses ZAB, inspired by Paxos but with ring-based partitioning)
  - MOMs and middleware: any system needing scalable, self-organizing discovery
]

== Distributed File Systems

=== NFS: Network File System

#def("Network File System (NFS)")[
  #kw[NFS] is the pioneer *client/server file system* and the most widespread network file system. It is based on the idea of *client machines that interact with server machines where files reside*. After mounting, the implementation is *transparent*: any client can access server files as if they were local.
]
#v(-1em)
#important("NFS Design Trade-off")[
  NFS was designed for *efficiency and cost reduction* at the expense of consistency and global view. #hl[The client is *stateful*]: it must keep track of operations on files. If the server goes down, nothing is notified and the client cannot manage single file state and operations. *No replication, no QoS, no global shared view.*
]

NFS architecture:
- *Stateless and efficient*: there is *no heavy weight on server machines*; the load is on the client.
- Uses *UDP* connections (and many TCP variations).
- Based on *RPC* for the entire communication support: efficient, low overhead.

*NFS limitation:* a client can mount from *several servers*, giving each client a *different global view* (no uniform namespace), on top of the no-replication, no-QoS constraints already noted.

#figure(
  image("../assets/nfs.jpg", width: 60%),
  caption: [NFS flow.]
)

=== AFS: Andrew File System - Quality File Systems

Other file systems introduced *global quality* in the sense of *replication* and *uniformity in view* of the file system.

#def("Andrew File System (AFS)")[
  #kw[AFS] provides:
  - *Same view* of the file system independently of where the user is accessing from.
  - *Files are replicated*, so even if some nodes are not available, the contents are always available.
  - Replication is *dynamically managed*: the file is *cached at the client site* and more copies can be added if several clients are asking for the same contents (and deleted).
  - The client uses a *call-back* to signal to the server any possible change actions (typically one per writing).
  - Clients can access from any possible OS support, with many *additional services* provided.
  - Designed for *expected more reads than writes*.
]

=== Modern Global File Systems

Modern *global systems* need new tools for data storage with *global scalability and quality*. Starting from traditional C/S file systems (similar to NFS), they move to *replication* and *dynamic management of data in all their parts* to achieve better QoS.

Major global distributed file systems:
- *Google File System (GFS)*: for Google data
- *Hadoop Distributed File System (HDFS)*: open source, analogue of GFS

== Google File System (GFS)

#kw[GFS] exploits *Google hardware, data, and application properties* to improve performance of *storage and search at scale*.

=== GFS Design Assumptions

GFS is designed around the specific workload and failure profile of Google's infrastructure:

- *Large scale, large files*: thousands of machines and disks; a "limited" number (a few millions) of *huge files* (100 MB to multi-GB), few small files.
- #hl[*Read/append workload (almost no random write)*]: mostly large sequential streaming reads (multi-MB) and large sequential appends; random overwrites are practically non-existent (new data is appended, not overwritten).
- *Component failures are the norm*: with hundreds of thousands of machines/disks (MTBF ~3 years/disk #swarrow ~100 disk failures/day), plus network, memory, and power failures, the system must #hl[*detect, tolerate, and recover* automatically].
- *Atomic consistency for concurrent appends* at low overhead: every write covers a full block, so one block = one atomic write report even under parallel append.
- *Sustained throughput* matters far more than *low latency*.

=== GFS Design Novel Strategies

#def("GFS Architecture")[
  - *One master server* (backups replicate its state) and *many chunk servers* (100s-1000s) over Linux.
  - *Chunk*: 64 MB portion of a file, identified by a 64-bit globally unique ID. Chunks spread across racks for better throughput and fault tolerance (~5 copies max).
  - *Single master* coordinates access and keeps *metadata* (file/chunk namespaces, file-to-chunk mappings, location of replicas).
  - *Files stored as chunks kept with their descriptions* (metadata) and stored as local files on Linux file system.
  - Reliability through *replication* (at least 3+ replicas).
]

Key design decisions:
- *Simple centralized design* (one master per GFS cluster).
- Global knowledge to optimize *chunk placement and replication decisions* using *no caching* (large data set/streaming reads render caching useless).
- Clients cache *metadata* (e.g., chunk locations).
- Linux buffer cache allows keeping interesting data in memory for fast access.

==== GFS Metadata

All metadata is kept *in memory* (< 64 bytes per chunk), limiting total GFS capacity but enabling fast lookups.

Large chunks have many advantages:
- Fewer *client-master interactions* and reduced size of metadata.
- Enable persistent *TCP connections* between clients and chunk servers.

==== GFS Operations

- *Normal operations*: stream reads, going on in parallel and reading any copy
- *Rare operations*: writes, stream append write (can go in parallel if different space)
- *Even rarer*: random overwriting writes, done with some cautions
- *Control operations*: metadata changes, must be done *sequentially* (write operations called *mutations*)

==== GFS Step-by-Step Write (Mutation) Protocol

The write protocol carefully separates *control flow* from *data flow*:

+ Client asks master for *identities of primary chunk server holding lease* and secondaries holding other replicas.
+ Master *replies* with chunk locations.
+ Client *pushes data to all replicas* for consistency (pipelined).
+ Client sends *mutation request to primary*, which assigns it a *serial number*.
+ Primary *forwards mutation request to all secondaries*, which apply it according to the serial number
+ Secondaries *Ack* completion.
+ *Reply* to client: an error in any replica results in an error code and a client retry.

#analogy("GFS Write as a Chain of Responsibility")[
  Think of the write protocol as a *relay race*: the client hands the data to the closest replica, which passes it to the next closest (in network topology), which passes it onward. Meanwhile, the *primary acts as the sergeant*: it assigns a serial number to ensure all replicas apply mutations *in the same order*. Control and data travel different paths for efficiency.
]

#figure(
  crop(image("../assets/gfs-write.PNG", width: 40%), bottom: 20%),
  caption: [GFS write flow.]
)

==== Data Flow for Pipe Write

- Client can push data to *any* replica.
- Data is pushed *linearly along a carefully picked chain* of chunk servers.
- Each machine forwards data to the "closest" machine in network topology that has not yet received it.
- *Pipelining*: servers receive and send data at the same time.
- Method introduces delay but offers good *bandwidth utilization*.

==== Mutations, Leases, and Version Numbers

- *Mutation*: write operation that changes either the *contents* (write, append) or *metadata* (create, delete) of a chunk.
- *Lease*: mechanism to maintain *consistent mutation order across replicas*.
  - Master grants a *chunk lease* to one replica (Primary chunk server).
  - Primary picks a *serial order* to all mutations to the chunk.
  - All replicas follow this order when applying mutations.
- *Version numbers*: chunks have version numbers to distinguish *up-to-date and stale replicas*; each time master grants new lease, increments version and informs all replicas.

==== GFS Consistency Model

#prop("GFS Consistency States")[
  - *Consistent*: all clients see the same data regardless of which replica they read.
  - *Defined*: consistent AND client sees the mutation in its entirety.
  - *Consistent but undefined*: example: initial record = AAAA, concurrent writes \_B and CC\_C; result = CBAC (none of the clients sees the expected result).
  - *Inconsistent*: due to a failed mutation, clients see different data from different replicas
]

File namespace mutations (create/delete) are *atomic*. For file regions the state depends on success/failure of mutations and existence of concurrent mutations.

*In case of inconsistent data or undefined, a data reconciliation must run.*

==== Record Append Semantics and Undefined State Avoidance

*Traditional random writes* would require expensive synchronization (e.g., lock manager): serializing writes does not help because of undefined interleaving.

*Atomic record append*: allows multiple clients to append data to the same file concurrently:
- Serializing append operations *at the primary* solves the problem.
- The result of successful operations is well defined: *data is written at the same offset by all replicas with "at least once" semantics*.
- If one operation fails at any replica, the client retries: replicas may contain duplicates or fragments.
- If not enough space in chunk, add padding and return error: client retries.

Applications using record append should include *checksums* in writing records. The reader can identify padding/record fragments using checksums. If the application cannot tolerate duplicated records, it should include a *unique ID* in records; readers use unique IDs to filter duplicates.

== HDFS: Hadoop Distributed File System

#def("HDFS")[
  #kw[HDFS] (Hadoop Distributed File System) is *inspired by GFS* but *open source*. It follows the same master/slave architecture and is based on *low cost hardware* with *high fault tolerance and high availability*. Applications access with a *write-once-and-read-many* model, the consistency model is similar to GFS, and *computation is moved close to the related data*.
]

=== HDFS Architecture

*Master/slave architecture:*
- *NameNode* is the master: executes file system *NameSpace operations* (open, close, directories...) and decides on *mapping* of blocks to DataNodes. Manages metadata: keeps FSImage and EditLog in memory.
- *DataNodes* are slaves: one per node in the cluster. Execute *read/write operations* requested from clients and operate on blocks of data. DataNodes store blocks as files on the local Linux file system.

*Files:*
- Stored in *blocks* in several DataNodes.
- Each file decides its *block size and its own replication degree*.
- HDFS is *written in Java* and must work on normal hardware to store very large files on different machines.

#figure(
  image("../assets/handoop.png", width: 50%),
  caption: [Handoop architecture.]
)

=== HDFS Replication

- Applications can *dynamically decide the replication factor*.
- *NameNode receives heartbeats and block reports* from DataNodes:
  - *Heartbeats*: grant the operation state of DataNodes.
  - *Block reports*: give the current block situations of DataNodes.
- The NameNode stores: `(Filename, numReplicas, block-ids, ...)`.
  #extra[e.g., `/users/sameerp/data/part-0, r:2, {1,3},...`.]

#note[HDFS uses a rack-aware replication strategy: one replica on the local rack, one on a different rack, balancing fault tolerance (rack failure) against write bandwidth (fewer cross-rack writes).]

== Summary: Properties Behind These Building Blocks

Overlay Networks and Distributed File Systems are *global tools to support new global systems*. They are *black boxes* used by any global application and *mechanisms (bricks)* to build other tools.

These systems are designed to favor strategic choices in tension with traditional approaches:

#table(
  columns: (1fr, 1fr),
  align: (left, left),
  fill: (x, y) => if y == 0 { accent.lighten(45%) } else {
    if calc.rem(y, 2) == 0 { gray.lighten(70%) } else { white }
  },
  stroke: 0.5pt,
  inset: 1em,
  table.header([*Favored*], [*Trade-off with*]),
  [*Dynamicity*], [Staticity],
  [*Availability*], [Reliability (strict)],
  [*Eventual Consistency*], [Strict consistency (ACID)],
  [*Fast answers*], [Safe delayed answers],
)

They should favor *life cycle widening, scalability, dependability*, enabling global distributed applications that must work at internet scale across thousands of nodes that join, leave, and fail continuously.
