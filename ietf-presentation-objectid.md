---
marp: true
theme: uncover
paginate: true
style: |
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap');

  :root {
    --color-bg: #0f1729;
    --color-bg-light: #1a2744;
    --color-accent: #60a5fa;
    --color-accent-dim: #3b82f6;
    --color-accent-glow: rgba(96, 165, 250, 0.15);
    --color-text: #e2e8f0;
    --color-text-muted: #94a3b8;
    --color-text-dim: #64748b;
    --color-surface: #1e293b;
    --color-border: #334155;
    --color-green: #4ade80;
    --color-orange: #fb923c;
    --color-pink: #f472b6;
  }

  section {
    background: var(--color-bg);
    color: var(--color-text);
    font-family: 'Inter', system-ui, -apple-system, sans-serif;
    font-size: 24px;
    line-height: 1.5;
    padding: 50px 70px;
  }

  h1 {
    color: #ffffff;
    font-weight: 800;
    font-size: 2.2em;
    line-height: 1.15;
    margin-bottom: 0.3em;
    letter-spacing: -0.02em;
  }

  h2 {
    color: var(--color-accent);
    font-weight: 700;
    font-size: 1.6em;
    margin-bottom: 0.4em;
    letter-spacing: -0.01em;
  }

  h3 {
    color: var(--color-text);
    font-weight: 600;
    font-size: 1.1em;
    margin-bottom: 0.2em;
  }

  code {
    font-family: 'JetBrains Mono', 'Consolas', monospace;
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: 5px;
    padding: 2px 7px;
    font-size: 0.82em;
    color: var(--color-accent);
  }

  pre {
    background: var(--color-surface) !important;
    border: 1px solid var(--color-border);
    border-radius: 10px;
    padding: 20px 24px !important;
    font-size: 0.68em;
    line-height: 1.55;
    box-shadow: 0 4px 24px rgba(0,0,0,0.3);
    overflow-x: auto;
  }

  pre code {
    background: none;
    border: none;
    padding: 0;
    color: var(--color-text);
    font-size: 1em;
  }

  strong {
    color: #ffffff;
    font-weight: 700;
  }

  em {
    color: var(--color-accent);
    font-style: normal;
    font-weight: 600;
  }

  a {
    color: var(--color-accent);
    text-decoration: none;
  }

  ul, ol {
    margin: 0.4em 0;
    padding-left: 1.3em;
  }

  li {
    margin-bottom: 0.35em;
    color: var(--color-text);
  }

  li::marker {
    color: var(--color-accent);
  }

  blockquote {
    border-left: 3px solid var(--color-accent);
    background: var(--color-accent-glow);
    padding: 12px 20px;
    margin: 0.8em 0;
    border-radius: 0 8px 8px 0;
    font-size: 0.92em;
  }

  blockquote p {
    margin: 0;
  }

  table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    margin: 0.6em 0;
    font-size: 0.88em;
    border-radius: 8px;
    overflow: hidden;
  }

  th {
    background: var(--color-accent-dim);
    color: #ffffff;
    font-weight: 600;
    padding: 10px 16px;
    text-align: left;
  }

  td {
    background: var(--color-surface);
    padding: 8px 16px;
    border-bottom: 1px solid var(--color-border);
  }

  tr:last-child td {
    border-bottom: none;
  }

  /* Footer / page number styling */
  section::after {
    color: var(--color-text-dim);
    font-size: 14px;
  }

  /* Title slide class */
  section.title {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    text-align: center;
    padding: 60px 80px;
  }

  section.title h1 {
    font-size: 2.6em;
    background: linear-gradient(135deg, #60a5fa, #a78bfa, #f472b6);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    margin-bottom: 0.2em;
  }

  section.title h2 {
    color: var(--color-text-muted);
    font-weight: 400;
    font-size: 1.1em;
    margin-bottom: 0;
  }

  /* Closing slide */
  section.closing {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    text-align: center;
  }

  section.closing h1 {
    font-size: 2.4em;
    background: linear-gradient(135deg, #60a5fa, #a78bfa, #f472b6);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  /* Label pills */
  .pill {
    display: inline-block;
    background: var(--color-accent-glow);
    border: 1px solid var(--color-accent-dim);
    color: var(--color-accent);
    padding: 2px 12px;
    border-radius: 20px;
    font-size: 0.75em;
    font-weight: 600;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    margin-bottom: 8px;
  }

  .pill-green {
    background: rgba(74, 222, 128, 0.12);
    border-color: var(--color-green);
    color: var(--color-green);
  }

  .pill-orange {
    background: rgba(251, 146, 60, 0.12);
    border-color: var(--color-orange);
    color: var(--color-orange);
  }

  .two-col {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 30px;
    margin-top: 0.5em;
  }

  .highlight-box {
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: 10px;
    padding: 18px 22px;
    margin: 0.5em 0;
  }

---

<!-- _class: title -->
<!-- _paginate: false -->

# IMAP OBJECTID+

## draft-ietf-mailmaint-imap-objectid-bis-02

<br>

**Bron Gondwana** · Fastmail
**Mauro De Gennaro** · Stalwart Labs

<br>

IETF 125 · mailmaint Working Group

---

## What's New in OBJECTID+

OBJECTID+ obsoletes RFC 8474 and introduces a **compound response format** that bundles identifiers into key-value pairs, replacing the individual response codes used in the original OBJECTID extension.

<div class="two-col">
<div>

### RFC 8474

Separate `MAILBOXID`, `EMAILID`, `THREADID` attributes returned individually in FETCH, STATUS, and response codes

</div>
<div>

### OBJECTID+

Single `OBJECTID (key val ...)` compound: all identifiers optional, unsupported ones simply omitted

</div>
</div>

**New additions**: `ACCOUNTID` for account-level context · `OBJECTID` response code on `RENAME` · ID-based mailbox selection on `SELECT`/`EXAMINE`

> Empty compound `OBJECTID ()` is valid: the server supports the extension but has no identifiers to return.

---

## Activation Model

OBJECTID+ uses **implicit activation**: no mandatory `ENABLE` required. The extension is activated the first time the client uses any OBJECTID+ feature:

| Trigger | Example |
|---------|---------|
| `ENABLE OBJECTID+` | `C: a1 ENABLE OBJECTID+` |
| OBJECTID param on SELECT/EXAMINE | `C: a2 SELECT "inbox" (OBJECTID)` |
| OBJECTID STATUS attribute | `C: a3 STATUS "inbox" (OBJECTID)` |
| OBJECTID FETCH data item | `C: a4 FETCH 1:* (OBJECTID)` |

When activated by any mechanism other than `ENABLE`, the server sends an untagged `ENABLED` response before any affected response:

```
S: * ENABLED OBJECTID+
```

Once activated, **activation persists** for the entire IMAP session and cannot be reversed.

---

## SELECT / EXAMINE with OBJECTID

The `OBJECTID` parameter on SELECT and EXAMINE has two forms.

**Activation only**: requests compound OBJECTID in place of MAILBOXID:

```
C: 27 SELECT "foo" (OBJECTID)
S: * ENABLED OBJECTID+
   ...
S: * OK [OBJECTID (MAILBOXID F2212ea87-6097-4256-9d51-71338625
        ACCOUNTID u1a48e8e3)] Ok
S: 27 OK [READ-WRITE] Completed
```

**ID-based selection**: locates the mailbox by identifiers, falls back to name:

```
C: 28 SELECT "foo" (OBJECTID (MAILBOXID F2212ea87-6097-4256-9d51-71338625
        ACCOUNTID u1a48e8e3))
S: * OK [OBJECTID (MAILBOXID F2212ea87-6097-4256-9d51-71338625
        ACCOUNTID u1a48e8e3)] Ok
S: 28 OK [READ-WRITE] Completed
```

---

## CREATE with OBJECTID

When OBJECTID+ has been activated, `CREATE` returns a compound `OBJECTID` response code instead of `MAILBOXID`:

```
C: 3 CREATE foo
S: 3 OK [OBJECTID (MAILBOXID F2212ea87-6097-4256-9d51-71338625
        ACCOUNTID u1a48e8e3)] Completed

C: 5 CREATE shared/team
S: 5 OK [OBJECTID (MAILBOXID F8839dca12-3ef8-4a72-b63d-54f9e8a1
        ACCOUNTID u2b59f9f4)] Completed
```

> The `ACCOUNTID` differs for shared mailboxes belonging to other accounts.

---

## RENAME with OBJECTID

OBJECTID+ adds a `RENAME` response code, returning the identifiers of the renamed mailbox.

**Same-account rename**: identifiers preserved:
```
C: 8 RENAME foo renamed
S: 8 OK [OBJECTID (MAILBOXID F2212ea87-6097-4256-9d51-71338625
        ACCOUNTID u1a48e8e3)] Completed
```

**Cross-account rename**: new identifiers may be issued:
```
C: 13 RENAME bar "Other Users.shared.bar"
S: 13 OK [OBJECTID (MAILBOXID Fa77c2e19-84d3-4b0f-9e12-67df5c8a
        ACCOUNTID u2b59f9f4)] Completed
```

---

## STATUS with OBJECTID

The `OBJECTID` STATUS attribute requests the compound OBJECTID for a mailbox.:

```
C: 6 STATUS foo (OBJECTID)
S: * ENABLED OBJECTID+
S: * STATUS foo (OBJECTID (MAILBOXID F2212ea87-6097-4256-9d51-71338625
        ACCOUNTID u1a48e8e3))
S: 6 OK Completed
```

Example with `LIST-STATUS`:

```
C: 11 LIST "" "*" RETURN (STATUS (OBJECTID))
S: * ENABLED OBJECTID+
S: * LIST (\HasNoChildren) "." INBOX
S: * STATUS INBOX (OBJECTID (MAILBOXID Ff8e3ead4-9389-4aff-adb1-d8d89efd8cbf
        ACCOUNTID u1a48e8e3))
S: * LIST (\HasNoChildren) "." "Other Users.other.sub.folder"
S: * STATUS "Other Users.other.sub.folder" (OBJECTID (
        MAILBOXID F8839dca12-3ef8-4a72-b63d-54f9e8a1
        ACCOUNTID u2b59f9f4))
S: 11 OK Completed
```

---

## FETCH with OBJECTID

The `OBJECTID` FETCH data item returns `EMAILID` and `THREADID` in compound form. Requesting it **activates** OBJECTID+. `ACCOUNTID` is omitted since the account context is established by SELECT/EXAMINE.

```
C: 30 FETCH 1:* (OBJECTID)
S: * ENABLED OBJECTID+
S: * 1 FETCH (OBJECTID (EMAILID M6d99ac3275bb4e THREADID T64b478a75b7ea9))
S: * 2 FETCH (OBJECTID (EMAILID M5fdc09b49ea703 THREADID T11863d02dd95b5))
S: 30 OK Completed
```

When the server does not support THREADID, it is simply omitted:
```
S: * 1 FETCH (OBJECTID (EMAILID M00000001))
```

When no message identifiers are supported:
```
S: * 1 FETCH (OBJECTID ())
```

---

## SEARCH by EMAILID / THREADID

OBJECTID+ defines `EMAILID` and `THREADID` filters for the SEARCH command:

```
C: 27 SEARCH EMAILID M6d99ac3275bb4e
S: * SEARCH 1
S: 27 OK Completed (1 msgs in 0.000 secs)

C: 28 SEARCH THREADID T64b478a75b7ea9
S: * SEARCH 1 2
S: 28 OK Completed (2 msgs in 0.000 secs)
```

> When using MULTISEARCH (RFC 7377), clients SHOULD only search across mailboxes that share the same `ACCOUNTID`: object identifiers are unique within the scope of a single account.

---

<!-- _class: closing -->
<!-- _paginate: false -->

# Questions?

## draft-ietf-mailmaint-imap-objectid-bis-02

<br>

Bron Gondwana · brong@fastmailteam.com
Mauro De Gennaro · mauro@stalw.art