# EZ Client Profile — Prototypes

Interactive, click-through prototypes for a redesigned Client Profile. Static, single-file
prototypes (React + MUI via CDN) with mock data only — no backend.

## Live site

- Landing page: `https://lmerriam.github.io/ez-profile-tabbed/`
- Long-term vision: `https://lmerriam.github.io/ez-profile-tabbed/long-term/`

Each variation has a **stable link that never changes** across iterations — publishing a new
version updates that same URL, so viewers always see the latest without tracking new links.

## Repo layout

```
index.html            ← landing page (links to each variation)
long-term/index.html  ← the "long-term vision" prototype
publish.sh            ← publishes the current state to the live site
```

Each variation is a top-level folder (`long-term/`, and future ones like `mvp/`). Local and
live paths are identical, e.g. `/long-term/`.

## How publishing works

You work **locally** on the `main` branch and commit as much as you like — **none of it goes
live**. GitHub Pages serves a separate `gh-pages` branch, and the only way to update it is to
run the publish script:

```bash
./publish.sh                     # publish current files (committed or not)
./publish.sh "MVP feedback pass" # publish with a custom deploy note
```

This snapshots your current working files onto `gh-pages` and pushes. Viewers only ever see
what you've published, so half-baked local work stays private until you're ready.

### Typical loop
1. Edit `<variation>/index.html` locally.
2. Preview locally (see below).
3. Commit your work on `main` (normal Git, keeps history — still not live).
4. When you hit a checkpoint worth sharing: `./publish.sh`.

## Previewing locally

Open the file directly, or (recommended, avoids any CDN/CORS quirks) serve it:

```bash
python3 -m http.server 8000
# then visit http://localhost:8000/  (landing) or /long-term/
```

## Adding a new variation

1. `mkdir <slug>` and add an `index.html` (copy an existing variation to start).
2. Add a card linking to `./<slug>/` in the landing `index.html`
   (between the `<!-- VARIATIONS:START -->` / `END` markers).
3. `./publish.sh`

New live link: `https://lmerriam.github.io/ez-profile-tabbed/<slug>/`
