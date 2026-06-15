<link rel="stylesheet" href="./css/globals.css">

# testing CDK code

the way you catch an infrastructure mistake <em>on your laptop</em> — before it
ever touches an account.

---

## the outcome: confidence the template is what you intended

what you actually want from a test:

- to know that the stack you wrote produces the resources you meant — the right
  bucket, the right encryption, the right policy — **before** a deploy turns a
  typo into a real, billable, possibly-public mistake.
- to lock in intent so that next month's refactor can't *silently* change what
  gets deployed. you rename a construct, the tests still pass, you ship with a
  clear conscience.

CDK is just code, so it gets tested like code: a test runner, assertions, a red
or green result in your terminal. the only twist is *what* you point those
assertions at — and that's the whole mental model.

---

## the mental model: you test the synthesized template

you do **not** deploy anything to test it. you test the artifact CDK produces
*before* deploy.

> a CDK test synthesizes the stack and makes assertions about the resulting
> <em>CloudFormation template</em> — not a live deployment.

remember the synth → deploy split from [cdk concepts](./cdk_concepts.md): your
TypeScript runs, the [construct tree](./constructs.md) collapses into a single
JSON CloudFormation template, and *that* template is the truth about what AWS
will build. a test grabs that JSON and inspects it.

- **fast** — synth is a local in-memory step. no AWS calls, no credentials, no
  waiting on a stack to come up. tests run in seconds.
- **honest** — you're checking the exact thing that gets deployed, not a model
  of it. if the template says `Encrypted: false`, the test sees `false`.
- **the shape of every test** — construct your stack in code, synth it, assert
  against the template. everything below is just *how* you write that assertion.

---

## the three techniques

three ways to assert against that synthesized template. the first is the
everyday workhorse; the others guard different things.

### fine-grained assertions

check that a *specific* resource with *specific* properties exists in the
template.

- you load the template with `Template.fromStack(stack)`, then ask precise
  questions: does an `AWS::S3::Bucket` exist with encryption on? are there
  exactly two of them?
- `hasResourceProperties` matches a *subset* — you list only the properties you
  care about, and it ignores the rest. `resourceCountIs` guards against
  accidentally creating two of something.
- **when to use** — your default. reach for this whenever you care that one
  particular knob is set the way you intend (encryption on, retention set, a
  policy attached). expresses intent precisely and stays quiet about everything
  you didn't mention.

### snapshot tests

capture the *whole* template to a file and fail the test if it ever changes.

- the first run records the full synthesized JSON. every later run diffs against
  that saved snapshot; any difference is a failure until you review and re-bless
  it.
- **when to use** — to guard against *accidental drift* during a refactor. you
  swap an L2 construct for a custom one and want a tripwire that screams if the
  output changed at all.
- **the tradeoff** — great at answering "did *anything* change?", bad at saying
  *whether the change was correct*. an intentional edit lights up the whole
  snapshot, and the temptation is to rubber-stamp the update without reading it.
  overused, they become noise you reflexively re-approve.

> contrast: fine-grained says **"this specific thing is right."** a snapshot
> says **"nothing changed."** one encodes intent; the other detects surprise.
> most stacks want a handful of fine-grained assertions and, at most, one
> snapshot.

### validation / custom assertions

check that your *own* constructs uphold the rules you designed them around.

- when you build a reusable construct (an L3 — see [constructs](./constructs.md)),
  you can assert callers used it correctly: a required prop is present, a value
  is in range, two settings aren't contradictory.
- CDK also runs built-in validations at synth time and aborts with an error if
  the tree is malformed — your custom checks ride the same path.
- **when to use** — only once you're *authoring* constructs others consume, not
  for app stacks you assemble from off-the-shelf parts.

---

## a real example

a Jest test that synthesizes a stack and asserts one property — the whole shape
in ten lines.

```ts
import { Template, Match } from 'aws-cdk-lib/assertions';
import { App } from 'aws-cdk-lib';
import { MyStack } from '../lib/my-stack';

test('bucket is encrypted', () => {
  const template = Template.fromStack(new MyStack(new App(), 'test'));
  template.hasResourceProperties('AWS::S3::Bucket', {
    BucketEncryption: Match.anyValue(), // an encryption block is present
  });
});
```

construct → synth (`fromStack` does it) → assert. swap the assertion for
`resourceCountIs('AWS::S3::Bucket', 1)` or a snapshot and the skeleton is
identical.

---

## where this runs

the same tests run in two places, for two reasons.

- **locally** — on your laptop while you write, the same `jest` (or your runner
  of choice) you'd use for any code. fast feedback, no AWS account needed.
- **in CI** — the real payoff. wire these tests as a gate so a pull request
  can't merge, and the [pipeline](./pipelines_practices.md) can't deploy, until
  the template asserts clean. that's how "before it reaches an account" stops
  being a hope and becomes enforced.

#### the manual cousin

`cdk diff` is the by-hand version of a snapshot test: it shows you what *this*
synth changes versus what's deployed, so you eyeball the drift before shipping.
a snapshot test automates that same instinct in CI. see
[the workflow](./workflow.md).

---

## recap

- **fine-grained** assertions answer *"is this specific thing right?"* — your
  daily driver, and where intent lives.
- **snapshot** tests answer *"did anything change?"* — a refactor tripwire,
  powerful but easy to over-trust.
- both run against the **synthesized template**, never a live deploy — which is
  why they're fast, honest, and safe to gate a [pipeline](./pipelines_practices.md)
  on.
