<link rel="stylesheet" href="./css/globals.css">

# security & identity

keeping the system safe is really one question asked over and over: *can this person, or this service, do this thing — and should they be able to?* this page builds the machinery for answering it.

---

## the outcome: only the right entities can do the right things

every breach you've ever read about is a version of the same failure: someone (or something) could do a thing they should never have been able to do. read a database. delete a bucket. spin up servers on your bill.

so the destination is narrow and precise:
- the <em>right entities</em> — people *and* services — can do the <em>right things</em>
- and nothing and no one else can do anything else
- and your data stays unreadable to anyone who isn't on that list, even if they get their hands on it

everything below is in service of that one sentence. identity decides *who can act*; encryption protects *the data itself*; the threat services *watch the walls*. start from "only the right things happen" and the rest has somewhere to land.

> security isn't a feature you bolt on. it's a property of *who can do what*, designed in from the start.

---

## who secures what: the shared responsibility model (the deep version)

[cloud concepts](./cloud_concepts.md) introduced this as a partnership: AWS secures the building, you lock your own apartment. that analogy got you the shape. now the precise version, because *misjudging the line is itself the vulnerability*.

> AWS is responsible for security <em>of</em> the cloud. you are responsible for security <em>in</em> the cloud.

the split is about *who can physically touch the thing*.

### AWS — security *of* the cloud
the foundation you rent but never see:
- the physical datacenters — buildings, guards, locked racks, power, cooling
- the host hardware and the hypervisor that slices it into instances
- the global network backbone between regions and availability zones
- the *internals* of managed services — the engine that runs S3, the database software under DynamoDB, the Lambda execution sandbox

you cannot patch a datacenter or harden a hypervisor, so you don't have to. that half is AWS's job and AWS's alone.

### you — security *in* the cloud
everything you put *on top of* that foundation, and every decision about it:
- your **data** — what you store, how it's classified, whether it's encrypted
- your **access controls** — who has accounts, what they're allowed to do (this is IAM, below)
- your **configuration** — is that S3 bucket public? is that security group open to the world?
- your **own software and, where applicable, the OS** — patching, updates, firewall rules

### the line *moves* depending on the service
this is the part the analogy hides, and the part exams and real outages turn on. the more managed the service, the more of the stack AWS takes over.

- **EC2 (you rent a virtual machine)** — AWS secures the hardware and hypervisor; *you* own the guest OS, its patches, the firewall config, the app, and the data. lots of responsibility lands on you.
- **managed service like RDS** — AWS now also patches the database engine and the OS under it; you keep the data, access rules, and network configuration. your half shrank.
- **serverless like Lambda or S3** — AWS handles the OS, the runtime, the scaling, the patching; *you* own essentially only your code/data and who may touch it. your half is at its smallest.

the rule to carry: **the more AWS manages, the less you do — but you *never* hand off your data and your access decisions.** those are always yours.

> see this same line drawn for network defenses in [networking](./networking.md), and as a formal design lens in the [well-architected security pillar](./well_architected.md).

---

## IAM — deciding who can do what

your half of the model leans on one service above all others: **IAM (identity and access management)**. it's the bouncer at every door in your account.

it answers two separate questions — keep them separate, because conflating them is where confusion (and holes) come from:

- **authentication — *who are you?*** proving identity. a password, an access key, MFA.
- **authorization — *what are you allowed to do?*** once you're known, which actions on which resources are permitted.

> being *known* (authenticated) is not being *allowed* (authorized). a valid login with no permissions can do nothing — and that's the design working correctly.

### the root user (and why you lock it away)
when you create an AWS account, it comes with one all-powerful identity tied to the account's email: the **root user**. it can do *literally anything*, including close the account and change billing.

- use it once to set up, then <em>stop using it</em> for daily work
- enable **MFA (multi-factor authentication)** on it immediately — a password alone is one stolen secret away from total compromise
- create regular IAM identities for actual work; treat root like the master key you seal in a safe

### users, groups, and roles
three ways an identity exists. the contrast is the lesson:

- **IAM user** — a fixed identity for *a specific person or app*, with long-lived credentials (password, access keys). think "a named employee badge."
- **IAM group** — a bucket of users you attach permissions to *once*, so every member inherits them. "the developers." you manage the group, not each person. groups hold no credentials themselves.
- **IAM role** — an identity with *no permanent credentials* that an entity <em>assumes to get temporary ones</em>. think "a visitor badge you check out, use, and return."

#### when to use a role instead of a user
roles are the grown-up answer, and the one that matters most:
- **a service needs to act** — let an EC2 instance read from S3 by attaching a role, so you never bake access keys into the machine (keys leak; temporary credentials expire on their own)
- **cross-account access** — let an identity in one account assume a role in another, without creating a second user
- **federated / temporary access** — humans logging in from an external identity provider get a role, not a permanent account

the through-line: **prefer temporary credentials over long-lived secrets.** a credential that expires can't haunt you for years after it leaks.

### policies — the rules themselves
permissions are written as **policies**: JSON documents that **allow** or **deny** specific actions on specific resources. attach a policy to a user, group, or role and you've defined what it may do.

- explicit **deny** always wins over any allow — a hard stop you can rely on
- no matching allow means *implicitly* denied — IAM is locked-down by default, which is the safe default

