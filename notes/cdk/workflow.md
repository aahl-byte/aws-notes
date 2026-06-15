<link rel="stylesheet" href="./css/globals.css">

# the workflow

the code on your laptop isn't infrastructure yet — it's a *recipe* for it. this
page is about the loop that turns that recipe into real resources in an account,
and tears them back out again, the same way every time.

> assumes you've read [cdk concepts](./cdk_concepts.md) (the synth → deploy model)
> and [constructs](./constructs.md) (what you're actually deploying). this page is
> the *how*, not the *what*.

---

## the outcome: a tight, safe loop anyone can run

what you actually want is a repeatable cycle:

- **write** a bit of infrastructure in code
- **preview** exactly what it will change in the account, before you touch anything
- **apply** it for real
- **tear it down** cleanly when you're done

the prize is that this loop is *identical* for everyone — you, a teammate, a CI
robot. no one clicks around the console hoping they remember the steps. the
sequence is the same on a laptop and in a [pipeline](./pipelines_practices.md);
that's the whole point.

---

## the mental model: a pipeline of verbs

the CDK toolkit (the `cdk` command line) is a handful of verbs you run in order.
hold this sequence in your head and everything else is detail:

> `init` → (`bootstrap` once) → `synth` → `diff` → `deploy` → `destroy`

- **init** — scaffold a new app. once per project.
- **bootstrap** — prepare the *account+region* to receive deployments. once per
  account+region, not per project.
- **synth** — turn your code into a CloudFormation template.
- **diff** — show what that template would change in the live account.
- **deploy** — make the change real.
- **destroy** — remove it all again.

the middle four (`synth` → `diff` → `deploy`) are the loop you run constantly.
the first two are one-time setup you'll do once and forget. anchor every command
below to its slot in this line.

---

## `cdk init` — scaffold a new app

starts a fresh CDK project with the folders, config, and a sample stack already
wired up.

```bash
cdk init app --language typescript
```

- run it in an empty directory; it lays down `cdk.json`, a `bin/` entry point,
  and a `lib/` stack to edit.
- `--language` picks the template: `typescript`, `python`, `java`, `csharp`, `go`.
- you do this *once* at the start of a project, then never again — it's the
  birth of the app, not part of the daily loop.

---

## `cdk bootstrap` — prepare the account to receive deployments

a one-time setup, **per account, per region**, that creates the supporting
resources CDK needs before it can deploy *anything*.

this is the step that trips beginners up, so make it click. CDK deployments need
a place to stage things and permission to act:

- somewhere to upload **assets** — your zipped lambda code, docker images,
  large templates — so CloudFormation can pull them in. that's an S3 bucket and
  an ECR repo.
- **deployment roles** — IAM roles CloudFormation assumes to actually create
  resources on your behalf.

bootstrap creates all of that as a single stack called <em>CDKToolkit</em>. think
of it as *furnishing an empty account* so it's ready to receive CDK deploys.
until you've done it, `deploy` has nowhere to put assets and no role to act with.

```bash
cdk bootstrap aws://123456789012/eu-west-1
```

- run it **once per account+region combo**, not once per project — every app in
  that account+region reuses the same `CDKToolkit` stack.
- a brand-new region is a fresh empty account from CDK's view, so deploying to a
  new region means bootstrapping it first.
- this is also why a first `deploy` into a clean account fails with "this stack
  uses assets, so the toolkit stack is required" — it's telling you to bootstrap.

> who, where, and which account `aws://…` refers to is the job of
> [environments & config](./environments_config.md) — bootstrap just sets the
> target up to receive what you send it.

---

## `cdk synth` — turn code into a template

runs your app and emits the CloudFormation template it describes.

this is the synth half of the synth → deploy model from
[cdk concepts](./cdk_concepts.md): your TypeScript executes, the construct tree
resolves, and out falls plain CloudFormation JSON/YAML.

```bash
cdk synth
```

- prints the template and writes the full output (templates + assets) to the
  **`cdk.out/`** directory — the *cloud assembly*, the deployable artifact.
- nothing touches the account here. synth is pure: code in, template out. it's
  the safe place to catch errors before anything is live.
- `deploy` runs synth for you automatically, so you rarely call it alone — but
  reach for it when you want to *see* the generated template.

---

## `cdk diff` — preview what will change

compares the freshly synthesized template against what's actually deployed and
shows the delta.

this is your **review step** — the equivalent of reading a git diff before you
commit.

```bash
cdk diff
```

- shows resources being **added, modified, or destroyed**, plus changes to IAM
  and security rules called out separately.
- always read it. "modify" can quietly mean *replace* — some property changes
  force CloudFormation to delete and recreate a resource, which can drop data.
  diff is where you catch that before it happens, not after.

---

## `cdk deploy` — make it real

provisions or updates the actual resources by handing your template to
CloudFormation.

```bash
cdk deploy
```

- shows you the changes (like a built-in diff) and, when a change touches **IAM
  or security groups**, pauses to ask for approval before proceeding — a guard
  against silently widening permissions.
- control that prompt with `--require-approval`: `never` (no prompt — what CI
  uses), `any-change`, or the default `broadening` (only when access expands).
- deploy is idempotent by design: run it again after editing your code and it
  computes the difference and applies only that. the loop is just *edit → deploy,
  edit → deploy*.

---

## `cdk destroy` — tear it back down

removes the stack and the resources it created.

```bash
cdk destroy
```

- the clean exit from the loop: spin an environment up to experiment, tear it
  down when you're done, pay for nothing idle.
- some resources resist deletion on purpose (a data store with a retain policy,
  a non-empty bucket) so you don't lose data by accident — those you remove
  deliberately.
- note this does **not** remove the `CDKToolkit` bootstrap stack; that's shared
  account furniture, not part of your app.

---

## the fast inner loop: `--watch` and hotswap

the full `deploy` round-trips through CloudFormation, which is safe but slow —
fine for shipping, painful when you're iterating on a lambda every thirty seconds.

```bash
cdk deploy --watch
```

- **`--watch`** keeps running, sees you save a file, and redeploys automatically —
  a live edit→deploy loop without retyping the command.
- it deploys with **hotswap** where it can: for supported changes (lambda code,
  step functions definitions, ecs containers) it pushes the update *straight to
  the service*, skipping CloudFormation entirely. seconds instead of minutes.

> hotswap is a **dev-only** shortcut. because it bypasses CloudFormation, your
> deployed state drifts from what CloudFormation thinks is there — never use it
> against production. for production, plain `deploy` (and a
> [pipeline](./pipelines_practices.md)) is the only safe path.

---

## `cdk ls` — what's in this app

lists the stacks defined in your app.

```bash
cdk ls
```

- one app can hold several stacks (dev/prod, or front-end/back-end split apart).
  most CDK commands take a **stack name** to act on just one:

```bash
cdk deploy MyApiStack
cdk diff Dev/*          # wildcards select groups
```

- with no name, commands act on every stack (or prompt you to pick), which is
  rarely what you want once an app grows.

> wiring multiple stacks together — sharing values between them, targeting
> different accounts per stack — is its own topic in
> [environments & config](./environments_config.md).

---

## recap: each verb, back in the loop

map every command to its slot in the pipeline and the page is yours:

- **`init`** — scaffold the app. once per project.
- **`bootstrap`** — furnish the account+region with assets bucket and deploy
  roles (the `CDKToolkit` stack). once per account+region.
- **`synth`** — code → CloudFormation template, into `cdk.out/`. no account change.
- **`diff`** — preview the delta against what's live. your review step.
- **`deploy`** — apply the change for real; approves IAM/security changes.
- **`--watch` / hotswap** — the fast dev loop; bypasses CloudFormation, dev only.
- **`destroy`** — tear it all back down.

the steady state, day to day, is just the middle: edit your
[constructs](./constructs.md), read the `diff`, `deploy`. everything else is
either one-time setup or the same loop run faster.

---

## where to go next

- [environments & config](./environments_config.md) — pointing this loop at the
  right account/region, and managing apps with many stacks
- [pipelines & best practices](./pipelines_practices.md) — running this exact loop
  automatically in CI instead of from your laptop
