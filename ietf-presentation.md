---
marp: true
theme: default
---

# JMAP Extensions
## Object Metadata, Enhanced References and Mail Sharing

**Stalwart Labs LLC**
IETF 124

---

# Overview

Three complementary JMAP extensions:

1. **JMAP Object Metadata** - Standardized metadata management
2. **JMAP Enhanced Result References** - Advanced result referencing 
3. **JMAP Mail Sharing** - Mailbox sharing framework

---

# JMAP Object Metadata

**Problem**: No standardized way to manage metadata in JMAP
- IMAP has the METADATA extension (RFC 5464)
- WebDAV has "dead properties" (RFC 4918)
- JMAP lacks equivalent functionality

**Impact**: 
- Cannot store user annotations, tags, or custom properties.
- No way to extend JMAP types with standardized meta-types (i.e. `Photography` for a `FileNode`).
- Vendors forced to create incompatible custom solutions.

---

# JMAP Object Metadata
## What It Solves

✓ **Unified metadata model** across all JMAP data types
✓ **IANA metadata registry** for common Metadata objects (i.e. `Photography`)
✓ **Extensibility** - Vendor-specific properties with namespacing (`Annotation` type)
✓ **IMAP interoperability** - Bridge IMAP metadata (`ImapMetadata` type)
✓ **WebDAV interoperability** - Expose WebDAV dead properties (`WebDavMetadata` type)

---

# JMAP Object Metadata

**IANA JMAP Metadata Types registry:**

- **Annotation** - Generic metadata for any JMAP object
- **ImapMetadata** - Maps IMAP METADATA extension entries
- **WebDavMetadata** - Exposes WebDAV dead properties
- **TBD** - Future standardized metadata types

**Key properties:**
- `@type` - Metadata object type
- `parentId` / `parentType` - Links to JMAP object
- `isPrivate` - Private vs. shared metadata
- Vendor-specific extensible properties

---

### JMAP Object Metadata

```json
[
  ["Mailbox/set", {
    "accountId": "A12345",
    "create": {
      "new-mailbox": { "name": "Project Alpha" }
    }
  }, "c1"],
  ["Metadata/set", {
    "accountId": "A12345",
    "create": {
      "new-metadata": {
        "@type": "Annotation",
        "parentType": "Mailbox",
        "parentId": "#new-mailbox",
        "isPrivate": true,
        "acme.example.com:color": "blue",
        "acme.example.com:priority": "high",
        "acme.example.com:project": {
          "@type": "acme.example.com:ProjectInfo",
          "projectId": "ALPHA-2024",
          "deadline": "2024-12-31",
          "team": "Engineering"
        }
      }
    }
  }, "c2"]
]
```

---

### JMAP Object Metadata

```json
[
  ["Metadata/set", {
    "accountId": "A12345",
    "create": {
      "photo-meta": {
        "@type": "PhotoMetadata",
        "parentType": "FileNode",
        "parentId": "F456",
        "isPrivate": false,
        "geoLocation": {
          "latitude": 46.362,
          "longitude": 14.090
        },
        "cameraMake": "Canon",
        "cameraModel": "EOS R5",
        "aperture": "f/2.8",
        "shutterSpeed": "1/250",
        "iso": 400,
        "focalLength": "50mm",
        "dateTaken": "2023-10-01T01:14:00Z",
        "imageSize": {
          "width": 6000,
          "height": 4000
        }
      }
    }
  }, "c2"]
]
```

---

### JMAP Object Metadata

**Request:**
```json
[["Mailbox/get", {
  "accountId": "a1",
  "ids": ["m234"],
  "properties": ["id", "name"],
  "metadataTypes": ["ImapMetadata"],
  "metadataProperties": ["@type", "parentId", "metadata", "isPrivate"],
}, "c0"]]
```

---

### JMAP Object Metadata

**Response:**
```json
[
  ["Mailbox/get", {
    "accountId": "a1",
    "list": [ { "id": "m234", "name": "Sales Meetings" } ],
    "metadata": [ {
        "id": "meta99",
        "@type": "ImapMetadata",
        "parentId": "m234",
        "isPrivate": false,
        "metadata": {
          "comment": "Quarterly sales meeting notes",
          "vendor/example.com/setting": "custom-value"
        }
      } ],
  }, "c0"]
]
```

