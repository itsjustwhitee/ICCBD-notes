#!/usr/bin/env python3
"""
ICCBD Concept Map (per-technology composition) -> draw.io

Each TECHNOLOGY is a container box. Inside it: its main COMPONENTS / characteristics.
Cross-references to other technologies are shown as a "Links" chip (text, with the
"->" pointer marker) PLUS a small number of short arrows between adjacent containers,
so the canvas stays readable.

Run:   python generate-concept-map.py
Open:  ICCBD-concept-map.drawio  at https://app.diagrams.net  (or desktop draw.io)

HOW TO EDIT
  * In the GUI (easiest): open the .drawio, double-click any box to retype, drag to move,
    Arrange > Layout to auto-tidy. Everything is a normal editable shape.
  * In this script (bulk edits): edit TECH[...] (title / col / components / links / color)
    or EDGES, then re-run. Components: prefix a line with "@" to render it as a dashed
    "pointer to another technology" box.
"""

OUTPUT = "ICCBD-concept-map.drawio"

# ── geometry ──────────────────────────────────────────────────
COL_X       = {0: 40, 1: 500, 2: 960, 3: 1420, 4: 1880, 5: 2340, 6: 2800}
BOX_W       = 400
HDR_H       = 34
COMP_H      = 46
COMP_GAP    = 6
PAD         = 12
COL_VGAP    = 56     # vertical gap between stacked containers in a column
TOP_Y       = 140    # leave room for title/legend

# theme palette: (fill, stroke)
T = {
    "blue":   ("#dae8fc", "#6c8ebf"),
    "orange": ("#ffe6cc", "#d6b656"),
    "purple": ("#e1d5e7", "#9673a6"),
    "red":    ("#f8cecc", "#b85450"),
    "green":  ("#d5e8d4", "#82b366"),
    "yellow": ("#fff2cc", "#d6b656"),
    "teal":   ("#b0e3e6", "#0e8088"),
}

