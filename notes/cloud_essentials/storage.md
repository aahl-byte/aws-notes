<link rel="stylesheet" href="./css/globals.css">

# storage

where your data lives, and how it survives. once you can run code ([compute](./compute_types.md)), the next question is always: *where does the data go, and is it still there tomorrow?*

---

## the outcome
the job of storage is to <em>keep data so it survives hardware failure and stays reachable by the right things</em>.

- disks die, instances disappear, whole buildings can go offline — your data should outlive all of it.
- "reachable by the right things" matters as much as "survives": data a server can't read, or that the wrong account *can* read, has failed you.
- everything below is a different bargain between durability, how fast you reach the data, who can reach it, and what you pay (see [billing & pricing](./billing_pricing.md)).
- durability comes from spreading copies across [Availability Zones](./global_infrastructure.md) — the more independent the copies, the more failure they survive.

---

## the key idea: three shapes of storage
before any service name, learn the three *shapes* data can take. nearly every storage choice is really a choice of shape first, service second.

think of where you keep things in real life:

### object storage
a self-service locker room — you hand over a whole item with a label, get it back whole.
- you store and retrieve <em>entire files as a unit</em> (the "object") — you don't edit the middle of one, you replace the whole thing.
- each object carries its data plus metadata and a unique key (its label).
- there's no folder tree underneath — it's a flat pool of labelled items that *looks* like folders.
- ideal for things written once and read many times: images, backups, logs, video.
- this is <em>Amazon S3</em>.

### block storage
a raw hard drive bolted to one computer.
- data is split into fixed-size <em>blocks</em>; the OS treats it like a physical disk it can format and write to anywhere.
- change one byte and only that block is rewritten — fast, fine-grained edits.
- attached to a *single* machine at a time, like a drive you can only plug into one laptop.
- ideal for the live disk of a running server: operating systems, databases, anything doing constant small writes.
- this is <em>Amazon EBS</em>.

### file storage
a shared network drive the whole office mounts.
- data lives in a <em>file system with real folders and paths</em>, exactly like the drives you already use.
- many machines mount it at once and all see the same files.
- ideal when several servers must share and edit the same files.
- this is <em>Amazon EFS</em> (and FSx).

> the contrast, in one line: object = whole files in a flat pool (S3), block = a raw disk for one server (EBS), file = a shared folder tree for many (EFS). hold this and the rest is detail.


---

## amazon S3 — object storage
store and retrieve any amount of data as objects in <em>buckets</em>.

- a **bucket** is a top-level container with a globally-unique name; an **object** is a file plus its metadata, found by its key.
- the namespace is <em>flat</em> — "folders" are just a naming convention in the key (`photos/2026/cat.jpg` is one key, not three folders).
- **durability is 11 9's** (99.999999999%) — store 10 million objects and you'd expect to lose one roughly every 10,000 years. AWS gets this by copying objects across multiple AZs for you.
- scales effectively without limit — you never provision capacity, you just put more in.

### storage classes — the cost vs access tradeoff
same durability across the classes; what changes is <em>how quickly and cheaply you can get the data back</em>. the rule: the colder (rarely accessed) the data, the cheaper to store but the slower/pricier to retrieve.

- **S3 Standard** — frequent access, instant. the default; websites, active content.
- **S3 Standard-IA** (infrequent access) — cheaper storage, you pay a retrieval fee. accessed monthly-ish but needed instantly. stored across multiple AZs.
- **S3 One Zone-IA** — like Standard-IA but kept in <em>a single AZ</em>, so cheaper but lost if that AZ is destroyed. use only for data you can recreate.
- **S3 Intelligent-Tiering** — you don't know the access pattern, so let S3 move objects between tiers automatically for a small monitoring fee.
- **S3 Glacier Instant Retrieval** — archive priced storage, but milliseconds to retrieve. rarely touched data you still need *now* when you touch it.
- **S3 Glacier Flexible Retrieval** — cheaper archive; retrieval takes minutes to hours. backups, disaster recovery.
- **S3 Glacier Deep Archive** — cheapest of all; retrieval takes hours. long-term compliance archives you may never read.

when to use which:
- accessed all the time → Standard
- accessed sometimes, needed instantly → Standard-IA (or One Zone-IA if recreatable)
- access pattern unknown / changing → Intelligent-Tiering
- archive but might need it fast → Glacier Instant Retrieval
- archive, can wait minutes–hours → Glacier Flexible Retrieval
- archive, can wait hours, cheapest → Glacier Deep Archive

