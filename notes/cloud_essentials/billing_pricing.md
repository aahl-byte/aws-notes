<link rel="stylesheet" href="./css/globals.css">

# billing & pricing

renting IT instead of owning it ([cloud concepts](./cloud_concepts.md)) means the bill now tracks what you *do*, not what you *bought*. that's powerful — and it's exactly why a cloud bill can surprise you. this page is about making sure it doesn't.

---

## the outcome: a bill you understand and control

the goal isn't "spend less." it's <em>no surprises</em> — you can answer three questions at any moment:

- **what did i spend, and on what?**
- **what will this cost before i build it?**
- **warn me before i blow past a number i care about.**

everything below exists to answer one of those three. if you finish this page able to ask the right tool the right question, it worked.

---

## the pricing mental model: three principles

almost every AWS price decision comes back to three ideas. learn these first and the specifics slot into place.

> **pay as you go. pay less when you reserve. pay less per unit as you grow.**

### pay as you go
- you pay for what you use, when you use it — like a utility meter, not a subscription
- turn a resource off and that cost goes to zero
- this is the default, and it's the whole reason capex became opex ([why that matters](./cloud_concepts.md))

### pay less when you reserve
- if usage is *predictable*, commit to it ahead of time and AWS discounts the rate
- the trade: a 1- or 3-year commitment in exchange for a lower price than on-demand
- this is the engine behind EC2 savings plans and reserved instances — covered in depth in [compute pricing models](./compute_types.md)

### pay less per unit as you grow
- the more you use, the cheaper each unit gets — AWS passes its [economies of scale](./cloud_concepts.md) down as tiered, volume-based pricing
- e.g. the first chunk of storage costs more per GB than the next; transfer rates step down as volume climbs
- you don't negotiate this — it's built into the rate card

> when a price confuses you, ask which principle it's expressing. it's almost always one of these three.

---

## what actually drives the cost

a bill is mostly three things. knowing them tells you where to look when a number jumps.

