<link rel="stylesheet" href="./css/globals.css">

# resources, permissions & assets

once you've got [constructs](./constructs.md) in a stack, the real work begins: making the
pieces *talk to each other* — safely, and without hand-writing the plumbing.

---

## the outcome: parts that reach each other, with the boilerplate handled

a real system is never one resource. it's a lambda that reads a bucket, a service that
talks to a database, an app that ships a folder of code and a container image. for any of
that to work, three boring-but-load-bearing problems have to be solved every single time:

- **permission** — the lambda needs an IAM policy saying it may read that bucket, and nothing more
- **packaging** — your code and files have to physically get *into* AWS before a resource can run them
- **reuse** — sometimes the bucket or VPC already exists and you just need to point at it

done by hand, each of these is fiddly and easy to get wrong — and getting permissions wrong
is how breaches happen (see [security & identity](../cloud_essentials/security_identity.md)).
the destination for this page: <em>resources that can reach each other with least-privilege
access, code and files bundled and shipped automatically, and existing resources reused —
without you writing a line of IAM policy JSON.</em>

CDK's L2 constructs solve all three for you. the rest of this page is the four tools that do it:
**grants** for permission, **connections** for the network, **assets** for shipping local stuff,
and **`fromXxx`** for reuse.

---

## grants — permissions without writing policy JSON

> instead of authoring an IAM policy, you call a method like `bucket.grantRead(fn)` and CDK
> writes the <em>least-privilege</em> policy for you and attaches it to the right role.

this is CDK's single best ergonomics win, so it's worth slowing down on.

recall from [security & identity](../cloud_essentials/security_identity.md) how access
*should* work: least privilege — grant only the actions needed for the task, nothing more,
written as a JSON policy attached to a role. doing that by hand means knowing the exact action
names (`s3:GetObject`, `s3:ListBucket`, …), the exact resource ARNs, and remembering to wire
them to the consumer's role. miss an action and it breaks; add too many and you've widened your
blast radius.

grants collapse all of that into one line:

```ts
const bucket = new s3.Bucket(this, 'Data');
const fn = new lambda.Function(this, 'Handler', { /* ... */ });

bucket.grantRead(fn); // fn's role can now read this bucket — and only read it
```

what that one call actually does for you:

- figures out the **right actions** — `grantRead` expands to exactly the read actions S3 needs, no more
- scopes them to the **right resource** — *this* bucket's ARN, not `*`
- attaches the policy to **fn's execution role** automatically — it knows fn is the consumer
- if the bucket is KMS-encrypted, it even grants use of the **key** too, so you don't get a silent access-denied

the grant family follows a predictable shape across services — `grantRead`, `grantWrite`,
`grantReadWrite`, plus service-specific ones like `table.grantReadData(fn)` or
`queue.grantConsumeMessages(fn)`. you reach for the verb you mean and let CDK translate it into
the locked-down policy.

> the win isn't "less typing." it's that the *default* outcome is least privilege. with raw
> JSON, the easy path is `"Action": "*"` and the safe path takes effort; grants flip that so the
> easy path is the safe one.

---

## connections — letting things talk at the network layer

permission says "you're *allowed* to call me." the network still has to *let the packets
through*. that's security groups (see [networking](../cloud_essentials/networking.md)) — and L2
constructs give them the same one-line treatment.

> `.connections` is a helper on network-attached constructs that opens the security-group rules
> between two things by talking about the *things*, not the rules.

```ts
db.connections.allowFrom(fn, ec2.Port.tcp(5432)); // let fn reach the database on 5432
```

contrast with doing it raw:

- **by hand** — create a security group for the db, create one for fn, write an *ingress* rule on
  the db's group referencing fn's group, on the right port, and don't fat-finger the direction
- **with `.connections`** — name the two constructs and the port; CDK creates the groups (if needed)
  and writes the rule on the correct side, in the correct direction

it's the grants pattern again, one layer down: you describe intent ("fn may reach db"), CDK emits
the fiddly rule. keep the two layers distinct in your head — **a grant is IAM (identity), a
connection is a security group (network)**; a working call usually needs *both*.

---

## roles — when you create one vs let CDK do it

most of the time you never write `new iam.Role(...)` at all.

- **let the construct create it** (the default) — an L2 like `lambda.Function` makes its own
  execution role, and every `grant*` call you make just adds policies to that role. this is the
  common path; lean on it.
- **create a role explicitly** — only when you need control the auto-created one can't give you:
  - a **service needs a role you'll reference by name** elsewhere, or reuse across resources
  - you must set a specific **trust policy** (who may assume it) — e.g. cross-account access
  - org rules require attaching a fixed **permissions boundary**

rule of thumb: start by letting CDK create roles and using `grant*`. reach for an explicit
`iam.Role` only when a requirement forces your hand — same least-privilege thinking as
[security & identity](../cloud_essentials/security_identity.md), just expressed in code.

---

## assets — shipping your local files into AWS

here's a problem the template alone can't solve: your lambda's code lives in a folder *on your
laptop*. CloudFormation can't run a folder. the code has to be *somewhere in AWS* first.

> an **asset** is a local file, directory, or Docker image that CDK uploads to a store in your
> account during deploy, then references in the template by its uploaded location.

the mental model:

