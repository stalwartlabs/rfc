---
theme: default
title: "MTA Hooks"
titleTemplate: "%s"
info: |
  MTA Hooks: an HTTP-based mail processing protocol.
  draft-degennaro-mta-hooks-02. IETF 127 BoF.
author: "Mauro De Gennaro"
keywords: mta hooks, milter, smtp, email filtering, json patch, dkim2
colorSchema: light
highlighter: shiki
lineNumbers: false
drawings:
  persist: false
transition: none
routerMode: hash
mdc: true
fonts:
  sans: "Inter Variable"
  serif: "Plus Jakarta Sans Variable"
  mono: "JetBrains Mono Variable"
  italic: false
  provider: "none"
layout: default
class: full
---

<div class="bento hero">
  <div class="tile c-7 hero-copy">
    <span class="pill">IETF 127 BoF &middot; ART Area</span>
    <div class="display">MTA <span class="hl">Hooks</span></div>
    <p class="lead">An HTTP protocol that lets an MTA delegate processing decisions to external services, across the whole life of a message.</p>
    <div class="hero-meta">
      draft-degennaro-mta-hooks-02<br/>
      Mauro De Gennaro, Stalwart Labs
    </div>
  </div>
  <div class="tile tile--rose c-5 center">
    <div class="aside-grid">
      <div>One state object<span>Session, envelope, message and delivery, described once.</span></div>
      <div>One JSON Patch<span>Every decision is a change to that state.</span></div>
      <div>Grants<span>The MTA decides what may change.</span></div>
      <div>Nine stages<span>From connect to the DSN.</span></div>
      <div>Plain HTTP<span>JSON or CBOR.</span></div>
    </div>
  </div>
</div>

---

<span class="pill">Today</span>

# MTAs delegate through three kinds of interface

<div class="rail">
  <div class="st">connect</div>
  <div class="st">helo</div>
  <div class="st">mail</div>
  <div class="st">rcpt</div>
  <div class="st">data</div>
  <div class="st">route</div>
  <div class="st">send</div>
  <div class="st">outcome</div>
  <div class="st">bounce</div>
</div>
<div class="band" style="grid-template-columns: 5fr 2fr 2fr;">
  <span class="yes">Milter</span>
  <span class="no">Lookup tables</span>
  <span class="no">Logs</span>
</div>

<div class="bento mt">
  <div class="tile c-4">
    <div class="cap">Reception</div>
    <h3>Milter</h3>
    <p>Filters the SMTP conversation, from connect to the end of DATA, while the client waits.</p>
  </div>
  <div class="tile tile--sand c-4">
    <div class="cap">Routing</div>
    <h3>Lookup tables</h3>
    <p>Transport, next hop and address maps: a key in, a value out.</p>
  </div>
  <div class="tile tile--sand c-4">
    <div class="cap">Outcomes</div>
    <h3>Logs</h3>
    <p>Deliveries, deferrals and bounces, read from logs and bounce mailboxes.</p>
  </div>
</div>

<div class="note">Each was designed for its own job, and does it well.</div>

---

<span class="pill">Today</span>

# Milter is the established reception-time filter

<div class="rail">
  <div class="st on">connect</div>
  <div class="st on">helo</div>
  <div class="st on">envfrom</div>
  <div class="st on">envrcpt</div>
  <div class="st on">header</div>
  <div class="st on">body</div>
  <div class="st on">eom</div>
</div>

<div class="bento mt">
  <div class="tile c-4">
    <h3>Built for reception</h3>
    <p>Callbacks along the SMTP conversation. The filter can reject, defer, discard or modify while the client waits for the reply.</p>
  </div>
  <div class="tile tile--sand c-4">
    <h3>Widely deployed</h3>
    <p>Sendmail around 2000, through <code>libmilter</code>, and Postfix since. Rspamd, ClamAV, SpamAssassin, OpenDKIM and OpenDMARC all speak it.</p>
  </div>
  <div class="tile tile--rose c-4">
    <h3>Unchanged by this work</h3>
    <p>Specifying Milter is out of scope. Gateways in either direction are expected to exist.</p>
  </div>
