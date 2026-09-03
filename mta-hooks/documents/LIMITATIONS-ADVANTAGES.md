# Milter Limitations and MTA Hooks Selling Points

Working material for the MTA Hooks BoF. Source for the BoF request, the charter
and the presentation.

**Framing note.** Earlier presentations led with "Milter is binary and has no
libraries outside C". That invites the obvious answer: "then write down the
Milter wire format and be done". This document deliberately avoids that framing.
The argument here is that Milter is *structurally* incapable of carrying a large
and growing class of mail processing requirements, that today those requirements
are met by a conglomerate of unrelated ad-hoc interfaces, and that DKIM2, an
active IETF work item, cannot be implemented over Milter at all. Serialization is a
consequence, not the case.

That said, "HTTP is ubiquitous" is a real selling point and stays in, at section
11, argued through the constituency that actually asked for it: MTA *operators*
writing small site-specific filters, not filter vendors. The distinction matters.
"Milter is binary" invites "so write the format down". "The people who need to
write filters cannot write Milters, and a spec would not change that" does not.

**Baseline.** Claims marked **[-02]** are extension proposals not yet in the
published `draft-degennaro-mta-hooks-01`. Everything unmarked is specified in -01
and implemented in Stalwart today.

---

## 1. Milter stops at acceptance

This is the single largest structural gap, and it is not fixable by writing down
the Milter wire format.

Milter has callbacks for connect, helo, envfrom, envrcpt, header, body and eom.
It has nothing after that. The moment the MTA answers `250 Ok` to the final dot,
the filter is out of the picture for the remaining lifetime of the message:
routing, transport selection, TLS negotiation with the next hop, per-recipient
delivery outcome, retry scheduling, DSN generation. A Milter never learns whether
the message it accepted was delivered.

| Question a filter cannot ask over Milter |
|---|
| Which transport and next hop will this recipient take? |
| Which source IP and TLS policy will be used for this delivery? |
| Did recipient B get it, and with what SMTP response from which MX? |
| This has been deferred five times against Outlook: should I reroute? |
| A DSN is about to be generated: may I modify, suppress or sign it? |

What exists in Postfix are two narrow workarounds, and naming them is what
makes the point land:

- **Routing**, indirectly: a Milter sets a header, and `milter_header_checks`
  translates it via `FILTER transport:nexthop` or `REDIRECT`. No recipient
  granularity, no retry context, no source IP or TLS control, and the routing
  decision has to be smuggled through the message body.
- **Delivery status**, indirectly: `smtp_delivery_status_filter` runs the remote
  SMTP response through a pcre lookup before Postfix classifies it, so a broken
  5xx can be bent into a 4xx. It is a regexp on a string, not a callout: no queue
  ID, no structured recipient or remote object, no attempt counter, no event to
  an external service.
- **TLS results**: `libtlsrpt` (Postfix 3.10) exports a per-handshake datagram to
  a collector. A dedicated TLSRPT-only side channel with its own
  collector/fetcher/generator chain, seeing only handshake success or failure,
  never connect failures or aborts, at most one final status per connection.

Three different mechanisms, none of them a filter interface, none correlated
with each other or with the inbound scan.

**MTA Hooks:** `delivery`, `defer` and `dsn` are stages in the same protocol as
`connect` through `data`, under the same queue ID, with the same registration and
negotiation. **[-02]** adds a `route` stage before MX resolution with
per-recipient routing, job splitting, retry-aware failover and source IP or pool
selection, plus `tls_level` / `tls_result` / `tls_failure_reason` per attempt in
the delivery result, which makes the delivery hook a strictly better TLSRPT data
source than libtlsrpt.

### Answering "that is an implementation gap, not a protocol gap"

The objection to expect is that Milter *could* be used for outbound processing
just as easily and simply is not. It does not survive contact with the shape of
the protocol.

Milter's entire response vocabulary is SMTP transaction verdicts: `SMFIR_ACCEPT`,
`SMFIR_REJECT`, `SMFIR_TEMPFAIL`, `SMFIR_DISCARD`, `SMFIR_REPLYCODE`, plus the
eom modification actions. Every one of them answers a single question: what do I
say to the client that is waiting on this command. Delivery is a different shape
in four ways at once.

- It happens **after** the SMTP transaction is over, so there is no waiting client
  and no reply code to send.
