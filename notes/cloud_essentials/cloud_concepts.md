<link rel="stylesheet" href="./css/globals.css">

# cloud concepts

the foundation. everything else on this site assumes the mental models built here. read this first.

---

## the outcome: run real systems without owning hardware

the whole point of "the cloud" is this:
- you can run a website, an app, a database — a real system that real people use — <em>without ever buying a server</em>
- someone else owns the building, the machines, the power, the cooling, the network
- you just rent the slice you need, for as long as you need it, and hand it back when you're done

### renting vs owning (the analogy that runs the whole page)
think of computing power like a place to live.
- **owning** = buying a house. huge cost up front, it's yours forever, and *you* fix the roof. if you need more space you build an extension (slow, expensive). if you have spare rooms, you paid for them anyway.
- **renting** = a hotel/apartment. pay only for what you use, leave when you want, and the landlord handles the plumbing. need a bigger room? ask for one and move in today.

owning a datacenter is buying the house. the cloud is renting — and that single shift is where almost every advantage below comes from.

> hold onto renting-vs-owning. we'll retire the analogy once the precise terms land, but it's the spine of this page.

---

## what cloud computing is

> the <em>on-demand delivery of IT resources over the internet</em>, with pay-as-you-go pricing.

unpack that one sentence:
- **on-demand** — you ask for a server and get it in minutes, no purchase order, no waiting for hardware to ship.
- **IT resources** — compute (machines that run code), storage (where data lives), networking, databases, and much more.
- **over the internet** — you reach it from anywhere; the actual machines sit in AWS datacenters.
- **pay-as-you-go** — you're billed for what you use, like electricity, not a flat fee for owning the plant.

that's it. if you understand "rent IT resources over the internet and pay for what you use," you have the coarse model. everything else is detail.

---

## the shift it represents: capex → opex

the deepest change isn't technical, it's *financial* — and it's worth understanding because it explains why companies care.

- **capital expense (capex)** — the old way. buy servers up front, own them, depreciate them. you spend a fortune *before* you know if anyone shows up.
- **variable / operating expense (opex)** — the cloud way. no big purchase. you pay a running cost that tracks your actual usage, and it drops to near zero when usage drops.

this is buying-the-house vs renting, stated in money. you stop sinking cash into hardware that may sit idle, and start paying only for the rooms you actually occupy.

---

## the six advantages of cloud computing

all six fall out of the rent-don't-own shift. learn them as consequences, not a list to memorize.

### trade capital expense for variable expense
- stop paying up front for servers you're guessing you'll need
- pay only when you consume, only for what you consume

### benefit from massive economies of scale
- AWS buys hardware for millions of customers at once, so it's cheaper per unit than you could ever buy alone
- those savings show up as lower pay-as-you-go prices — the landlord's bulk discount passed to you

### stop guessing capacity
- owning forces a guess: buy too much and you waste money, buy too little and you fall over under load
- in the cloud you scale up and down to match real demand, so the guess disappears

### increase speed and agility
- new resources are minutes away instead of weeks
- experiments get cheap; a failed idea costs a few dollars instead of a server purchase

### stop spending money running and maintaining datacenters
- no buildings, power bills, cooling, or racking-and-stacking staff
- you spend on what makes *your* product better, not on keeping the lights on

### go global in minutes
- deploy your system close to users around the world with a few clicks
- lower latency for them, no new datacenter for you — see [where systems actually run](./global_infrastructure.md)

---

## deployment models: where your system lives

not everyone goes all-in on the cloud. three patterns, chosen by how much you keep on your own hardware.

### cloud
everything runs on a cloud provider; you own no hardware.
- when to use: new projects ("cloud-native"), and anyone who wants the six advantages with the least baggage
- the default assumption for the rest of this site

### hybrid
some workloads in the cloud, some still on your own servers, connected together.
- when to use: you have existing on-premises systems you can't move yet (legacy apps, strict data rules) but still want cloud for new or bursty work

### on-premises (private cloud)
you run cloud-style infrastructure inside your own datacenter.
- when to use: heavy regulatory or latency constraints force the hardware to stay in your building
- you get some cloud conveniences but keep the capex and the maintenance burden

---

## how you actually interact with AWS

four front doors to the same set of services. just enough to orient — you'll meet each in depth later.

- **management console** — the website with buttons. great for learning, exploring, and one-off tasks.
- **CLI (command line interface)** — drive AWS by typing commands; scriptable and repeatable.
- **SDKs (software development kits)** — call AWS from inside your own code (python, javascript, etc.).
- **infrastructure as code (IaC)** — describe the system you want in a file and have AWS build it, so it's versioned and reproducible instead of hand-clicked.

rule of thumb: click in the console to learn, automate with CLI / SDK / IaC once you know what you want.

---

## the shared responsibility model (intro)

security in the cloud is a partnership — neither side owns all of it.

> AWS is responsible for security <em>of</em> the cloud; you are responsible for security <em>in</em> the cloud.

- **AWS — *of* the cloud** — the physical datacenters, the hardware, the underlying software that runs the services. the parts you can't touch.
- **you — *in* the cloud** — your data, who can access it, how you configure what you rent, patching your own software.

back to the analogy: the landlord secures the building and locks the front doors; you still lock your own apartment and decide who gets a key. assuming the other side covers your half is how things go wrong.

this is just the outline — the full breakdown lives in the [shared responsibility deep dive](./security_identity.md).

---

## where to go next

- [where systems run](./global_infrastructure.md) — regions, availability zones, going global
- [running code](./compute_types.md) — EC2, Lambda, containers: the machines you rent
- [shared responsibility deep dive](./security_identity.md) — securing what you run
- [judging a good design](./well_architected.md) — what "well-architected" means