### the principle that governs all of it: least privilege
> grant <em>only the permissions required to do the task, and nothing more</em>.

- start from zero and add what's needed — don't start from "admin" and try to trim
- a role that only reads one bucket can't delete your database, even if its credentials leak
- least privilege is *the* habit that turns "a mistake" into "a small mistake" instead of "a breach"

---

## managing many accounts

one account is fine to learn in. real organizations run *dozens* — separate accounts for prod, dev, each team — so a mistake in one can't spill into another. two services keep that fleet sane.

### AWS Organizations
a way to centrally manage *many AWS accounts* as one tree.
- group accounts into **organizational units (OUs)** and apply rules to whole branches
- consolidated billing across every account, plus volume discounts pooled together

#### service control policies (SCPs)
the org-level guardrail: an SCP sets the <em>maximum permissions any account in that branch can ever have</em>.
- it doesn't *grant* anything — it caps what IAM inside the account is even allowed to grant
- e.g. "no account in the dev OU may use regions outside the US" — true no matter what a dev's IAM policy says
- think of SCPs as the ceiling and IAM policies as the furniture: IAM can't reach above the ceiling

### IAM Identity Center (SSO)
single sign-on across all your accounts and many business apps from one login.
- connect your existing company directory and let people use one identity everywhere
- when to use: more than a handful of users or accounts — stop managing separate logins per account

---

## watching the walls: protective services

identity controls *who may act*. these services assume someone hostile is *trying anyway*, and they sit at different layers of defense. one crisp line and a "when" for each.

- **AWS Shield** — absorbs **DDoS** attacks (floods of traffic trying to knock you offline). always-on basic protection is free; *Shield Advanced* adds deeper defense and cost protection. when: anything internet-facing.
- **AWS WAF (web application firewall)** — filters **malicious web requests** (SQL injection, bad bots) by rules, before they reach your app. when: you run a website or API and want to block bad requests by pattern.
- **Amazon GuardDuty** — continuous **threat detection** that watches your logs for suspicious behavior (a server suddenly talking to a known-bad address). when: you want an always-on detective, no agents to install.
- **Amazon Inspector** — automated **vulnerability scanning** of your EC2 and container workloads against known CVEs. when: "is anything I'm running known to be exploitable?"
- **Amazon Macie** — uses ML to **discover sensitive data** (like personal info / PII) sitting in your S3 buckets. when: "do I even know where my secrets are stored?"

> note the layering: Shield and WAF guard the *front door* (incoming traffic), GuardDuty and Inspector *watch what's already inside*, Macie *audits the data itself*. no single one is "security" — they stack.

---

## protecting the data itself

even with perfect access control, assume someone eventually gets the bytes. **encryption** makes those bytes useless without a key. two places it matters:

- **encryption at rest** — data scrambled *while stored* on disk, so a stolen drive or snapshot is gibberish
- **encryption in transit** — data scrambled *while moving* over the network (TLS/HTTPS), so it can't be read mid-flight

### AWS KMS (key management service)
the keys that do the scrambling have to be created, stored, and rotated safely — that's KMS.
- create and control the encryption keys most AWS services use to encrypt your data at rest
- you control *who can use each key* (back to IAM), so access to data and access to its key are both gated

### AWS Secrets Manager
a vault for **secrets your applications need** — database passwords, API keys.
- store them centrally instead of hardcoding them in source (where they leak)
- can **rotate** them automatically, so a leaked secret has a short life

### AWS Certificate Manager (ACM)
handles the **TLS certificates** that make encryption in transit (HTTPS) work.
- provision and *auto-renew* certs for free, so the padlock in the browser never silently expires
- when: you terminate HTTPS on AWS (e.g. a load balancer) and don't want to babysit cert renewals

---

## proving you're compliant: AWS Artifact

at some point an auditor or customer asks "prove AWS meets SOC 2 / ISO / PCI." **AWS Artifact** is the self-service portal for AWS's **compliance reports and agreements**.
- download AWS's audit reports on demand — the evidence for the *of the cloud* half
- remember: Artifact proves AWS's side. proving *your* side (your config, your access) is still on you

---

## recap: security is layered (defense in depth)

no single control is "secure." real safety is **defense in depth** — overlapping layers, so one failure isn't a breach:

- the **shared responsibility model** tells you which layers are even yours to build
- **IAM + least privilege** is the spine — grant the minimum, prefer temporary credentials, lock away root
- **Organizations + SCPs** cap what whole fleets of accounts can do
- **Shield / WAF / GuardDuty / Inspector / Macie** watch the front door, the interior, and the data
- **encryption + KMS / Secrets Manager / ACM** make the data worthless to whoever slips past the rest
- **Artifact** lets you prove the foundation you stand on

bring it back to the outcome: *only the right entities can do the right things.* every service on this page is one more layer enforcing that single sentence — and least privilege is the habit that keeps every layer honest.

---

## where to go next

- [cloud concepts](./cloud_concepts.md) — where the shared responsibility model was introduced
- [networking](./networking.md) — security groups & NACLs, the network-layer line of defense
- [judging a good design](./well_architected.md) — the security pillar of the well-architected framework