### compute — time × size
- you pay for *how long* a resource runs × *how big* it is
- a bigger instance running longer costs more — idle-but-running still costs (it's reserved for you)
- the lever: turn things off, right-size them, and commit to the steady baseline (see [compute pricing models](./compute_types.md))

### storage — amount × class
- you pay for *how much* data you keep × the *storage class* (how fast/durable/available it needs to be)
- colder, slower classes are cheaper per GB — you trade instant access for a lower rate
- the lever: don't store hot data in an expensive tier longer than you need to

### data transfer — the one that trips people up
- this is the line item people forget, so spotlight it:

> **data coming IN is generally free. data going OUT to the internet costs money.**

- **inbound** (uploads into AWS) — generally free; AWS wants your data in
- **outbound** (data leaving AWS for the internet) — billed per GB, and it adds up fast for media, downloads, or chatty APIs
- transfer *between* AWS services can also cost — e.g. crossing regions or availability zones
- the lever: keep traffic inside a region where you can, cache at the edge, and watch what you're shipping out

---

## the free tier

AWS lets you learn and prototype without a bill — but "free" comes in three flavors, and mixing them up is how a "free" experiment starts charging.

### always free
- never expires — available to every account, forever
- for services with a generous standing allowance (e.g. a monthly slice of Lambda requests)
- when it applies: low-volume usage that stays under the standing limit

### 12-months free
- free for your **first 12 months** after sign-up, then reverts to pay-as-you-go
- the classic starter allowances (e.g. a small EC2 instance for a set number of hours/month)
- when it applies: kicking the tires in your first year — but watch the calendar and the limits

### short-term trials
- free for a **fixed window** that starts when you *activate* a specific service (not at sign-up)
- when it applies: trying a particular service for a limited promotional period

> the trap: "free tier" doesn't mean "can't be charged." exceed an allowance, or pass the time window, and normal rates resume. set a budget (below) so you find out *before* the bill does.

---

## visibility & control: who answers which question

these are the tools that deliver the outcome at the top. map each to the question it answers rather than memorizing them in a row.

### AWS Billing dashboard
- the front page of your spend — current charges, this month so far, at a glance
- answers: **"what's it doing right now?"**

### AWS Cost Explorer
- visualize and analyze usage and cost <em>over time</em>, with filters and trends
- spot what's growing, which service drives the bill, where the spikes are
- answers: **"what did i spend, and why is it changing?"**

### AWS Budgets
- set a threshold and get **alerted** as you approach or exceed it
- the proactive guardrail — it reaches out to *you* instead of waiting for you to look
- answers: **"warn me before i cross a line."**

### AWS Cost & Usage Report (CUR)
- the most **granular** export of billing data — every line item, for deep analysis
- when to use: you've outgrown Cost Explorer's charts and need raw data to slice yourself
- answers: **"give me the full ledger."**

### AWS Pricing Calculator
- estimate cost <em>before you build</em> — model an architecture and get a projected bill
- when to use: planning, budgeting, and comparing design options up front
- answers: **"what *will* this cost?"**

> contrast worth holding: Cost Explorer and CUR look *backward* at what happened; the Pricing Calculator looks *forward* at what would; Budgets watches the *present* and alerts. past, future, now.

---

## many accounts: organizations & consolidated billing

once you have more than one account (teams, environments, projects), managing separate bills gets painful. AWS turns many accounts into one billing relationship.

### AWS Organizations
- centrally manage a group of AWS accounts as one unit
- apply policies and structure across all of them from the top

### consolidated billing
- all member accounts roll up into **one bill** paid by the management account
- you still see per-account detail, but pay once
- the bonus: usage is **pooled**, so everyone shares the volume discounts (principle three) — combined usage reaches the cheaper tiers faster than any account would alone

> when to use: any time you run more than one account and want a single bill plus shared volume pricing.

---

## thinking bigger: total cost of ownership (TCO)

before moving a workload to the cloud, the real question isn't "what's the hourly rate?" — it's "what does the *whole thing* cost, both ways?"

- **on-premises** carries hidden costs: the hardware, the building, power, cooling, and the staff to rack and maintain it — most of it **capex**, paid up front whether or not you use it
- **cloud** converts that into **opex**: a running cost that tracks usage and drops when usage drops (the [capex → opex shift](./cloud_concepts.md))
- TCO thinking counts *all* of it — not just the server, but everything around it — so you compare like for like

> the lesson: a cloud line item can look more expensive than a server until you add up the building, the power, and the people the server quietly required.

cost is also a formal design concern — see the **cost optimization pillar** of the [well-architected framework](./well_architected.md).

---

## support plans

AWS sells tiers of help. higher tiers add faster response, more guidance, and broader access to **Trusted Advisor** (the service that inspects your account for savings, security, and best-practice issues — see [monitoring & management](./monitoring_management.md)).

### basic
- free, included with every account
- documentation, forums, and a core set of Trusted Advisor checks
- when to use: learning, experimenting, no production workloads

### developer
- adds business-hours email access to support (technical guidance)
- when to use: building and testing, but not yet running critical production

### business
- 24/7 access via phone, chat, and email; **full** set of Trusted Advisor checks
- when to use: you run production workloads and need timely help

### enterprise
- everything in business, plus a **technical account manager (TAM)** and the fastest response for business-critical systems
- when to use: large, mission-critical deployments where downtime is expensive

> the pattern to remember: as you climb the tiers, **response gets faster, guidance gets more personal, and Trusted Advisor opens up fully**.

---

## recap

- the outcome is **no surprises** — answer *what did i spend / what will it cost / warn me*
- three principles run everything: **pay as you go, pay less when you reserve, pay less per unit as you grow**
- cost is driven by **compute (time × size)**, **storage (amount × class)**, and **data transfer** — remember **in is free, out costs**
- the **free tier** has three flavors (always / 12-months / trials) — none of them mean "can't be charged"
- match the tool to the question: **Billing dashboard** (now), **Cost Explorer / CUR** (past), **Pricing Calculator** (future), **Budgets** (alert me)
- **Organizations + consolidated billing** = one bill and shared volume discounts across accounts
- **TCO** compares the *whole* cost cloud vs on-prem; support plans scale help (and Trusted Advisor) with the tier

### where to go next
- [compute pricing models](./compute_types.md) — on-demand, savings plans, reserved, spot in depth
- [cloud concepts](./cloud_concepts.md) — the capex → opex shift behind all of this
- [monitoring & management](./monitoring_management.md) — Trusted Advisor and account health
- [well-architected framework](./well_architected.md) — the cost optimization pillar
