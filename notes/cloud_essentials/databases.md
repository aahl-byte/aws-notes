<link rel="stylesheet" href="./css/globals.css">

# Resources & Links

## Database Links
- [database resource list](https://aws.amazon.com/products/databases/)
- [database blog](https://aws.amazon.com/blogs/database/)
- [database services overview](https://docs.aws.amazon.com/whitepapers/latest/aws-overview/database.html)
- [which database to choose](https://aws.amazon.com/products/databases/)




# Notes: Databases

## the outcome
the point of a database is to keep data <em>organized so you can query and relate it reliably</em> — and to let AWS run the database engine so you don't have to.

- raw storage (see [./storage.md](./storage.md)) holds *files*; a database holds *structured records you can ask questions about*
- you could run a database yourself on EC2 (see [./compute_types.md](./compute_types.md)) — install the engine, patch the OS, take your own backups, fix your own failover
- "managed" means AWS does that undifferentiated work for you, so you only own the data and the queries

| you do it on EC2 | AWS manages it (RDS, etc.) |
| --- | --- |
| install & patch the engine | done for you |
| backups & restore | automated |
| failover when a server dies | automatic (Multi-AZ) |
| scaling | mostly a config change, not a re-architecture |

> rule of thumb: reach for a managed database first. only self-manage on EC2 when you need control AWS doesn't expose (a specific version, an exotic extension, a license you already own).


---

## the key idea first: relational vs non-relational
before any service, decide the *shape* of your data. this single choice drives everything else.

### relational (SQL)
data lives in <em>tables with a fixed schema</em>, and tables relate to each other through shared keys.
- think a spreadsheet where every row has the same columns, and sheets reference each other
- you define the structure up front; the database enforces it
- strength: *joins* — answering questions that span many tables ("which customers in this region bought this product")
- strength: transactions that are all-or-nothing (move money between two accounts and never lose a cent)
- cost: the schema is rigid, and scaling usually means a *bigger* server (scale up)

### non-relational (NoSQL)
data lives in <em>flexible items, not fixed rows</em> — most often key-value or document.
- think a giant dictionary: hand it a key, get the item back, fast
- each item can have different attributes; no schema to migrate when your data shape changes
- strength: huge scale by spreading data across many servers (scale *out*, horizontally)
- strength: predictable speed at any size
- cost: no real joins — you design around the queries you know you'll make

when to use which:
- **relational** when relationships and consistency matter: orders, inventory, finance, anything you'll slice with complex queries
- **non-relational** when you need massive scale and simple lookups: user sessions, shopping carts, IoT events, leaderboards
- if you're unsure and your data is structured with clear relationships, start relational


---

## Amazon RDS
managed <em>relational</em> databases — you pick an engine, AWS runs it.

- supported engines: MySQL, PostgreSQL, MariaDB, Oracle, SQL Server
- what "managed" buys you: automated patching, automated backups, point-in-time restore, and automatic failover
- you still own: the schema, the queries, and choosing the instance size

### Multi-AZ vs read replicas
these two get confused constantly — they solve *different* problems. keep the contrast crisp.

#### Multi-AZ — for availability
a <em>standby copy in another Availability Zone</em> that takes over if the primary fails.
- synchronous copy — the standby is always up to date
- you do not read or write to it; it sits ready
- if the primary dies, RDS fails over to the standby automatically
- this is about *surviving failure*, not about going faster (see [./well_architected.md](./well_architected.md) — reliability)

#### read replicas — for scaling reads
<em>extra read-only copies</em> that take load off the primary.
- asynchronous copies you *can* query
- point read-heavy traffic (reports, dashboards) at the replicas so the primary is free to write
- this is about *performance under read load*, not failover

> one line to remember: Multi-AZ keeps you *up*, read replicas make you *fast*.


---

## Amazon Aurora
AWS's cloud-native relational engine, <em>MySQL- and PostgreSQL-compatible</em>.

- speaks the same wire protocol as MySQL/PostgreSQL, so existing apps and tools just work
- why it exists vs vanilla RDS: AWS rebuilt the storage layer for the cloud — faster (up to ~5x MySQL, ~3x PostgreSQL), replicates data across multiple AZs by default, self-healing storage
- costs more than plain RDS, but you trade money for performance and built-in durability

when to use:
- you want relational + want to push throughput and resilience further than stock RDS
- you're already on MySQL/PostgreSQL and want a drop-in upgrade
- stick with plain RDS when cost matters more than peak performance, or you need an engine Aurora doesn't emulate (Oracle, SQL Server)


---

## Amazon DynamoDB
managed, <em>serverless NoSQL key-value</em> database.

- serverless: no instances to size or patch — you don't see a server at all
- single-digit-millisecond response times, at any scale
- scales automatically as traffic grows; you don't re-architect
- the trade-off you accept: design around key lookups, not ad-hoc joins

when to use DynamoDB vs RDS:
- **DynamoDB** for huge scale, simple/known access patterns, and spiky traffic: carts, sessions, gaming state, IoT
- **RDS/Aurora** when you need joins, complex queries, or strong relational consistency
- the deciding question is your *data shape and query pattern*, decided back in the relational-vs-NoSQL section — not the service first


---

## supporting services
each fills a niche the main two don't. brief, with the gap each closes.

### Amazon ElastiCache
in-memory <em>cache</em> in front of a database (Redis or Memcached).
- keeps hot data in memory so repeated reads never hit the database
- use when the same queries are read over and over and latency must be tiny

### Amazon Redshift
a <em>data warehouse</em> for analytics over huge historical datasets.
- this is the OLTP vs OLAP split worth naming:
  - **OLTP** (online *transaction* processing) — many small fast reads/writes, "what is this customer's current balance." that's RDS, Aurora, DynamoDB.
  - **OLAP** (online *analytical* processing) — a few enormous queries over mountains of data, "what were sales trends across all regions for three years." that's Redshift.
- use for big reporting and BI queries, not day-to-day app traffic

### Amazon DocumentDB
managed <em>document</em> database, MongoDB-compatible.
- for JSON-style document workloads where you'd otherwise self-manage MongoDB

### Amazon Neptune
managed <em>graph</em> database.
- for data that's mostly *relationships*: social networks, recommendation engines, fraud rings
- when the question is "how is X connected to Y," not "what are X's columns"

### AWS DMS (Database Migration Service)
moves an existing database <em>into AWS</em> with minimal downtime.
- migrate on-prem → cloud, or between engines
- the on-ramp, not a place data lives long-term


---

## choosing a database
work right → left: start from the data shape and the question you ask of it, then pick the service.

- structured data with relationships and joins → **RDS** (or **Aurora** for more speed/durability)
- key-value at massive scale, simple lookups → **DynamoDB**
- speeding up repeated reads → **ElastiCache** in front of the above
- analytics over large historical data → **Redshift**
- documents → **DocumentDB**; graphs/relationships → **Neptune**
- moving an existing database in → **DMS**

remember: pick the *shape* first (relational vs NoSQL), then the *service*, then the *settings*. and for who can reach the data and how it's encrypted, see [./security_identity.md](./security_identity.md).

### where to go next
- [storage](./storage.md) — the raw bytes a database is built on; when you need files, not queries
- [running code](./compute_types.md) — the compute that talks to these databases
- [billing & pricing](./billing_pricing.md) — managed databases bill for what they run; how that shows up on your bill
