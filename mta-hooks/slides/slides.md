---
theme: default
title: "MTA Hooks"
titleTemplate: "%s"
info: |
  MTA Hooks: a protocol for delegating mail processing decisions.
  BoF proposal, IETF 127.
author: "Mauro De Gennaro"
keywords: mta hooks, milter, smtp, email filtering, dkim2
class: text-left
highlighter: shiki
lineNumbers: false
drawings:
  persist: false
transition: none
mdc: true
fonts:
  sans: "Inter"
  mono: "JetBrains Mono"
  weights: "400,500,600,700"
  italic: false
  provider: "none"
hideInToc: true
---

<div class="eyebrow">IETF 127 &middot; BoF proposal &middot; ART Area</div>

<h1 style="font-size: clamp(2.8rem, 6.4vw, 4.6rem); margin: 0; letter-spacing: -0.03em; line-height: 1;">
  <span class="brand">MTA Hooks.</span>
</h1>

<p class="tagline" style="font-size: clamp(1.25rem, 2.3vw, 1.8rem); font-weight: 600;
          line-height: 1.15; letter-spacing: -0.01em; margin: 0.85rem 0 0 0;">
  An HTTP protocol for delegating MTA processing decisions to external services.
</p>

<p class="muted" style="font-size: 1.05rem; margin-top: 0.85rem;">
  Built on HTTP, JSON and CBOR, JSON Pointer and the JMAP message model.
</p>

<div class="title-meta" style="margin-top: 2.2rem;">
  draft-degennaro-mta-hooks-02<br/>
  Mauro De Gennaro &middot; Stalwart Labs LLC
</div>

---

# The decision in front of this room

<div class="lanes">
  <div class="lane good">
    <div class="hd">We are asking</div>
    <div class="bd">
      <ul>
        <li>Is this problem real?</li>
        <li>Is it well scoped?</li>
        <li>Is it worth solving here?</li>
        <li>Will people do the work?</li>
      </ul>
    </div>
  </div>
  <div class="lane bad">
    <div class="hd">We are not asking</div>
    <div class="bd">
      <ul>
        <li>Approve this wire format.</li>
        <li>Ratify a data model.</li>
        <li>Bless one implementation.</li>
      </ul>
    </div>
  </div>
</div>

<p class="lead" style="margin-top: 1.2rem;">
  The draft exists as evidence that the problem is tractable, not as the thing
  on the table today.
</p>

---

# Milter, in one slide

Out-of-process filtering protocol. Sendmail, around 2000. A C library,
`libmilter`. Implemented by Sendmail and Postfix.

<div class="rail">
  <div class="seg on"><div class="k">connect</div></div>
  <div class="seg on"><div class="k">helo</div></div>
  <div class="seg on"><div class="k">envfrom</div></div>
  <div class="seg on"><div class="k">envrcpt</div></div>
  <div class="seg on"><div class="k">header</div></div>
  <div class="seg on"><div class="k">body</div></div>
  <div class="seg on"><div class="k">eom</div></div>
</div>

<div class="cols dense" style="margin-top: 1.1rem;">
<div>

- Callbacks fire along the SMTP conversation
- The filter may reject, defer, discard, or modify the message
- Twenty five years of deployment, an enormous installed base

</div>
<div>

- Rspamd, ClamAV, SpamAssassin, OpenDKIM, OpenDMARC and the rest of the
  ecosystem all speak it
- It is the only portable way to filter mail today

</div>
</div>

<p class="callout">This talk is not an argument that Milter is bad. It is an argument about reach.</p>

---

# Where Milter's reach ends

<div class="rail">
  <div class="seg on"><div class="k">connect</div><div class="v">hook</div></div>
  <div class="seg on"><div class="k">helo</div><div class="v">hook</div></div>
  <div class="seg on"><div class="k">mail</div><div class="v">hook</div></div>
  <div class="seg on"><div class="k">rcpt</div><div class="v">hook</div></div>
  <div class="seg on"><div class="k">data</div><div class="v">hook</div></div>
  <div class="seg off"><div class="k">route</div><div class="v">nothing</div></div>
  <div class="seg off"><div class="k">deliver</div><div class="v">nothing</div></div>
  <div class="seg off"><div class="k">retry</div><div class="v">nothing</div></div>
  <div class="seg off"><div class="k">dsn</div><div class="v">nothing</div></div>
