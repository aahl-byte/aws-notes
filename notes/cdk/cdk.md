<link rel="stylesheet" href="./css/globals.css">

# the AWS CDK

the layer where you stop clicking the console and start <em>describing</em> your
infrastructure in code.

these pages are built **right → left**, same as the [cloud essentials](../cloud_essentials/cloud_essentials.md):
each opens with *the thing you're trying to get done* and works back into the
detail. read them in order the first time — every page assumes the mental models
built above it — then jump around once the shape is in your head.

> assumes you already know roughly *what* the services do. if "S3 bucket" or "IAM
> role" don't mean anything yet, start with the [cloud essentials](../cloud_essentials/cloud_essentials.md)
> first — CDK is how you *build* those things, not what they are.

---

## how to read this

same onion as the rest of the notes.

- the **outer layers** are the mental model: what CDK is and how your code becomes
  real infrastructure.
- the **middle layers** are the moving parts: the construct tree you build apps
  from, and the workflow that deploys them.
- the **core** is the craft: environments, permissions, testing, and shipping it
  through a pipeline.

code examples are in **TypeScript** (CDK's most common language), but the ideas
carry to python, java, c#, and go unchanged.


## 1 — the foundation (what CDK actually is)

- [cdk concepts](./cdk_concepts.md) — infrastructure as *real code*, how it relates
  to CloudFormation, and the synth → deploy mental model everything hangs on.
  **read first.**


## 2 — the model (how a CDK app is shaped)

- [constructs](./constructs.md) — the construct tree: app, stack, and construct,
  and the L1 / L2 / L3 levels you compose from.
- [the workflow](./workflow.md) — bootstrap and the CLI lifecycle: how code on
  your laptop becomes infrastructure in an account.


## 3 — the cross-cutting craft (doing it well)

- [environments & config](./environments_config.md) — targeting accounts and
  regions, context, stages, and wiring multiple stacks together.
- [resources, permissions & assets](./resources_permissions_assets.md) — granting
  least-privilege access the easy way, bundling assets, and referencing things
  that already exist.
- [testing](./testing.md) — proving your infrastructure is what you think it is,
  before you deploy it.


## 4 — the synthesis (shipping it)

- [pipelines & best practices](./pipelines_practices.md) — self-mutating CD with
  CDK Pipelines, the practices that keep a codebase sane, and when to reach for
  CDK over the alternatives.

---

## links

- [aws cdk developer guide](https://docs.aws.amazon.com/cdk/v2/guide/home.html)
- [construct hub](https://constructs.dev/) — published constructs you can reuse
- [cdk workshop](https://cdkworkshop.com/) — hands-on, step by step
