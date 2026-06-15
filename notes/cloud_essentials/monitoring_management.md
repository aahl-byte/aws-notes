<link rel="stylesheet" href="./css/globals.css">

# monitoring & management

you've launched real systems. now the question is no longer "can i build it?" but "is it *okay right now*, and can i run it without babysitting every machine by hand?"

---

## the outcome: see what your systems are doing, and operate them at scale

once something is live, you need to answer three plain questions at any moment:
- **is it healthy?** is the site up, fast, and not on fire?
- **what changed?** when it breaks, what's different from an hour ago?
- **who did what?** somebody opened a security group to the world — who, and when?

and you need to do all this <em>without logging into every server one at a time</em>. ten machines you can babysit. ten thousand you cannot. the tools on this page exist so you can *watch* your systems and *operate* them in bulk.

### the analogy: running a building, not living in a room

think of yourself as the operator of a large building rather than a tenant in one room.
- you don't walk into every apartment to check it — you watch a **panel of gauges** at the front desk (temperature, water pressure, power draw).
- a **sign-in book** records every person who came through the door and what they touched.
- a **survey of the rooms** tells you the current layout and flags any room that breaks the rules (a fire exit blocked, a lock missing).
- and you fix things **building-wide** — one work order patches every unit — instead of unit by unit.

hold onto the building. each tool below is one of those instruments. we'll retire the analogy once the service names land.

---

## the mental model: observability is a set of distinct questions

the single biggest unlock here is realizing that "monitoring" is not one thing. it's <em>four different questions, each with its own tool</em>. confusing them is the classic beginner mistake (and a classic exam trap).

| the question | what it means | the tool |
| --- | --- | --- |
| how is it *performing*? | metrics, health, alarms | **CloudWatch** |
| what *happened* in detail? | logs, line by line | **CloudWatch Logs** |
| *who did what*, when? | api calls, audit trail | **CloudTrail** |
| what does it *look like* now — and is that *allowed*? | resource config + compliance | **Config** |

if you remember nothing else: **CloudWatch = performance/health, CloudTrail = actions/audit, Config = state/compliance.** the rest of the page just fills these in. read this far and you have a correct coarse model.

---

## seeing performance & health

### amazon cloudwatch
the panel of gauges at the front desk — the tool that answers <em>how is it performing, and tell me the moment it isn't</em>.

it collects **metrics** (numbers over time: cpu %, request count, disk usage), turns them into **dashboards** you can watch at a glance, and lets you set **alarms** that fire when a number crosses a line you drew.

the pieces, from raw signal to action:
- **metrics** — the gauges. many come for free from AWS services; you can publish your own too.
- **dashboards** — arrange the gauges you care about on one screen.
- **logs** — the detail behind the numbers. metrics tell you cpu spiked; logs tell you *which request* did it. (this is the "what happened in detail?" question.)
- **alarms** — a threshold with a consequence. when cpu > 80% for 5 minutes, *do something*.

#### the key idea: an alarm should *act*, not just beep
a metric you have to stare at is useless at 3am. the value of an alarm is that it can <em>trigger an action automatically</em>:
- notify a human or a team (via an SNS notification — email, sms, pager)
- kick off [EC2 Auto Scaling](./compute_types.md) to add servers when load climbs
- stop, terminate, or recover a misbehaving instance

this is the difference between *watching* and *operating*. a good alarm closes the loop without you.

when to use:
- you want to know your system's performance and health in real time
- you need to be paged when something crosses a threshold
- you want load to drive scaling automatically instead of by hand

---

## seeing who did what

### aws cloudtrail
the sign-in book at the door — it records <em>every api call made in your account</em>: who made it, when, from where, and what they touched.

nearly everything in AWS is an api call underneath, even clicking a button in the console. CloudTrail captures that stream, so:
- when a resource changes, you can trace it back to a user, a role, or a service
- you get an audit trail for security investigations and compliance evidence
- "who opened this security group on tuesday?" becomes an answerable question

#### cloudwatch vs cloudtrail (don't mix these up)
they sound similar and the exam loves the confusion. the split is clean:
- **CloudWatch** answers *how is the system performing?* — it watches **metrics and logs** (the gauges).
- **CloudTrail** answers *who did what?* — it records **actions/api calls** (the sign-in book).

a spike in cpu is a CloudWatch story. a person deleting a database is a CloudTrail story. CloudTrail is a governance and [security](./security_identity.md) tool, not a performance tool.

---

## seeing state & compliance

### aws config
the survey of the rooms — it tracks <em>how each resource is configured over time</em>, and checks whether that configuration is *allowed*.

