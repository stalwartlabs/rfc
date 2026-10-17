# Repository layout

This repository contains multiple IETF Internet-Draft sources. Each
draft lives in its own subdirectory. Currently:

- `imap-objectid/`
- `imap-objectid-accountid/`
- `jmap-calendar-scheduling/` (source only, no Makefile yet)
- `jmap-enhanced-references/`
- `jmap-filenode/` (separate git clone, see below)
- `jmap-mail-sharing/`
- `jmap-object-metadata/`
- `mta-hooks/`

Drafts that are set up for building follow the same convention:

- `index.mkd` is the kramdown-rfc source.
- `Makefile` builds `index.xml`, `index.html`, and `index.txt` from
  `index.mkd` via `kramdown-rfc2629` and `xml2rfc`.
- `.refcache/` (created on first build) caches bibxml references.

# External drafts

`jmap-filenode/` is a clone of the co-authored draft at
`brong/draft-gondwana-jmap-filenode`, not part of this repository (it
is listed in `.gitignore`). Inside it, `origin` is the fork
`mdecimus/draft-gondwana-jmap-filenode` and `upstream` is
`brong/draft-gondwana-jmap-filenode`. Work on a branch, push to
`origin`, and open PRs against `upstream`. Sync with
`git fetch upstream && git merge upstream/master`.

Its source is `draft-ietf-jmap-filenode.mkd` rather than `index.mkd`,
so builds produce `draft-ietf-jmap-filenode.{xml,html,txt}`. The
version check below applies to that file instead.

# Building a draft

The build toolchain (`kramdown-rfc2629` Ruby gem and `xml2rfc`
Python tool) is not installed on the host; it lives on the orb VM
`dev-box`. Run `make` over there against the working tree, which is
shared between host and VM at the same absolute path.

Build a single draft:

    orb -m dev-box bash -c 'cd /Users/me/code/rfc/<subdir> && make all'

Force a full rebuild:

    orb -m dev-box bash -c 'cd /Users/me/code/rfc/<subdir> && make clean && make all'

Targets:

- `make all` (default): generate `index.xml`, `index.html`, `index.txt`.
- `make clean`: remove generated files.

The `xml2rfc --text` step occasionally prints "too wide" warnings
about source artwork; those are advisory and do not fail the build.

# Watching for changes

`watch.sh` at the repo root runs `make` automatically when any
`.mkd` file changes. Pass the draft subdirectory as an argument:

    ./watch.sh imap-objectid

It uses `fswatch` on macOS and `inotifywait` on Linux. To get the
build to actually run when watching from the host, point the script
at a path inside dev-box, or run it from inside the VM.

# Verifying a build

After building, the version stamp in `index.txt` should match the
`docname:` field in `index.mkd`'s frontmatter. A quick check:

    grep '^docname:' <subdir>/index.mkd
    grep -o 'draft-[a-z0-9-]*' <subdir>/index.txt | sort -u | tail -1