- It is **per recipient**, while Milter's modification model addresses one
  message.
- It is **repeated**, once per attempt across hours or days, so a verdict is
  meaningless without an attempt counter and the last response.
- The things a filter needs to say back (route this recipient via that next hop,
  retry at this time, suppress this DSN, use that source IP) have no verbs at
  all.

So "use Milter for outbound" means adding callbacks, adding macros for the
delivery context, defining per-recipient result structures, and inventing a
response vocabulary that does not exist. That is designing a new protocol and
calling it Milter, and every field added along the way pays the extensibility
cost in section 2: a core patch per MTA plus an ecosystem-wide macro rollout.

The empty cells are not an accident of what implementers got around to. Twenty
five years and two implementations produced none of it, because the protocol has
nowhere to put it.

---

## 2. Extensibility: a new datum costs an MTA core patch

The strongest single argument, because it is about the protocol's shape rather
than any one feature. The question is not "can Milter carry datum X" but "what
does it cost to introduce datum X at all".

Milter's only channel for extra context is **macros**: a hard-wired vocabulary
the MTA core must know. Adding one new piece of information requires:

1. a patch to the MTA core,
2. new macro names,
3. a documentation update (`MILTER_README`),
4. and every Milter author in the ecosystem learning the new macro names and
   requesting them explicitly, or they never see them.

**This is happening right now.** postfix-devel, August 2026, "Trusted origin
evidence for locally generated DSNs" (Christian Rößner, author of Nauthilus and
the experimental `dkim2d`, with Wietse Venema). The requirement: a DKIM2 signer
must be able to *trust* that a DSN really came from the local `bounce(8)`, since
the null sender and the RFC 3464 body are forgeable. The cost of transmitting
that one boolean-plus-envelope: a Postfix core patch (bounce(8) passes validated
origin evidence through a private cleanup record; cleanup(8) accepts it only on
the internal bounce code path), two new macros
(`{postfix_dsn_evidence}`, `{postfix_dsn_original_envelope}`), a MILTER_README
update, and an ecosystem-wide knowledge rollout.

**MTA Hooks:** the `/ext` reverse-domain namespace plus `fetchProperties`
negotiation. The MTA offers `/ext/org.postfix.dsnEvidence`, a scanner orders it
during registration, unknown namespaces are ignored. No protocol change, no wire
format change, no central registry anyone has to know about; the MTA author and
the scanner author agree bilaterally and the rest of the ecosystem is untouched.
And in this specific case the datum is not even needed: the `dsn` stage fires
MTA-side by definition, so **[-02]** `source: "mta"` answers the provenance
question structurally.

---

## 3. Context arrives by configuration, and silently does not

Every piece of context a Milter sees (client IP, PTR, TLS parameters, SASL
identity, daemon address) must be exported by the administrator through
`milter_connect_macros`, `milter_helo_macros`, `milter_mail_macros`,
`milter_rcpt_macros`, `milter_data_macros`, `milter_end_of_data_macros`. The
default sets are lean. A forgotten macro does not produce an error: the field is
simply absent, and the filter cannot distinguish "not configured" from "not
available".

There is no negotiation. A scanner cannot ask for what it needs, cannot discover
what the MTA can provide, and cannot fail loudly when a required input is
missing.

**MTA Hooks:** discovery advertises the available property set; registration
orders a subset via `fetchProperties`; the response is a declared, negotiated
contract. What is not advertised is known to be unavailable, so the scanner can
adapt (compute it itself) or refuse to start.

---

## 4. Authentication results are not supplied

Milter has no concept of SPF, DKIM, DMARC or ARC results. A filter either
recomputes them itself, duplicating work the MTA may already have done, or parses
`Authentication-Results` headers whose trust boundary it has to establish on its
own.

**MTA Hooks:** `senderAuth` is a structured, first-class property supplied by the
MTA, with the trust boundary on the MTA side where it belongs.

---

## 5. Incremental callbacks, and no way to ask for one aggregated call

Milter delivers headers one at a time and the body in chunks. Every filter that
wants to reason about the whole message has to buffer it, parse MIME itself, and
stitch the connection-level context back together via `smfi_setpriv`.