</div>

---

<span class="pill">Beyond reception</span>

# The charter adds routing, delivery, deferral and DSNs

<div class="bento">
  <div class="tile tile--ink c-12">
    <div class="cap">Draft charter</div>
    <p class="statement" style="font-size: 20px;">&ldquo;...across the whole lifetime of a message: from the SMTP conversation that receives it, through routing and delivery, to the generation of delivery status notifications.&rdquo;</p>
  </div>
  <div class="tile c-3">
    <div class="cap">Routing</div>
    <p>Before delivery, per recipient, including the TLS policy for each destination.</p>
  </div>
  <div class="tile c-3">
    <div class="cap">Delivery</div>
    <p>The outcome of each attempt, recipient by recipient.</p>
  </div>
  <div class="tile c-3">
    <div class="cap">Deferral</div>
    <p>Retries, their timing, and when the next notice is due.</p>
  </div>
  <div class="tile tile--rose c-3">
    <div class="cap">DSN</div>
    <p>Before the MTA sends a notification it generated.</p>
  </div>
</div>

<div class="note">New capabilities for a broader protocol. Archiving and TLS reporting are examples built on them.</div>

---

<span class="pill">Routing</span>

# Routing decisions need the message's full context

<div class="bento">
  <div class="tile tile--sand c-5">
    <div class="cap">An external routing lookup receives</div>
    <div class="big">one key</div>
    <p>The recipient domain or address. A transport and next hop come back.</p>
  </div>
  <div class="tile tile--rose c-7">
    <div class="cap">The decision can use the whole message state</div>
    <div class="chips">
      <span class="chip">attempts so far</span>
      <span class="chip">last reply</span>
      <span class="chip">TLS outcome</span>
      <span class="chip">sender</span>
      <span class="chip">verdict at reception</span>
      <span class="chip">queue lifetime</span>
    </div>
  </div>
  <div class="tile c-4">
    <div class="step-head"><div class="dot"></div><div class="cap">Attempt 1</div></div>
    <p>STARTTLS fails at <code>mx.partner.example</code>.</p>
  </div>
  <div class="tile c-4">
    <div class="step-head"><div class="dot"></div><div class="cap">Before attempt 2</div></div>
    <p>The routing service sees the TLS failure of the last attempt.</p>
  </div>
  <div class="tile tile--ink c-4">
    <div class="step-head"><div class="dot"></div><div class="cap">Attempt 2</div></div>
    <p>The message goes through the VPN relay instead.</p>
  </div>
</div>

---

<span class="pill">Example consumer</span>

# DKIM2 needs a hook for each copy and each DSN

<div class="bento">
  <div class="tile c-6">
    <div class="big hl">1</div>
    <h3>Each copy transmitted</h3>
    <p>Signed with the exact envelope of the SMTP transaction that carries it, so blind copies stay out of other copies' signatures.</p>
    <div class="chips"><span class="chip chip--brand">transmit stage</span></div>
  </div>
  <div class="tile c-6">
    <div class="big hl">2</div>
    <h3>Each DSN the MTA generates</h3>
    <p>Carries its own DKIM2 signature, so it is processed before it is sent.</p>
    <div class="chips"><span class="chip chip--brand">dsn stage</span></div>
  </div>
</div>

<div class="note">DKIM2 is an example consumer, not a dependency: nothing in the deliverables requires it.</div>

<p class="cap" style="margin-top: 12px;">draft-ietf-dkim-dkim2-spec</p>

---

<span class="pill">Demand</span>

# Operators and scanner authors are asking for this

