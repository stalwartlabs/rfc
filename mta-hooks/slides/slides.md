---
theme: default
title: "MTA Hooks"
titleTemplate: "%s"
info: |
  MTA Hooks: an HTTP-based mail processing protocol.
  draft-degennaro-mta-hooks-02. BoF proposal, IETF 127.
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
hideInToc: true
---

<div class="bento hero">
  <div class="tile c-7 hero-copy">
    <span class="pill">IETF 127 BoF proposal &middot; ART Area</span>
    <div class="display">MTA <span class="hl">Hooks</span></div>
    <p class="lead">An HTTP protocol that lets an MTA delegate processing decisions to external services, across the whole life of a message.</p>
    <div class="hero-meta">
      draft-degennaro-mta-hooks-02<br/>
      Mauro De Gennaro &middot; Stalwart Labs
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

<span class="pill">Before we start</span>

# The decision in front of this room

<div class="bento">
  <div class="tile tile--rose c-6">
    <div class="cap">We are asking</div>
    <ul>
      <li>Is this problem real?</li>
      <li>Is it well scoped?</li>
      <li>Is it worth solving here?</li>
      <li>Will people do the work?</li>
    </ul>
  </div>
  <div class="tile tile--sand c-6">
    <div class="cap">We are not asking</div>
    <ul>
      <li>Approve this wire format.</li>
      <li>Ratify a data model.</li>
      <li>Bless one implementation.</li>
    </ul>
  </div>
</div>

<div class="note">The draft is evidence that the problem is tractable. It is not the thing on the table today.</div>

---
class: full
title: "The problem"
---

<div class="section">
  <div class="num">01</div>
  <div class="title">The problem</div>
  <div class="sub">Mail servers delegate decisions to external services. That delegation covers the conversation that receives a message, and stops there.</div>
</div>

---

<span class="pill">Prior art</span>

# Milter, in one slide

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
  <div class="tile c-6">
    <h3>Twenty five years of deployment</h3>
    <p>Sendmail, around 2000. A C library, <code>libmilter</code>. Callbacks along the SMTP conversation; the filter may reject, defer, discard or modify.</p>
  </div>
  <div class="tile tile--sand c-6">
    <h3>The ecosystem speaks it</h3>
    <p>Rspamd, ClamAV, SpamAssassin, OpenDKIM, OpenDMARC. It is the only portable way to filter mail today.</p>
  </div>
</div>

<div class="note">This is not an argument that Milter is bad. It is an argument about reach.</div>

---

<span class="pill">Reach</span>

# Milter's reach ends at DATA

<div class="rail">
  <div class="st on">connect<small>hook</small></div>
  <div class="st on">helo<small>hook</small></div>
  <div class="st on">mail<small>hook</small></div>
  <div class="st on">rcpt<small>hook</small></div>
  <div class="st on">data<small>hook</small></div>
  <div class="st off">route<small>nothing</small></div>
  <div class="st off">transmit<small>nothing</small></div>
  <div class="st off">deliver<small>nothing</small></div>
  <div class="st off">dsn<small>nothing</small></div>
</div>
<div class="band" style="grid-template-columns: 5fr 4fr;">
  <span class="yes">One protocol covers this</span>
  <span class="no">A different mechanism per MTA covers this</span>
</div>

<div class="tile mt">
  <p class="statement">The moment the server answers <code>250 Ok</code>, the filter is out of the picture. It never learns whether what it accepted was delivered.</p>
</div>

---

<span class="pill">After acceptance</span>

# Everything after acceptance, today

<div class="tile">

| What you need | How it is wired today |
|---|---|
| Choose a transport or next hop | Lookup tables: one key string in, one value out |
| Archive with proof it was archived | BCC maps, with no return channel |
| Know whether recipient B received it | VERP addressing, a bounce mailbox, and log parsing |
| Report on delivery TLS | A dedicated side channel with its own collector chain |
| Suppress a notification | Global switches, or nothing |

</div>

<div class="note">None is an IETF specification. None is portable. None is correlated with the others, or with what was decided at reception.</div>

---

<span class="pill">Lookup tables</span>

# A routing decision gets one string

<div class="bento">
  <div class="tile tile--sand c-5">
    <div class="cap">A transport lookup sees</div>
    <div class="big">one key</div>
    <p>The recipient domain or address. One value comes back: a transport and next hop.</p>
  </div>
  <div class="tile c-7">
    <div class="cap">Invisible to the lookup</div>
    <ul>
      <li>The authenticated sender or the client that submitted the message</li>
      <li>The verdict of the spam filter at reception</li>
      <li>How many attempts failed, and how the last one failed</li>
      <li>Whether TLS failed on the default path</li>
    </ul>
  </div>
</div>

<div class="note">Failover after three failed attempts, or a VPN route that must hold or the mail waits, has no standard place to live.</div>

---

<span class="pill">Context</span>

# Context arrives by configuration, and silently does not

<div class="bento">
  <div class="tile c-6">
    <h3>Macros</h3>
    <p>The client address, reverse name, TLS parameters and authenticated identity must each be exported by the administrator, per stage, by name.</p>
    <p>A forgotten macro is not an error. The filter cannot tell "not configured" from "not available".</p>
  </div>
  <div class="tile tile--sand c-6">
    <h3>No negotiation</h3>
    <p>A filter cannot ask for what it needs, discover what the server can provide, or refuse to start when an input is missing.</p>
  </div>
  <div class="tile tile--sand c-6">
    <h3>No authentication results</h3>
    <p>SPF, DKIM and DMARC are not part of the interface. Every filter recomputes them or parses headers.</p>
  </div>
  <div class="tile c-6">
    <h3>No session signals</h3>
    <p>Pregreet traffic, pipelining violations, command counts and an unverified client certificate stay invisible.</p>
  </div>