`SMFIP_NO*` negotiation flags let a filter *unsubscribe* from callbacks, but the
data of the skipped phases is then simply never delivered. There is no "call me
once at eom with everything you gathered".

**This costs real work in the field.** Rspamd's Milter frontend in the proxy
worker takes every callback (connect, helo, envfrom, envrcpt, each header, each
body chunk), holds them in the connection context, and reconstructs the complete
message plus metadata at eom in order to make one HTTP call to the Rspamd
scanner. The most widely deployed open source mail filter maintains a
Milter-to-aggregated-HTTP-call adapter, because that is the shape it actually
wants.

**MTA Hooks:** a scanner registers only for `data` and receives one call with the
cumulative context (connect, ehlo, mail, rcpt, TLS, auth, senderAuth) plus the
message, as a parsed JMAP object and/or `rawMessage`. The skipping is real: the
earlier stages generate no round trip for that scanner. Aggregation is a protocol
feature, not something each scanner rebuilds.

---

## 6. No chain provenance: who decided this?

A Milter cannot, in principle, know what another Milter did. Each runs as its own
process and sees only its own actions. The only channel between filters is a
self-set header, which is unstructured, forgeable, and becomes part of the
delivered mail. "The previous filter quarantined this, and here is why" is
inexpressible.

**MTA Hooks:** the MTA orchestrates the chain centrally and holds the authorship.
**[-02]** stable hook identifiers plus action and modification provenance plus
`scannerContext` as a structured inter-hook channel replace "scanner writes an
X-header, next scanner parses it" outright.

---

## 7. Milter is a filter, not a protocol interface

Milter fires on the message-bearing commands. Everything else about the SMTP
conversation is invisible, and much of it is exactly what reputation and bot
detection need:

| Signal | Milter | MTA Hooks |
|---|---|---|
| RSET, NOOP, VRFY, syntax errors, rejected commands | invisible | **[-02]** `session` counters |
| Session duration, inter-command gaps (bot timing) | invisible | **[-02]** `session` timing |
| Pregreet / early talker | invisible | **[-02]**, incl. provoking it via connect delay |
| Pipelining violations | invisible | **[-02]** |
| FCrDNS status | filter must resolve it itself | **[-02]** |
| ESMTP parameters (SIZE, REQUIRETLS, DSN, AUTH=) | partial | **[-02]** structured |
| Client DSN usage (NOTIFY, ORCPT, ENVID, RET) | invisible | **[-02]** |
| TLS client cert | only if verification succeeded | **[-02]** incl. unverified |
| TLS fingerprint | MD5 (Sendmail) or nothing (Postfix) | **[-02]** SHA-256 |
| JA3 / JA4 | never | **[-02]** |
| Time budget for this callback | never | **[-02]** `timeoutMs` |
| Proxy metadata (PROXY protocol, XCLIENT, XFORWARD) | not distinguishable | **[-02]** explicit |

Two further blind spots deserve their own line:

- **Alias resolution is invisible.** The smtpd Milter runs *before* `cleanup`,
  where `canonical` and `virtual_alias` rewriting happens. The filter never sees
  the address the message is actually going to. **[-02]** carries `original` and
  `resolved` per recipient.
- **Per-recipient outcome.** The cumulative recipient list carries no per-address
  verdict. **[-02]** puts the outcome in `envelope.to`.

---

## 8. Milter and per-recipient content are mutually exclusive

Milter modifies *the* message: one body, one header set, one queue entry. It has
no way to say "recipient A gets this body, recipients B and C get that one".

Today that requirement is met with a `content_filter` loop: accept, hand off over
SMTP to a gateway, re-inject. The costs are structural:

- double queue pass per message,
- new queue ID and often a new Message-ID on re-injection, so correlation across
  the operation requires log stitching,
- one re-injection per recipient group, so a single transaction to five
  recipients with three treatments becomes a tree nobody can see as one
  operation,
- two policy points that must be kept consistent (TLS decision in transport
  tables, content crypto decision in the filter config), with guaranteed drift,
- ordering (scan before encrypt, sign after encrypt) wired implicitly through
  filter instance ordering and re-injection ports.

**MTA Hooks [-02]:** message variants at the `route` stage. The scanner returns a
per-recipient body alongside the per-recipient route; the MTA splits into
equivalence classes of (route tuple, variant hash) and delivers each in its own
SMTP transaction. The original stays canonical in the queue, variants reference
it via `variantOf`, and `delivery` / `defer` / `dsn` all still fire under the
original queue ID.

