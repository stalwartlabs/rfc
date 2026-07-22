---
marp: true
theme: default
paginate: true
style: |
  section {
    font-size: 26px;
    padding: 50px 60px;
  }
  section.lead {
    background: #1a2332;
    color: #f5f7fa;
  }
  section.lead h1 {
    color: #ffffff;
    border: none;
    font-size: 56px;
  }
  section.lead h2 {
    color: #8fb3d9;
    font-weight: 400;
  }
  section.title {
    background: #24405c;
    color: #f5f7fa;
  }
  section.title h1 {
    color: #ffffff;
    border: none;
    font-size: 48px;
    margin-bottom: 0;
  }
  section.title h2 {
    color: #9dc3e6;
    font-weight: 400;
    margin-top: 10px;
  }
  section.title code {
    background: rgba(255,255,255,0.12);
    color: #d6e6f5;
  }
  h1 {
    color: #1a2332;
    border-bottom: 3px solid #4a7ab5;
    padding-bottom: 8px;
  }
  h2 {
    color: #4a7ab5;
  }
  code {
    font-size: 0.85em;
  }
  pre {
    font-size: 0.72em;
    line-height: 1.35;
  }
  strong {
    color: #1a2332;
  }
  section.lead strong, section.title strong {
    color: #ffffff;
  }
  .status {
    background: #eef4fa;
    border-left: 5px solid #4a7ab5;
    padding: 14px 20px;
    margin-top: 10px;
  }
---

<!-- _class: lead -->

# JMAP Extensions

## Mail Sharing, Object Metadata, Enhanced Result References

**Mauro De Gennaro**
Stalwart Labs LLC

IETF 126

---

# Agenda

| Draft | Version | Ask |
|---|---|---|
| JMAP Mail Sharing | `draft-ietf-jmap-mail-sharing-01` | WGLC? |
| JMAP Object Metadata | `draft-ietf-jmap-metadata-02` | Review the redesign |
| JMAP Enhanced Result References | `draft-ietf-jmap-refplus-02` | Is there interest? |

---

<!-- _class: title -->

# JMAP Mail Sharing

## `draft-ietf-jmap-mail-sharing-01`

---

# JMAP Mail Sharing
## Overview

**Problem**: RFC 8621 (JMAP Mail) predates RFC 9670 (JMAP Sharing), so `Mailbox` never picked up the sharing framework.

**Solution**: a small, focused bridge.

- New capability: `urn:ietf:params:jmap:mail:share`
- `Mailbox.shareWith`: `Id[MailboxRights]|null`, a map of Principal id to rights
- `MailboxRights.mayShare`: `Boolean`, may modify `shareWith`
- `mayShare` maps to the IMAP ACL "a" right (RFC 4314)

`isSubscribed` and `myRights` already exist in RFC 8621, so nothing else is needed.

---

# JMAP Mail Sharing
## Status

<div class="status">

**The document is essentially done.**

</div>

- Two new properties plus one capability registration; no new data types, no new methods.
- Security considerations cover ACL enforcement, IMAP ACL consistency, unauthorized sharing, information disclosure, resource exhaustion and privilege escalation.
- No open technical issues known to the author.

**Ask to the WG: I believe this draft is ready for WGLC.**

---

<!-- _class: title -->

# JMAP Object Metadata

## `draft-ietf-jmap-metadata-02`

---

# JMAP Object Metadata
## Overview

**Problem**: JMAP has no standard way to attach auxiliary data to objects.

- IMAP has METADATA (RFC 5464); WebDAV has dead properties (RFC 4918).
- Without it, vendors ship incompatible custom extensions.

**Solution**: two properties on each opted-in data type.

- `metadata`: shared, visible to everyone who can read the object
- `privateMetadata`: per-user, visible only to the user who wrote it

Both are keyed by *namespace identifier*: an IANA-registered name (no dot), or a vendor-controlled domain name (`acme.example.com`).

---

# JMAP Object Metadata
## The -02 design in one slide

```json
{
  "id": "MB1",
  "name": "Team Inbox",
  "metadata": {
    "acme.example.com": { "color": "blue", "owner": "team-alpha" }
  },
  "privateMetadata": {
    "acme.example.com": { "workflowState": "pending-review" }
  }
}
```

Metadata is **just a property of the object**, so `/get`, `/set`, `/changes`, `/queryChanges` and `/query` apply unchanged.

---

# JMAP Object Metadata
## What changed from -01 to -02

**-01 was a separate data type.** A `Metadata` object with `Metadata/get`, `/set`, `/query`, `/changes`, `relatedId`/`relatedType` pointers back to the annotated object, a uniqueness constraint, cascading deletion, extra `/get` and `/set` arguments (`fetchMetadata`, `onSuccessCreateMetadata`, `onSuccessUpdateMetadata`), and two IANA registries.

**-02 deletes all of that.** Metadata became two ordinary properties.

Gone: the `Metadata` type, all `Metadata/*` methods, the related-object plumbing, the uniqueness rule, cascading deletes, and the transactional `onSuccess*` arguments.

---

# JMAP Object Metadata
## Why the redesign

- **No lifecycle problem.** Metadata lives and dies with its object; no dangling references, no cascading deletion, no uniqueness constraint to enforce.
- **No second round trip.** Create an object and its metadata in one `/set` create, atomically, with no `onSuccess*` machinery.
- **No parallel sync channel.** One state string, one `/changes` feed per type.
- **Combined queries for free.** Metadata conditions AND primary conditions in a single `Foo/query`.
- **Less to implement.** Ordinary PatchObject semantics, ordinary property fetching.

---

# JMAP Object Metadata
## What -02 adds