</div>

---

<span class="pill">Extensibility</span>

# Adding one new field

<p class="lead" style="margin-bottom: 14px;">A DKIM2 signer needed one datum from Postfix: proof that a DSN really came from the local bounce daemon.</p>

<div class="bento">
  <div class="tile c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Step 1</div></div>
    <h3>Patch the core</h3>
    <p>bounce(8) passes evidence to cleanup(8) through a private record.</p>
  </div>
  <div class="tile c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Step 2</div></div>
    <h3>New macros</h3>
    <p><code>{postfix_dsn_evidence}</code> and the original envelope.</p>
  </div>
  <div class="tile c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Step 3</div></div>
    <h3>Document it</h3>
    <p>An update to MILTER_README so anyone can find it.</p>
  </div>
  <div class="tile tile--rose c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Step 4</div></div>
    <h3>Roll it out</h3>
    <p>Every filter author learns the names and requests them.</p>
  </div>
</div>

<div class="note">The real ceiling is not "can it carry X". It is what it costs to introduce X at all. (postfix-devel, August 2026)</div>

---

<span class="pill">Chains</span>

# Filters cannot talk to each other

<div class="bento">
  <div class="tile c-7">
    <h3>The only channel is a header</h3>
    <p>A filter that wants to pass a score to the next one writes <code>X-Spam-Status</code> into the message. The next filter parses it.</p>
    <ul>
      <li>Unstructured, and forgeable by the sender</li>
      <li>Travels onward with the mail</li>
      <li>No way to learn who quarantined it, or why</li>
    </ul>
  </div>
  <div class="tile tile--sand c-5">
    <h3>No single call</h3>
    <p>A filter that wants the whole message with its metadata takes every callback and rebuilds it. The Rspamd proxy does exactly this, then makes one HTTP call.</p>
  </div>
</div>

---

<span class="pill">A requirement arriving now</span>

# DKIM2 asks for things that happen after acceptance

<div class="bento">
  <div class="tile c-6">
    <div class="cap">Section 10.6</div>
    <p>The signature records the <code>RCPT TO</code> values of the SMTP transaction that carried the copy. A <code>Bcc:</code> address <strong>MUST NOT</strong> appear in the copy sent to anyone else.</p>
  </div>
  <div class="tile c-6">
    <div class="cap">Section 16.1</div>
    <p>A DSN <strong>MUST</strong> carry its own Message-Instance and DKIM2-Signature fields, and goes to the <code>mf=</code> address of the highest numbered signature.</p>
  </div>
  <div class="tile tile--rose c-12">
    <p class="statement">Signing per SMTP transaction, not per queued message, and a hook at DSN generation.</p>
  </div>
</div>

<p class="cap" style="margin-top: 12px;">draft-ietf-dkim-dkim2-spec-07</p>

---

<span class="pill">A requirement arriving now</span>

# One Milter cannot produce that signature

<div class="bento">
  <div class="tile tile--sand c-6">
    <div class="cap">The filter runs early</div>
    <p>At <code>cleanup</code>. One queued message, one body, one recipient list. The delivery job has not been split yet.</p>
  </div>
  <div class="tile tile--sand c-6">
    <div class="cap">The split happens later</div>
    <p>Later, in <code>qmgr</code>, when recipients are grouped by transport and next hop. No filter runs there.</p>
  </div>
  <div class="tile c-12">
    <p>At signing time the filter can put every recipient in the signature, disclosing the blind copies, or guess a recipient set that does not match the transaction. Bounces fare no better: there is no hook before a DSN is injected, so nothing can sign it.</p>
  </div>
</div>

<div class="note">A filter cannot consolidate its way to data the server has not computed yet.</div>

---

<span class="pill">Demand</span>

# The people asking for this

<div class="bento">
  <div class="tile tile--sand c-5">
    <h3>Not the filter vendors</h3>
    <p>Rspamd, SpamAssassin and ClamAV paid the integration cost once and amortise it across every deployment.</p>
  </div>
  <div class="tile c-7">
    <h3>The operators</h3>
    <p>People who want one site-specific rule. Check the recipient against our directory. Apply the footer legal asked for. Push an event into our SIEM. Fifty lines, in whatever language the shop already uses.</p>
  </div>
</div>

<div class="note">Stalwart ships Milter support. Its users asked for an HTTP interface anyway: a revealed preference from people who had both options.</div>

---

<span class="pill">Demand</span>

# Scanners already want to be HTTP services

<div class="bento">
  <div class="tile tile--ink c-7 center">
    <div class="cap">dkim2d, an independent DKIM2 implementation</div>
    <div class="rail" style="margin-top: 8px;">
      <div class="st ink">Postfix<small>dkim2-milter</small></div>
      <div class="st ink">Exim<small>local_scan + filter</small></div>
      <div class="st ink" style="flex: 0.4;">&rarr;</div>
      <div class="st on">dkim2d<small>HTTP / JSON</small></div>
    </div>
  </div>
  <div class="tile c-5">
    <h3>The adapter zoo</h3>
    <p>The logic lives in one HTTP daemon. Each MTA needs its own adapter to gather the envelope, call it, and validate what comes back.</p>
  </div>