two jobs in one:
- **configuration history** — a running record of what each resource looked like and how it changed. "what did this bucket's settings look like last month?"
- **compliance rules** — define what *good* looks like (every bucket must be encrypted, no security group open to 0.0.0.0/0) and Config flags anything that drifts out of line.

#### config vs cloudtrail (the other easy mix-up)
both touch "change," but from opposite ends:
- **CloudTrail** = the *action* — the event that someone made a change ("user X modified the bucket at 2:01").
- **Config** = the *state* — what the resource looks like now and whether it's compliant ("the bucket is currently unencrypted, which violates the rule").

CloudTrail is the verb, Config is the noun. together they support [governance and security](./security_identity.md): one tells you *who changed it*, the other tells you *whether the result is acceptable*.

---

## seeing AWS itself

### aws health dashboard
everything above watches *your* stuff. but sometimes the problem is AWS, not you. the Health Dashboard shows <em>the status of AWS services and events affecting your account</em>.

- the **service health** view: is a region or service having a broad outage right now?
- the **your account** view: personalized alerts about events that touch *your* specific resources (scheduled maintenance, a hardware issue under one of your instances)

when to use:
- before you spend an hour debugging, check whether AWS itself is degraded
- you want a heads-up about maintenance that will affect resources you actually run

---

## operating at scale

seeing is half the job. the other half is *acting* across a whole fleet without doing it by hand. these tools turn one decision into many actions.

### aws cloudformation
infrastructure as code — describe the infrastructure you want in a **template**, and CloudFormation builds it for you, the same way every time.

- you write what you want (this vpc, these servers, this database) in a file; AWS makes reality match it
- the same template spins up identical environments — dev, test, prod — with no hand-clicking to drift apart
- tear it all down or rebuild it on demand; the template is the source of truth

this is the IaC front door introduced in [cloud concepts](./cloud_concepts.md), made concrete. it replaces "click around the console and hope you remember the steps" with a versioned, repeatable definition.

when to use:
- you need environments to be reproducible and identical
- you want infrastructure reviewed and versioned like code
- you're tired of manual setup drifting out of sync

### aws systems manager
the building-wide work order — operate <em>fleets of servers from one place</em> instead of one machine at a time.

- **patching** — apply OS and software updates across many instances on a schedule, not by sshing into each
- **run commands** — execute the same operation on a whole group at once
- **parameter store** — keep configuration values and secrets in one central, secure place your apps read from

when to use:
- you have more machines than you can reasonably manage individually
- you want consistent patching and config across a fleet

### aws trusted advisor
an automatic inspector that <em>checks your account against AWS best practices</em> and tells you where you fall short.

it scans across five categories and hands you a prioritized to-do list:
- **cost optimization** — idle resources you're paying for, see also [billing & pricing](./billing_pricing.md)
- **security** — exposed permissions, missing protections
- **performance** — resources configured below their potential
- **fault tolerance** — single points of failure, missing backups
- **service limits** — where you're nearing an account quota before it bites you

when to use:
- you want a fast, automated read on what to fix first across the whole account
- you're reviewing cost, security, or resilience and want a starting checklist

### ec2 auto scaling
the loop that makes "stop guessing capacity" real — it <em>adds and removes servers automatically</em> to match demand. it's covered in depth with [compute](./compute_types.md); here just note its place: a CloudWatch alarm on load is what *triggers* it. monitoring and operating-at-scale meet here.

---

## recap: each tool maps to a question

if you can finish this sentence for each, you've got the page:
- **CloudWatch** → *how is it performing?* (metrics, logs, alarms that act)
- **CloudTrail** → *who did what, when?* (api audit trail)
- **Config** → *what does it look like, and is that allowed?* (state + compliance)
- **Health Dashboard** → *is AWS itself okay?* (service & account events)
- **CloudFormation** → *build the same infrastructure repeatably* (IaC templates)
- **Systems Manager** → *operate a whole fleet from one place* (patch, run, configure)
- **Trusted Advisor** → *what should i fix?* (best-practice checks across 5 areas)
- **EC2 Auto Scaling** → *match capacity to demand* (triggered by CloudWatch)

being able to see and operate your systems is the **operational excellence** pillar in practice — see [judging a good design](./well_architected.md).

---

## where to go next

- [securing what you run](./security_identity.md) — CloudTrail & Config as governance tools
- [billing & pricing](./billing_pricing.md) — Trusted Advisor & cost visibility
- [judging a good design](./well_architected.md) — the operational excellence pillar
- [running code](./compute_types.md) — EC2 Auto Scaling in depth