</div>

<div class="band" style="grid-template-columns: 5fr 4fr;">
  <span class="yes">One protocol covers this</span>
  <span class="no">A different mechanism per MTA covers this</span>
</div>

<p class="lead" style="margin-top: 1.3rem;">
  The moment the server answers <code>250 Ok</code>, the filter is out of the
  picture for the rest of the message's life. It never learns whether what it
  accepted was delivered.
</p>

---
layout: default
---

<div class="divider">
  <div class="num">01</div>
  <div>
    <p class="title">What this costs</p>
    <p class="sub">Starting with a requirement that arrived this year and cannot be met at all.</p>
  </div>
</div>

---

# DKIM2 asks for things that happen after acceptance

<div class="cards two">
  <div class="card">
    <h4>Section 8.6</h4>
    <p>The signature records the <code>RCPT TO</code> values used in the SMTP
    transaction that actually carried the message. If <code>bcc:</code>
    recipients are involved, each of them <strong>MUST NOT</strong> be revealed
    to any other recipient.</p>
  </div>
  <div class="card">
    <h4>Sections 12.1.4 and 12.2</h4>
    <p>A DSN <strong>MUST</strong> carry its own signature, and <strong>MUST</strong>
    be addressed back to the MTA that sent the message, using the <code>mf=</code>
    tag of the highest numbered signature, not the return path.</p>
  </div>
</div>

<div class="cards two" style="margin-top: 0.2rem;">
  <div class="card">
    <h4>Section 12.1.1.1</h4>
    <p>A forwarder receiving a DSN may propagate it to the address it was itself
    delivered under, after verifying the embedded message against the highest
    numbered Message-Instance field.</p>
  </div>
  <div class="card">
    <h4>What that adds up to</h4>
    <p>Signing per delivery transaction, not per queued message. A hook at DSN
    generation. And the ability to consume a DSN and originate a new one.</p>
  </div>
</div>

<div class="footnote">draft-ietf-dkim-dkim2-spec-04</div>

---

# One Milter cannot produce that signature

<div class="lanes">
  <div class="lane bad">
    <div class="hd">When the filter runs</div>
    <div class="bd">
      <p>At <code>cleanup</code>. One queued message, one body, one recipient
      list. The delivery job has not been split yet.</p>
    </div>
  </div>
  <div class="lane bad">
    <div class="hd">When the split happens</div>
    <div class="bd">
      <p>Later, in <code>qmgr</code>, when recipients are grouped by transport
      and next hop. No filter runs there at all.</p>
    </div>
  </div>
</div>

At signing time the filter has two options, and both are wrong:

- put every recipient in the signature, which discloses the blind copies to all of them
- guess, and sign a recipient set that does not match the transaction

<p class="callout">The obstacle is not that the logic is spread across several filters.
A filter cannot consolidate its way to data the server has not computed yet.</p>

---

# And then the delivery notifications

<div class="cols col-2-3 dense">
<div>

### Generating one
There is no hook in the bounce path before the notification is injected. Nothing
can attach a signature chain, and nothing can address it anywhere other than the
return path.

</div>
<div>

### The nearest approximation
Postfix can pass self-generated bounces through a filter after the fact. It acts
globally on every bounce, runs after generation and never before, and the
documentation flags it as an expert setting because a filter that rejects will
destroy bounces outright.

</div>
</div>

### Forwarding one
Recognise an inbound DSN, verify the embedded chain, correlate it to forwarding
state held by this hop, and emit a new, re-signed notification addressed to the
previous hop. A filter can add headers and recipients to the message in front of
it. It cannot consume a message and cause the server to originate a different one.

---

# Everything after acceptance, today

| What you need | How it is wired today |
|---|---|
| Choose a transport or next hop | Lookup tables: one key string in, one value out |
| Transform content per destination | A filter loop with re-injection, giving the message a new identity midway |
| Archive with proof it was archived | BCC maps, with no return channel |
| Know whether recipient B received it | VERP addressing, a bounce mailbox, and log parsing |
| Report on delivery TLS | A dedicated side channel with its own collector chain |
| Suppress a notification | Global switches, or nothing |