</div>

<div class="note">The adapters are the missing standard, rebuilt per MTA from whatever interface each one offers.</div>

---

<span class="pill">An obvious alternative</span>

# Specifying Milter would not close the gap

<div class="bento">
  <div class="tile c-4">
    <h3>Reach</h3>
    <p>A specification of the existing protocol still stops when the message is accepted.</p>
  </div>
  <div class="tile tile--sand c-4">
    <h3>Extensibility</h3>
    <p>Context still arrives by macro, and a new field still costs a core change in every server.</p>
  </div>
  <div class="tile c-4">
    <h3>Audience</h3>
    <p>The operator with a fifty-line rule still cannot practically use it.</p>
  </div>
</div>

<div class="note">Outbound delegation is not an unimplemented Milter feature. Its whole vocabulary answers one question: what do I say to the client waiting on this command.</div>

---

<span class="pill">Summary</span>

# The problem, in short

<div class="bento">
  <div class="tile tile--ink c-5 r-2 center">
    <p class="statement">Delegation covers the conversation that receives a message, and stops there.</p>
  </div>
  <div class="tile c-7">
    <ul>
      <li>Everything after acceptance is a different mechanism in every server, none standard, none correlated</li>
      <li>A new field costs a change to the server core</li>
      <li>Requirements from IETF work, such as DKIM2, cannot be expressed at all</li>
      <li>The people who most need to write filters are the least able to</li>
    </ul>
  </div>
  <div class="tile tile--rose c-7">
    <p class="statement" style="font-size: 19px;">Is that the right problem, and is this the right place to solve it?</p>
  </div>
</div>

---
class: full
title: "The idea"
---

<div class="section">
  <div class="num">02</div>
  <div class="title">The idea</div>
  <div class="sub">Shown as evidence the problem is tractable, not as a proposal to ratify.</div>
</div>

---

<span class="pill">The idea</span>

# Three ideas carry the whole design

<div class="bento">
  <div class="tile c-4">
    <div class="big hl">1</div>
    <h3>One state object</h3>
    <p>At each stage the MTA describes the session, the envelope with every recipient's status, the message and the delivery attempts, in one object.</p>
  </div>
  <div class="tile tile--sand c-4">
    <div class="big hl">2</div>
    <h3>One JSON Patch</h3>
    <p>The scanner answers with an RFC 6902 patch against that object. The MTA carries out the resulting state.</p>
  </div>
  <div class="tile tile--rose c-4">
    <div class="big">3</div>
    <h3>The MTA controls change</h3>
    <p>Each scanner may change only the paths it was granted, and by default only toward stricter processing.</p>
  </div>
</div>

---

<span class="pill">The idea</span>

# Every decision is a change to the state

<div class="bento">
  <div class="tile c-7">

| Decision | Path it changes |
|---|---|
| Accept, reject, quarantine | `/action`, `/response` |
| Add a header field | `/message/headers` |
| Drop a recipient | `/envelope/to/*/status` |
| Choose a route | `/envelope/to/*/route` |
| Suppress a DSN | `/envelope/to/*/status` |
| Hand data to the next scanner | `/ext/org.example.spam` |

  </div>
  <div class="tile tile--ink c-5 center">
    <p class="statement">No other way to influence processing exists.</p>
    <p>So every effect a scanner can have is a path, and every permission is a grant on a path.</p>
  </div>
</div>

---

<span class="pill">Architecture</span>

# The MTA is always the client

<div class="bento">
  <div class="tile c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Optional</div></div>
    <h3>Discover</h3>
    <p>GET <code>/.well-known/mta-hooks</code></p>
  </div>
  <div class="tile c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Once</div></div>
    <h3>Register</h3>
    <p>POST stages, properties and grants</p>
  </div>
  <div class="tile c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Per stage</div></div>
    <h3>Hook request</h3>
    <p>POST the current state</p>
  </div>
  <div class="tile tile--rose c-3">
    <div class="step-head"><div class="dot"></div><div class="cap">Per stage</div></div>
    <h3>JSON Patch</h3>
    <p>Validated against grants, then applied</p>
  </div>
  <div class="tile tile--sand c-12">
    <p>The MTA exposes no HTTP endpoint. No registration floods against it, no callback forgery, and existing HTTP clients, load balancers, proxies and monitoring work unchanged.</p>
  </div>
</div>

---
class: full
title: "The protocol"
---

<div class="section">
  <div class="num">03</div>
  <div class="title">The protocol</div>
  <div class="sub">Discovery, registration, stages, the request, the patch, grants, recipients, extension data and failure.</div>
</div>

---

<span class="pill">Discovery</span>

# The scanner advertises its needs

<div class="bento">
  <div class="tile tile--code c-8">
    <div class="cap">GET /.well-known/mta-hooks</div>

