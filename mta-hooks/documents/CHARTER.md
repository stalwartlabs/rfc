Working Group Name:     MTA Hooks (mtahooks)
Area:                   Applications and Real-Time (ART)
Chairs:                 TBD
Area Director:          TBD
Mailing List:
  General discussion:   mtahooks@ietf.org
  To subscribe:         https://www.ietf.org/mailman/listinfo/mtahooks
  Archive:              https://mailarchive.ietf.org/arch/browse/mtahooks/


Description of Working Group

  The MTA Hooks Working Group will standardise an HTTP-based protocol
  by which a Mail Transfer Agent (MTA) delegates per-message
  processing decisions to one or more external services across the
  whole lifetime of a message: from the SMTP conversation that
  receives it, through routing and delivery, to the generation of
  delivery status notifications. No IETF specification covers this
  interface at any stage today, and the operations that follow
  acceptance of a message are covered per MTA by unrelated,
  non-portable mechanisms. The Working Group will produce a Standards
  Track protocol specification using request/response semantics,
  capability negotiation and JSON or CBOR serialisation, together
  with a document on operational and deployment considerations.

  MTAs delegate processing decisions to external services for spam
  and virus filtering, policy enforcement, compliance capture,
  cryptographic signing and content transformation. The mechanisms
  that exist for this today cover the reception of a message, from
  connection through the end of DATA.

  The operations that occur after a message is accepted are covered
  by a different mechanism in every MTA, and usually by several at
  once: lookup tables for transport selection, re-injection loops
  through a content filter, BCC maps for archiving, VERP addressing
  and log parsing for delivery feedback, purpose-built side channels
  for TLS reporting. None of these is an IETF specification, none is
  portable between MTAs, and none is correlated with the others or
  with the decisions taken during reception. A filter author cannot
  write one component that follows a message through its lifetime.

  Building on HTTP gives the work a large existing implementation
  base and lets deployments reuse the authentication, load balancing
  and observability infrastructure they already operate.


Scope

  The Working Group will produce a Standards Track specification of
  the MTA Hooks protocol, covering:

   - the wire protocol (request and response formats, headers, error
     handling);
   - the discovery mechanism (well-known endpoint and capability
     document);
   - the registration mechanism between MTA and scanner;
   - the set of inbound and outbound processing stages at which hooks
     may be invoked, including delivery, deferral and delivery status
     notification;
   - delegation of routing decisions before delivery, including
     per-recipient routing, the splitting of a delivery job that this
     implies, and per-destination TLS policy selection;
   - the modification model by which scanners influence MTA
     behaviour;
   - the security model, including authentication, transport,
     authorisation, and the limits an operator can place on what a
     scanner is permitted to change.

  The Working Group will also document the operational
  considerations of deploying the protocol.


Out of Scope

  The following are explicitly out of scope:

   - Specifying the Milter protocol, or a translation layer between
     Milter and MTA Hooks.
   - Mailbox-level filtering. Filtering performed after final
     delivery is the domain of Sieve (RFC 5228) and is unaffected by
     this work.
   - Specific filtering rules, content signatures, scoring
     algorithms, or detection logic of any kind.
   - Modifications to SMTP, JMAP, Sieve, or any other existing IETF
     protocol.
   - Definition or registration of specific scanner products,
     vendor-specific extensions, or filtering policy languages.
   - Mechanisms for human users to interact with quarantines, review
     queues, or scanner administrative interfaces.


Deliverables

  1. MTA Hooks Protocol Specification.
     Standards Track. Based on draft-degennaro-mta-hooks.

  2. MTA Hooks Operational and Deployment Considerations.
     Informational. Retry behaviour, fail-open versus fail-closed
     policy, multi-scanner chaining, latency budgets and
     observability. Developed concurrently with deliverable 1.


Considerations

  Architecture: the protocol places an external service in the path
  of a message. The specification must define what the MTA remains
  authoritative for, how a chain of scanners composes, and how a
  scanner discovers which stages a given MTA implements.

  Security: a scanner that can modify messages and influence routing
  sits inside the mail system's trust boundary. The specification
  must define authentication and transport requirements, and must let
  an operator bound what a given scanner may change, instead of
  leaving that to deployment convention.

  Operations and scaling: hooks are invoked in the SMTP path, so the
  work must address latency budgets, timeouts, failure semantics, and
  the behaviour of a scanner chain when one member is unavailable.

  Manageability: hook invocations and delivery events are the point
  at which a deployment becomes observable. The work must define
  stable identifiers that correlate a message across stages, so that
  operators are not left reconstructing this from logs.

  Transition: adoption is incremental. An MTA may implement a subset
  of stages, and capability negotiation is how a scanner discovers
  this. Gateways in either direction between Milter and MTA Hooks are
  expected to exist, but specifying them is out of scope.


Milestones

  M+0   WG formed; adopt draft-degennaro-mta-hooks as a WG draft.
  M+6   Adopt operational considerations as a WG draft.
  M+12  WGLC on the protocol specification.
  M+15  Submit the protocol specification to the IESG.
        WGLC on operational considerations.
  M+18  Submit operational considerations to the IESG.


Relationship to Other Work

  - Sieve (RFC 5228 et seq): complementary; Sieve filters after
    delivery, MTA Hooks filters at MTA processing stages.
  - JMAP (RFC 8620, RFC 8621): the message data model is reused; no
    changes to JMAP are proposed.
  - DKIM2 (DKIM WG, in progress): a potential consumer of this work,
    not a dependency. Nothing in these deliverables requires DKIM2,
    and no changes to it are proposed.