<div class="bento">
  <div class="tile c-5">
    <h3>Operators</h3>
    <p>Site-specific rules: check the recipient against the directory, add the footer legal asked for, send an event to the SIEM.</p>
    <p>Stalwart ships Milter support; its users asked for an HTTP interface as well.</p>
  </div>
  <div class="tile tile--ink c-7 center">
    <div class="cap">dkim2d, an independent DKIM2 implementation</div>
    <div class="rail" style="margin-top: 8px;">
      <div class="st ink">Postfix<small>dkim2-milter</small></div>
      <div class="st ink">Exim<small>local_scan + filter</small></div>
      <div class="st ink" style="flex: 0.4;">&rarr;</div>
      <div class="st on">dkim2d<small>HTTP / JSON</small></div>
    </div>
    <p>The logic is one HTTP service; each MTA has its own adapter.</p>
  </div>
</div>

<div class="note">The operators of mailbox.org (Heinlein Group) sent detailed proposals that shaped -02.</div>

---

<span class="pill">Design goals</span>

# Five goals shape the design

<div class="bento">
  <div class="tile c-4">
    <div class="cap">Goal 1</div>
    <h3>Adopted formats</h3>
    <p>HTTP, JSON or CBOR, JSON Patch and the JMAP Email model, so existing libraries do most of the work of a targeted filter service.</p>
  </div>
  <div class="tile c-4">
    <div class="cap">Goal 2</div>
    <h3>Negotiated capabilities</h3>
    <p>A scanner learns at registration what it will receive and may change, and gets explicit errors, never silent absence. Extensions use negotiated namespaces.</p>
  </div>
  <div class="tile c-4">
    <div class="cap">Goal 3</div>
    <h3>Operator-bounded authority</h3>
    <p>The operator grants each scanner what it may change; by default, only toward stricter processing.</p>
  </div>
  <div class="tile tile--sand c-6">
    <div class="cap">Goal 4</div>
    <h3>Explicit failure semantics</h3>
    <p>A time budget on every request, and a chosen behavior when a scanner fails.</p>
  </div>
  <div class="tile tile--sand c-6">
    <div class="cap">Goal 5</div>
    <h3>Stable identifiers</h3>
    <p>One queue identifier correlates a message across every stage; a request id stays the same on every retry.</p>
  </div>
</div>

---

<span class="pill">Core idea</span>

# One state object, one JSON Patch, and the MTA controls change

<div class="bento">
  <div class="tile c-4">
    <div class="big hl">1</div>
    <h3>One state object</h3>
    <p>At each stage: the session, the envelope with each recipient's status, the message and the delivery attempts.</p>
  </div>
  <div class="tile tile--sand c-4">
    <div class="big hl">2</div>
    <h3>One JSON Patch</h3>
    <p>The scanner answers with an RFC 6902 patch against that object. The MTA acts on the resulting state.</p>
  </div>
  <div class="tile tile--rose c-4">
    <div class="big">3</div>
    <h3>The MTA controls change</h3>
    <p>Each scanner may change only the paths it was granted.</p>
  </div>
  <div class="tile tile--ink c-12">
    <p>Accepting, rejecting, adding a header, discarding a recipient, choosing a route and suppressing a DSN are all changes to the state. <strong>Every effect is a path, and every permission is a grant on a path.</strong></p>
  </div>
</div>

---

<span class="pill">Discovery and registration</span>

# The MTA is always the client

<div class="bento">
  <div class="tile c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Optional</div></div>
    <h3>Discover</h3>
    <p>GET <code>/.well-known/mta-hooks</code></p>
    <p>The stages, properties and grants the scanner wants.</p>
  </div>
  <div class="tile c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Once</div></div>
    <h3>Register</h3>
    <p>POST label and subscriptions. The scanner may narrow them, never widen.</p>
  </div>
  <div class="tile c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Per stage</div></div>
    <h3>Hook request</h3>
    <p>POST the current state to the <code>hookEndpoint</code>.</p>
  </div>
  <div class="tile tile--rose c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Per stage</div></div>
    <h3>JSON Patch</h3>
    <p>Validated against the grants, then applied.</p>
  </div>
  <div class="tile c-6">
    <h3>No endpoint on the MTA</h3>
    <ul>
      <li>No callbacks, no redirects followed</li>
      <li>HTTP/1.1 required, HTTP/2 recommended</li>
      <li>Errors are RFC 9457 Problem Details</li>
    </ul>
  </div>
  <div class="tile tile--sand c-6">
    <h3>Authenticated, over TLS</h3>
    <ul>
      <li>Bearer tokens mandatory to implement</li>
      <li>TLS client certificates optional</li>
      <li>TLS 1.2 or later, scanner certificate validated</li>
    </ul>
  </div>