- you point a construct at a **local path** (`./lambda-src`, `./website`, a `Dockerfile`)
- on `cdk deploy`, the CLI packages it, **uploads** it — files/zips to **S3**, images to **ECR**
  (see [storage](../cloud_essentials/storage.md) for what those stores are) — and rewrites the
  template to point at the uploaded copy
- the resource then pulls from that store, not from your machine

this is *why* `cdk bootstrap` exists. bootstrapping creates the S3 bucket and ECR repo that
assets land in; without it, there's nowhere to upload to and deploy fails (the bootstrap step is
covered in [the workflow](./workflow.md)).

the three asset flavors you'll meet:

### code — `lambda.Code.fromAsset(...)`
package a directory of function code and hand it to a lambda.

```ts
new lambda.Function(this, 'Handler', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('lambda-src'), // this folder gets zipped + uploaded to S3
});
```

### files — `s3-assets` and `aws-s3-deployment`
get arbitrary files into S3.

- **`aws_s3_assets.Asset`** — upload a file/dir as a raw asset you reference by its S3 location
  (handy for passing a config file or script to another resource)
- **`aws_s3_deployment.BucketDeployment`** — sync the *contents* of a local folder into a bucket
  you manage. the go-to for publishing a built static website into its hosting bucket.

### containers — `DockerImageAsset`
build a Docker image locally and push it to ECR, ready for ECS/Fargate or a container lambda.

```ts
const image = new ecr_assets.DockerImageAsset(this, 'Image', {
  directory: 'app', // folder with a Dockerfile; built and pushed to ECR on deploy
});
```

the through-line across all three: **you keep referring to a local path; CDK handles the upload
and the indirection.** the bootstrapped store is the landing pad that makes it possible.

---

## referencing things that already exist — the `fromXxx` pattern

not everything your app touches is *yours to create*. the bucket might be owned by another team,
the VPC might predate your stack. you need to *point at* it without CDK trying to create or change it.

> the **`.fromXxx` / `fromLookup`** importers give you a <em>read-only handle</em> to an existing
> resource. CDK will reference it, but never create or modify it.

```ts
// by a known identifier — resolved at synth, no AWS call
const bucket = s3.Bucket.fromBucketName(this, 'Existing', 'my-legacy-bucket');

// by lookup — CDK queries your account at synth to find it (needs a concrete environment)
const vpc = ec2.Vpc.fromLookup(this, 'Default', { isDefault: true });
```

the contrast that matters — **import vs create**:

- `new s3.Bucket(...)` — CDK **owns** it: creates it, can change it, can delete it on stack teardown
- `s3.Bucket.fromBucketName(...)` — CDK **borrows** it: a handle for wiring (you can still
  `grantRead` on it), but it's outside this stack's lifecycle and CDK won't touch its existence

two import styles, worth distinguishing:

- **`fromXxxName` / `fromXxxArn`** — you supply the identifier; resolved purely at synth, no network call
- **`fromLookup`** — CDK *queries your account* at synth time to discover the resource, then caches
  the result in context. needs a real account/region (no environment-agnostic stacks), but lets you
  find things by attribute instead of hardcoding an ARN

> mental test: *did this app create the thing?* if yes, `new`. if it already existed, `fromXxx`.

---

## removal policies — what happens when the resource goes away

a practical gotcha worth its own beat: when a stack is deleted (or a resource removed from it),
what happens to the real resource?

> **`RemovalPolicy`** decides the fate of a resource on removal — `DESTROY` (delete it) or
> `RETAIN` (orphan it, leave the data alone).

- **stateless resources** (a lambda, a role) default to `DESTROY` — losing them costs nothing, recreate freely
- **stateful resources** (S3 buckets, RDS/DynamoDB) default to **`RETAIN`** — CDK refuses to delete
  your data on a teardown, because that's almost never what you meant. the resource is left behind.

the gotcha both directions:

- tearing down a dev stack and finding **orphaned buckets/databases still on your bill** — that's `RETAIN` doing its job; clean them up by hand or set `DESTROY` deliberately
- setting `DESTROY` on a real database to make teardown clean, then **losing production data** — the policy exists to stop exactly this, so set it with intent

```ts
const bucket = new s3.Bucket(this, 'Temp', {
  removalPolicy: cdk.RemovalPolicy.DESTROY, // dev-only: I really do want this gone on teardown
  autoDeleteObjects: true,                  // and empty it first, since S3 won't delete a full bucket
});
```

---

## recap

five tools, one theme — *describe intent, let CDK emit the fiddly bits*:

- **grants** (`bucket.grantRead(fn)`) — least-privilege IAM policy, written and attached for you
- **connections** (`db.connections.allowFrom(fn, port)`) — security-group rules by naming the things, not the rules
- **roles** — let the construct create them; write `new iam.Role` only when a requirement forces it
- **assets** (`Code.fromAsset`, `BucketDeployment`, `DockerImageAsset`) — local code/files/images uploaded to the bootstrapped store and referenced in the template
- **`fromXxx` / `fromLookup`** — a read-only handle to something that already exists; CDK borrows, never owns
- **`RemovalPolicy`** — DESTROY vs RETAIN; stateful resources retain by default so a teardown can't eat your data

the spine to carry forward: grants make least privilege the *easy* path. that single ergonomic
choice is most of why teams reach for CDK over hand-written CloudFormation — next, [testing](./testing.md)
proves the infrastructure you described is the infrastructure you meant.
