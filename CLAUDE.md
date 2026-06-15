# aws-notes — project guide

living study notes for AWS, published as a static site via GitHub Pages.

this is an *educational* repository. the product is **understanding**, not coverage.
every change should leave a learner better able to reason about AWS, not just
better supplied with facts.

---

## the core teaching principle: think Right → Left

> always reason from **"how big things get done"** — the outcome on the *right* —
> and work *leftward* into the detail required to get there.

most documentation is written left → right: it starts at the smallest primitive
(here is a flag, here is a parameter) and hopes the reader assembles the big
picture themselves. they rarely do. we invert this.

- **start at the right edge: the outcome.** what does a real system *do*? what
  problem does a person actually have? a website that stays up under load, data
  that survives a disk failure, a bill that doesn't surprise you. name the
  destination before describing the road.
- **move leftward into capability.** what has to be true for that outcome to
  exist? this surfaces the *categories* (compute, storage, networking) before
  the *services*, and the services before their *settings*.
- **the smallest details come last**, and only once there is somewhere for them
  to land. a parameter is noise until the learner knows which knob it turns and
  why they'd reach for it.

when you draft or review a section, ask: *does this open with the thing a person
is trying to accomplish, or does it open with a primitive?* if it opens with a
primitive, it's backwards. fix it.

---

## structure like an onion

build a foundation of understanding, then peel back to specifics — never the
reverse. each layer should be *complete and correct on its own terms*, so a
reader can stop at any depth and still hold a true (if coarse) mental model.

1. **outer skin — the mental model.** the shape of the thing, in plain language,
   with an analogy a beginner already owns. "a region is a city you choose to
   build in." no jargon survives this layer un-defined.
2. **middle layers — the moving parts.** the services and how they relate. what
   each one is *for*, when you'd reach for it, what it replaces. relationships
   over enumeration.
3. **core — the specifics.** instance families, storage classes, pricing knobs,
   limits. the detail that only makes sense once the outer layers are in place.

a specific introduced before its layer exists has nowhere to settle and is
forgotten. peel deliberately.

---

## write for how people actually learn

architecture decisions here are really *cognitive* decisions. keep these in mind:

- **manage cognitive load.** introduce one hard idea at a time. don't make a
  reader hold five new terms in their head to understand the sixth.
- **scaffold, then remove the scaffold.** lead with a familiar analogy, then
  graduate to the precise term once the idea is anchored. (analogies are
  training wheels, not the bicycle — retire them before they mislead.)
- **build schemas, not lists.** a fact connected to a mental model is retained;
  an isolated fact is crammed and lost. always answer *why does this exist* and
  *what does it connect to* before *what are its parameters*.
- **progressive disclosure.** a learner should be able to read the first third
  of any page and walk away with a correct coarse model. depth is opt-in.
- **concrete before abstract.** a worked example or a real scenario earns the
  right to state a general rule. lead with the case, then generalize.
- **respect the expertise-reversal effect.** what helps a novice (heavy
  scaffolding, analogy) slows an expert. use clear headings and summaries so
  returning readers can skip to the core without re-reading the skin.
- **spacing and connection.** link related concepts across pages so ideas are
  re-encountered in new contexts; that's what moves them into long-term memory.

if a section is *accurate* but a beginner finishes it with no mental model, it
has failed. accuracy is necessary, not sufficient.

---

## house style & conventions

match the existing notes — consistency is part of the learning experience.

- **markdown**, one topic area per file, living under `notes/<learning-plan>/`.
- link the shared stylesheet at the **top of every page**:
  `<link rel="stylesheet" href="./css/globals.css">`
- **`<em>` is a colored highlight, not italics** (see `globals.css`). use it to
  spotlight the key phrase in a definition, e.g. lambda runs functions in
  `<em>under 15 minutes</em>`.
- **lowercase, casual headers.** these are study notes, not a manual. `h1` is the
  page/major topic, `h2` sections, `h3` services/sub-topics, `h4` finer points.
- **bullets over prose.** definitions get a one-line plain-language summary, then
  bullets. include a **"when to use"** list wherever a service competes with
  alternatives — the choice is the lesson.
- **relate, don't just list.** prefer "X instead of Y because Z" to a bare
  enumeration. contrast is where understanding lives.
- keep each page anchored to the right→left, onion, learning-psychology
  principles above. when in doubt, re-read the destination-first rule.

## the site (github pages + docsify)

the notes are published as a website at **https://aahl-byte.github.io/aws-notes/**.
the markdown files are the source of truth; the site is rendered **client-side by
[docsify](https://docsify.js.org)** — a single `index.html` at the repo root, no
build step, no pipeline. this keeps the value in the notes, not the tooling.

how it fits together:

- **`index.html`** — the docsify shell. holds the central theme (the dark palette
  mirrors `globals.css`) so *every* page is styled from one place. you almost
  never need to touch this.
- **`_sidebar.md`** — the navigation, organized by onion tier. **when you add a
  new note, add it here** or it won't appear in the nav. use site-absolute paths
  (`/notes/...`).
- **`_coverpage.md` / `_navbar.md` / `home.md`** — the landing experience.
- **`.nojekyll`** — required. it stops github pages from running jekyll, which
  would otherwise hide the `_`-prefixed files docsify depends on. don't delete it.

authoring rules under docsify:

- **note-to-note links stay relative** (`./storage.md`) — docsify resolves them
  via `relativePath`. nav files (`_sidebar.md`, etc.) use absolute paths (`/...`).
- the central theme styles everything, so the per-page
  `<link rel="stylesheet" href="./css/globals.css">` is now **optional/legacy** —
  harmless if present, not required for the site to look right. keep new pages
  consistent with their neighbors.
- preview locally with any static server from the repo root (e.g.
  `python3 -m http.server`) and open `index.html`.