</div>

---

<span class="pill">Subscriptions</span>

# The first matching subscription applies

<div class="bento">
  <div class="tile tile--code dense c-7 r-2">
    <div class="cap">POST /v1/registrations</div>

```json
{"name": "mx1.example.com", "label": "spam",
 "softwareVersion": "2.1.0", "timeoutMs": 5000,
 "serialization": "application/json",
 "subscriptions": [
  {"stages": ["data"],
   "filter": {"authenticated": false},
   "properties": ["/session", "/envelope", "/message"],
   "grants": [{"path": "/action"}, {"path": "/response"}],
   "onFailure": "continue"},
  {"stages": ["route"],
   "filter": {"envelopeTo": "*@partner.example"},
   "properties": ["/envelope", "/queue"],
   "grants": [{"path": "/envelope/to/*/route/name",
               "values": ["vpn-partner"]}],
   "onFailure": "tempfail"}]}
```

  </div>
  <div class="tile c-5">
    <h3>First match wins</h3>
    <p>Per stage, the first subscription that lists it and whose filter matches. Each has its own properties, grants and <code>onFailure</code>.</p>
    <div class="chips">
      <span class="chip chip--brand">envelopeTo</span>
      <span class="chip chip--brand">clientIp</span>
      <span class="chip chip--brand">authenticated</span>
      <span class="chip">+ JMAP Email filters</span>
    </div>
  </div>
  <div class="tile tile--rose c-5">
    <h3>Per recipient, outbound</h3>
    <p>At <code>route</code> and <code>delivery</code>, each subscription gets only the recipients it matches. <code>transmit</code> and <code>dsn</code> match as a whole.</p>
  </div>
</div>

---

<span class="pill">Stages</span>

# Nine stages follow a message from connect to DSN

<div class="rail">
  <div class="st">connect<small>before greeting</small></div>
  <div class="st">ehlo<small>each EHLO</small></div>
  <div class="st">mail<small>each MAIL</small></div>
  <div class="st">rcpt<small>each RCPT</small></div>
  <div class="st">data<small>end of DATA</small></div>
  <div class="st on">route<small>each attempt</small></div>
  <div class="st on">transmit<small>before sending</small></div>
  <div class="st on">delivery<small>after the job</small></div>
  <div class="st on">dsn<small>before a DSN</small></div>
</div>
<div class="band" style="grid-template-columns: 5fr 4fr;">
  <span class="no">Inbound: an action and an SMTP reply</span>
  <span class="yes">Outbound: the status of each recipient</span>
</div>

<div class="bento mt">
  <div class="tile c-6">
    <h3>State accumulates</h3>
    <p>A scanner subscribed only to <code>data</code> gets connection, TLS, authentication, envelope and message in one request, and can still reject at SMTP time.</p>
  </div>
  <div class="tile tile--sand c-6">
    <h3>One queue identifier</h3>
    <p>The same from <code>data</code> to the last <code>delivery</code> or <code>dsn</code>, so a scanner can keep what it learned at reception.</p>
  </div>
</div>

---

<span class="pill">Hook request</span>

# The hook request carries the state the MTA holds

<div class="bento">
  <div class="tile tile--code dense c-8 r-2">
    <div class="cap">At data, message omitted</div>