```json
[
  { "op": "add", "path": "/envelope/to/0/route",
    "value": { "queue": "tls-mandatory" } },
  { "op": "add", "path": "/envelope/to/1/route",
    "value": { "queue": "partner-a" } },
  { "op": "add", "path": "/envelope/to/1/rawMessage",
    "value": "<S/MIME variant for partner A>" }
]
```

Transport path and content form become one decision, per recipient, in one place,
within one queue identity.

---

## 9. Worked case: DKIM2 cannot be implemented over Milter

This section answers one specific challenge: the claim that DKIM2 can be done in
a single Milter. `draft-ietf-dkim-dkim2-spec-04` is the clearest available
demonstration that the Milter interface is not merely dated but insufficient for
current IETF work. Three independent requirements fail against it, and they fail
for three different reasons, so consolidating logic into one filter does not
recover any of them.

### 9.1 The `rt=` tag leaks BCC recipients

Section 8.6 requires the signature to record the RFC 5321 RCPT TO values actually
used in the SMTP transaction, and states:

> if 'bcc:' recipients are involved then in order to meet the requirements of
> [RFC5322] Section 3.6.3 each and every bcc recipients MUST NOT be revealed to
> any other message recipient.

Correctly, this needs either per-recipient copies or careful control over which
recipients share a transaction, with a signature computed per copy.

A Milter signs at `cleanup`, on one queued message, before `qmgr` splits the
recipients across transports and next hops. At that moment the filter cannot know
which recipients will share an SMTP transaction. It has exactly two options, both
wrong:

- enumerate every recipient in `rt=`, which leaks the BCC list to all of them, or
- guess, and produce a signature whose `rt=` does not match the transaction.

There is no third option, because per-recipient message variants and
sign-at-delivery are what Milter cannot express (section 8 above).

Why one Milter does not fix this: the obstacle is not that
the signing logic is spread across several filters. It is that the information
needed to sign correctly does not exist yet at the only moment a filter runs. At
`cleanup` time the recipient set has not been split. The split happens later, in
`qmgr`, where no Milter runs at all. A filter cannot consolidate its way to data
the MTA has not computed yet.

MTA Hooks with `route` + variants gives per-transaction signing over the bytes
that are actually transmitted.

### 9.2 Outbound DSNs cannot be generated correctly

Section 12.1.4 requires the DSN itself to carry Message-Instance and
DKIM2-Signature fields (with a null MAIL FROM), and section 12.2 requires:

> A DSN MUST be addressed to the MTA that sent the message. This prevents
> 'backscatter' by passing failures back along the chain of MTAs that were
> involved in passing the message forwards. This is achieved by using the mf= tag
> from the highest numbered DKIM2-Signature field.

That is a hook *at DSN generation time*, with access to the original message's
signature chain, and with authority over the DSN's envelope recipient (which is
no longer the original return path).

Postfix `bounce(8)` offers no such point. The nearest approximation,
`internal_mail_filter_classes = bounce` plus `non_smtpd_milters`, sees the DSN
only *after* generation, on the cleanup path, acts globally on all bounces, and
is documented as a risky expert setting because a rejecting Milter loses bounces
outright. Sendmail has no equivalent at all.

### 9.3 Inbound DSN forwarding cannot be expressed

Section 12.1.1.1: a Forwarder receiving a DSN MAY propagate it to the MAIL FROM
address it was itself delivered under, after verifying the embedded message's
header hashes against the highest numbered Message-Instance field (12.1.2).

Operationally that means: recognize an inbound DSN, validate the embedded chain,
correlate it to forwarding state held by this hop, and emit a *new*, re-signed
DSN addressed to the previous hop. A Milter at inbound DATA can add headers and
recipients to the message in front of it; it cannot consume a message and cause
the MTA to originate a differently addressed, freshly signed one, and it has no
view of the delivery-side state the correlation needs.

### 9.4 The workaround already exists, and it is MTA Hooks by hand

