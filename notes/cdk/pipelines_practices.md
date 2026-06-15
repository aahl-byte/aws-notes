<link rel="stylesheet" href="./css/globals.css">

# pipelines & best practices

the synthesis. every other CDK page taught you a piece — a construct, a stack, a
test, a permission. this page is about shipping all of it *for real, on repeat*,
and keeping the codebase you ship sane as it grows. it's also where you step back
and ask: is CDK even the right tool here?

---

## the outcome: push to git, and it deploys itself — forever

the destination, stated plainly:

- you make a change, commit it, and merge. from there <em>no human touches a
  deploy</em> — your tests run, your app synths, and the change rolls out through
  dev, then staging, then prod on its own.
- promoting from one environment to the next is automatic (with a human approval
  in front of prod if you want one), not a checklist someone runs by hand at 5pm
  on a friday.
- and a year later, when the app has tripled in size, the code is still
  *readable* — someone new can open it and find their way around, because it was
  organized to be understood, not just to work.

that's two outcomes braided together: a **pipeline that ships without you**, and
a **codebase that stays maintainable**. the first half is CDK Pipelines. the
second half is the practices. we take them in that order.

> this is the operational-excellence pillar made concrete — *run things as code,
> automate the routine, improve continuously*. see
> [judging a good design](../cloud_essentials/well_architected.md).

---

## CDK Pipelines — a pipeline that updates itself

a continuous-delivery pipeline that builds, tests, and deploys your app — and is
*itself* defined in CDK, in the same codebase.

the ordinary way to build a deploy pipeline is to set it up once (in the console,
or a separate config) and then maintain it by hand forever. CDK Pipelines flips
the awkward part: the pipeline is just more CDK code, so changing the pipeline is
*just another commit*.

### the one idea: it's self-mutating

> a CDK pipeline <em>updates its own definition before it deploys your app</em>.

that's the whole trick, and it's worth slowing down on:

- you add a new stage, or a new test step, in your CDK code and commit it.
- on the next run, the pipeline notices its own definition changed, and
  **rebuilds itself first** — so the new stage exists *before* it tries to use it.
- only then does it go on to deploy your application.

so you never log into a CI tool to "add the staging step." you write it in code,
commit, and the pipeline absorbs the change on its next run. the pipeline is a
construct like everything else — recall that
[everything is a construct](./constructs.md).

### the shape of a run

four moves, left to right, every time someone merges:

- **source** — the pipeline watches a git repo (or branch). a commit is the
  trigger; nothing starts without one.
- **build / synth** — it installs deps, runs your **tests**, and runs
  `cdk synth` to turn your code into CloudFormation. this is the gate: if the
  build fails, *nothing deploys* (more on tests below).
- **self-mutate** — the pipeline updates its own definition from the synth output,
  so any change you made *to the pipeline* takes effect now.
- **deploy stages** — it deploys the app to each environment in order, promoting
  outward: dev → staging → prod.

```ts
const pipeline = new CodePipeline(this, 'Pipeline', {
  synth: new ShellStep('Synth', {
    input: CodePipelineSource.gitHub('me/my-app', 'main'),
    commands: ['npm ci', 'npm test', 'npx cdk synth'], // test gates the build
  }),
});

// a Stage is a whole copy of the app for one environment — see environments_config
pipeline.addStage(new MyAppStage(this, 'Beta', { env: betaEnv }));

pipeline.addStage(new MyAppStage(this, 'Prod', { env: prodEnv }), {
  pre: [new ManualApprovalStep('PromoteToProd')], // optional human gate
});
```

note `MyAppStage` — promotion is done with **stages**, the same "a whole copy of
the app for one environment" idea from [environments & config](./environments_config.md).
you don't re-describe your app per environment; you instantiate the same stage
against a different `env`, and the pipeline deploys each in turn.

#### where tests fit

the build step is the gate, and your tests are what arm it.

- the `npm test` line above runs the assertion and snapshot tests from
  [testing](./testing.md) *before* synth produces anything deployable.
- a failed test fails the build, and a failed build deploys nothing — so a broken
  change can't reach even dev, let alone prod.
- this is the payoff of having written tests at all: they stop being something you
  *remember* to run and become something the pipeline *won't skip*.

---

## best practices — the part that keeps it sane

a pipeline ships whatever you give it. these are the habits that keep what you
give it worth shipping. each is a principle, stated with the *why* — not a rule to
memorize.

### organize by construct, not by service

model your app as **meaningful components**, not as a pile of resources grouped by
AWS service.

- bad: a "buckets" file, a "functions" file, a "roles" file. nothing tells you
  what the app *does*.
- good: an `OrderProcessor` construct that contains its queue, its function, and
  its table — the things that belong together because they *work* together.
- this is just the [construct tree](./constructs.md) used as designed: blocks that
  map to ideas in your domain, so the code reads like the system it builds.

### keep configuration in code, not scattered context

per-environment values belong in **typed props** you pass down, not in loose
context keys fished out at random.

- typed props are checked by the compiler and visible at the call site — you can
  *see* what a stack needs.
- leaning on `cdk.json` context or `tryGetContext` for everything hides the wiring
  and fails at runtime instead of compile time.
- the contrast and the mechanics live in
  [environments & config](./environments_config.md): pass values *in*, don't reach
  *out* for them.

### least privilege via grants, not hand-written policies

let constructs write the IAM for you.

- `bucket.grantRead(fn)` produces the *minimum* policy for exactly that action on
  exactly that resource — and updates it if the resource changes.