**Per-data-type capability.** `dataTypes` maps type name to what it supports:
`namespaces` (registered), `supportsVendorNamespaces`, `supportsPrivate`, `maxDepth`.

**Query filters.** `metadataExists`, `metadataTextContains`, `metadataTextEquals` plus the `privateMetadata*` variants. Existence checks MUST be supported; text matches MAY be rejected with `unsupportedFilter`.

**Changes.** `updatedProperties` in `Foo/changes` (modelled on `Mailbox/changes`), and `ignoreMetadataOnlyChanges` so clients that do not care about metadata avoid needless wakeups.

**Per-viewer state.** A private write by user A MUST NOT advance state for user B.

---

# JMAP Object Metadata
## Fetch and patch

Subselectors keep responses small:

```json
["Mailbox/get", {
  "accountId": "A1", "ids": ["MB1"],
  "properties": ["id", "name",
                 "metadata/acme.example.com",
                 "privateMetadata/acme.example.com"]
}, "c1"]
```

Ordinary PatchObject for a single key:

```json
["Mailbox/set", {
  "accountId": "A1",
  "update": { "MB1": { "metadata/acme.example.com/color": "green" } }
}, "c1"]
```

---

# JMAP Object Metadata
## Namespaces registry

One registry replaces the two in -01: **JMAP Metadata Namespaces**, Expert Review.

- Registered names contain **no dot**; vendor namespaces are domain names, so collision is impossible by construction and vendors need no registration.
- **-02 defines no initial entries.**
- Bindings to other protocols (IMAP METADATA, WebDAV dead properties) are now expected to be separate specifications rather than baked into this document.

**Ask to the WG: does the property-based model look right? Feedback welcome.**

---

<!-- _class: title -->

# JMAP Enhanced Result References

## `draft-ietf-jmap-refplus-02`

---

# JMAP Enhanced Result References
## Overview

RFC 8620 result references work only in **method arguments** and only with **JSON Pointer**.

This extension (`urn:ietf:params:jmap:refplus`) adds:

- Result references **inside `/set` create and update objects**
- Result references **inside `FilterCondition` objects** in `/query`
- **JSON Path** (RFC 9535) as an optional alternative to JSON Pointer, signalled by a `jsonPath` capability flag; paths starting with `$` are JSON Path

**Goal**: build an object from a previous result without an extra round trip.

---

# JMAP Enhanced Result References
## Example

```json
["Email/set", {
  "accountId": "a1",
  "create": {
    "new-email": {
      "mailboxIds": { "inbox-id": true },
      "subject": "Quarterly Reports",
      "#attachments": {
        "resultOf": "c0",
        "name": "Email/get",
        "path": "$.list[0].attachments[?@.name && ...endsWith('.pdf')]"
      }
    }
  }
}, "c1"]
```

Copy participants from a template event, reuse attachments, filter a query by an id from a previous query.

---

# Enhanced Result References
## Review comments

**Overall**: the added complexity and execution cost may outweigh saving a few round trips. Not objecting to the document moving forward, but **would like evidence of a real use case**.

**Capability placement**: `refplus` belongs in the top-level `capabilities` only, not in `accountCapabilities`. These are protocol-level behaviours, like JMAP Core, not per-account features.

---

# Enhanced Result References
## Review comments (continued)

**Type-directed resolution is a layering violation.** Requiring the dispatcher to know the expected type of the target property means a generic JMAP proxy cannot resolve references without understanding the methods it forwards. Splitting the work across a reference-resolution layer and a method-implementation layer does not fix it: it now needs support in two layers.

*Suggestion*: add a `type` property to the `ResultReference` object. The caller knows what it expects; the resolver then needs no schema knowledge and everything happens in the syntactic resolution phase.

---

# Enhanced Result References
## Review comments (continued)

**Literal `#` in property names.** The draft should state explicitly that opting in to `refplus` means you cannot set a property whose name begins with a literal `#`. Not a problem for any current JMAP type, but worth recording. A client that needs this must simply not include `refplus` in `using`.

**`/set` failure handling.** Rejecting an individual create/update with an `invalidResultReference` `SetError` forces resolution at *method execution* time rather than *dispatch* time.

*Suggestion*: resolve before dispatch and fail the whole method with `invalidResultReference`, consistent with all other result references. Otherwise `refplus` would have to appear in `accountCapabilities` after all, since in the proxy case not all accounts may support it.

---

# Enhanced Result References
## My position

- The specific comments are all **reasonable and actionable**, and I am happy to incorporate them:
  - move the capability to the top level only,
  - add an explicit `type` to `ResultReference` and resolve purely syntactically at dispatch time,
  - fail the whole method rather than the individual `/set` entry,
  - document the literal `#` restriction.
- I do find the extension genuinely useful: it removes round trips for object-from-object creation patterns that keep recurring in Calendars, Contacts and Mail.

---

# Enhanced Result References
## Question to the WG

<div class="status">

**Does anyone else want this?**

</div>

- I am willing to do the work and address every point raised.
- But the value here is interoperability, and that only matters if others implement it.
- **If the WG does not see a real use case, I am fine dropping the draft.** There is no point standardising an extension that only one implementation will ship.

Please speak up either way, on the list or at the mic.

---

# Summary

| Draft | Version | Status |
|---|---|---|
| **Mail Sharing** | `-01` | Stable and simple; **requesting WGLC** |
| **Object Metadata** | `-02` | Substantially redesigned and simplified; wants review |
| **Enhanced References** | `-02` | Review comments actionable; **needs a show of interest** |

---

<!-- _class: lead -->

# Questions?

**mauro@stalw.art**
