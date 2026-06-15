<link rel="stylesheet" href="./css/globals.css">

# environments & config

one codebase, many targets. how you point CDK at the right account and region,
feed it the right values, and wire a handful of stacks together — without
copy-pasting your app per environment.

---

## the outcome: same code, dev → staging → prod

the thing you're actually trying to do:

- write the app **once**, then deploy it to a throwaway dev account, a shared
  staging account, and a locked-down prod account — each in whatever region you
  want — with <em>no forked copies of the code</em>.
- per-environment differences (smaller instances in dev, real domain in prod)
  are just *values you pass in*, not separate files you maintain in parallel.
- stacks that need something from each other (a vpc, a bucket name) get it
  handed across cleanly, instead of you copy-pasting ARNs by hand.

everything below is the machinery that makes that one outcome boring and safe.
four ideas carry the whole page:

- **env** — *where* a stack deploys (account + region).
- **context / props** — *with what values* it deploys.
- **stage** — *a whole copy* of the app for one environment.
- **cross-stack refs** — how stacks *share* with each other.

---

## env — where a stack deploys

an <em>environment</em> in CDK is dead simple: a specific **account + region** a
stack lands in. it's set on the stack, not the app.

```ts
new MyStack(app, 'Prod', {
  env: { account: '111122223333', region: 'eu-west-1' },
});
```

- the `env` is the *address* the stack deploys to. no `env` means CDK figures it
  out at deploy time from your CLI credentials.
- think of `account + region` the way [global infrastructure](../cloud_essentials/global_infrastructure.md)
  frames it: the region is the city you're building in, the account is whose name
  is on the lease.

### environment-agnostic vs explicitly-targeted

the choice is whether you pin the address now or leave it blank.

- **environment-agnostic** (no `env`) — the stack deploys wherever your current
  credentials point. flexible, and fine for simple apps, but CDK has to generate
  CloudFormation that works *anywhere*, so it can't know things like "how many
  AZs does this region have."
- **explicitly-targeted** (`env` set) — you name the account and region up front.
  more verbose, but it unlocks <em>environment lookups</em>.

### why hardcoding the address matters

the payoff is **lookups at synth time**. if CDK knows the exact region, it can
ask AWS real questions while it builds your template:

- "what are the actual availability zones in `eu-west-1`?" — so it can spread
  resources across real AZs instead of guessing.
- "what's the id of the existing default vpc here?"

an agnostic stack can't do any of this — it has no region to ask about, so it
falls back to conservative assumptions (e.g. only two AZs). **when to pin the
env:** any time you do lookups or care about real AZ counts. leave it agnostic
only for the simplest, region-portable stacks.

---

## context — values handed in at synth time

<em>context</em> is CDK's key-value bag of inputs, available while your code
synthesizes. it's how the framework passes in answers — both ones you set and
ones it discovers.

- **set in `cdk.json`** under a `"context"` key — checked in, shared by everyone.
- **passed on the CLI** with `--context key=value` (alias `-c`) for one-off
  overrides.
- **read in code** with `this.node.tryGetContext('key')`.

```ts
const stage = this.node.tryGetContext('stage'); // e.g. 'dev'
```

### context lookups (and the cache)

the more interesting use is **lookups**: CDK reaching into a *real* account to
find something that already exists.

```ts
const vpc = ec2.Vpc.fromLookup(this, 'Vpc', { isDefault: true });
```

- the first synth actually calls AWS, finds the vpc, and **caches the answer in
  `cdk.context.json`** so future synths are deterministic and don't drift.
- that cache file is checked in on purpose — it means a teammate (or a pipeline)
  synthesizes the *same* template you did, without needing live AWS access.
- lookups need a concrete `env` to know *which* account/region to query — another
  reason to pin the address.

### context vs plain constants — when to use which

- **plain code constant** — the value is *yours* and known at author time
  (a port number, a list of stage names). just write it in TypeScript.
- **context** — the value comes from *outside* the code: discovered from AWS
  (lookups), or injected per-invocation by the CLI / a pipeline. don't reach for
  context to hold config you could just type as a constant.

---

## configuration — prefer typed code over config files