`github.com/croessner/dkim2` (experimental, PoC-style) is built exactly the way
the argument predicts: a central HTTP/JSON daemon (`dkim2d`, OpenAPI, holding the
DKIM2 logic in a standalone library) with a **separate transport adapter per
MTA** in front of it: `dkim2-milter` (Milter v6 over a Unix socket, for Postfix)
and `dkim2-exim` (`local_scan()` plus transport filter). Each adapter gathers
MTA-specific envelope evidence, calls `dkim2d` over loopback HTTP "with route
capability", validates the response against the OpenAPI model, and applies the
"admitted action plan".

Read that back: `dkim2d` *is* an MTA Hooks scanner. The adapters are the missing
standardization, rebuilt twice from whatever each MTA happened to offer, and the
DSN provenance piece still needed a Postfix core patch (section 2).

---

## 10. Multi-host MTAs: you cannot hook what one host never saw

Raised on the mtahooks list and still open, so it should be answered on a slide
before it is raised from the floor.

Production MTAs are routinely spread across several hosts: one machine receives,
another expands addresses and decides to forward, a third performs outbound
delivery, and mail still undelivered after an hour is commonly shunted to a
separate host that keeps retrying for a week.

For Milter this is less a limitation than a boundary it never approached. A
Milter is bound to one `smtpd` process, on one host, for one SMTP connection. It
sees reception and nothing else, under any architecture. From the host that is
now delivering the message, the question "what did the receiving host know about
this" cannot be asked at all.

MTA Hooks makes the question askable. The answer is partial, and claiming more
than this invites an easy rebuttal:

- **Within one host**, the outbound stages already carry the message context
  forward: a `delivery` hook sees what the `data` hook saw, under the same queue
  ID.
- **Across hosts**, **[-02]** proposes a `transaction.id` (UUIDv7) that survives
  internal handoff, propagated by ESMTP parameter or header with a defined trust
  boundary, plus queue ID guarantees and `previousId` so a handed-off or
  re-injected message stays linked to its predecessor.
- **What a correlation ID does not solve** is the case where the delivering host
  needs the receiving host's *data* and not merely its identifier. An ID lets you
  join two records; it does not move a record. Closing that gap means either
  propagating context along with the handoff or giving scanners a way to fetch
  it, and the specification should say which.

That last bullet is an open design question for the WG, and the charter's
scope discussion is where it belongs. The narrower claim is what goes on the
slide, and it holds: distributed deployments are the normal case in production,
Milter has no story for them whatsoever, and MTA Hooks is the only proposal on
the table where the question can even be posed.

---

## 11. MTA Hooks replaces more than Milter

The "then standardize Milter" answer assumes Milter is the only thing in scope.
It is not. Everything below is a distinct, incompatible mechanism that operators
wire up today because no single interface covers the lifecycle, and each one
lands in the same place in MTA Hooks:

| Wired up today with | For | MTA Hooks equivalent |
|---|---|---|
| Milter | inbound scan and modification | inbound stages |
| `check_policy_service` | rich-context smtpd decisions | `connect` / `mail` / `rcpt` hooks |
| `tcp_table`, `socketmap`, SQL/LDAP maps | routing, recipient validation, TLS policy | **[-02]** `route` stage; `rcpt` hook |
| `content_filter` loop with re-injection | crypto gateways, DLP, heavy scanning | `data` hook; **[-02]** variants |
| `always_bcc` / BCC maps | archiving and journaling | `data` + `delivery` hooks, with proof of delivery |
| VERP, bounce mailboxes, log parsing | delivery and bounce feedback | `delivery` / `defer` / `dsn` hooks |
| `libtlsrpt` collector chain | TLSRPT (RFC 8460) | **[-02]** TLS fields in delivery results |
| `smtp_delivery_status_filter` pcre | bending delivery status | `delivery` hook |
| nginx mail proxy HTTP auth server | per-connection auth and routing | `connect` hook |

The last row is worth its own sentence at the BoF: nginx has been asking an
external HTTP service, per connection, whether and where to forward SMTP, IMAP
and POP3 for years (`Auth-Status`, `Auth-Server`, `Auth-Port`). "The MTA asks an
HTTP service" is not a novel or exotic idea in the mail world. MTA Hooks
generalizes an already accepted pattern from the connection and auth level to the
whole lifecycle.

Lookup tables deserve the same treatment: they delegate real decisions, but
through a keyhole. One key string in, one value out. No sender, no auth identity,
no queue ID, no attempt counter, no correlation, and only at the points the MTA
happened to provide.

