<link rel="stylesheet" href="./css/globals.css">

# constructs — the construct tree

CDK's one big idea. once you have it, the rest of the section is just detail.

---

## the outcome: build infrastructure out of building blocks

the goal is to describe a whole system — a bucket here, a function there, a
database, the network they sit in — *without* writing one giant template by hand
where everything is tangled together.

instead you compose it:
- the smallest block is a single resource — `new s3.Bucket(...)` is one line.
- you group a few of those into a bigger block — "the storage layer."
- you group *those* into bigger ones still — "the whole app."
- and you can take a block someone else wrote and drop it into yours.

the win is the same one functions gave programming: <em>name a thing once, reuse
it everywhere, and stop repeating yourself</em>. a CDK app is built bottom-up out
of labelled, reusable pieces — and every one of those pieces is a **construct**.

> if you haven't met *synth → deploy* yet — how this code becomes a CloudFormation
> template and then real infrastructure — read [cdk concepts](./cdk_concepts.md)
> first. this page is what you're actually *building* in that flow.

---

## the mental model: everything is a construct

> a construct is a <em>reusable cloud component</em> — a labelled node that knows
> how to turn itself into infrastructure.

that's the whole abstraction. hold onto two facts:

- a construct can be **one resource** (an S3 bucket) *or* **a whole pattern of
  many** (a load balancer + service + auto-scaling, bundled together). same word
  for both — size doesn't change what it *is*.
- constructs **nest inside constructs**. the thing you put a construct *into* is
  itself a construct. that nesting forms a **tree**, and the tree *is* your app.

think of it like LEGO. a single brick is a piece; so is a pre-built wall made of
twenty bricks; so is the finished house. they all click together the same way,
and the house is just bricks-of-bricks all the way down.

when CDK runs, it walks that tree top to bottom and asks every node to render
itself into CloudFormation. you build the tree; CDK produces the template.

---

## the three constructs that frame an app

most constructs are resources you choose. but three special ones give every CDK
app its shape — they're the trunk the rest of the tree hangs from.

### app — the root

the whole CDK application; the single node everything else lives under.
- you create exactly one, usually on the first line of your entry file.
- it owns no infrastructure itself — it's the container for your stacks.

### stack — the unit of deployment

a stack maps <em>1:1 to a CloudFormation stack</em> — the thing that actually gets
deployed, updated, and torn down as one unit.
- everything you want to deploy together goes in the same stack.
- it's the boundary CloudFormation cares about: one stack = one template.

### construct — the generic node

anything you compose *inside* a stack: the buckets, functions, and tables, plus
any groupings of your own. this is the everyday meaning of "construct."

putting them together — app contains stack contains resources:

```ts
const app = new App();

class StorageStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    new s3.Bucket(this, 'RawData');      // a construct, inside…
    new dynamodb.Table(this, 'Index', {  // …this stack, inside the app
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
    });
  }
}

new StorageStack(app, 'Storage');
```

read the tree off the page: `app → StorageStack → { RawData, Index }`. that
parent-child chain is the construct tree, and it's the same shape no matter how
big the app gets.

---

## construct levels — the schema that matters most

the single most useful thing to internalise: constructs come in **three levels**,
and they trade *control* for *convenience*. pick the level, and you've half-made
every decision that follows.

### L1 — the raw mapping (`Cfn*`)

a thin, mechanical 1:1 mirror of a CloudFormation resource. every property is
exposed, *nothing* is defaulted — you supply it all.
- named `CfnBucket`, `CfnFunction`, etc. — the `Cfn` prefix is the tell.
- maximum control, minimum help. it's CloudFormation wearing a TypeScript coat.
- **when to use:** a brand-new or niche resource that no L2 covers yet, or when
  you need to set a property the L2 hasn't surfaced. otherwise, avoid.

### L2 — the curated everyday level

an opinionated, hand-built construct with <em>sensible defaults, helper methods,
and best practices baked in</em>. this is the level you'll live in.
- `new s3.Bucket(this, 'X')` gives you a working, secure-by-default bucket — no
  need to spell out encryption or block-public-access by hand.
