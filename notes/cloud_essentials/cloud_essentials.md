<link rel="stylesheet" href="./css/globals.css">

# cloud essentials

the foundational layer of these notes. start here.

these pages are built **right → left**: each one opens with *the thing you're
trying to get done* and works back into the detail. read them in order the first
time — every page assumes the mental models built by the ones above it — then
jump around freely once the shape is in your head.

---

## how to read this

think of the whole topic as an onion.

- the **outer layers** are mental models: what the cloud *is* and why it exists.
- the **middle layers** are the building blocks: the services you actually
  assemble systems from.
- the **core** is the cross-cutting craft: keeping systems secure, observable,
  and affordable — and the framework that ties it all together.

stop at any depth and you'll still hold a true picture. depth is opt-in.


## 1 — the foundation (why any of this exists)

before the services make sense, you need the shape of the thing.

- [cloud concepts](./cloud_concepts.md) — what "the cloud" actually is, the value
  proposition, and the mental model everything else hangs on. **read first.**
- [global infrastructure](./global_infrastructure.md) — *where* your systems run:
  regions, availability zones, and the edge.


## 2 — the building blocks (what you assemble systems from)

the core service categories. these are the verbs and nouns of AWS.

- [compute](./compute_types.md) — *running* code: servers, serverless, containers.
- [storage](./storage.md) — *keeping* data: objects, blocks, and files.
- [databases](./databases.md) — *organizing* data so you can query it.
- [networking & content delivery](./networking.md) — *connecting* it all and
  getting it to users quickly and safely.


## 3 — the cross-cutting craft (keeping it real)

these concerns cut across every system you build.

- [security & identity](./security_identity.md) — *who can do what*, and how the
  responsibility is split between you and AWS.
- [monitoring & management](./monitoring_management.md) — *seeing* what your
  systems are doing, and managing them at scale.
- [billing & pricing](./billing_pricing.md) — *what it costs*, and how not to be
  surprised by the bill.


## 4 — the synthesis (putting it together well)

- [the well-architected framework](./well_architected.md) — the six pillars AWS
  uses to judge a "good" architecture. this is where every layer above connects.

---

## links

- [cloud essentials learning plan](https://explore.skillbuilder.aws/learn/public/learning_plan/view/82/cloud-essentials-learning-plan-earn-a-learning-badge) — free
- [cloud essentials w/ labs](https://explore.skillbuilder.aws/learn/public/learning_plan/view/8/cloud-essentials-learning-plan-includes-labs-earn-a-learning-badge) — subscription ($30/mo)
- [aws getting started](https://aws.amazon.com/getting-started)