---

## 12. Who actually writes filters, and what they asked for

Not the argument to lead with at the BoF, and it is placed last among the
technical sections on purpose. But it is the reason the protocol exists, and
dropping it loses a constituency that "just standardize Milter" does not serve at
all.

MTA Hooks did not originate with filter vendors. Rspamd, ClamAV and SpamAssassin
have already paid the Milter integration cost once and amortize it over their
entire user base; a written-down Milter specification changes very little for
them. The requests came from **operators**: people running an MTA who want to add
one site-specific rule.

A vocabulary note, because this distinction has already caused confusion. The
draft calls the hook-receiving side a **scanner**, and a scanner is obviously a
kind of filter. The split that matters is not scanner versus filter, it is
**filters that are standalone products** (Rspamd, SpamAssassin, ClamAV) versus
**filters written by the MTA's own operator** for one site. Both are scanners in
the draft's terminology. Only the second group is priced out by Milter.

Those filters are small and specific. Check the recipient against our CRM. Reject
senders the billing system flagged. Tag mail from a partner domain. Push an event
into our SIEM. Apply the disclaimer policy legal asked for. Ten to a hundred
lines of business logic, written in whatever language the rest of the shop
already uses.

What Milter asks of that person: link against `libmilter`, a C library, and write
callbacks in C. Or find a binding for their language, and hope it is maintained,
hope it handles protocol version negotiation correctly, and hope its semantics
match their own MTA and not Sendmail's. Bindings do exist (`pymilter` and
others). The informative datum is that people who had a binding available still
asked for HTTP.

**Stalwart supports Milter.** The MTA that went on to design MTA Hooks already
shipped a working Milter implementation, and its
users asked for an HTTP interface anyway. That is not a claim that binary
protocols are hard to implement. It is a revealed preference from people who had
both options in front of them.

What MTA Hooks asks: an HTTP endpoint that accepts JSON and returns JSON.

```
POST /hooks/scan
{ "stage": "rcpt", "envelope": {...}, "senderAuth": {...} }

200 OK
{ "set": [ { "path": "/action",   "value": "reject" },
           { "path": "/response", "value": { "code": 550, "message": "..." } } ] }
```

Every language ships that in its standard library or in the first framework
anyone learns. These consequences are why operators asked for it:

- **Nothing new to learn.** No wire format, no framing, no negotiation
  state machine. The skill is already in the building.
- **Debuggable.** A hook call can be reproduced with `curl`, replayed from a log,
  and read by a human. A binary framing protocol with undocumented semantics can
  be none of those things.
- **Operationally free.** TLS, authentication middleware, load balancers, health
  checks, rate limiting, retries, tracing and metrics are off-the-shelf, and none
  of them had to be specified in the draft.
- **Deployable anywhere.** The scanner does not have to run on the MTA host or
  share a Unix socket with it. Milter over TCP exists, but it puts an
  undocumented binary protocol on the network with no transport security story of
  its own.
- **Small specification, small implementations.** HTTP, JSON and CBOR, JSON
  Pointer (RFC 6901) and the JMAP message model (RFC 8620, RFC 8621) are all
  existing IETF work. The draft defines hook semantics and very little else.
  Modifications are patches against the request, so a scanner never echoes back a
  message it did not change.

Two related points from the same angle:

- **"Milter compatible" is not a testable claim.** Two MTAs implement Milter and
  they disagree: behaviour differs meaningfully between Sendmail and Postfix.
  With no specification there is nothing to conform to, so a filter is tested
  against implementations, never written against a document.
- **No modern MTA adopted it.** The generation after Postfix (Haraka, KumoMTA,
  Halon, Maddy, Mox, Stalwart) did not implement Milter. Every one of them has a
  plugin or scripting layer and speaks HTTP and JSON natively. Standardizing
  Milter would document a protocol that the MTAs written in the last decade
  already declined.

**The answer to "then just standardize Milter".** It would produce an accurate
description of a binary protocol from 2000 that still stops at acceptance, still
carries context by macro, still cannot express DKIM2, and that the operator with
a fifty-line rule still cannot practically use. The two implementations such a
document would serve, Postfix and Sendmail, are exactly the two that a
Milter-to-MTA-Hooks adapter already covers today.