# ── TECHNOLOGY CONTAINERS ────────────────────────────────────
# id: dict(title, col, color, comps[], links[])
# comps: "Name: short description"   (prefix "@" => pointer-to-another-tech box)
TECH = {
  # ===== Column 0 : applications, packaging, classic middleware =====
  "microservices": dict(title="MICROSERVICES", col=0, color="blue", links=["-> Containers", "-> FaaS (finer split)"], comps=[
      "Single responsibility: one job, composable",
      "Independent deploy & scaling",
      "Bounded context: owns its own data store",
      "Polyglot: own language/stack per service",
      "Own process: fault isolation",
      "API Gateway: single entry, routing, auth",
      "@Service discovery: Consul / etcd / DNS-SD",
      "Circuit breaker: resilience pattern",
      "@Service mesh: Istio / Envoy / Cilium-eBPF",
  ]),
  "containers": dict(title="CONTAINERS / DOCKER", col=0, color="blue", links=["-> Kubernetes (orchestration)", "-> used by FaaS executors"], comps=[
      "Process isolation: lighter than a VM",
      "Namespaces: PID/NET/MNT/IPC/UTS/USER",
      "cgroups: CPU / RAM / I/O limits",
      "Image: immutable layers (Union/OverlayFS)",
      "Dockerfile: declarative build recipe",
      "Docker engine: CLI + daemon + containerd",
      "Registry: image store/distribution",
      "Compose: multi-container app",
      "Networks / Volumes / Secrets",
  ]),
  "middleware": dict(title="MIDDLEWARE", col=0, color="blue", links=["-> CORBA", "-> MOM", "-> Cloud"], comps=[
      "Role: decoupling layer (hide distribution + heterogeneity)",
      "Communication: RPC, message queues",
      "Information: file/record/DB/log managers",
      "Control: threads, scheduler, transactions",
      "Naming / discovery / security",
      "@Examples: CORBA, Java RMI, MOM",
  ]),
  "corba": dict(title="CORBA", col=0, color="blue", links=["-> Middleware", "-> Pub/Sub (events)"], comps=[
      "ORB: object bus, routes calls (no hosting)",
      "IDL: language-neutral interface contract",
      "IOR: global remote object reference",
      "Stub (Proxy C) / Skeleton (Proxy S)",
      "POA: maps request -> servant",
      "GIOP / IIOP: binary wire protocol (CDR)",
      "SII / DII / DSI: static vs dynamic invocation",
      "IR / IMR: interface & impl repositories",
      "OMA: services, facilities, domain interfaces",
  ]),

  # ===== Column 1 : cloud platforms & orchestration =====
  "cloud_models": dict(title="CLOUD SERVICE MODELS", col=1, color="orange", links=["-> OpenStack (IaaS)", "-> Serverless (FaaS)"], comps=[
      "Spectrum: On-prem > MaaS > IaaS > PaaS > FaaS > SaaS",
      "Who manages what (provider vs customer)",
      "@IaaS: virtual machines -> OpenStack",
      "@FaaS: only function logic -> Serverless",
      "BaaS: DBaaS, storage, auth, push",
      "NIST: on-demand, elastic, pooled, metered",
      "XaaS umbrella (anything-as-a-service)",
  ]),
  "openstack": dict(title="OPENSTACK (IaaS)", col=1, color="orange", links=["-> Cloud models", "-> shared-nothing + AMQP/RabbitMQ"], comps=[
      "Nova: compute (VM lifecycle, scheduler)",
      "Neutron: networking (NaaS, SDN, L2/L3)",
      "Cinder: block storage (volumes, snapshots)",
      "Swift: object storage (account/container/object)",
      "Glance: image registry (metadata catalog)",
      "Keystone: identity, auth, tokens, catalog",
      "Horizon: web dashboard (presentation)",
      "Ceilometer: telemetry / metering",
      "Heat: orchestration (stack templates)",
  ]),
  "kubernetes": dict(title="KUBERNETES (k8s)", col=1, color="orange", links=["-> Containers (Pods)", "-> RAFT (etcd)", "-> base for Knative/OpenFaaS"], comps=[
      "API Server: REST CRUD, watch = pub/sub",
      "@etcd: KV store, source of truth (RAFT)",
      "Scheduler: places Pods on nodes",
      "Controller mgr: reconcile loops (operator pattern)",
      "kubelet: node agent, health",
      "@Pod: 1+ containers, shared net/storage",
      "kube-proxy / eBPF (Cilium): service routing",
      "CNI: Flannel / Calico / Cilium",
      "Workloads: Deployment, StatefulSet, DaemonSet, Job",
      "Service + Ingress: discovery, load balance",
      "HPA / KEDA: autoscaling",
  ]),

  # ===== Column 2 : serverless platforms =====
  "serverless": dict(title="SERVERLESS / FaaS", col=2, color="purple", links=["-> Containers (isolation)", "-> Kubernetes (platforms)"], comps=[
      "Stateless, event-driven, ephemeral",
      "Zero-scaling: pay per activation",
      "Cold start: boot latency (slim images, warm pool)",
      "BaaS + FaaS split",
      "Orchestration vs Choreography",
      "Trigger: events -> platform",
      "Controller: lifecycle, LB, async via MOM",
      "Executor: Invoker/watchdog + env + logic",
      "Composition: merging / reflective / chaining",
  ]),
  "knative": dict(title="KNATIVE", col=2, color="purple", links=["-> Kubernetes (CRDs)", "-> Kafka (eventing src)", "NOT FaaS: microservices"], comps=[
      "@Built on Kubernetes (CRDs); not FaaS",
      "Serving: Ingress, Activator, Autoscaler",
      "Serving: Queue-Proxy sidecar, Controller",
      "CRDs: Service, Route, Configuration, Revision",
      "Revisions: scale-to-zero, traffic split, rollback",
      "Eventing: Broker, Trigger, Channel, Subscription",
      "@Eventing sources: Kafka, Pub/Sub, CloudEvents",
      "At-least-once delivery (HTTP POST)",
  ]),
  "openfaas": dict(title="OpenFAAS", col=2, color="purple", links=["-> Kubernetes/Docker", "-> Prometheus", "-> NATS"], comps=[
      "@Built on Kubernetes / Docker",
      "Gateway: HTTP trigger + controller + UI/REST",
      "Watchdog/Invoker: forking vs HTTP mode",
      "Providers: faas-provider abstraction",
      "@Prometheus: pull-based monitoring",
      "@NATS: pub/sub + req/reply messaging",
      "faasd: containerd, single-node (edge/IoT)",
  ]),
  "openwhisk": dict(title="APACHE OpenWhisk", col=2, color="purple", links=["-> Kafka", "-> Serverless"], comps=[
      "Action-oriented, event-driven FaaS",
      "NGINX: single API gateway",
      "Controller: auth + load balance (bottleneck)",
      "@Apache Kafka: async event bus",
      "Invoker: runs actions in Docker containers",
      "CouchDB: functions, params, results",
  ]),

  # ===== Column 3 : messaging & QoS =====
  "mom": dict(title="MOM / PUB-SUB", col=3, color="red", links=["-> Kafka", "-> CORBA (events)"], comps=[
      "Decoupling: space + time + synchronization",
      "Pub-Sub: producers/consumers over topics",
      "Filtering: topic / content / type based",
      "Tuple space (Linda): out/in, non-deterministic",
      "Models: centralized hub vs distributed P2P",
      "Blocks: queue mgr, relay, broker, MCA",
      "@MQTT: IoT broker, sensors (low power)",
      "OPC-UA: Industry 4.0, C/S + pub-sub",
      "@Examples: Kafka, RabbitMQ, NATS, JMS, DDS",
  ]),
  "kafka": dict(title="APACHE KAFKA", col=3, color="red", links=["-> ZooKeeper (metadata)", "-> feeds Spark/Flink"], comps=[
      "Topic: append-only, totally-ordered log",
      "Partition: ordered unit of parallelism (offset)",
      "Broker: leader/follower per partition",
      "Producer: writes to partition leader",
      "Consumer: pull model, offset-based",
      "Consumer group: 1 partition per consumer",
      "@ZooKeeper: metadata + leader election",
      "Replication (passive): leader + followers",
      "Visibility: write>replicate>ack>readable",
      "Retention & replay: reset offset",
  ]),
  "qos": dict(title="QoS (QUALITY OF SERVICE)", col=3, color="red", links=["best-effort vs guaranteed"], comps=[
      "TCP/IP best-effort vs OSI guaranteed (SLA)",
      "App classes: Elastic vs Real-time",
      "Indicators: latency/RTT, jitter, skew, QoE",
      "IntServ: per-flow reservation (RSVP)",
      "DiffServ: per-class, DSCP marking",
      "RTP / RTCP: real-time transport + control",
      "RTSP / SIP: streaming & session control",
      "Shaping: leaky bucket / token bucket",
      "Scheduling: WFQ, fair queuing, RR, GPS",
      "Congestion: RED; Mgmt: SNMP / RMON",
  ]),

  # ===== Column 4 : coordination & dependability =====
  "zookeeper": dict(title="APACHE ZOOKEEPER", col=4, color="green", links=["-> Kafka", "-> Cassandra", "-> Replication"], comps=[
      "Coordination service (hierarchical KV / znodes)",
      "Leader election (ZAB, RAFT-like)",
      "Distributed locks / config / membership",
      "Ensemble: quorum of nodes",
      "Reads scale on followers; writes via leader",
  ]),
  "replication": dict(title="REPLICATION & DEPENDABILITY", col=4, color="green", links=["-> RAFT/ZooKeeper", "-> NoSQL", "-> Group algorithms"], comps=[
      "Dependability = availability + reliability + recovery",
      "Passive (master-slave): checkpoint to backup",
      "Active: all replicas execute + agreement",
      "Eager (sync, strong) vs Lazy (async, eventual)",
      "Quorum: W+R>N, W>N/2",
      "Fault models: Safe/Silent/Operational/High-Dep",
      "Stable memory, RAID, TANDEM",
      "HA cluster: failover, heartbeat, SAN",
      "@Red Hat Cluster: CMAN, DLM, GFS, Fencing",
      "Docker Swarm",
  ]),
  "group": dict(title="GROUP COMM. & ALGORITHMS", col=4, color="green", links=["-> Replication", "-> ZooKeeper"], comps=[
      "Multicast ordering: FIFO / Causal / Atomic",
      "Reliable multicast: hold-back, NAK",
      "Lamport clock: logical time, happened-before",
      "Vector clock: causal + concurrency detection",
      "Mutual exclusion: coordinator, Ricart-Agrawala",
      "Election: Bully, Ring",
      "ISIS: ABCast / CBCast / GBCast",
      "Global snapshot: consistent cuts (Chandy-Lamport)",
      "Clock sync: UTC, NTP",
  ]),

  # ===== Column 5 : storage & data models =====
  "overlay": dict(title="OVERLAY NETWORKS & DHT", col=5, color="yellow", links=["-> NoSQL (DHT)", "-> Kafka (hashing)"], comps=[
      "ON: logical network at application level",
      "Unstructured: Napster (index), Gnutella (flood)",
      "Scale-free topology (BitTorrent, Kazaa)",
      "Structured: DHT = consistent hashing key->node",
      "Chord: finger table, O(log N) lookup",
      "Pastry / CAN: prefix routing",
      "VPN: classic overlay (IPSec/SSL tunnel)",
  ]),
  "nosql": dict(title="NoSQL", col=5, color="yellow", links=["-> Cassandra", "-> MongoDB", "-> Consistency/CAP"], comps=[
      "Models: Key-Value, Document, Wide-Column, Graph",
      "Schema-less; scale-out on COTS",
      "@Consistent hashing (DHT-based)",
      "Column-oriented storage (fast range scans)",
      "@BASE over ACID (eventual consistency)",
      "Examples: DynamoDB, BigTable, HBase, Redis, Neo4j",
  ]),
  "cassandra": dict(title="CASSANDRA", col=5, color="yellow", links=["-> DHT ring", "-> ZooKeeper", "-> quorum"], comps=[
      "Column-based key-value store (multi-DC)",
      "@Ring DHT: partitioner, token ranges",
      "Replication: RF, KeySpace, NetworkTopology",
      "Write: commit log > Memtable > SSTable (immutable)",
      "Bloom filter, compaction, tombstone",
      "Gossip membership, accrual detector (phi)",
      "Consistency levels: ANY/ONE/QUORUM/ALL",
      "Hinted handoff: always writable",
  ]),
  "mongodb": dict(title="MONGODB", col=5, color="yellow", links=["-> RAFT", "-> quorum", "-> NoSQL"], comps=[
      "Document store: BSON collections",
      "Sharded cluster: mongos, config server, shards",
      "Shard = replica set (primary + secondaries)",
      "Sharding: chunks, hash/range key",
      "@Oplog replication, RAFT election, arbiters",
      "Read preference / write concern",
      "Balancing: split + migrate chunks",
      "CAP: CP (consistency under partition)",
  ]),
  "consistency": dict(title="CONSISTENCY & CAP", col=5, color="yellow", links=["-> NoSQL", "-> Cloud edge/internal"], comps=[
      "CAP theorem: pick 2 of C / A / P",
      "ACID (RDBMS): consistency-first",
      "BASE (NoSQL): availability-first",
      "Eventual consistency: replicas converge",
      "Cloud DC: Edge (guess) + Internal (sharding, cache)",
  ]),

  # ===== Column 6 : file systems & big-data processing =====
  "distfs": dict(title="DISTRIBUTED FILE SYSTEMS", col=6, color="teal", links=["-> MapReduce (storage)", "-> Replication"], comps=[
      "NFS: stateless, remote mount",
      "AFS: client caching, callbacks",
      "GFS: master + chunkservers (64MB, 3 replicas)",
      "GFS: leases, version numbers, record append",
      "HDFS: NameNode + DataNodes",
      "Consistency: defined / undefined regions",
  ]),
  "mapreduce": dict(title="MAPREDUCE / HADOOP", col=6, color="teal", links=["-> GFS/HDFS", "-> Spark (evolution)"], comps=[
      "Map: parallel transform -> (k,v) pairs",
      "Shuffle & Sort: group by key (global barrier)",
      "Reduce: aggregate per key",
      "@Runs on GFS/HDFS (data locality)",
      "Master/Worker farm; backup tasks (stragglers)",
      "Fault tolerance: re-execute via heartbeat",
      "Hadoop: Common, HDFS, MapReduce, YARN",
      "YARN: GRM, App Master, Node Manager, containers",
  ]),
  "spark": dict(title="APACHE SPARK", col=6, color="teal", links=["-> YARN/MESOS", "-> HDFS", "-> Spark Streaming"], comps=[
      "RDD: immutable, in-memory, distributed",
      "Transformations (lazy) / Actions (eager)",
      "Lineage: fault tolerance without replication",
      "persist/cache: fast iterative reuse",
      "DAG -> stages -> tasks",
      "Driver + Cluster Master + Executors",
      "@Deploy: Standalone / YARN / MESOS",
      "~40x faster than Hadoop (iterative)",
  ]),
  "stream": dict(title="STREAM PROCESSING", col=6, color="teal", links=["-> Kafka (source)", "-> Spark (micro-batch)"], comps=[
      "Unbounded data, real-time (sec/sub-sec)",
      "Dataflow graph of operators (kernels)",
      "@Spark Streaming: micro-batch, DStream (RDD seq)",
      "Flink: true event-at-a-time streaming",
      "Flink: JobManager/TaskManager, slots, pipelining",
      "Back-pressure handling",
      "Guarantees: at-least-once (Storm) / exactly-once",
      "Flink snapshots: barriers, checkpoints",
      "Windows, event-time, watermark",
  ]),
}