```json
{
  "stage": "data", "action": "accept", "decidedBy": "mta",
  "response": {"code": 250, "message": "Queued as 4F2A31B0C9"},
  "timestamp": "2026-10-28T16:30:00Z", "timeoutMs": 4200,
  "session": {"id": "01JBDX3TQ8V0D6H1E2F3G4H5J6",
              "startedAt": "2026-10-28T16:29:58Z",
              "client": {"ip": "192.0.2.100", "port": 54321},
              "counters": {"commands": 5, "pregreetBytes": 0}},
  "envelope": {
    "from": {"address": "sender@example.org", "parameters": {}},
    "to": [{"address": "bob@example.com", "parameters": {},
            "status": "accepted", "decidedBy": "mta"}]},
  "senderAuth": {"spfMailFrom": "pass", "dmarc": "pass"},
  "queue": {"id": "4F2A31B0C9"}
}
```

  </div>
  <div class="tile c-4">
    <h3>Only what is subscribed</h3>
    <p>Always the stage, timestamp and time budget; inbound, the action and reply.</p>
    <p>The message as a JMAP Email object, as raw bytes, or both. Outbound adds attempts and routes.</p>
  </div>
  <div class="tile tile--sand c-4">
    <div class="cap">HTTP header fields</div>
    <div class="chips">
      <span class="chip">MTA-Hooks-Registration</span>
      <span class="chip">MTA-Hooks-Request-Id</span>
      <span class="chip">MTA-Hooks-Context</span>
    </div>
  </div>
</div>

---

<span class="pill">Hook response</span>

# The answer is a JSON Patch, validated as a whole

<div class="bento">
  <div class="tile tile--code dense c-7">
    <div class="cap">Reject a message</div>

```json
[
  {"op": "replace", "path": "/action", "value": "reject"},
  {"op": "replace", "path": "/response",
   "value": {"code": 550, "enhancedCode": "5.7.1",
             "message": "Virus detected"}}
]
```

  </div>
  <div class="tile c-5">
    <h3>Or nothing</h3>
    <p><code>204</code>, or an empty patch, means no changes.</p>
    <p>The patch applies to the state the MTA holds, so a header can be added without receiving the message.</p>
  </div>
  <div class="tile c-3">
    <div class="big hl">1</div>
    <p>It applies per RFC 6902, including every <code>test</code>.</p>
  </div>
  <div class="tile c-3">
    <div class="big hl">2</div>
    <p>Every location that differs is covered by a grant.</p>
  </div>
  <div class="tile c-3">
    <div class="big hl">3</div>
    <p>Ordered properties only move toward strict.</p>
  </div>
  <div class="tile c-3">
    <div class="big hl">4</div>
    <p>Types, stage rules, headers and MIME are valid.</p>
  </div>
</div>

<div class="note">The MTA compares the original and resulting states. All or nothing: an invalid patch is discarded whole.</div>

---

<span class="pill">Grants</span>

# Grants bound every change, and restrict by default

<div class="bento">
  <div class="tile tile--code c-7">

```json
[
  {"path": "/message/headers"},
  {"path": "/action", "relax": true},
  {"path": "/envelope/to/*/route/name",
   "values": ["default", "vpn-*"]},
  {"path": "/response/delayMs", "max": 30000},
  {"path": "/ext/org.example.spam", "max": 4096}
]
```

  </div>
  <div class="tile c-5">
    <ul>
      <li><strong>path</strong>: with <code>*</code> for any index</li>
      <li><strong>values</strong>: allowed strings, with wildcards</li>
      <li><strong>max</strong>: a number ceiling, or a size in octets</li>
      <li><strong>relax</strong>: may loosen ordered properties</li>
    </ul>
    <p>No grant, no change. The most specific path applies.</p>
  </div>
  <div class="tile c-7">

| Ordered property | Permissive to strict |
|---|---|
| `/action` | accept, quarantine, then reject, discard, disconnect |
| `/envelope/to/*/route/tls` | none, opportunistic, required, verified |

  </div>
  <div class="tile tile--ink c-5">
    <p><strong>With relax</strong>, the scanner is the final authority for that property: it can override a rejection or lower TLS. Granted explicitly; REQUIRETLS still wins.</p>
    <p>If several scanners relax the same property, the last in the chain prevails.</p>
  </div>