---

## 13. Selling points, condensed

For the presentation and the charter, in the order they should be argued:

1. **Coverage of the whole lifecycle.** Accept, route, deliver, retry, DSN, in
   one protocol, under one queue ID. Milter and every out-of-process filter stop
   at acceptance. This is the standardization-worthy added value.
2. **Extensibility without a core patch.** `/ext` namespaces plus negotiation.
   Milter's answer to a new datum is an MTA core patch and an ecosystem rollout,
   as postfix-devel is demonstrating right now.
3. **Negotiated, declared context.** Discovery and `fetchProperties` instead of
   per-stage macro configuration that fails silently.
4. **The context an MTA already has, supplied structurally.** senderAuth
   (SPF/DKIM/DMARC/ARC), TLS details, resolved recipients, session and protocol
   signals. Not recomputed by every filter.
5. **Per-recipient decisions.** Routing, TLS policy, delivery status, and
   **[-02]** message variants, without the re-injection loop and its identity
   break.
6. **Correlation end to end.** Stable queue IDs, `previousId`, `variantOf`, and
   **[-02]** a UUIDv7 transaction ID that survives across hops, replacing VERP
   and log stitching.
7. **Central chain provenance.** The MTA holds the authorship; scanners talk to
   each other through a structured channel instead of X-headers in the mail.
8. **Consolidation.** One interface in place of Milter, policy delegation, lookup
   tables, content filter loops, BCC maps, VERP, log parsing and a TLSRPT side
   channel.
9. **A filter is an HTTP endpoint that takes JSON.** This is the reason the
   protocol was written (section 12). Operators, not filter vendors, asked for
   it: `libmilter` is a C library, bindings are second-hand, and people who had a
   binding still wanted HTTP. Say this as "the people who need to write filters
   cannot write Milters", not as "binary is old".
10. **It runs on infrastructure operators already have.** Load balancers, reverse
   proxies, auth middleware, health checks, retries, tracing and metrics work
   unchanged; a hook call can be reproduced with `curl`. The draft reuses HTTP,
   JSON, CBOR, JSON Pointer and JMAP, so it specifies hook semantics and little
   else.

---

## 14. Evidence to cite

- **Running code.** Full implementation in Stalwart, in production across
  thousands of deployments.
- **Declared intent.** On record as implementers: Stalwart
  (shipping), Rspamd (stated intent; its Milter frontend is already a
  Milter-to-aggregated-HTTP adapter, so the target shape is not speculative), and
  Haraka (offered on the list, August 2026). On record as supporters without an
  implementation commitment: Heinlein Group, Beonex, KTP Digital, the SAKE
  project. KumoMTA has declined for now, citing no customer demand. Do not round
  any of this up: the earlier BoF request was declined for insufficient
  demonstrated interest, and overstating it in the room is the fastest way to
  repeat that outcome.
- **Independent confirmation.** `dkim2d` builds the same architecture by hand
  because no standard exists (section 9.4). `zone-mta` advertises its own plugins
  as "more flexible than milters" and carries custom envelope properties into the
  delivery object, which is the in-process version of `scannerContext`. KumoMTA
  and commercial ESP MTAs have real outbound event infrastructure, all of it
  proprietary and per-product. The need is demonstrably real and is being met
  privately, over and over.
- **Migration path, no flag day.** Two adapters, one per direction: a
  Milter-to-MTA-Hooks adapter in front of unmodified Postfix and Sendmail, whose
  limits (no outbound, no routing) are themselves the argument for native
  support; and an MTA-Hooks-to-Milter gateway so modern MTAs keep using OpenDKIM
  and the rest of the existing scanner ecosystem unchanged.
- **Third-party scanners.** Multiple independent scanner implementations already
  on GitHub, written against -00 and -01 by people who are not protocol authors.
  That is the ubiquity argument from section 12 as a measurement, not a claim.
- **Process and interest.** Presented at MAILMAINT (IETF 123, Madrid), discussed
  at FOSDEM 2026, then DISPATCH (IETF 125), which recommended proceeding to a
  BoF. Between six and ten people at IETF 123 and FOSDEM expressed interest in
  participating in a Working Group. Feedback from those rounds is already in the
  draft: raw alongside parsed message representations, CBOR serialization, and
  the JSON Pointer modification model.
