---
marp: true
theme: default
paginate: true
backgroundColor: #fff
header: 'IETF - IMAP OBJECTID Account Identifier Extension'
footer: 'Draft: draft-imap-objectid-accountid'
---

<!-- _class: lead -->

# IMAP OBJECTID Account Identifier Extension

**Extending RFC 8474 to Support Multi-Account Environments**

An extension to provide account-level identification for mailboxes in IMAP, enabling IMAP-JMAP interoperability when multiple JMAP accounts are accessible through a single IMAP session.

---

# OBJECTID IMAP Extension (RFC 8474)

- **Persistent Identifiers**: Provides stable object IDs for mailboxes and messages
- **MAILBOXID**: Unique identifier for each mailbox that persists across renames
- **EMAILID**: Unique identifier for messages across mailbox moves/copies
- **THREADID**: Optional identifier for related messages (threading)
- **Client Benefits**: Efficient cache reuse without redownloading data

---

# JMAPACCESS IMAP Extension (RFC 9698)

- **Protocol Bridge**: Tells IMAP clients that mailboxes/messages are also available via JMAP
- **Shared Identifiers**: Same MAILBOXID and EMAILID used in both IMAP and JMAP
- **Gradual Migration**: Clients can transition from IMAP to JMAP incrementally
- **Discovery**: GETJMAPACCESS command returns JMAP session URL
- **ID Mapping**: Assumes 1:1 correspondence between IMAP and JMAP objects
- **Current Limitation**: Assumes all mailboxes belong to a single JMAP account

---

# JMAP Email Delivery Push Extension

- **Real-time Notifications**: Clients receive EmailPush objects when new mail arrives
- **Filtered Delivery**: Client-defined filters control which messages trigger notifications
- **Property Inclusion**: Push includes requested email properties (from, subject, etc.)
- **Account Context**: Each EmailPush object includes an **accountId** field

---

# The Problem

**IMAP Mailbox Structure:**

```
├── INBOX
├── Drafts
└── Shared Folders/
    ├── sales/
    │   ├── INBOX
    │   └── Drafts
    └── support/
        ├── INBOX
        └── Drafts
```

Multiple accounts' mailboxes presented in single IMAP hierarchy

---

# The Problem

**With RFC 8474 MAILBOXID (Current State):**

```
├── INBOX                                (MAILBOXID "m1")
├── Drafts                               (MAILBOXID "m2")
└── Shared Folders/
    ├── sales/
    │   ├── INBOX                        (MAILBOXID "m1")
    │   └── Drafts                       (MAILBOXID "m2")
    └── support/
        ├── INBOX                        (MAILBOXID "m1")
        └── Drafts                       (MAILBOXID "m2")
```

**Problem**: Same MAILBOXID can appear in different accounts!
Cannot uniquely identify which JMAP account a mailbox belongs to.

---

# The Solution

**With the ACCOUNTID Extension:**

```
├── INBOX                    (MAILBOXID "m1") (ACCOUNTID "a1")
├── Drafts                   (MAILBOXID "m2") (ACCOUNTID "a1")
└── Shared Folders/
    ├── sales/
    │   ├── INBOX            (MAILBOXID "m1") (ACCOUNTID "a2")
    │   └── Drafts           (MAILBOXID "m2") (ACCOUNTID "a2")
    └── support/
        ├── INBOX            (MAILBOXID "m1") (ACCOUNTID "a3")
        └── Drafts           (MAILBOXID "m2") (ACCOUNTID "a3")
```

**Solution**: ACCOUNTID + MAILBOXID uniquely identifies mailboxes across accounts

---

# The Solution

```
C: A001 CAPABILITY
S: * CAPABILITY IMAP4rev2 OBJECTID OBJECTID=ACCOUNTID JMAPACCESS
S: A001 OK Capability completed
C: A002 LIST "" "*" RETURN (STATUS (MAILBOXID ACCOUNTID))
S: * LIST (\HasNoChildren) "/" "INBOX"
S: * STATUS "INBOX" (MAILBOXID (m1) ACCOUNTID (a1))
S: * LIST (\HasNoChildren) "/" "Drafts"
S: * STATUS "Drafts" (MAILBOXID (m2) ACCOUNTID (a1))
S: * LIST (\HasNoChildren) "/" "Shared Folders/sales/INBOX"
S: * STATUS "Shared Folders/sales/INBOX" (MAILBOXID (m1) ACCOUNTID (a2))
S: * LIST (\HasNoChildren) "/" "Shared Folders/sales/Drafts"
S: * STATUS "Shared Folders/sales/Drafts" (MAILBOXID (m2) ACCOUNTID (a2))
S: * LIST (\HasNoChildren) "/" "Shared Folders/support/INBOX"
S: * STATUS "Shared Folders/support/INBOX" (MAILBOXID (m1) ACCOUNTID (a3))
S: * LIST (\HasNoChildren) "/" "Shared Folders/support/Drafts"
S: * STATUS "Shared Folders/support/Drafts" (MAILBOXID (m2) ACCOUNTID (a3))
S: A002 OK List completed
```

---

<!-- _class: lead -->

# Questions? Comments?

**Thank you!**

Draft: draft-imap-objectid-accountid
Contact: mauro@stalw.art