```json
{
  "version": "1.0",
  "registration": "/v1/registrations",
  "serialization": ["application/cbor", "application/json"],
  "stages": ["connect", "rcpt", "data", "route", "delivery"],
  "properties": ["/session", "/envelope", "/message",
                 "/senderAuth", "/queue", "/ext/org.example.av"],
  "grants": [
    {"path": "/action",
     "values": ["accept", "quarantine", "reject", "discard"]},
    {"path": "/message/headers"},
    {"path": "/envelope/to/*/route"}
  ],
  "maxMessageSize": 52428800,
  "timeoutMs": 2000
}
```

  </div>
  <div class="tile c-4">
    <h3>Optional</h3>
    <p>The MTA may be configured with the registration URL instead.</p>
    <h3 style="margin-top: 10px;">A wish list</h3>
    <p>Stages, properties and grants the scanner would like. The MTA operator decides what it actually gets.</p>
  </div>
</div>

---

<span class="pill">Registration</span>

# The MTA states the contract

<div class="bento">
  <div class="tile tile--code dense c-8">
    <div class="cap">POST /v1/registrations, label "spam"</div>

```json
"subscriptions": [
  {"stages": ["data"],
   "filter": {"authenticated": false},
   "properties": ["/session", "/envelope", "/message"],
   "grants": [{"path": "/action"}, {"path": "/response"},
              {"path": "/message/headers"},
              {"path": "/ext/org.example.spam", "max": 4096}],
   "onFailure": "continue"},
  {"stages": ["route"],
   "filter": {"envelopeTo": "*@partner.example"},
   "properties": ["/envelope", "/queue", "/ext/org.example.spam"],
   "grants": [{"path": "/envelope/to/*/route/name",
               "values": ["vpn-partner"]}],
   "onFailure": "tempfail"}
]
```

  </div>
  <div class="tile c-4">
    <h3>Written by the MTA</h3>
    <p>From its own configuration: what it will send and what it will allow.</p>
    <h3 style="margin-top: 10px;">Narrow, never widen</h3>
    <p>The scanner may drop properties and grants it does not need, or refuse with 422.</p>
  </div>
</div>

---

<span class="pill">Subscriptions</span>

# Different traffic, different contract

<div class="bento">
  <div class="tile c-6">
    <h3>First match wins</h3>
    <p>For each stage the MTA uses the first subscription that lists it and whose filter matches. No match, no call.</p>
    <p>Each subscription carries its own properties, grants and failure policy.</p>
  </div>
  <div class="tile tile--sand c-6">
    <h3>Filters reuse JMAP</h3>
    <p>The Email filter conditions of RFC 8621, plus connection conditions:</p>
    <div class="chips">
      <span class="chip chip--brand">envelopeFrom</span>
      <span class="chip chip--brand">envelopeTo</span>
      <span class="chip chip--brand">clientIp</span>
      <span class="chip chip--brand">serverPort</span>
      <span class="chip chip--brand">tls</span>
      <span class="chip chip--brand">authenticated</span>
      <span class="chip chip--brand">authLogin</span>
    </div>
  </div>
  <div class="tile tile--rose c-12">
    <p>At <code>route</code> and <code>delivery</code>, subscriptions match per recipient. Each one's grants and failure policy apply only to the recipients it matched.</p>
  </div>
</div>

---

<span class="pill">Stages</span>

# Nine stages, one message

<div class="rail">
  <div class="st">connect</div>
  <div class="st">ehlo</div>
  <div class="st">mail</div>
  <div class="st">rcpt</div>
  <div class="st">data</div>
  <div class="st on">route</div>
  <div class="st on">transmit</div>
  <div class="st on">delivery</div>
  <div class="st on">dsn</div>
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
    <h3>One queue identity</h3>
    <p>The queue id is the same from <code>data</code> to the last <code>delivery</code> or <code>dsn</code>, so a scanner can keep what it learned at reception.</p>
  </div>
</div>

---

<span class="pill">Stages</span>

# Two stages with no Milter equivalent

<div class="bento">
  <div class="tile c-6">
    <div class="cap">route</div>
    <h3>Before every delivery attempt</h3>
    <p>Runs each time recipients leave the queue, before the next hop is resolved. Sets a route per recipient.</p>
    <p>Recipients with different routes never share an SMTP transaction.</p>
  </div>
  <div class="tile tile--rose c-6">
    <div class="cap">transmit</div>
    <h3>Before every SMTP transaction</h3>
    <p>Runs once the transaction's envelope is final, with the exact reverse-path and recipients that will be sent.</p>
    <p>Changes apply to this copy only and are not kept in the queue.</p>
  </div>
</div>

---

<span class="pill">Hook request</span>

# The state, as the MTA holds it

<div class="bento">
  <div class="tile tile--code dense c-8 r-2">

```json
{
  "stage": "data",
  "action": "accept",
  "decidedBy": "mta",
  "response": {"code": 250, "message": "Queued as 4F2A31B0C9"},
  "timeoutMs": 4200,
  "session": {
    "client": {"ip": "192.0.2.100", "ptr": "mail.example.org"},
    "tls": {"version": "TLSv1.3"},
    "counters": {"commands": 5, "pregreetBytes": 0}
  },
  "envelope": {
    "from": {"address": "sender@example.org"},
    "to": [{"address": "bob@example.com", "status": "accepted"}]
  },
  "message": {"size": 2048, "subject": "Meeting Tomorrow"},
  "senderAuth": {"spfMailFrom": "pass", "dmarc": "pass"}
}
```

  </div>
  <div class="tile c-4">
    <h3>Contents</h3>
    <p>Only the properties the subscription lists. The message as a JMAP Email object, raw bytes, or both.</p>
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