---

# JMAP Enhanced Result References
## Motivation

**Problem**: 
- Result references can only be used in method arguments.
- JSON Pointer has limited expressiveness for complex data extraction.

**Impact**: 
- Calling `/set` with data derived from previous results requires multiple round-trips.
- `FilterOperator` cannot reference results from previous method calls.
- Some queries cannot be expressed at all with JSON Pointers.

---

# JMAP Enhanced Result References
## What It Solves

✓ **Reduce round-trips** - Build `/set` requests using prior `/get` results directly
✓ **Complex queries** - Build `/query` filters with `FilterOperator` referencing results
✓ **JSON Path expressions** - Powerful data extraction from previous results (*optional!*)
✓ **Example use cases**:
  - Extract calendar participants or locations from previous events
  - Copy specific attachments from previous emails
  - And more... build any JMAP object from partial data or templates

---

### JMAP Enhanced Result References  

```json
[
  ["CalendarEvent/query", {
    "accountId": "a1", "filter": { "uid": "meeting-template-001" }
  }, "c0"],
  ["CalendarEvent/get", {
    "accountId": "a1",
    "#ids": {
      "resultOf": "c0",
      "name": "CalendarEvent/query",
      "path": "/ids"
    },
    "properties": ["participants", "locations"]
  }, "c1"],
  ["CalendarEvent/set", {
    "accountId": "a1",
    "create": {
      "new-event": {
        "calendarIds": {"cal-1": true},
        "title": "Team Sync",
        "start": "2025-11-01T14:00:00Z",
        "duration": "PT1H",
        "#participants": {
          "resultOf": "c1",
          "name": "CalendarEvent/get",
          "path": "$.list[0].participants"
        },
        "#locations": {
          "resultOf": "c1",
          "name": "CalendarEvent/get",
          "path": "$.list[0].locations"
        }
      }
    }
  }, "c2"]
]
```

---

### JMAP Enhanced Result References

```json
[
  ["Email/get", {
    "accountId": "a1",
    "ids": ["template-email-id"],
    "properties": ["attachments"],
    "bodyProperties": ["blobId", "name", "type"]
  }, "c0"],
  ["Email/set", {
    "accountId": "a1",
    "create": {
      "new-email": {
        "mailboxIds": {
          "inbox-id": true
        },
        "subject": "Quarterly Reports",
        "from": [{"email": "sender@example.com"}],
        "to": [{"email": "recipient@example.com"}],
        "#attachments": {
          "resultOf": "c0",
          "name": "Email/get",
          "path": "$.list[0].attachments[?@.name && 
                @.name.toLowerCase().endsWith('.pdf')]"
        }
      }
    }
  }, "c1"]
]
```

---

### JMAP Enhanced Result References

```json
[
  ["Mailbox/query", {
    "accountId": "a1",
    "filter": {
      "role": "inbox"
    }
  }, "c0"],
  ["Email/query", {
    "accountId": "a1",
    "filter": {
      "#inMailboxOtherThan": {
        "resultOf": "c0",
        "name": "Mailbox/query",
        "path": "$.ids[0]"
      },
      "from": "boss@example.com"
    },
    "sort": [{"property": "receivedAt", "isAscending": false}],
    "limit": 50
  }, "c1"]
]
```

---

# JMAP Mail Sharing
## Quick Overview

**Problem**: RFC 8621 (JMAP Mail) predates RFC 9670 (JMAP Sharing)
- `Mailbox` object lacks sharing framework properties
- No standardized way to share mailboxes between users

**What's needed**: Extend `Mailbox` object with RFC 9670 sharing properties

---

# JMAP Mail Sharing

### Extension Summary

- Extends `Mailbox` object with:
  - `shareWith` A map of Principal IDs to `MailboxRights`.
  - `mayShare` Permission to modify sharing settings.

- Adds new capability: `urn:ietf:params:jmap:mail:share`

---

# Summary

**JMAP Object Metadata**: Standardized metadata management with protocol bridging

**JMAP Enhanced Result References**: Powerful JSON Path-based result extraction

**JMAP Mail Sharing**: Complete RFC 9670 sharing framework for mailboxes

---

# Questions?

Thank you!
