<link rel="stylesheet" href="./css/globals.css">

# cdk concepts

the foundation of the CDK section. everything else here assumes the synth → deploy
model built on this page. read this first.

---

## the outcome: infrastructure you ship like software

the whole point of the CDK is this:
- you describe your cloud — the buckets, the databases, the networks — in a file,
  then commit that file to git like any other code
- you can <em>review it in a pull request, diff it, and redeploy it</em> the same
  way your team ships application code
- when you need the same setup again — a second environment, a fresh account, a
  recovery after disaster — you run one command instead of re-clicking a hundred
  screens

clicking around the console is fine for *learning* what a service does. but a
system you built by hand has no record of how it was built, can't be reviewed
before it changes, and can't be rebuilt the same way twice. the CDK turns your
infrastructure into something you can treat exactly like the rest of your codebase.

> if "S3 bucket" or "IAM role" don't mean anything yet, read the
> [cloud concepts](../cloud_essentials/cloud_concepts.md) first — CDK is *how you
> build* those things, not what they are.

---

## the problem it solves: clicking doesn't scale

there are three ways to get a resource into AWS, and the first two have a ceiling.

- **clicking the console** — fast to learn, impossible to repeat. nobody can
  review a click. you can't diff what changed. and "do that again, exactly" is a
  prayer, not a process.
- **raw templates (CloudFormation / Terraform)** — this is the real fix:
  *infrastructure as code* (IaC), where you write a file that *declares* the
  system you want and a service builds it. versioned, reviewable, repeatable.
- **but the templates are written in data, not code** — CloudFormation is
  YAML/JSON, Terraform is HCL. you can describe resources, but you can't really
  *program*: no loops, no functions, no real abstraction, no reuse.

so IaC is the category, and it's the right idea. the catch is the language. a
plain template makes you spell out every resource by hand, even when ten of them
are nearly identical.

---

## what the CDK is

> a toolkit for defining your cloud infrastructure in a <em>familiar programming
> language</em> — then turning that code into a template AWS knows how to deploy.

- you write TypeScript, Python, Java, C#, or Go — whatever your team already uses
- you get everything a real language gives you: variables, loops, functions,
  types, editor autocomplete, and packages you can share
- the CDK takes that code and *generates* a CloudFormation template from it

the key move: CDK is not a new deployment engine. it's an <em>authoring layer on
top of CloudFormation</em>. you author in code; CloudFormation still does the
actual provisioning. that relationship is the whole mental model — next.

---

## the core mental model: synth → deploy

this is the spine of the entire section. hold onto it.

> your code → `cdk synth` → a CloudFormation template → CloudFormation creates or
> updates the real resources.

walk it left to right:
- **your code** describes what you want (a bucket, a function, a database)
- **`cdk synth`** *synthesizes* — it runs your code and emits a plain
  CloudFormation template (JSON). this is the moment your program becomes data.
- **the template** is the artifact AWS understands — the same kind of file you'd
  have hand-written, only generated for you
- **CloudFormation** reads that template and makes reality match it: it creates
  what's new, changes what differs, and deletes what you removed

two things fall out of this that matter:
- the CDK runs entirely on *your* machine (or your pipeline). AWS never sees your
  TypeScript — only the template it produces.
- because CloudFormation does the deploying, you inherit all of its guarantees:
  one resource fails, the whole change rolls back; the template is the single
  record of what's deployed.

everything else in these notes — constructs, the workflow, testing — is just
detail hanging off this one pipeline.

---

## why a real language beats a template

the contrast is the lesson. say you need five buckets that differ only by name.

in a template, you copy the same block five times:

```yaml
Bucket0: { Type: AWS::S3::Bucket, Properties: { BucketName: data-0 } }
Bucket1: { Type: AWS::S3::Bucket, Properties: { BucketName: data-1 } }
Bucket2: { Type: AWS::S3::Bucket, Properties: { BucketName: data-2 } }
# ...and so on, by hand, forever
```

in the CDK, you loop:

```ts
for (let i = 0; i < 5; i++) {
  new s3.Bucket(this, `Bucket${i}`, { bucketName: `data-${i}` });
}
```

- **loops and conditionals** — generate many resources, or toggle them per
  environment, instead of pasting
- **functions and types** — wrap a common pattern once; the compiler catches the
  typo before you deploy
- **autocomplete** — your editor tells you what properties exist, so you stop
  living in the docs
- **reuse** — package a working component and share it across teams, the same way
  you share any library

a template *describes* infrastructure. code lets you *build* it.

---

## a tiny taste

just enough to make it real — don't worry about the API yet, that's
[constructs](./constructs.md)'s job. a stack with a single bucket:

```ts
import { App, Stack } from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';

const app = new App();
const stack = new Stack(app, 'MyStack');
new s3.Bucket(stack, 'MyBucket', { versioned: true });
```

run `cdk synth` on that and you get a CloudFormation template with an
`AWS::S3::Bucket` in it. run `cdk deploy` and the bucket appears in your account.
that's the entire loop, from code to real resource.

---

## cdk vs the alternatives (quick orientation)

all of these are infrastructure as code; they differ in *how* you write it. the
short version — the full comparison lives in
[pipelines & best practices](./pipelines_practices.md).

- **raw CloudFormation** — write the YAML/JSON yourself. no extra tooling, but no
  loops, types, or abstraction. when to use: tiny stacks, or you want the template
  with zero layers on top.
- **AWS SAM** — a slim CloudFormation shorthand aimed squarely at serverless
  (Lambda + API Gateway). when to use: a small, serverless-only app where SAM's
  focus is a feature, not a limit.
- **Terraform** — a different IaC tool with its own language (HCL) that deploys
  across many clouds, not just AWS. when to use: you're multi-cloud, or your team
  already lives in Terraform.
- **the CDK** — author in a real language, synth to CloudFormation. when to use:
  you want programming-language power and you're committed to AWS.

---

## what you need to follow along

just enough to start; the actual commands live in [the workflow](./workflow.md).

- **node.js** — the CDK toolkit runs on it, even if you write Python or Java
- **the `aws-cdk` toolkit** — the `cdk` command line tool (`npm i -g aws-cdk`)
- **an AWS account with credentials configured** — so the toolkit can deploy on
  your behalf

---

## where to go next

- [constructs](./constructs.md) — the building blocks you actually assemble apps
  from, and the construct tree they form
- [the workflow](./workflow.md) — the CLI lifecycle: bootstrap, synth, deploy, and
  how code on your laptop becomes infrastructure in an account
- [pipelines & best practices](./pipelines_practices.md) — the full tool
  comparison and the practices that keep a CDK codebase sane
