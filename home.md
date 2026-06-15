# the notes

> compiled and organized by AI — a living set of study notes for AWS, shaped to fit the cloud into your head instead of overwhelming it.

these are reading notes, not a manual. each page opens with what you're actually trying to *do*, then works back into the detail — so you can go as deep as you need and stop the moment it clicks.

## the shape

they're layered like an onion:

<div class="onion">
  <div class="layer l1">the mental model<small>the shape of the thing, in plain language</small>
    <div class="layer l2">the moving parts<small>the services and how they relate</small>
      <div class="layer l3">the specifics<small>limits · classes · knobs</small></div>
    </div>
  </div>
</div>

each layer holds up on its own, so a quick skim still leaves you with a true picture. read top to bottom the first time through — each tier leans on the one above it — then jump around once the shape is in your head.

## the tiers

<div class="cards">
  <a class="card" href="#/notes/cloud_essentials/cloud_concepts.md">
    <span class="tier">① the foundation</span>
    <h3>cloud concepts</h3>
    <p>what "the cloud" is, and the mental model the rest hangs on. start here.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/global_infrastructure.md">
    <span class="tier">① the foundation</span>
    <h3>global infrastructure</h3>
    <p>where your systems run: regions, availability zones, the edge.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/compute_types.md">
    <span class="tier">② building blocks</span>
    <h3>compute</h3>
    <p>running code: servers, serverless, containers.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/storage.md">
    <span class="tier">② building blocks</span>
    <h3>storage</h3>
    <p>keeping data: objects, blocks, files.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/databases.md">
    <span class="tier">② building blocks</span>
    <h3>databases</h3>
    <p>organizing data so you can query and relate it.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/networking.md">
    <span class="tier">② building blocks</span>
    <h3>networking</h3>
    <p>connecting it all, and reaching users quickly and safely.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/security_identity.md">
    <span class="tier">③ cross-cutting craft</span>
    <h3>security &amp; identity</h3>
    <p>who can do what, and how responsibility is split with AWS.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/monitoring_management.md">
    <span class="tier">③ cross-cutting craft</span>
    <h3>monitoring &amp; management</h3>
    <p>seeing what your systems do, and running them at scale.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/billing_pricing.md">
    <span class="tier">③ cross-cutting craft</span>
    <h3>billing &amp; pricing</h3>
    <p>what it costs, and how not to be surprised by the bill.</p>
  </a>
  <a class="card" href="#/notes/cloud_essentials/well_architected.md">
    <span class="tier">④ the synthesis</span>
    <h3>well-architected</h3>
    <p>the six pillars for a "good" design — where every tier connects.</p>
  </a>
</div>

---

new here? open [cloud concepts](/notes/cloud_essentials/cloud_concepts.md) and read down the sidebar.
