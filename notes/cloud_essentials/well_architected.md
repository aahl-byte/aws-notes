<link rel="stylesheet" href="./css/globals.css">

# judging a good design

the synthesis. every other page taught you a piece — a service, a region, a price. this page is the lens that asks whether the *whole thing you built out of those pieces* is any good.

---

## the outcome: know if a system is well built — before it fails or overspends

two systems can both "work" in a demo and be wildly different in quality.
- one falls over the moment a single server dies, leaks data through an open door, and quietly triples your bill
- the other survives a datacenter going dark, locks every door by default, and costs only what it uses

both pass the demo. only one is <em>well-architected</em>. the goal of this page is a way to look at any design and tell which is which — *while you can still change it*, not after the incident.

> the destination isn't "make it run." it's "make it run *well* — and be able to prove it."

---

## what the well-architected framework is

> AWS's set of <em>questions and best practices for evaluating and improving cloud architectures</em>.

it's not a product you turn on. it's a shared way of thinking — a checklist of "have you thought about…?" that turns vague taste ("this feels fragile") into specific, answerable questions.

- think of it like a home inspection. the inspector doesn't build your house — they walk it with a structured list (wiring, plumbing, foundation, fire safety) and tell you where it's weak before you move in.
- the framework is that walkthrough for a cloud system. its checklist is organized into **six pillars** — six angles you interrogate every design from.
- the payoff is a *shared vocabulary*. when someone says "the reliability story is thin," everyone knows which set of questions just failed.

read the first third of this page and stop here, you already have the coarse model: **six pillars, each a category of question you ask to judge a design.** the rest names them.

---

## the six pillars

each pillar below leads with the *one question it forces you to answer*. the ideas underneath it are mostly things earlier pages already taught — the pillar just gives them a place to land. follow the links to go deep.

### operational excellence
> the question: *can you run, watch, and keep improving this system once it's live?*

building it is day one. operations is every day after. this pillar is about whether you can actually *see* what your system is doing and make it better over time.
- run things as code, not as hand-clicks — so changes are repeatable and reversible (recall [infrastructure as code](./cloud_concepts.md))
- watch the system with metrics, logs, and alarms so you learn of trouble *before* users do
- automate the routine: deploys, recovery, responses — humans make mistakes the third time they do a thing by hand
- improve continuously; treat every failure as something to learn from, not just patch
- deep dive: [running & monitoring systems](./monitoring_management.md)

### security
> the question: *are your data and systems protected, and can only the right people touch them?*

this is the [shared responsibility model](./cloud_concepts.md) made actionable — the "*in* the cloud" half is yours, and this pillar is how you judge whether you held it up.
- **least privilege** — give every person and service the *minimum* access they need, nothing spare
- **defense in depth** — don't rely on one wall; layer protections so one failure doesn't open everything
- protect data both at rest and in transit; know who did what (auditing)
- deep dive: [security & identity](./security_identity.md)

### reliability
> the question: *when something breaks — and it will — does the system recover and keep serving?*

failure is the default assumption, not the surprise. this pillar asks whether you *designed for* the break instead of hoping it won't come.
- spread across [multiple availability zones](./global_infrastructure.md) so one datacenter dying doesn't take you with it
- scale to meet real demand instead of guessing — recall *stop guessing capacity* from the [cloud advantages](./cloud_concepts.md)
- use [load balancing and auto scaling](./networking.md) to absorb load and replace failed instances automatically (the [compute](./compute_types.md) layer that actually does the scaling)
- recover automatically; test that your recovery actually works rather than assuming it does

### performance efficiency
> the question: *are you using the right resources for the job, and only as much as you need?*

reliability keeps it *up*; this pillar keeps it *fast and fitting*. it's the discipline of matching the tool to the task.
- pick the right [compute type](./compute_types.md) — a serverless function vs a server vs a container is a performance *and* effort decision, not just a cost one
- pick the right [database](./databases.md) for the access pattern instead of forcing one shape to do everything
- choose the right [instance family](./compute_types.md) (compute- vs memory- vs storage-optimized) for the workload's actual bottleneck
- scale and measure; let data tell you what's slow rather than guessing

### cost optimization
> the question: *are you paying for value, or paying for idle?*

this is the financial half of the same instinct: don't run what you don't need, and don't overbuy what you do.
- right-size — stop renting a mansion for one tenant; match resource size to real usage
- pay for what you use, and pick the [pricing model](./billing_pricing.md) that fits the workload's shape (on-demand vs savings plans vs spot — see the [compute pricing options](./compute_types.md))
- turn off or scale down what's idle; track spend so surprises don't reach the invoice
- deep dive: [billing & pricing](./billing_pricing.md)

### sustainability
> the question: *what is the environmental cost of running this, and can you lower it?*

the newest pillar. it points the same right-sizing instinct at energy and impact rather than just dollars.
- a workload that's right-sized and not idling is *also* using less energy — efficiency and sustainability pull the same direction
- choose efficient resources, regions, and patterns; delete data and capacity you no longer need
- it sits last because it only makes sense once you can already reason about cost and performance — its scaffolding is the five pillars before it

---

## the framework's design principles

zoom out from the pillars and the same handful of instincts keep reappearing. these are the framework's general design principles — worth knowing as a set because they explain *why* the pillars say what they say.

- **stop guessing capacity** — scale to real demand (the cloud advantage that started it all in [cloud concepts](./cloud_concepts.md))
- **test at production scale** — try it under real load *before* real users do, then tear the test down
- **automate to make experimentation easy** — cheap, repeatable changes mean you can afford to try and roll back
- **allow for evolutionary change** — design so the system can be revised, not frozen
- **drive architecture with data** — measure, then decide; don't argue from taste
- **improve through game days** — rehearse failure on purpose so the real failure is boring

notice these aren't six new ideas — they're the pillars stated as habits.

---

## recap: this page is the synthesis

- every other page handed you a *part*; the framework is how you judge the *whole* those parts form.
- the model that survives if you forget everything else: **six pillars — operational excellence, security, reliability, performance efficiency, cost optimization, sustainability — each a category of question you ask to decide if a design is good.**
- the pillars don't introduce much new; they give the concepts from earlier pages a place to connect. that's what makes this the innermost layer of the onion.
- want the map of the whole journey, skin to core? go back to [cloud essentials](./cloud_essentials.md).