- the helpers are the payoff: `bucket.grantRead(fn)` wires up IAM for you
  (much more in [resources, permissions & assets](./resources_permissions_assets.md)).
- **when to use:** almost always. reach for L2 first and only drop down to L1
  when it can't reach a knob you need.

### L3 — patterns (whole solutions)

an opinionated construct that wires up *many* resources to solve a complete use
case in one shot.
- e.g. `ApplicationLoadBalancedFargateService` stands up a load balancer, a
  Fargate service, a task definition, and the networking between them — from a
  few lines. (Fargate and friends live in [compute types](../cloud_essentials/compute_types.md).)
- highest convenience, most opinions imposed on you.
- **when to use:** a common, well-trodden architecture you'd rather not hand-wire.
  if your needs diverge from its opinions, you'll fight it — drop to L2 then.

the throughline: **L1 is every knob, L2 is the right defaults, L3 is the whole
machine.** same tree, same composition — just how much is decided for you.

---

## the construct contract: `(scope, id, props)`

every construct — L1, L2, L3, your own — is created the same way. learn this once
and you can read any CDK code:

```ts
new s3.Bucket(this, 'RawData', { versioned: true });
//            └──┬─┘  └───┬──┘   └──────┬───────┘
//            scope     id           props
```

- **scope** — *where it sits in the tree*; its parent node. passing `this` means
  "this construct belongs to the stack (or construct) I'm inside." that single
  argument is what builds the tree.
- **id** — a string <em>unique within its parent</em>. CDK combines the ids along
  the path from the root to compute each resource's CloudFormation **logical id**,
  so a stable id keeps a resource stable across deploys — renaming it replaces the
  resource. (you saw `'RawData'`, `'Index'`, `'Storage'` above.)
- **props** — the construct's configuration; an object whose shape depends on the
  construct. this is where L2's sensible defaults mean you set little, and L1's
  total exposure means you set everything.

this `(scope, id, props)` pattern repeats *everywhere*. it's not three signatures
to memorise — it's one, reused by every node in the tree.

---

## composition: writing your own construct

here's the payoff of "everything is a construct." once you've grouped a few
resources you keep deploying together, wrap them in your *own* construct by
extending `Construct` — and now your bundle is a reusable block exactly like the
built-in ones.

```ts
class WebsiteBucket extends Construct {
  readonly bucket: s3.Bucket;

  constructor(scope: Construct, id: string) {
    super(scope, id);                       // same contract, passed upward
    this.bucket = new s3.Bucket(this, 'Site', {
      websiteIndexDocument: 'index.html',
      publicReadAccess: true,
    });
    // …add a CloudFront distribution, a deployment, etc. here later
  }
}

// then, anywhere:
new WebsiteBucket(this, 'Marketing');
new WebsiteBucket(this, 'Docs');
```

- you defined the building block *once*; the two uses are one line each.
- it nests into the tree like any other construct — `scope` is `this`, an `id`
  makes it unique.
- this is how L3 patterns are built, and how teams ship internal "golden path"
  constructs that bake in their own standards. (S3 specifics live in
  [storage](../cloud_essentials/storage.md).)

---

## where prebuilt constructs come from

you rarely start from scratch — most blocks already exist.

- **`aws-cdk-lib`** — the single package that ships the L1 and L2 constructs for
  (almost) every AWS service. `import * as s3 from 'aws-cdk-lib/aws-s3'` and the
  bucket is there.
- **[Construct Hub](https://constructs.dev/)** — the public registry of
  community and partner constructs, including most L3 patterns. search it before
  you build a pattern by hand — someone has often solved it already.

---

## where to go next

- [the workflow](./workflow.md) — now that you can build the tree, how the CLI
  turns it into real infrastructure in an account.
- [resources, permissions & assets](./resources_permissions_assets.md) — working
  with the resources *inside* your constructs: granting access, bundling assets,
  referencing things that already exist.
- back to [cdk concepts](./cdk_concepts.md) if synth → deploy still feels fuzzy.
