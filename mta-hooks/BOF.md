# Name: MTA Hooks (MTAHOOKS)
## Description

Email filtering is critical infrastructure for the modern internet. Spam filtering, virus scanning, policy enforcement, and compliance monitoring all depend on the ability of a Mail Transfer Agent (MTA) to delegate processing decisions to external services at well-defined points during mail reception and delivery. Despite the importance of this capability, there is currently no formal, open standard governing how MTAs communicate with such filtering services.

The de facto solution today is the Milter protocol, originally developed for Sendmail around the year 2000. Milter has no formal specification; it exists only as a C library (`libmilter`) with undocumented wire semantics. Its binary framing protocol is cumbersome to implement in modern programming languages, and its behavior differs meaningfully between the two MTAs that support it (Sendmail and Postfix). Milter also has no concept of outbound delivery hooks, limiting its applicability to inbound mail reception only. Despite these shortcomings, widely deployed open-source filters such as Rspamd, ClamAV, and SpamAssassin rely on Milter as their only standardized integration path, and they do so over an undocumented, proprietary protocol. The internet's email filtering infrastructure, which handles billions of messages per day, is built on a foundation with no open standard.

MTA Hooks proposes a modern, standardized replacement. The protocol uses HTTP POST requests from the MTA to registered scanner endpoints at each SMTP processing stage (connect, ehlo, mail, rcpt, data for inbound; delivery, defer, and DSN for outbound). Scanners receive full message context (envelope, parsed message structure, authentication results, and TLS information) and respond with JSON Pointer patches (RFC 6901) that specify actions and modifications. The protocol supports both JSON and CBOR serialization, builds on JMAP message representations (RFC 8620 / RFC 8621), and includes a capability negotiation mechanism via discovery and registration. Because it is built on HTTP, it integrates naturally with existing operational infrastructure: load balancers, reverse proxies, authentication middleware, and observability tooling all work without modification.

MTA Hooks has already demonstrated real-world viability. It is implemented and in production in the Stalwart Mail Server, where it is actively used in thousands of deployments worldwide (https://stalw.art/docs/api/mta-hooks/overview). Rspamd, the most widely deployed open-source mail filtering system, has expressed intent to implement MTA Hooks support. Heinlein Consulting GmbH, a major European email hosting provider and long-standing contributor to the email ecosystem, is actively involved in the proposal. The draft was first presented at the MAILMAINT session at IETF 123 (Madrid), then at the DISPATCH session at IETF 125, where the discussion resulted in a recommendation to proceed with a BOF. Between 6 and 10 people at IETF 123 and FOSDEM 2026 expressed interest in participating in a Working Group. Feedback gathered from those early discussions has already been incorporated into the current draft, including support for both raw and parsed message representations, CBOR serialization, and the JSON Pointer modification model.

We propose a BOF to assess community interest and initiate the formation of a focused Working Group to standardize an HTTP-based protocol for MTA-to-filter communication.

## Required Details
- Status: WG Forming
- Responsible AD: Applications and Real-Time (ART) Area
- BOF proponents: Mauro De Gennaro <mauro@stalw.art>, Bron Gondwana <brong@fastmailteam.com>, Arnt Gulbrandsen <arnt@gulbrandsen.priv.no>, Manu Zurmühl <m.zurmuehl@heinlein-support.de>, Carsten Rosenberg <c.rosenberg@heinlein-support.de>
- Number of people expected to attend: 80
- Length of session (1 or usually 2 hours): 2 hours
- Conflicts (whole Areas and/or WGs)
   - Chair Conflicts: TBD
   - Technology Overlap: MAILMAINT, DISPATCH, LAMPS, DMARC
   - Key Participant Conflict: TBD

## Information for IAB/IESG
To allow evaluation of your proposal, please include the following items:

- Any protocols or practices that already exist in this space:
  The Milter protocol (originating from Sendmail, circa 2000) is the dominant existing mechanism. It has no formal specification; it is documented only through a C library (`libmilter`). Postfix implements a partial and behaviorally divergent version. Some MTAs (e.g., Exim) have proprietary filter hook mechanisms, none of which are interoperable. No existing IETF or other standards-body specification addresses MTA-to-filter communication.

- Which (if any) modifications to existing protocols or practices are required:
  None. MTA Hooks is designed as an opt-in capability layered on top of existing SMTP infrastructure. Existing MTAs and filters may continue to operate as before; adoption of MTA Hooks is entirely additive.

- Which (if any) entirely new protocols or practices are required:
  A new protocol specification is required: the MTA Hooks protocol itself, as described in draft-degennaro-mta-hooks-00. The protocol defines a discovery mechanism, a registration procedure, and a hook invocation request/response format. All underlying technologies (HTTP, JSON, CBOR, JSON Pointer, JMAP) are already standardized.

- Open source projects (if any) implementing this work:
  - Stalwart Mail Server: full implementation in production (https://stalw.art/docs/api/mta-hooks/overview)
  - Rspamd: implementation planned
  - Multiple third-party scanner implementations available on GitHub

## Agenda
   - Welcome, agenda, and Note Well - 5 minutes
   - Problem statement: the state of MTA filtering and the limitations of Milter - 15 minutes (Mauro De Gennaro)
   - Protocol overview: MTA Hooks design, architecture, and wire format - 20 minutes (Mauro De Gennaro)
   - Implementation experience: Stalwart Mail Server deployment report - 10 minutes (Mauro De Gennaro)
   - Operator and community perspective: Heinlein Consulting - 10 minutes (Manu Zurmühl / Carsten Rosenberg)
   - Open issues and design discussion - 25 minutes (all)
   - Draft charter discussion and scope - 20 minutes (chairs / proponents)
   - Consensus assessment and next steps - 15 minutes (chairs)

## Links to the mailing list, draft charter if any (for WG-forming BoF), relevant Internet-Drafts, etc.
   - Mailing List: TBD
   - Draft charter: TBD
   - Relevant Internet-Drafts:
      - https://datatracker.ietf.org/doc/html/draft-degennaro-mta-hooks-00
   - Dispatch presentation slides (IETF 125):
      - https://datatracker.ietf.org/doc/slides-125-dispatch-mta-hooks-presentation/