the CDK way is to treat config as **plain, typed code**, not an external
`config.yaml` you parse. you already have a real programming language — use it.

- per-environment settings live in a typed structure, so a wrong key or a missing
  field is a **compile error**, not a 3am surprise in prod.
- contrast with context: context is stringly-typed and untyped; a typed props
  interface gives you autocomplete and type-checking.

```ts
interface AppConfig {
  readonly env: { account: string; region: string };
  readonly instanceSize: string;
  readonly minCapacity: number;
}

const environments: Record<string, AppConfig> = {
  dev:  { env: { account: '111111111111', region: 'us-east-1' }, instanceSize: 't3.micro', minCapacity: 1 },
  prod: { env: { account: '222222222222', region: 'us-east-1' }, instanceSize: 'm5.large', minCapacity: 3 },
};
```

you then pass the chosen config into a stack as **props** — the normal way one
construct configures another. the environment differences are now data, flowing
through typed interfaces, with one source of truth.

---

## stages — a whole copy of the app

a `Stage` is a deployable **copy of an entire set of stacks** — the whole app for
one environment, treated as a single unit.

- where a *stack* is one deployable unit, a *stage* groups several stacks into one
  logical "the app, for beta" or "the app, for prod."
- you typically give a stage its own `env`, so all the stacks inside it inherit
  where they deploy.

```ts
class MyApp extends Stage {
  constructor(scope: Construct, id: string, props?: StageProps) {
    super(scope, id, props);
    new NetworkStack(this, 'Network');
    new AppStack(this, 'App');
  }
}

new MyApp(app, 'Beta', { env: environments.dev.env });
new MyApp(app, 'Prod', { env: environments.prod.env });
```

- this is the natural seam for **promotion**: deploy `Beta`, check it, then deploy
  the *identical* `Prod`. same code, different address.
- stages are how a [pipeline](./pipelines_practices.md) models environments — beta
  then prod become ordered stages the pipeline walks through.

---

## multiple stacks in one app

one app can hold many stacks, and splitting them is a feature, not a mess. you
split along the lines you want to deploy and reason about **separately**:

- **lifecycle** — a slow-changing vpc shouldn't redeploy every time you tweak a
  lambda. separate stacks, separate cadence.
- **blast radius** — a bad change to the app stack can't take the database stack
  with it.
- **ownership** — different teams own different stacks.

the rule of thumb is **one stack per deployment unit** — group what should ship
together, split what shouldn't. you pick which to deploy from the CLI (see
[the workflow](./workflow.md)).

---

## cross-stack references — sharing between stacks

when stack A needs a value from stack B, you don't copy ARNs around — you just
**reference the construct**, and CDK wires it up.

```ts
const network = new NetworkStack(app, 'Network');
new AppStack(app, 'App', { vpc: network.vpc }); // hand the construct across
```

- under the hood CDK creates a CloudFormation **export** on the producing stack and
  an **import** on the consuming one. you never write those by hand.
- this also teaches the deploy order: CDK sees the dependency and deploys
  `Network` before `App`.

### the gotcha: tight coupling & the "deadly embrace"

cross-stack refs are convenient, so it's easy to over-use them.

- once stack B imports an export from stack A, A can't simply remove or change
  that exported value while B still uses it — you can get stuck unable to deploy
  either. this is the **deadly embrace**.
- worse, two stacks referencing *each other* create a cycle CDK can't order.
- keep it practical: share sparingly and in one direction. for values that cross
  account or region boundaries (where exports don't reach), pass them as plain
  config/props instead.

---

## recap

the four ideas, one line each:

- **env** = *where* — the account + region a stack deploys to. pin it to unlock
  lookups and real AZs.
- **context / props** = *with what values* — context for discovered/injected
  inputs (cached in `cdk.context.json`); typed props for config you own.
- **stage** = *a whole copy* — the entire app bundled for one environment, the
  unit a [pipeline](./pipelines_practices.md) promotes.
- **cross-stack refs** = *sharing* — reference the construct and CDK handles the
  export/import; share sparingly to avoid the deadly embrace.

next: [resources, permissions & assets](./resources_permissions_assets.md) — granting
access and referencing things that already exist.