# The answer is a JSON Patch

<div class="bento">
  <div class="tile tile--code c-8">
    <div class="cap">Reject a message</div>

```json
[
  {"op": "replace", "path": "/action", "value": "reject"},
  {"op": "replace", "path": "/response",
   "value": {"code": 550, "enhancedCode": "5.7.1",
             "message": "Message rejected: virus detected"}}
]
```

  </div>
  <div class="tile c-4">
    <h3>Or nothing</h3>
    <p><code>204</code>, or an empty patch, means no changes.</p>
    <h3 style="margin-top: 8px;">Blind writes</h3>
    <p>The patch applies to the state the MTA holds, so a scanner can add a header without having received the message.</p>
  </div>
  <div class="tile tile--code c-12">
    <div class="cap">Add a header field, and pass a score to later scanners</div>

```json
[{"op": "add", "path": "/message/headers/0",
  "value": {"name": "X-Spam-Status", "value": " No, score=0.4"}},
 {"op": "add", "path": "/ext/org.example.spam",
  "value": {"score": 0.4, "symbols": ["DKIM_VALID"]}}]
```

  </div>
</div>

---

<span class="pill">Validation</span>

# The MTA compares states, not operations

<div class="bento">
  <div class="tile c-3">
    <div class="big hl">1</div>
    <h3>It applies</h3>
    <p>Per RFC 6902, including every <code>test</code>.</p>
  </div>
  <div class="tile c-3">
    <div class="big hl">2</div>
    <h3>It is granted</h3>
    <p>Every location that differs is covered, within its values and max.</p>
  </div>
  <div class="tile c-3">
    <div class="big hl">3</div>
    <h3>It is stricter</h3>
    <p>Ordered properties only tighten, unless relaxed.</p>
  </div>
  <div class="tile c-3">
    <div class="big hl">4</div>
    <h3>It is valid</h3>
    <p>Types, stage rules, headers, addresses and MIME.</p>
  </div>
</div>

<div class="note">Applied to a copy, all or nothing. An invalid patch is discarded whole and counts as a scanner failure.</div>

---

<span class="pill">Grants</span>

# A grant is a path, with limits

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
      <li><strong>path</strong>: covers everything below it; <code>*</code> matches any array index</li>
      <li><strong>values</strong>: allowed strings, with wildcards</li>
      <li><strong>max</strong>: a number ceiling, or a size in octets</li>
      <li><strong>relax</strong>: may loosen ordered properties</li>
    </ul>
  </div>
  <div class="tile tile--rose c-12">
    <p>No grant, no change. When grants overlap, the most specific path applies, so a narrow grant can restrict part of a broad one.</p>
  </div>
</div>

---

<span class="pill">Grants</span>

# Restrict by default

<div class="bento">
  <div class="tile c-7">
    <div class="cap">Ordered from permissive to strict</div>

| Property | Order |
|---|---|
| `/action` | accept, quarantine, then reject, discard, disconnect |
| `/envelope/to/*/route/tls` | none, opportunistic, required, verified |

  </div>
  <div class="tile tile--sand c-5">
    <h3>Without relax</h3>
    <p>A scanner may keep the value or move it toward strict. It can reject what the MTA accepted, never accept what the MTA rejected.</p>
  </div>
  <div class="tile tile--ink c-12">
    <p><strong>With relax</strong>, the scanner becomes the final authority for that property: it can override a rejection, or lower TLS below the destination's policy, like <code>TLS-Required: No</code>. The operator grants it explicitly, and REQUIRETLS still wins.</p>
  </div>
</div>

---

<span class="pill">Chains</span>

# Inbound: actions, in a chain

<div class="bento">
  <div class="tile c-7">

| Action | Effect |
|---|---|
| accept | Continue normally |
| quarantine | Accept, then hold instead of delivering |
| reject | Send `/response`, a 4xx or 5xx |
| discard | Accept and drop |
| disconnect | Send `/response` and close |

  </div>
  <div class="tile tile--sand c-5">
    <h3>Ordered, attributed</h3>
    <p>Scanners run in configured order, each seeing the state left by the previous ones.</p>
    <p><code>decidedBy</code> names the label of whoever set the action, or <code>mta</code>.</p>
  </div>
  <div class="tile tile--rose c-12">
    <p>Reject, discard and disconnect are terminal: the chain stops. At <code>rcpt</code> they apply only to the current recipient.</p>
  </div>
</div>

---

<span class="pill">Recipients</span>

# Outbound: the status of each recipient

<div class="bento">
  <div class="tile c-5">
    <div class="cap">One status set, every stage</div>
    <div class="chips">
      <span class="chip">pending</span>
      <span class="chip">accepted</span>
      <span class="chip">deferred</span>
      <span class="chip">failed</span>
      <span class="chip">delivered</span>
      <span class="chip chip--brand">discarded</span>
    </div>
    <p>Recipients are never removed. Dropping one means setting it to <code>discarded</code>, with no delivery and no DSN.</p>
  </div>
  <div class="tile c-7">

| Stage | From | To |
|---|---|---|
| data | accepted | discarded |
| route, transmit, delivery | accepted, deferred | deferred, failed, discarded |
| delivery | failed | discarded |
| dsn | accepted | discarded |

  </div>
</div>

<div class="note">A scanner that fails or defers a recipient may set the reply the DSN reports, and reschedule the next attempt.</div>