<p class="callout">Not one of these is an IETF specification. Not one is portable
between servers. Not one is correlated with the others, or with the decisions
taken while the message was being received.</p>

---

# Context arrives by configuration, and silently does not

<div class="cols dense">
<div>

### Macros
Every piece of context, the client address, the reverse name, TLS parameters,
the authenticated identity, must be exported by the administrator, per stage,
by name.

A forgotten macro is not an error. The field is simply absent, and the filter
cannot tell "not configured" from "not available".

</div>
<div>

### No negotiation
A filter cannot ask for what it needs, cannot discover what the server is able
to provide, and cannot refuse to start when a required input is missing.

### No authentication results
SPF, DKIM, DMARC and ARC are not part of the interface. Every filter either
recomputes them or parses headers and establishes its own trust boundary.

</div>
</div>

---

# Adding one new field

<div class="flow">
  <div class="step">
    <div class="n">Step 1</div>
    <div class="t">Patch the server core</div>
    <div class="d">Macros are a fixed vocabulary the core must know. There is no
    generic channel for extra data.</div>
  </div>
  <div class="arrow">&rarr;</div>
  <div class="step">
    <div class="n">Step 2</div>
    <div class="t">Define new macro names</div>
    <div class="d">Plus a documentation update, so implementers can discover
    that the field now exists.</div>
  </div>
</div>

<div class="flow" style="margin-top: -0.4rem;">
  <div class="step">
    <div class="n">Step 3</div>
    <div class="t">Roll out the knowledge</div>
    <div class="d">Every filter author has to learn the new names and request
    them explicitly, or they never see the field.</div>
  </div>
  <div class="arrow">&rarr;</div>
  <div class="step">
    <div class="n">Result</div>
    <div class="t">A core change per server</div>
    <div class="d">For one field. This is the real ceiling on what the interface
    can ever carry.</div>
  </div>
</div>

<p class="callout">The strongest objection to Milter is not "can it carry X".
It is "what does it cost to introduce X at all".</p>

---

# One message, one body

Milter modifies *the* message. There is no way to say that recipient A gets this
body and recipients B and C get that one. Per-recipient content is met with a
filter loop and re-injection.

<div class="lanes">
  <div class="lane bad">
    <div class="hd">What the loop costs</div>
    <div class="bd">
      <ul class="tight">
        <li>Two passes through the queue for every message</li>
        <li>A new queue identity, so correlation needs log stitching</li>
        <li>One re-injection per recipient group</li>
        <li>Two policy points that must be kept consistent</li>
      </ul>
    </div>
  </div>
  <div class="lane bad">
    <div class="hd">Who needs it</div>
    <div class="bd">
      <ul class="tight">
        <li>Encryption gateways, per recipient</li>
        <li>Data loss prevention with a redacted variant</li>
        <li>Compliance footers that differ by destination</li>
        <li>DKIM2, for the reason two slides ago</li>
      </ul>
    </div>
  </div>
</div>

---

# Signals the interface cannot carry

<div class="cols dense small">
<div>

| Connection and session | |
|---|---|
| Resets, no-ops, syntax errors | invisible |
| Session duration, command timing | invisible |
| Pregreet and early talkers | invisible |
| Pipelining violations | invisible |
| Forward-confirmed reverse DNS | filter resolves it itself |

</div>
<div>

| Transaction and transport | |
|---|---|
| Client DSN options in use | invisible |
| Address rewriting, before and after | invisible |
| TLS fingerprint | absent or obsolete |
| Client certificate if unverified | never |
| Time budget for this call | never |

</div>
</div>

<p class="callout">And nothing carries provenance. A filter cannot learn that the
previous filter quarantined the message, or why. The only channel between them is
a header, which is unstructured, forgeable, and travels onward with the mail.</p>

---

# The people asking for this

<div class="cols col-2-3">
<div>

### Not the filter vendors
Rspamd, SpamAssassin and ClamAV paid the integration cost once and amortise it
across every deployment. A written-down Milter specification changes little for
them.

</div>
<div>

### The operators
People running a server who want to add one site-specific rule. Check the
recipient against our directory. Apply the footer policy legal asked for. Push
an event into our SIEM. Ten to a hundred lines, in whatever language the rest of
the shop already uses.

</div>
</div>