# ── arrows between containers (short, adjacent) ───────────────
# (src, tgt, label, dashed)
EDGES = [
    ("microservices", "containers",  "deployed in", False),
    ("containers",    "kubernetes",  "orchestrated by", False),
    ("middleware",    "corba",       "e.g.", False),
    ("cloud_models",  "openstack",   "IaaS", False),
    ("serverless",    "knative",     "platform", False),
    ("knative",       "kubernetes",  "based on", True),
    ("openfaas",      "kubernetes",  "based on", True),
    ("openwhisk",     "kafka",       "uses", True),
    ("mom",           "kafka",       "e.g.", False),
    ("kafka",         "zookeeper",   "metadata", True),
    ("group",         "replication", "enables", False),
    ("replication",   "zookeeper",   "uses", True),
    ("overlay",       "nosql",       "DHT", False),
    ("nosql",         "cassandra",   "e.g.", False),
    ("distfs",        "mapreduce",   "storage", False),
    ("mapreduce",     "spark",       "evolved into", False),
    ("spark",         "stream",      "Spark Streaming", False),
]

# ── XML helpers ───────────────────────────────────────────────
def xa(s):
    return (s.replace("&", "&amp;").replace('"', "&quot;")
             .replace("<", "&lt;").replace(">", "&gt;"))

