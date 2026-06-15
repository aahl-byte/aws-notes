# the notes

> understand AWS the way you'd actually reason about it: start from <em>how big things get done</em>, then peel back into the detail.

most documentation is written left → right — it opens with the smallest primitive (here is a flag, here is a parameter) and hopes you assemble the big picture yourself. you rarely do. these notes invert that. every page names the **destination** first — a website that stays up, data that survives a disk failure, a bill that doesn't surprise you — then works *leftward* into the capability and detail required to get there.

## structured like an onion

each layer is complete on its own terms, so you can stop at any depth and still hold a true (if coarse) mental model. depth is opt-in.

<div class="onion">
  <div class="layer l1">the mental model<small>the shape of the thing, in plain language</small>
    <div class="layer l2">the moving parts<small>the services and how they relate</small>
      <div class="layer l3">the specifics<small>limits · classes · knobs</small></div>
    </div>
  </div>
</div>

read the building tiers in order the first time — each assumes the models built above it — then jump around freely once the shape is in your head.

## where to start

<div class="cards">
  <a class="card" href="#/notes/cloud_essentials/cloud_concepts.md">
    <span class="tier">① the foundation</span>
    <h3>cloud concepts</h3>
    <p>what "the cloud" actually is, the value proposition, and the mental model everything else hangs on. read first.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/global_infrastructure.md">
    <span class="tier">① the foundation</span>
    <h3>global infrastructure</h3>
    <p>where your systems run: regions, availability zones, and the edge.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/compute_types.md">
    <span class="tier">② building blocks</span>
    <h3>compute</h3>
    <p>running code: servers (EC2), serverless (Lambda), and containers.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/storage.md">
    <span class="tier">② building blocks</span>
    <h3>storage</h3>
    <p>keeping data: the three shapes — objects, blocks, and files.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/databases.md">
    <span class="tier">② building blocks</span>
    <h3>databases</h3>
    <p>organizing data so you can query and relate it reliably.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/networking.md">
    <span class="tier">② building blocks</span>
    <h3>networking</h3>
    <p>connecting it all, and getting it to users quickly and safely.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/security_identity.md">
    <span class="tier">③ cross-cutting craft</span>
    <h3>security &amp; identity</h3>
    <p>who can do what, and how responsibility is split with AWS.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/monitoring_management.md">
    <span class="tier">③ cross-cutting craft</span>
    <h3>monitoring &amp; management</h3>
    <p>seeing what your systems do, and operating them at scale.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/billing_pricing.md">
    <span class="tier">③ cross-cutting craft</span>
    <h3>billing &amp; pricing</h3>
    <p>what it costs, and how not to be surprised by the bill.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/well_architected.md">
    <span class="tier">④ the synthesis</span>
    <h3>well-architected</h3>
    <p>the six pillars AWS uses to judge a "good" architecture — where every layer connects.</p>
  </a>
</div>

## how these notes are written

a few principles guide every page, drawn from how people actually learn:

- **manage cognitive load** — one hard idea at a time; no holding five new terms to grasp the sixth.
- **scaffold, then remove the scaffold** — lead with a familiar analogy, then graduate to the precise term.
- **build schemas, not lists** — always answer *why does this exist* and *what does it connect to* before *what are its parameters*.
- **concrete before abstract** — a worked example earns the right to state a general rule.

if a page is accurate but you finish it with no mental model, it has failed. accuracy is necessary, not sufficient.

---

new here? open [cloud concepts](/notes/cloud_essentials/cloud_concepts.md) and read straight down the sidebar.
