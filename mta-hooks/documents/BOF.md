# Name: MTA Hooks (MTAHOOKS)

## Description

Mail Transfer Agents delegate processing decisions to external services: spam and virus filtering, policy enforcement, compliance capture, cryptographic signing and content transformation. The mechanisms that exist for this today, principally Milter, cover the reception of a message: the SMTP conversation from connection through the end of DATA.

The operations that occur after a message is accepted are covered by a different mechanism in every MTA, and usually by several unrelated ones at once. Transport selection goes through lookup tables that carry a single key and return a single value. Content transformation goes through a re-injection loop that gives the message a new identity halfway through its own delivery. Archiving goes through BCC maps with no return channel. Delivery feedback is reconstructed from VERP addressing, bounce mailboxes and log parsing. TLS reporting has a purpose-built side channel of its own. None of these is an IETF specification, none is portable between MTAs, and none is correlated with the others or with the decisions taken during reception.

A filter author cannot write one component that follows a message through its lifetime. Every deployment is a different assembly of mechanisms, and the resulting integration is the least portable part of running a mail system. Requirements now arriving from IETF work cannot be met at all. DKIM2 (draft-ietf-dkim-dkim2-spec) requires a signature over the recipient set of each individual SMTP transaction, which means the signature must be computed once the delivery job has been split and not before, and it requires delivery status notifications to be signed and addressed back along the chain that carried the message. Neither is expressible through an interface that ends when a message is accepted.

There is also a constituency that is easy to overlook. Standalone filter products (Rspamd, SpamAssassin, ClamAV) have paid their integration cost once and amortise it across their user base. The people who ask for a different interface are operators writing one site-specific filter: check the recipient against our directory, apply the footer policy legal asked for, push an event into our SIEM. The clearest evidence comes from the reference implementation of MTA Hooks, which ships Milter support: its users asked for an HTTP interface anyway.

MTA Hooks proposes an HTTP-based protocol covering the whole lifetime of a message. The MTA POSTs to registered scanner endpoints at each processing stage, inbound (connect, ehlo, mail, rcpt, data) and outbound (routing, delivery, deferral, DSN). Scanners receive negotiated context (envelope, message, authentication results, TLS and connection information) and respond with JSON Pointer patches specifying actions and modifications. It builds on HTTP, JSON and CBOR, JSON Pointer (RFC 6901) and the JMAP message model (RFC 8620, RFC 8621), so it specifies hook semantics and little else, and deployments reuse authentication, load balancing and observability infrastructure they already run.

We propose a BOF to test whether the community agrees this problem is real, correctly scoped and worth solving, and to form a Working Group to solve it.

## Required Details

- Status: WG Forming
- Responsible AD: TBD (Applications and Real-Time area)
- BOF chairs: TBD
- BOF proponents: Mauro De Gennaro <mauro@stalw.art>, Bron Gondwana <brong@fastmailteam.com>, Arnt Gulbrandsen <arnt@gulbrandsen.priv.no>, Manu Zurmühl <m.zurmuehl@heinlein-support.de>, Carsten Rosenberg <c.rosenberg@heinlein-support.de>
- Number of people expected to attend: 50
- Length of session: 2 hours
- Conflicts (whole Areas and/or WGs)
   - Chair Conflicts: TBD
   - Technology Overlap: DKIM, MAILMAINT, DISPATCH, DMARC, LAMPS
   - Key Participant Conflict: TBD

## Information for IAB/IESG

- Any protocols or practices that already exist in this space:

  Milter, originating with Sendmail around 2000, is the dominant mechanism for filtering during message reception. It is a de facto standard with a broad deployed base, and it is not specified by the IETF or by any other standards body. Its reach is message reception; the stages after acceptance are covered per MTA by the unrelated mechanisms described above. Some MTAs have proprietary hook mechanisms of their own (Exim ACLs and local_scan, Haraka plugins, KumoMTA Lua policy, the OpenSMTPD filter API), none interoperable with any other. Only the ESP-oriented MTAs have delivery-time event infrastructure, and it is per-product. No IETF specification addresses MTA-to-filter communication at any stage.