---

<span class="pill">Extension data</span>

# A new field without a core patch

<div class="bento">
  <div class="tile tile--code c-6">
    <div class="cap">Written at data, read again at route</div>

```json
"ext": {
  "org.example.spam": {"score": 0.4},
  "org.example.av": {"verdict": "clean"}
}
```

  </div>
  <div class="tile c-6">
    <ul>
      <li>Namespaces are reverse domain names owned by their definer</li>
      <li>Subscription properties decide who reads a namespace; grants decide who writes it</li>
      <li>Kept with the message for as long as it is in the MTA</li>
      <li>Unknown namespaces are ignored</li>
    </ul>
  </div>
</div>

<div class="note">An MTA and a scanner agree on a namespace bilaterally. No wire format change, no registry, no ecosystem rollout.</div>

---

<span class="pill">Failure</span>

# On scanner failure, the operator decides

<div class="bento">
  <div class="tile tile--sand c-12">
    <p>A scanner fails when it times out, exhausts its retries, returns anything but 200 or 204, or sends an invalid patch. The state is left unchanged and the subscription's <code>onFailure</code> applies.</p>
  </div>
  <div class="tile c-6">
    <div class="cap">onFailure: continue</div>
    <h3>Fail open</h3>
    <p>Proceed as if the scanner had made no changes. The default.</p>
  </div>
  <div class="tile tile--rose c-6">
    <div class="cap">onFailure: tempfail</div>
    <h3>Fail closed</h3>
    <p>Inbound, answer 451 or 421. Outbound, keep the recipients deferred and retry later.</p>
  </div>
  <div class="tile c-12">
    <p>Each request carries its own <code>timeoutMs</code> budget, and a <code>MTA-Hooks-Request-Id</code> that stays the same on every retry, so scanners can deduplicate.</p>
  </div>
</div>

---
class: full
title: "Use cases"
---

<div class="section">
  <div class="num">04</div>
  <div class="title">Use cases</div>
  <div class="sub">Use cases, end to end, using only what the draft specifies.</div>
</div>

---

<span class="pill">Use case</span>

# Spam filtering at SMTP time

<div class="bento">
  <div class="tile c-4">
    <div class="step-head"><div class="dot"></div><div class="cap">Subscribe</div></div>
    <p>Only <code>data</code>, filtered to <code>{"authenticated": false}</code>. One call per message, with the whole session.</p>
  </div>
  <div class="tile c-4">
    <div class="step-head"><div class="dot"></div><div class="cap">Decide</div></div>
    <p>Sender authentication is already in the request. No recomputing SPF, DKIM or DMARC.</p>
  </div>
  <div class="tile tile--rose c-4">
    <div class="step-head"><div class="dot"></div><div class="cap">Answer</div></div>
    <p>Reject with a 550 while the client is still connected, or quarantine, or accept with a header.</p>
  </div>
  <div class="tile tile--code c-12">

```json
[{"op": "replace", "path": "/action", "value": "reject"},
 {"op": "replace", "path": "/response",
  "value": {"code": 550, "enhancedCode": "5.7.1", "message": "Spam"}}]
```

  </div>
</div>

---

<span class="pill">Use case</span>

# Slowing down a suspicious client

<div class="bento">
  <div class="tile tile--code c-6">
    <div class="cap">At connect: hold the greeting</div>

```json
[{"op": "add", "path": "/response/delayMs",
  "value": 15000}]
```

  </div>
  <div class="tile c-6">
    <h3>Signals in the session</h3>
    <div class="chips">
      <span class="chip">pregreetBytes</span>
      <span class="chip">pipeliningViolations</span>
      <span class="chip">bareLinefeeds</span>
      <span class="chip">invalidCommands</span>
      <span class="chip">firstCommandDelayMs</span>
    </div>
  </div>
  <div class="tile tile--sand c-6">
    <h3>Capped by the grant</h3>
    <p><code>{"path": "/response/delayMs", "max": 30000}</code> keeps delays below SMTP client timeouts.</p>
  </div>
  <div class="tile c-6">
    <h3>Withhold capabilities</h3>
    <p>At <code>ehlo</code>, offer AUTH only on some networks, or drop PIPELINING and CHUNKING for suspicious clients.</p>
  </div>
</div>

---

<span class="pill">Use case</span>

# Mandatory routing, fail closed

<div class="bento">
  <div class="tile tile--code c-7">
    <div class="cap">Route through the VPN, unless another scanner already routed it</div>

```json
[{"op": "test", "path": "/envelope/to/0/route/name",
  "value": "default"},
 {"op": "replace", "path": "/envelope/to/0/route/name",
  "value": "vpn-partner"}]
```

  </div>
  <div class="tile tile--rose c-5">
    <h3>The subscription</h3>
    <p>Filter <code>*@partner.example</code>, grant only the value <code>vpn-partner</code>, <code>onFailure: tempfail</code>.</p>
  </div>
  <div class="tile c-6">
    <h3>Blast radius</h3>
    <p>If the scanner is down, only partner mail waits in the queue. Everything else takes default routing.</p>
  </div>
  <div class="tile tile--sand c-6">
    <h3>Failover</h3>
    <p><code>route</code> runs before every attempt, with <code>attempts</code> and <code>lastAttempt</code>, so the scanner can switch paths after failures.</p>
  </div>
</div>

---