#### lifecycle policies
rules that <em>move objects between classes automatically as they age</em>.
- e.g. Standard for 30 days, then Standard-IA, then Glacier after 90, then delete after a year.
- you set the policy once; you don't hand-migrate objects.

#### versioning
keep <em>every version of an object</em> instead of overwriting.
- protects against accidental deletes and overwrites — recover an earlier copy.
- a delete just adds a "delete marker"; the old versions are still there.

### when to use S3
- static website assets, images, video, documents.
- backups, archives, and data lake storage.
- anything written-once / read-many where you handle whole files.
- NOT for the live disk of an EC2 instance (that's EBS) — and NOT when you need to *query inside* the data, where a [database](./databases.md) fits better.


---

## amazon EBS — block storage
virtual hard drives you <em>attach to a single EC2 instance</em>.

- behaves like a physical disk: format it, install an OS, run a database on it.
- attached to *one* instance at a time and lives in <em>one AZ</em> (same AZ as its instance — see [compute types](./compute_types.md)).
- persists independently of the instance: stop/terminate the instance and the volume can survive.

### volume types (high level)
- **gp3 / gp2 (general purpose SSD)** — the balanced default for most workloads: boot volumes, dev, small-to-medium databases.
- **io2 / io1 (provisioned IOPS SSD)** — high, guaranteed performance for I/O-heavy critical databases.
- **HDD types (st1 / sc1)** — cheaper spinning disk for large, sequential, throughput-style workloads (big logs, data processing).

### snapshots
point-in-time backups of a volume, <em>stored in S3</em> behind the scenes.
- incremental: after the first, only changed blocks are saved.
- restore a snapshot into a new volume, even in another AZ — this is how you move/back up block data across the single-AZ limit.

### when to use EBS
- the boot/system disk of an EC2 instance.
- databases and apps doing frequent, small read/writes to a disk.
- when exactly one instance needs the disk and you want disk-like behavior.


---

## amazon EFS — file storage
a <em>shared file system many instances mount at once</em>.

- a real file-system with folders and paths, accessed over the network.
- <em>spans multiple AZs</em> automatically, so it survives an AZ failure (unlike a single EBS volume).
- scales capacity up and down on its own — you never provision size.
- mounted by many EC2 instances simultaneously, all seeing the same files.

### EFS vs EBS — the contrast that matters
this is the question the exam (and real designs) keep asking:

- **EBS** = a disk for <em>one</em> instance, in <em>one</em> AZ. you size it; you back it up with snapshots.
- **EFS** = a shared file system for <em>many</em> instances, across <em>multiple</em> AZs. it auto-scales.
- reach for EFS when several servers must share files (content management, shared home directories, web farms).
- reach for EBS when a single instance needs a fast local disk (its OS, its database).


---

## the rest, briefly
you'll see these named; know what problem each solves.

### amazon FSx
fully managed <em>third-party file systems</em>.
- when you specifically need Windows File Server (SMB), Lustre (HPC), NetApp ONTAP, or OpenZFS — feature sets EFS doesn't offer.
- EFS is the Linux/NFS shared file system; FSx is for everything else file-shaped.

### AWS storage gateway
a bridge between <em>on-premises systems and AWS storage</em>.
- lets local apps use cloud storage as if it were local, often caching hot data on-site.
- the hybrid answer while you still run a data center.

### AWS backup
<em>centralized, policy-driven backup</em> across many AWS services.
- one place to schedule and manage backups for EBS, EFS, databases, and more — instead of per-service snapshots managed by hand.


---

## choosing storage — the summary
start from the shape, then the need:

- whole files, written-once read-many, any scale → <em>S3</em> (object). pick the storage class by how often and how fast you need it back.
- a disk for one EC2 instance (OS, database) → <em>EBS</em> (block).
- a folder tree shared by many Linux instances, multi-AZ → <em>EFS</em> (file).
- Windows / Lustre / specialty file system → <em>FSx</em>.
- bridge to an on-prem data center → <em>Storage Gateway</em>.
- one console to manage backups everywhere → <em>AWS Backup</em>.
- need to *query and relate* the data, not just store and fetch it → not storage at all, see [databases](./databases.md).