- hand-written policy JSON drifts: it's easy to over-grant `"*"`, and easy to
  forget to tighten it later.
- this is the security pillar's **least privilege** done the easy way — see
  [resources, permissions & assets](./resources_permissions_assets.md).

### one stack is a deployment + blast-radius unit

a stack is what deploys (and rolls back) **together**, so it's also what *fails*
together.

- put things in the same stack when they share a lifecycle; split them when a
  failure in one shouldn't be able to take down the other.
- splitting also lets you deploy a small change without redeploying the world.
- so "how many stacks?" is a *blast-radius* decision, made deliberately — not an
  accident of how the files happened to grow.

### prefer L2 constructs; reach down to L1 only when you must

stay at the level that does the work for you.

- **L2** constructs carry sane defaults, helper methods (the `grant*` calls above),
  and wiring — most of your app should be L2.
- drop to **L1** (the raw CloudFormation resource) only for something L2 doesn't
  expose yet. it's an exception, not a default.
- the levels and what each buys you are laid out in [constructs](./constructs.md).

### always read `cdk diff` before you deploy

look before you leap — the diff is your last cheap chance to catch a surprise.

- `cdk diff` shows exactly what will change in the account, including the scary
  ones: a replacement, a deletion, a widened permission.
- reading it is the difference between "I deployed a config tweak" and "I
  accidentally replaced the database." the full CLI lifecycle is in
  [the workflow](./workflow.md).

---

## escape hatches — you're never blocked by the abstraction

now and then an L2 construct won't expose the exact property you need. you don't
have to abandon CDK and rewrite the resource by hand — you reach *through* the
abstraction.

- grab the underlying L1 resource the L2 wraps:
  `const cfnBucket = bucket.node.defaultChild as s3.CfnBucket;` — now you can set
  anything CloudFormation supports.
- or override a single property directly:
  `cfnBucket.addPropertyOverride('VersioningConfiguration.Status', 'Enabled');`
- **when to use:** rarely, and only when the clean L2 path genuinely can't express
  it. the point isn't to live down here — it's that the abstraction has a trapdoor,
  so a missing feature never stops you cold.

---

## aspects — apply one rule to the whole tree

sometimes a rule has to hold *everywhere* — every bucket encrypted, every resource
tagged. visiting each construct by hand doesn't scale.

> an <em>aspect</em> is a visitor that CDK runs across every node in your construct
> tree.

- you write the rule once; CDK walks the [construct tree](./constructs.md) and
  applies it to every node — existing and future.
- **when to use:** cross-cutting concerns — enforce a tag on everything, flag any
  resource missing encryption, stamp a compliance check across a whole app.
  `Tags.of(app).add('team', 'payments')` is an aspect under the hood.

---

## choosing your tool — CDK vs the alternatives

CDK isn't the only way to do infrastructure as code, and it isn't always the right
one. the honest contrasts:

### CDK vs raw CloudFormation

- CloudFormation is the **substrate**: the YAML/JSON template AWS actually
  executes. CDK *synthesizes down to it* — recall the synth step from
  [cdk concepts](./cdk_concepts.md).
- CDK adds a real programming language on top: loops, types, reusable constructs,
  the `grant*` helpers. you trade a little "magic" for a lot less boilerplate.
- **when to use raw CFN:** tiny templates, or a team that wants zero abstraction
  between them and the resources. **when to use CDK:** anything that benefits from
  reuse, logic, or type-checking — which is most things.

### CDK vs AWS SAM

- SAM is a slim CloudFormation extension **focused on serverless** (Lambda, API
  Gateway, DynamoDB) with terse syntax for exactly that.
- **when to use SAM:** a small, purely serverless app where SAM's shorthand is all
  you need. **when to use CDK:** a broader system, or one you expect to grow beyond
  serverless — CDK covers every service and gives you a real language to grow into.

### CDK vs Terraform

- Terraform is **multi-cloud**, uses its own language (HCL), and manages its own
  **state file** outside the provider.
- **when to use Terraform:** you deploy across AWS *and* other clouds, or your org
  already standardized on it. **when to use CDK:** you're AWS-focused and want to
  stay in a general-purpose language (TypeScript, python, …) with CloudFormation
  handling state for you.
- honest note: there's also **CDKTF** (CDK syntax, Terraform engine) if you want
  the construct programming model with Terraform's reach — the ideas on these pages
  carry over.

the real lesson isn't "CDK wins." it's that the choice is a *fit* question:
abstraction level, blast radius, and how many clouds you're in.

---

## recap: this is the innermost layer

- the model that survives if you forget the rest: **CDK Pipelines is a
  self-mutating CD pipeline defined in CDK — push to git and it tests, synths,
  rebuilds itself, then promotes your app through every environment.**
- the practices are how the codebase feeding that pipeline stays sane: organize by
  construct, configure in typed code, grant least privilege, treat a stack as a
  blast-radius unit, prefer L2, and read the diff.
- escape hatches and aspects are the safety valves — you're never blocked, and you
  can enforce a rule everywhere at once.
- and CDK is a *choice*, weighed against CloudFormation, SAM, and Terraform — not a
  default.
- that closes the onion: from [what CDK is](./cdk_concepts.md), through the
  [construct tree](./constructs.md) and [the workflow](./workflow.md), into the
  craft of [environments](./environments_config.md),
  [permissions](./resources_permissions_assets.md), and [testing](./testing.md) —
  and out here to shipping it. want the map of the whole journey? go back to
  [the AWS CDK](./cdk.md).