<span class="pill">Use case</span>

# No bounce for noreply

<div class="bento">
  <div class="tile c-6">
    <div class="cap">At delivery</div>
    <h3>Drop the failed recipient</h3>
    <p>Setting a failed recipient to <code>discarded</code> suppresses its DSN. The scanner records the hard bounce in its own system instead.</p>
  </div>
  <div class="tile tile--sand c-6">
    <div class="cap">At dsn</div>
    <h3>Or drop the DSN itself</h3>
    <p>Discarding the recipient of a DSN suppresses that DSN, for example backscatter control on a list.</p>
  </div>
  <div class="tile tile--code c-12">

```json
[{"op": "replace", "path": "/envelope/to/2/status", "value": "discarded"}]
```

  </div>
</div>

<div class="note">Per message and per recipient, through a grant, instead of a global switch.</div>

---

<span class="pill">Use case</span>

# Scanner to scanner, without X- headers

<div class="bento">
  <div class="tile c-4">
    <div class="step-head"><div class="dot"></div><div class="cap">data</div></div>
    <h3>Spam scanner</h3>
    <p>Writes <code>/ext/org.example.spam</code>, granted with a 4096 octet max.</p>
  </div>
  <div class="tile c-4">
    <div class="step-head"><div class="dot"></div><div class="cap">data</div></div>
    <h3>Next in the chain</h3>
    <p>Receives the namespace as a property, along with <code>decidedBy</code> on the action.</p>
  </div>
  <div class="tile tile--rose c-4">
    <div class="step-head"><div class="dot"></div><div class="cap">route</div></div>
    <h3>Days later</h3>
    <p>The routing scanner still sees <code>{"score": 0.4}</code> on the queued message.</p>
  </div>
</div>

<div class="note">Structured, attributed, size-capped, and never part of the mail that travels onward.</div>

---

<span class="pill">Use case</span>

# DKIM2 signing at transmit

<div class="bento">
  <div class="tile c-6">
    <h3>The exact envelope</h3>
    <p><code>transmit</code> runs per SMTP transaction, after the job is split, with the reverse-path and recipients of this copy. The signature covers exactly those recipients, never a guess.</p>
  </div>
  <div class="tile tile--sand c-6">
    <h3>Fresh every attempt</h3>
    <p>Changes are not kept in the queue. The stage runs again on retry, so each signature carries the time and envelope of the attempt that uses it.</p>
  </div>
  <div class="tile tile--ink c-12">
    <p><strong>DSNs too.</strong> At <code>dsn</code> the request describes the notification about to be sent, so the same scanner signs it the same way.</p>
  </div>
</div>

<div class="note">No per-MTA adapter: a signer like dkim2d can be one MTA Hooks scanner.</div>

---

<span class="pill">Use case</span>

# Delivery outcomes as data

<div class="bento">
  <div class="tile c-4">
    <h3>Archiving</h3>
    <p>Capture at <code>data</code> with <code>tempfail</code>, so nothing is delivered unarchived. Proof of delivery arrives under the same queue id.</p>
  </div>
  <div class="tile tile--sand c-4">
    <h3>Bounce handling</h3>
    <p>The next hop's real reply per recipient, instead of VERP addresses and a bounce mailbox.</p>
  </div>
  <div class="tile c-4">
    <h3>TLS reporting</h3>
    <p>Each attempt reports remote host, TLS version, policy and failure as RFC 8460 values.</p>
  </div>
</div>

---

<span class="pill">Mapping back</span>

# Each problem and its answer

<div class="tile">

| The problem | What answers it |
|---|---|
| Nothing after acceptance | `route`, `transmit`, `delivery` and `dsn`, in the same protocol |
| Routing gets one string | The full state at `route`, a granted route per recipient |
| Context by macro, silently absent | A registration that states exactly what is sent |
| A new field costs a core patch | Reverse-domain `/ext` namespaces, ignored if unknown |
| Filters talk through headers | Shared `/ext` data and `decidedBy` attribution |
| DKIM2 signatures and DSNs | `transmit` per transaction, `dsn` before sending |
| Operators cannot write filters | An HTTP endpoint that takes JSON and returns a patch |

</div>

---
class: full
title: "The case for a standard"
---

<div class="section">
  <div class="num">05</div>
  <div class="title">The case for a standard</div>
  <div class="sub">The value is one scanner that works with every MTA.</div>
</div>

---

<span class="pill">Ecosystem</span>

# Write the scanner once

<div class="bento">
  <div class="tile tile--sand c-6">
    <div class="cap">Today</div>
    <h3>One adapter per MTA</h3>
    <p>Milter for Postfix, local_scan for Exim, plugins for Haraka, Lua for KumoMTA. Every scanner rebuilds the same bridge, per server.</p>
  </div>
  <div class="tile tile--rose c-6">
    <div class="cap">With a standard</div>
    <h3>One protocol, any MTA</h3>
    <p>A scanner discovers what a given MTA implements, and works with all of them.</p>
  </div>
  <div class="tile c-12">
    <p>Adoption is additive: no flag day, existing MTAs and filters unchanged. Gateways in both directions, Milter to MTA Hooks and back, can be built outside the WG.</p>
  </div>
</div>

---

<span class="pill">Ecosystem</span>

# Built on existing standards