<p class="callout" style="margin-top: 1.4rem;">Stalwart ships Milter support.
Its users asked for an HTTP interface anyway. That is a revealed preference from
people who had both options in front of them, not a claim that binary protocols
are hard.</p>

---

# Specifying Milter would not close the gap

It is a reasonable suggestion, and writing the format down would be useful. It
would not address any of the previous slides.

<div class="cards">
  <div class="card">
    <h4>Reach</h4>
    <p>A specification of the existing protocol still stops when the message is
    accepted. The empty half of slide four stays empty.</p>
  </div>
  <div class="card">
    <h4>Extensibility</h4>
    <p>Context still arrives by macro, and a new field still costs a core change
    in every server that implements it.</p>
  </div>
  <div class="card">
    <h4>Audience</h4>
    <p>The operator with a fifty-line rule still cannot practically use it. That
    is the constituency asking for the work.</p>
  </div>
</div>

<p class="callout">What is missing is not a document. Outbound delegation is not
an unimplemented feature of Milter; there is nowhere in the protocol to put it.
Its whole response vocabulary answers one question: what do I say to the client
waiting on this command.</p>

---

# The problem, in short

<p class="lead">Mail servers delegate decisions to external services. That
delegation covers the conversation that receives a message, and stops there.</p>

- Everything after acceptance is covered by a different mechanism in every
  server, and usually several unrelated ones at once
- None of those mechanisms is an IETF specification, portable, or correlated
  with the others
- The interface that does exist cannot carry a new field without a change to the
  server core
- Requirements now arriving from IETF work cannot be expressed through it at all
- The people who most need to write filters are the least able to

<p class="callout">Is that the right problem, and is this the right place to solve it?</p>

---
layout: default
---

<div class="divider">
  <div class="num">02</div>
  <div>
    <p class="title">What we have built</p>
    <p class="sub">Shown as evidence the problem is tractable, not as a proposal to ratify.</p>
  </div>
</div>

---

# MTA Hooks

<p class="lead">The server makes an HTTP request to a registered service at each
processing stage, and applies what comes back.</p>

<div class="cards">
  <div class="card">
    <h4>Why it exists</h4>
    <p>Operators asked for a way to write their own filters without linking
    against a C library. It grew from there.</p>
  </div>
  <div class="card">
    <h4>What it covers</h4>
    <p>The whole life of a message: reception, routing, delivery, retry and
    notification, under one identity.</p>
  </div>
  <div class="card">
    <h4>What it reuses</h4>
    <p>HTTP, JSON and CBOR, JSON Pointer, and the JMAP message model. It
    specifies hook semantics and little else.</p>
  </div>
</div>

<div class="strip">
  <div><div class="n">HTTP</div><div class="l">transport</div></div>
  <div><div class="n">9</div><div class="l">stages</div></div>
  <div><div class="n">JSON / CBOR</div><div class="l">serialisation</div></div>
  <div><div class="n">Shipping</div><div class="l">in production</div></div>
</div>

---

# How it works

<div class="flow">
  <div class="step">
    <div class="n">Once</div>
    <div class="t">Discovery</div>
    <div class="d">The service publishes a document at a well-known endpoint
    saying which stages it handles and which properties it understands.</div>
  </div>
  <div class="arrow">&rarr;</div>
  <div class="step">
    <div class="n">Once</div>
    <div class="t">Registration</div>
    <div class="d">Server and service negotiate: these stages, this context,
    these modifications permitted, this failure behaviour.</div>
  </div>
</div>

<div class="flow" style="margin-top: -0.4rem;">
  <div class="step">
    <div class="n">Per message</div>
    <div class="t">Hook call</div>
    <div class="d">An HTTP POST carrying exactly the context that was
    negotiated, and nothing else.</div>
  </div>
  <div class="arrow">&rarr;</div>
  <div class="step">
    <div class="n">Per message</div>
    <div class="t">Response</div>
    <div class="d">An action, and a set of patches describing what to change.</div>
  </div>
</div>

<p class="callout">Negotiation is what makes the rest work. What is not
advertised is known to be unavailable, so a service can adapt or refuse to
start.</p>

---

# The hook request

A service registered only for `data` gets one call, with the context of every
earlier stage already gathered. Skipping is real: the earlier stages produce no
round trip for it.