def container_h(t):
    return HDR_H + PAD + len(t["comps"]) * (COMP_H + COMP_GAP) + 8 + 54 + PAD

def build():
    L = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<mxfile host="app.diagrams.net" version="21.0.0">',
        '  <diagram name="ICCBD Concept Map" id="iccbd-concept">',
        '    <mxGraphModel dx="2800" dy="2000" grid="1" gridSize="10" guides="1" '
        'tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" '
        'pageWidth="1169" pageHeight="827" math="0" shadow="0">',
        '      <root>',
        '        <mxCell id="0" />',
        '        <mxCell id="1" parent="0" />',
    ]

    # title
    L += [
        '        <mxCell id="title" value="ICCBD &#8212; Concept Map: technologies &amp; their core components" '
        'style="text;html=1;fontSize=22;fontStyle=1;align=left;verticalAlign=middle;" vertex="1" parent="1">',
        '          <mxGeometry x="40" y="24" width="1100" height="40" as="geometry" />',
        '        </mxCell>',
        '        <mxCell id="legend" value="Solid box = component &#160;&#160;|&#160;&#160; Dashed box = pointer to another technology (&#8594;) &#160;&#160;|&#160;&#160; Arrow = based-on / feeds / evolves &#160;&#160;|&#160;&#160; &#8220;Links &#8594;&#8221; chip lists cross-references" '
        'style="text;html=1;fontSize=12;align=left;verticalAlign=middle;fontColor=#555555;" vertex="1" parent="1">',
        '          <mxGeometry x="40" y="74" width="1500" height="24" as="geometry" />',
        '        </mxCell>',
    ]

    # place containers, stacking per column
    y_cursor = {c: TOP_Y for c in COL_X}
    order = list(TECH.keys())
    for tid in order:
        t = TECH[tid]
        col = t["col"]
        x = COL_X[col]
        y = y_cursor[col]
        h = container_h(t)
        fill, stroke = T[t["color"]]

        sw_style = (f"swimlane;fontStyle=1;align=center;startSize={HDR_H};"
                    f"fillColor={fill};strokeColor={stroke};fontSize=13;rounded=1;arcSize=4;")
        L += [
            f'        <mxCell id="{tid}" value="{xa(t["title"])}" style="{xa(sw_style)}" vertex="1" parent="1">',
            f'          <mxGeometry x="{x}" y="{y}" width="{BOX_W}" height="{h}" as="geometry" />',
            f'        </mxCell>',
        ]

        cy = HDR_H + PAD
        for i, comp in enumerate(t["comps"]):
            pointer = comp.startswith("@")
            text = comp[1:] if pointer else comp
            # bold the part before the first colon (HTML tags escaped for XML; html=1 renders them)
            if ":" in text:
                head, tail = text.split(":", 1)
                label = f"&lt;b&gt;{xa(head)}&lt;/b&gt;:{xa(tail)}"
            else:
                label = f"&lt;b&gt;{xa(text)}&lt;/b&gt;"
            if pointer:
                cstyle = ("rounded=1;whiteSpace=wrap;html=1;dashed=1;dashPattern=6 4;"
                          "fillColor=#ffffff;strokeColor=" + stroke +
                          ";fontSize=11;align=left;verticalAlign=middle;spacingLeft=8;spacingRight=6;")
                label = "&#8594; " + label
            else:
                cstyle = ("rounded=1;whiteSpace=wrap;html=1;"
                          "fillColor=#ffffff;strokeColor=" + stroke +
                          ";fontSize=11;align=left;verticalAlign=middle;spacingLeft=8;spacingRight=6;")
            L += [
                f'        <mxCell id="{tid}_c{i}" value="{label}" style="{cstyle}" vertex="1" parent="{tid}">',
                f'          <mxGeometry x="{PAD}" y="{cy}" width="{BOX_W - 2*PAD}" height="{COMP_H}" as="geometry" />',
                f'        </mxCell>',
            ]
            cy += COMP_H + COMP_GAP

        # links chip
        if t.get("links"):
            links_txt = "&#8594; Links: &#160;" + " &#160;&#8226;&#160; ".join(xa(x.replace("-> ", "")) for x in t["links"])
            lstyle = ("rounded=1;whiteSpace=wrap;html=1;dashed=1;dashPattern=2 2;"
                      f"fillColor={fill};strokeColor={stroke};fontSize=11;fontStyle=2;"
                      "align=left;verticalAlign=middle;spacingLeft=8;spacingRight=6;")
            L += [
                f'        <mxCell id="{tid}_links" value="{links_txt}" style="{lstyle}" vertex="1" parent="{tid}">',
                f'          <mxGeometry x="{PAD}" y="{cy+2}" width="{BOX_W - 2*PAD}" height="50" as="geometry" />',
                f'        </mxCell>',
            ]

        y_cursor[col] = y + h + COL_VGAP

    # edges
    for n, (src, tgt, label, dashed) in enumerate(EDGES, 1):
        if dashed:
            es = ("edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;dashed=1;"
                  "endArrow=open;endFill=0;strokeColor=#888888;fontSize=10;fontColor=#555555;")
        else:
            es = ("edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;"
                  "endArrow=block;endFill=1;strokeColor=#555555;fontSize=10;fontColor=#555555;")
        L += [
            f'        <mxCell id="edge{n}" value="{xa(label)}" style="{es}" edge="1" parent="1" source="{src}" target="{tgt}">',
            f'          <mxGeometry relative="1" as="geometry" />',
            f'        </mxCell>',
        ]

    L += ['      </root>', '    </mxGraphModel>', '  </diagram>', '</mxfile>']
    return "\n".join(L)

if __name__ == "__main__":
    xml = build()
    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.write(xml)
    print(f"Written {OUTPUT}  ({len(xml):,} bytes, {len(TECH)} technologies, {len(EDGES)} arrows)")
    print("Open at https://app.diagrams.net (File > Open from > Device) or desktop draw.io")
