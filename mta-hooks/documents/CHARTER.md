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
  delivery status notifications. The Working Group will produce a
  Standards Track protocol specification using request/response
  semantics, capability negotiation and JSON or CBOR serialisation,
  together with operational and deployment considerations.

  Some contemporary MTAs are able to delegate processing decisions to
  external services for spam and virus filtering, policy enforcement,
  compliance capture, cryptographic signing and content
  transformation. The mechanisms that exist for this today cover the
  reception of a message, from connection through the end of DATA.
  However, the de facto standard for this delegation does not
  facilitate common modern capabilities not directly related to the
  SMTP state machine.

  A diverse ecosystem of capabilities and implementations has evolved
  around this. This work introduces a standard protocol by which
  filters and MTAs can negotiate and interoperate, with support for
  extensions and capabilities beyond the de facto standard.

  Building on HTTP allows this protocol to take advantage of the
  broadly developed frameworks supporting HTTP and RESTful
  interfaces, including authentication, load balancing, and
  observability.


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
   - failure semantics, including the time a hook call is allowed to
     take, what happens when it exceeds that, and whether an MTA
     proceeds or defers when a service is unavailable;
   - the composition of multiple services in a chain, including
     ordering and which actions terminate it;
   - the security model, including authentication, transport,
     authorisation, and the limits an operator can place on what a
     scanner is permitted to change.

  The Working Group will also document the operational
  considerations of deploying the protocol, either as part of the
  protocol document or separately.


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

  2. Operational and deployment considerations, either as a section
     of deliverable 1 or as a separate Informational document:
     deployment guidance, monitoring, and rollout.


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
  work must address the time a hook call is allowed to take, what
  happens when it exceeds that, and the behaviour of a scanner chain
  when one member is unavailable.

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
  M+3   Decide whether operational considerations form part of the
        protocol document or a separate draft, and adopt any
        separate draft.
  M+12  WGLC on the protocol specification.
  M+15  Submit the protocol specification to the IESG.
        WGLC on operational considerations, if a separate document.
  M+18  Submit operational considerations to the IESG, if a separate
        document.


Relationship to Other Work

  - Sieve (RFC 5228 et seq): complementary; Sieve filters after
    delivery, MTA Hooks filters at MTA processing stages.
  - JMAP (RFC 8620, RFC 8621): the message data model is reused; no
    changes to JMAP are proposed.
  - DKIM2 (DKIM WG, in progress): a potential consumer of this work,
    not a dependency. Nothing in these deliverables requires DKIM2,
    and no changes to it are proposed.