- Which (if any) modifications to existing protocols or practices are required:

  None. MTA Hooks is an opt-in capability layered on existing SMTP infrastructure. Existing MTAs and filters continue to operate unchanged; adoption is additive and incremental, with capability negotiation as the mechanism by which a scanner discovers which stages a given MTA implements.

- Which (if any) entirely new protocols or practices are required:

  The MTA Hooks protocol itself, as described in draft-degennaro-mta-hooks. All underlying technologies are already standardised.

- Migration and coexistence:

  Adoption does not require a flag day, and the proponents do not assume that MTAs with large Milter deployments will replace it. Two gateways are possible and are expected to be built outside this WG: Milter to MTA Hooks, letting an unmodified Postfix or Sendmail call MTA Hooks scanners for the inbound stages, and MTA Hooks to Milter, letting an MTA Hooks implementation reuse the existing Milter scanner ecosystem unchanged. The limits of the first gateway, which cannot reach the outbound stages, are themselves part of the problem statement.

- Open source projects implementing or committed to this work:

  - Stalwart Mail Server: full implementation of an older draft, in production (https://stalw.art/docs/api/mta-hooks/overview)
  - Rspamd: stated intent to implement
  - Haraka: offered on the mailing list, August 2026
  - Multiple third-party scanner implementations on GitHub, written by people other than the draft authors

  Support without an implementation commitment has been expressed on the list by Heinlein Group, Beonex, KTP Digital and the SAKE project. KumoMTA has stated it has no current demand for the work. Sendmail, approached via Proofpoint, showed little interest.

## Agenda

   - Welcome, Note Well, agenda bash (chairs): 5 minutes
   - Problem statement: what an MTA cannot delegate today, and what DKIM2 requires (Mauro De Gennaro): 20 minutes
   - Operator experience: filtering and delivery integration at scale (Carsten Rosenberg / Manu Zurmühl, Heinlein Group): 15 minutes
   - Discussion: is the problem statement correct, well scoped and worth solving? (all): 25 minutes
   - Existing work: draft status and implementation experience, as evidence the problem is tractable (Mauro De Gennaro): 10 minutes
   - Draft charter walkthrough: scope, out of scope, deliverables, milestones (chairs): 15 minutes
   - Charter discussion (all): 20 minutes
   - Consensus questions and next steps (chairs): 10 minutes

Per RFC 5434, the session is weighted towards agreement on the problem statement, not towards the proposed solution. The protocol is presented only as evidence that the problem is tractable. The draft charter will be posted to the list well in advance of the session, so nobody is asked to react to text put on screen for the first time.

## Consensus questions to be asked

These will be posted to the mailing list before the session so that they can be corrected in advance:

   1. Does the community agree that the problem statement is clear, well scoped, solvable, and useful to solve?
   2. Is there support to form a Working Group with the proposed charter?
   3. Who is willing to review documents? Who is willing to edit one?
   4. Who is willing to implement, on the MTA side and on the scanner side?
   5. Who believes a Working Group should not be formed, and on what grounds?

## Links

   - Mailing list: mtahooks@ietf.org
   - Archive: https://mailarchive.ietf.org/arch/browse/mtahooks/
   - Draft charter: posted to the mtahooks mailing list (see archive)
   - Relevant Internet-Drafts:
      - https://datatracker.ietf.org/doc/html/draft-degennaro-mta-hooks-01
      - MTA Hooks problem statement: in preparation, to be submitted before the BOF request deadline
      - Cited as a motivating consumer, not a dependency: https://datatracker.ietf.org/doc/draft-ietf-dkim-dkim2-spec/
   - Prior sessions:
      - MAILMAINT, IETF 123 (Madrid)
      - DISPATCH, IETF 125: https://datatracker.ietf.org/doc/slides-125-dispatch-mta-hooks-presentation/
      - Side meeting, IETF 126 (Vienna), 22 July 2026
