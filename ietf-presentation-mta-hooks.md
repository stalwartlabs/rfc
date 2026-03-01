---
marp: true
theme: default
paginate: true
backgroundColor: #fff
color: #333
style: |
  section {
    font-family: 'Helvetica Neue', Arial, sans-serif;
    font-size: 24px;
    padding: 20px 40px;
  }
  h1 {
    color: #DB2D54;
    font-size: 1.5em;
    margin-top: 0.1em;
    margin-bottom: 0.2em;
  }
  h2 {
    color: #DB2D54;
    font-size: 1.15em;
    margin-top: 0.1em;
    margin-bottom: 0.2em;
  }
  h3 {
    font-size: 1.05em;
  }
  a {
    color: #DB2D54;
  }
  section.title {
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  section.title h1 {
    font-size: 1.9em;
  }
  section.title p {
    font-size: 0.65em;
    color: #666;
  }
  section.outcome {
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  section.outcome h1 {
    font-size: 1.5em;
  }
  ul {
    font-size: 0.82em;
    margin-top: 0.1em;
    margin-bottom: 0.1em;
  }
  ul ul {
    font-size: 0.88em;
  }
  li {
    margin-bottom: 0.1em;
  }
  p {
    margin-top: 0.2em;
    margin-bottom: 0.2em;
  }
  code {
    font-size: 0.78em;
  }
  pre {
    font-size: 0.72em;
    margin-top: 0.3em;
    margin-bottom: 0.3em;
  }
  table {
    font-size: 0.72em;
  }
  .columns {
    display: flex;
    gap: 1.2em;
  }
  .columns > div {
    flex: 1;
  }
---

<!-- _class: title -->

# MTA Hooks
## An HTTP-Based Mail Processing Protocol

**draft-degennaro-mta-hooks-00**: IETF 125 DISPATCH
Mauro De Gennaro: Stalwart Labs LLC

---

# Why This Work Matters

Mail filtering is critical infrastructure: spam filtering, virus scanning, policy enforcement: yet **there is no standard protocol** for MTA-to-filter communication.

- **Milter** (Sendmail, ~2000) is the de facto solution but:
  - No formal specification: only a C library (`libmilter`)
  - Proprietary binary wire format, painful to implement in modern languages
  - Inconsistent behavior across MTAs (Sendmail vs. Postfix)
  - No support for outbound delivery hooks
  - Not adopted by modern MTAs

- Filters like **Rspamd, ClamAV, SpamAssassin** all rely on Milter over the network today: on an undocumented protocol

**MTA Hooks** proposes a standardized, HTTP-based replacement that is simple to implement, language-agnostic, and covers both inbound and outbound mail processing.

---

# Protocol Overview

MTA Hooks uses **HTTP POST** requests from the MTA to registered scanner endpoints at each SMTP processing stage. Scanners respond with **JSON Pointer patches** to modify the message transaction.

<div class="columns">
<div>

**Key Design Choices**
- Built on **HTTP**: works with existing infrastructure (load balancers, proxies, monitoring)
- **JSON** and **CBOR** serialization
- Message representation based on **JMAP** (RFC 8620 / RFC 8621)
- Modifications via **JSON Pointer** (RFC 6901) set/add/delete ops
- Capability negotiation via discovery & registration

</div>
<div>

**Inbound Stages** (reception)
`connect → ehlo → mail → rcpt → data`

**Outbound Stages** (delivery)
`delivery → defer → dsn`

**Actions**: accept, reject, discard, quarantine, disconnect (inbound) / continue, cancel (outbound)

</div>
</div>

---

# How It Works: Simple Model

```
MTA                                 Scanner
 │  POST /hooks/scan                │
 │  { "stage": "data",              │
 │    "action": "accept",           │
 │    "envelope": {...},            │
 │    "message": {...},             │
 │    "senderAuth": {...} }         │
 │ ──────────────────────────────►  │
 │                                  │  ← Analyze message
 │  { "set": [                      │
 │      {"path":"/action",          │
 │       "value":"reject"},         │
 │      {"path":"/response",        │
 │       "value":{"code":550,...}}  │
 │    ] }                           │
 │ ◄──────────────────────────────  │
```

- Scanner receives full context (envelope, parsed message, auth results, TLS info)
- Responds with **patches**: no need to echo back the entire message
- Multiple scanners chain sequentially; terminal actions stop the chain
- Both structured (`message`) and raw (`rawMessage`) representations supported

---

# Prior Work & Community Interest

| | |
|---|---|
| **Draft** | [draft-degennaro-mta-hooks-00](https://datatracker.ietf.org/doc/html/draft-degennaro-mta-hooks-00) |
| **Presented** | IETF 123 (Madrid): MAILMAINT session |
| **Discussed** | FOSDEM 2026 |
| **Implementation** | [Stalwart Mail Server](https://stalw.art): in production |
| **3rd-party scanners** | Multiple scanner implementations on GitHub |
| **Rspamd** | Plans to implement MTA Hooks support |
| **Interest** | 6–10 people expressed interest at IETF 123 and FOSDEM in participating in a WG |

Feedback from IETF 123 and FOSDEM has already shaped the current draft: including support for both raw and parsed message formats, CBOR serialization, and the JSON Pointer modification model.

---

<!-- _class: outcome -->

# Hoped Dispatching Outcome

We believe there is sufficient interest and a clear gap to fill.

We ask DISPATCH to consider:

### ➊ Propose a new focused Working Group
or
### ➋ Hold a full BOF at a future IETF meeting

to advance standardization of an HTTP-based MTA filtering protocol.

**Questions? Feedback?**
Mauro De Gennaro: mauro@stalw.art: https://stalw.art