<div class="bento">
  <div class="tile c-4"><div class="cap">Transport</div><div class="big hl">HTTP</div><p>TLS, connection reuse, load balancers, auth.</p></div>
  <div class="tile tile--sand c-4"><div class="cap">Encoding</div><div class="big">JSON / CBOR</div><p>Chosen at registration.</p></div>
  <div class="tile c-4"><div class="cap">Changes</div><div class="big hl">RFC 6902</div><p>JSON Patch, with JSON Pointer paths.</p></div>
  <div class="tile tile--sand c-4"><div class="cap">Message model</div><div class="big">JMAP</div><p>The Email object and its filters.</p></div>
  <div class="tile c-4"><div class="cap">TLS outcomes</div><div class="big hl">RFC 8460</div><p>Policy and failure values.</p></div>
  <div class="tile tile--ink c-4 center"><p class="statement">The draft specifies hook semantics and little else.</p></div>
</div>

---

<span class="pill">Status</span>

# Implementations and support

<div class="bento">
  <div class="tile c-7">
    <div class="cap">Implementations</div>
    <ul>
      <li><strong>Stalwart</strong>: an earlier revision, in production</li>
      <li><strong>Rspamd</strong>: stated intent to implement</li>
      <li><strong>Haraka</strong>: offered on the list</li>
      <li>Independent scanners on GitHub, written by people who are not the draft authors</li>
    </ul>
  </div>
  <div class="tile tile--sand c-5">
    <div class="cap">Support without a commitment</div>
    <p>Heinlein Group, Beonex, KTP Digital, the SAKE project.</p>
    <div class="cap" style="margin-top: 8px;">Prior sessions</div>
    <p>MAILMAINT at 123, DISPATCH at 125, a side meeting at 126.</p>
  </div>
  <div class="tile tile--rose c-12">
    <p>-02 folds in detailed proposals from mailbox.org operators on routing, observability and inbound signals.</p>
  </div>
</div>

---
class: full
title: "The ask"
---

<div class="section">
  <div class="num">06</div>
  <div class="title">The ask</div>
  <div class="sub">Form a working group with a narrow charter.</div>
</div>

---

<span class="pill">Draft charter</span>

# In scope

<div class="bento">
  <div class="tile c-4"><h3>Wire protocol</h3><p>Requests, responses, headers, errors.</p></div>
  <div class="tile tile--sand c-4"><h3>Discovery and registration</h3><p>Well-known endpoint and the MTA to scanner contract.</p></div>
  <div class="tile c-4"><h3>Stages</h3><p>Inbound and outbound, through delivery and DSN.</p></div>
  <div class="tile tile--sand c-4"><h3>Routing delegation</h3><p>Per recipient, job splitting, TLS policy.</p></div>
  <div class="tile c-4"><h3>Modification and chains</h3><p>Changing state, ordering, termination.</p></div>
  <div class="tile tile--rose c-4"><h3>Failure and security</h3><p>Time budgets, fail open or closed, limits on what a scanner may change.</p></div>
</div>

---

<span class="pill">Draft charter</span>

# Out of scope, deliverables, milestones

<div class="bento">
  <div class="tile tile--sand c-5 r-2">
    <div class="cap">Out of scope</div>
    <ul>
      <li>Specifying Milter, or a Milter gateway</li>
      <li>Mailbox-level filtering, which is Sieve</li>
      <li>Filtering rules, scores, detection logic</li>
      <li>Changes to SMTP, JMAP, Sieve or any other IETF protocol</li>
      <li>Scanner products, vendor extensions, policy languages</li>
      <li>Quarantine and admin user interfaces</li>
    </ul>
  </div>
  <div class="tile c-7">
    <div class="cap">Deliverables</div>
    <ul>
      <li><strong>Protocol specification</strong>, Standards Track, based on draft-degennaro-mta-hooks</li>
      <li><strong>Operational considerations</strong>, in the same document or a separate Informational one</li>
    </ul>
  </div>
  <div class="tile tile--rose c-7">
    <div class="cap">Milestones</div>
    <p><strong>M+0</strong> WG formed, draft adopted &middot; <strong>M+3</strong> decide whether operational considerations are a separate draft &middot; <strong>M+12</strong> WGLC on the protocol &middot; <strong>M+15</strong> protocol to the IESG, WGLC on a separate ops draft &middot; <strong>M+18</strong> ops draft to the IESG</p>
  </div>
</div>

---

<span class="pill">BoF questions</span>

# Questions for the BoF

<div class="bento">
  <div class="tile c-7">
    <div class="cap">The problem and the charter</div>
    <ul>
      <li>Is the problem well understood, solvable, and useful to solve?</li>
      <li>Is the IETF the right place to do this work?</li>
      <li>Are the scope and deliverables of the draft charter correct?</li>
      <li>Should a working group be formed on that basis?</li>
    </ul>
  </div>
  <div class="tile tile--rose c-5">
    <div class="cap">Commitment to the work</div>
    <ul>
      <li>Will you review documents?</li>
      <li>Will you edit one?</li>
      <li>Will you implement, in an MTA or a scanner?</li>
      <li>Would you deploy it?</li>
    </ul>
  </div>
</div>

<div class="note">Discussion: mtahooks@ietf.org</div>

---
class: full
---

<div class="section">
  <div class="num">?</div>
  <div class="title">Over to the room</div>
  <div class="sub">Is this a problem the IETF should take on, and are there enough of us to do the work?</div>
</div>