```json
{
  "stage": "data",
  "queue":     { "id": "01J8Z2K..." },
  "client":    { "ip": "203.0.113.10", "ptr": "mail.example.net", "fcrdns": "pass" },
  "tls":       { "version": "TLSv1.3", "cipher": "TLS_AES_256_GCM_SHA384" },
  "senderAuth":{ "spf": "pass", "dkim": "pass", "dmarc": "pass", "arc": "none" },
  "envelope":  { "from": "alice@example.org",
                 "to": [ { "address": "bob@example.com" } ] },
  "message":   { "subject": "Quarterly report", "bodyStructure": { } }
}
```

<p class="callout">The parsed message, the raw bytes, or both. Authentication
results come from the server, which already computed them.</p>

---

# The hook response

Patches against the request, so a service never echoes back a message it did not
change.

```json
{
  "set": [
    { "path": "/action",   "value": "reject" },
    { "path": "/response", "value": { "code": 550, "message": "Policy" } }
  ]
}
```

<div class="cols dense" style="margin-top: 0.6rem;">
<div>

**Inbound actions** accept, reject, discard, quarantine, disconnect

</div>
<div>

**Outbound actions** continue, cancel, and per-recipient overrides

</div>
</div>

<p class="callout">Modifications are declarative and bounded by what the
registration permitted. An operator decides what a given service may change; the
protocol does not assume it may change everything.</p>

---

# The stages

<div class="rail">
  <div class="seg on"><div class="k">connect</div></div>
  <div class="seg on"><div class="k">ehlo</div></div>
  <div class="seg on"><div class="k">mail</div></div>
  <div class="seg on"><div class="k">rcpt</div></div>
  <div class="seg on"><div class="k">data</div></div>
  <div class="seg on"><div class="k">route</div></div>
  <div class="seg on"><div class="k">delivery</div></div>
  <div class="seg on"><div class="k">defer</div></div>
  <div class="seg on"><div class="k">dsn</div></div>
</div>

<div class="band" style="grid-template-columns: 5fr 4fr;">
  <span class="yes">Receiving the message</span>
  <span class="yes">Delivering it, and reporting on it</span>
</div>

<div class="cols dense" style="margin-top: 1.2rem;">
<div>

- `route` fires before the next hop is resolved, per delivery job, and may route
  per recipient. The server splits the job accordingly
- `delivery` and `defer` report the real response from the real next hop, per
  recipient, per attempt, including the TLS outcome

</div>
<div>

- `dsn` fires before a notification is sent, and may modify or suppress it
- Everything stays under one queue identity, so one message is one story rather
  than a set of records to be stitched together afterwards

</div>
</div>

---

# Mapping back

| The problem | What answers it |
|---|---|
| Signature must match the delivery transaction | `route` fires after the job is split, per recipient, with per-recipient content |
| Notifications cannot be signed or redirected | `dsn` fires before the notification is sent, and may modify or suppress it |
| Nothing after acceptance | `route`, `delivery`, `defer` and `dsn` are stages in the same protocol |
| Context by macro, silently absent | Discovery and registration: a declared, negotiated contract |
| A new field costs a core patch | A reverse-domain extension namespace, negotiated bilaterally, ignored if unknown |
| One message, one body | Per-recipient variants at delivery time, without re-injection |
| No provenance between filters | The server orchestrates the chain and holds the authorship |
| Operators cannot write filters | An HTTP endpoint that accepts JSON and returns JSON |

---

# Status and open questions

<div class="cols col-3-2">
<div>

### Implementations
- **Stalwart**: complete, in production
- **Rspamd**: intent to implement stated
- **Haraka**: offered on the list
- Independent scanner implementations already on GitHub, written by people who
  are not the draft authors

### Support without a commitment
Heinlein Group, Beonex, KTP Digital, the SAKE project

</div>
<div>

### Open, and for a working group to decide
- How far routing delegation should go, and what bounds an operator sets
- Failure semantics: when to hold mail, when to let it pass
- Correlation across servers in a distributed deployment
- What belongs in the protocol and what belongs in deployment guidance

</div>
</div>

---
layout: default
---

<div class="divider">
  <div class="num">03</div>
  <div>
    <p class="title">Over to the room</p>
    <p class="sub">Is this a problem the IETF should take on, and are there enough
    of us to do the work?</p>
  </div>
</div>