</div>

---

<span class="pill">Outcomes</span>

# Inbound stages set an action, outbound stages set recipient status

<div class="bento">
  <div class="tile c-6">
    <div class="cap">Inbound: /action and /response</div>

| Action | Effect |
|---|---|
| accept, quarantine | Continue, or accept and hold |
| reject | Send a 4xx or 5xx reply |
| discard | Accept and drop |
| disconnect | Send a 421 reply and close |

  </div>
  <div class="tile c-6">
    <div class="cap">Outbound: /envelope/to/*/status</div>

| Stage | From | To |
|---|---|---|
| route, transmit, delivery | accepted, deferred | deferred, failed, discarded |
| delivery | failed | discarded |
| dsn | accepted | discarded |

  </div>
  <div class="tile tile--sand c-6">
    <div class="cap">route</div>
    <p>A route per recipient: a configured name, or next hop, port, source IP and TLS. Different routes never share a transaction.</p>
  </div>
  <div class="tile tile--rose c-6">
    <div class="cap">transmit</div>
    <p>Per SMTP transaction, with its final envelope. Message changes apply to this copy only; <code>dsn</code> works the same way.</p>
  </div>
</div>

---

<span class="pill">Failure and chains</span>

# Failures, time budgets and chains are explicit

<div class="bento">
  <div class="tile c-4">
    <div class="cap">onFailure: continue</div>
    <p>The default. Proceed as if the scanner made no changes.</p>
  </div>
  <div class="tile tile--rose c-4">
    <div class="cap">onFailure: tempfail</div>
    <p>Inbound, a 451 or 421 reply. At route and transmit, recipients stay deferred; at dsn, the DSN waits.</p>
  </div>
  <div class="tile tile--sand c-4">
    <div class="cap">Time budget</div>
    <p>Each request carries its <code>timeoutMs</code>. Retries reuse the same request id.</p>
  </div>
  <div class="tile c-6">
    <h3>Chains</h3>
    <p>Scanners run in configured order, each seeing the state the previous ones left and <code>decidedBy</code>. Reject, discard and disconnect end the chain.</p>
  </div>
  <div class="tile tile--code c-6">
    <div class="cap">Results passed along the chain</div>

```json
"ext": {"org.example.spam": {"score": 0.4}}
```

  <p class="muted" style="color: var(--on-ink-muted); padding: 8px 10px 4px;">Kept with the message, read again at route, delivery and dsn.</p>
  </div>
</div>

<div class="note">A timeout, an error status or an invalid patch is a failure; the state is left unchanged.</div>

---

<span class="pill">Next: Carsten and Manu</span>

# Implementer proposals shaped -02

<div class="bento">
  <div class="tile c-4">
    <h3>Routing</h3>
    <p>The <code>route</code> stage, per-recipient routes and TLS policy.</p>
  </div>
  <div class="tile c-4">
    <h3>Bounded authority</h3>
    <p>The operator defines the space; the scanner decides within it.</p>
  </div>
  <div class="tile c-4">
    <h3>Observability</h3>
    <p>Stable queue ids, per-attempt results, time budgets, trace ids.</p>
  </div>
  <div class="tile tile--sand c-4">
    <h3>Inbound signals</h3>
    <p>Session counters, proxy data, certificates, delayed replies.</p>
  </div>
  <div class="tile tile--sand c-4">
    <h3>Extension data</h3>
    <p>Namespaced results shared between scanners.</p>
  </div>
  <div class="tile tile--sand c-4">
    <h3>Per-copy changes</h3>
    <p>Changes to each transmitted copy, at the <code>transmit</code> stage.</p>
  </div>
  <div class="tile tile--brand c-12">
    <h3>Carsten Rosenberg and Manu Zurmühl, Heinlein Group (mailbox.org)</h3>
    <p>The details of their proposals, from operating mail at scale.</p>
  </div>
</div>
