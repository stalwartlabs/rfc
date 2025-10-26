# JMAP for Calendar Scheduling

## 1. Introduction

This document defines an extension to the [JSON Meta Application Protocol (JMAP)](https://datatracker.ietf.org/doc/html/rfc8620) for supporting explicit calendar scheduling operations. This extension is identified by the capability string `urn:ietf:params:jmap:calendars:scheduling`.

JMAP for Calendars \[RFC XXX] includes basic support for calendar scheduling by allowing clients to send and receive scheduling messages through the manipulation of calendar events. However, the scheduling model defined in JMAP for Calendars is based on the implicit scheduling model also used in CalDAV Scheduling \[RFC6638]. In this model, scheduling actions are triggered automatically by the server in response to changes to calendar data, and clients have limited control over the handling of scheduling messages.

While implicit scheduling is suitable for many organizational use cases, it imposes several limitations that hinder flexibility, transparency, and user control. Notably:

* Clients have no control over which scheduling messages are applied to their calendars; servers are required to automatically apply incoming invitations received over iTIP \[RFC5546], including via iMIP \[RFC6047].
* This opens a potential vector for abuse, where external actors can deliver unsolicited or malicious invitations to a user's calendar, such as through spam messages delivered over iMIP.
* The full range of iTIP scheduling functionality is not available in the implicit model. For example, actions such as sending counters (`COUNTER`), declining a counter-proposal (`DECLINECOUNTER`), replacing the organizer (`REQUEST` from a new organizer), or selectively processing or rejecting scheduling messages are unsupported or inconsistently implemented.

This specification introduces *JMAP for Calendar Scheduling*, an extension that defines an explicit scheduling model for JMAP. This model allows clients to receive, review, and explicitly act on scheduling messages rather than relying solely on server-side automation. It introduces two new JMAP data types: `CalendarSchedulingMessage` which represents an incoming iTIP message received by the user (including iMIP-delivered messages), optionally pending client review or action. And `CalendarSchedulingRequest` which represents an outbound scheduling message initiated by the user or client, to be delivered to one or more recipients via the appropriate transport.

By supporting these new objects and related methods, this extension enables clients to:

* View, filter, and inspect incoming scheduling messages.
* Explicitly control whether and how an incoming scheduling message affects their calendar data.
* Compose and send a full range of outbound iTIP messages, including those not supported in the implicit model.

Servers implementing this extension may continue to support the implicit scheduling model defined in JMAP for Calendars. This allows clients to choose the model most appropriate for their use case, whether that be automatic handling for intra-organizational scheduling, or explicit handling for user-mediated control of external invitations.

The goal of this extension is to provide a coherent and secure framework for interoperable, client-driven calendar scheduling that aligns with the full capabilities of the iTIP protocol while preserving the usability and simplicity of JMAP for Calendars.

### 1.1 Addition to the Capabilities Object

The capabilities object is returned as part of the JMAP Session object; see Section 2 of [RFC8620]. This document defines one additional capability URI called `urn:ietf:params:jmap:calendars:scheduling`. This capability indicates that the server supports the JMAP for Calendar Scheduling extension.

The value of this property in an account's "accountCapabilities" property is an object that MUST contain the following information on server capabilities and permissions for that account:

- `maxSchedulingMessagesPerRequest`: `UnsignedInt`
    > The maximum number of scheduling messages that can be processed in a single request. This is a server-defined limit to prevent abuse or excessive load.
- `maxRecipientsPerMessage`: `UnsignedInt|null`
    > The maximum number of recipients that can be included in a single scheduling message. If `null`, there is no limit.
- `outboundScheduling`: `Boolean`
    > Indicates whether the server supports sending outbound scheduling messages. If `false`, clients can only receive and process incoming scheduling messages.

## 2. Scheduling Message

A `CalendarSchedulingMessage` object represents an incoming iTIP \[RFC5546] or iMIP \[RFC6047] scheduling message received by the user. These messages convey operations such as invitations, replies, cancellations, updates, and other scheduling-related actions. The type of operation is indicated by the `method` property, which reflects the iTIP method used (e.g., `REQUEST`, `REPLY`, `CANCEL`).

Each scheduling message references a calendar event using its JSCalendar `uid` value, provided in the `uid` property. This approach allows clients to inspect, preview, or propose changes to an event without immediately adding it to their calendars. As defined in Section 1.4.1 of *JMAP for Calendars*, each `CalendarEvent` object has a `uid` property, which is a globally unique identifier for the event. 

The `event` property contains the JSCalendar representation of the iTIP message when the message is introducing a new event, or a new instance of a recurring event. If the referenced event or instance already exists in the user's account—either as a `CalendarEvent` or as a previously received `CalendarSchedulingMessage`—the server MAY instead include an `eventPatch` property. This property contains a patch object describing the differences between the content of the iTIP message and the corresponding event already present in the account. This enables clients to preview and evaluate the impact of the changes without automatically applying them.

To support both automated and user-driven workflows, the `processed` property indicates whether the message has already been applied by the server. If `true`, the server has already updated the user’s calendar in response to the message. If `false`, the message is pending client action and does not affect any calendar data until explicitly processed. Servers MAY allow users or clients to configure whether specific scheduling messages are processed automatically or manually.

A `CalendarSchedulingMessage` object represents an iTIP message with additional metadata for JMAP processing. This object has the following properties:

- `id`: `Id`
    > The id of the `CalendarSchedulingMessage`.

- `uid`: `String`
    > The JSCalendar `uid` of the event referenced by this message.

- `receivedAt`: `UTCDateTime`
    > The time this message was received.

- `sentBy`: `Person`
    > Who sent the iTIP message. The `Person` object is defined in JMAP for Calendars.

- `comment`: `String|null`
    > Comment sent along with the iTIP message.

- `processed`: `Boolean` 
    > `True` if the event has been automatically processed by the server. If false, the user must take action to process the event. 

- `unseen`: `Boolean`
    > `True` if the user has not yet seen this message. This is a client-side property that allows clients to track which messages have been viewed by the user.

- `method`: `String`
    > The method of the scheduling message. One of `REQUEST`, `REPLY`, `CANCEL`, `ADD`, `COUNTER`, `DECLINECOUNTER`, `REFRESH`, `PUBLISH`.

- `event`: `JSCalendar Event`
    > The event in JSCalendar format.

- `eventPatch`: `PatchObject|null`
    > A patch encoding the change between the data in the event property, and the data in the iTIP message. Or null if the message is not an update.


## 2.1.`CalendarSchedulingMessage/set`

This is a standard "/set" method as described in Section 5.3 of [RFC8620], with the following extra argument:

- **targetCalendarId: Id**
  > This argument is required when processing a scheduling message that does not reference an existing calendar event (i.e., `calendarEventId` is `null`) and the method implies event creation (e.g., `REQUEST`). It specifies the calendar in which the new event should be created.

A scheduling message is explicitly processed by the client by setting its `processed` property to `true` using the standard JMAP `/set` method. This signals to the server that the client wishes to apply the changes described in the scheduling message to the relevant calendar event.

If the scheduling message has already been processed (i.e., its `processed` property is already `true`), the server MUST reject the request and return an `alreadyProcessed` error. If the server is unable to apply the changes described in the scheduling message (such as due to a semantic conflict, missing referenced data, or validation failure), it MUST reject the update and return a `cannotProcess` error.

When the scheduling message does not reference an existing calendar event, and the `method` implies event creation (e.g., `REQUEST`, `PUBLISH`, or `ADD`), the client MUST specify the `targetCalendarId` argument in the same `/set` call. This argument identifies the calendar in which the event described in the scheduling message should be created. If `targetCalendarId` is required but omitted, the server MUST return `invalidArguments` error.

Example:

```javascript
            [[ "CalendarSchedulingMessage/set", {
                "accountId": "x",
                "targetCalendarId": "d",
                "update": {
                  "a": {
                    "id": "a",
                    "processed": true,
                  }
                }
             }, "0" ]]
```

### 2.2. `CalendarSchedulingMessage/get`

This is a standard "/get" method as described in Section 5.1 of [RFC8620].

### 2.3. `CalendarSchedulingMessage/query`

This is a standard "/query" method as described in Section 5.5 of [RFC8620].

A `FilterCondition` object has the following properties:

- `after`: `UTCDateTime|null`
    > Only return messages received after this date.
- `before`: `UTCDateTime|null`
    > Only return messages received before this date.
- `uid`: `String|null`
    > Only return messages with this iTIP UID.
- `method`: `String|null`
    > Only return messages with this iTIP method. One of `REQUEST`, `REPLY`, `CANCEL`, `ADD`, `COUNTER`, `DECLINECOUNTER`, `REFRESH`, `PUBLISH`.
- `from`: `String|null`
    > Only return messages sent by this person.
- `processed`: `Boolean|null`
    > Only return messages that have been processed (`true`) or not processed (`false`).
- `unseen`: `Boolean|null`
    > Only return messages that have been seen (`false`) or not seen (`true`).

### 2.4. `CalendarSchedulingMessage/changes`

This is a standard "/changes" method as described in Section 5.2 of [RFC8620].

## 3. Scheduling Request

A `CalendarSchedulingRequest` object represents an outgoing iTIP \[RFC5546] scheduling message initiated by the user. It allows a client to explicitly compose and send scheduling operations such as event invitations (`REQUEST`), replies (`REPLY`), cancellations (`CANCEL`), and other iTIP methods to one or more recipients.

To construct a `CalendarSchedulingRequest`, the client MUST specify the `method` property, identifying the iTIP method being used, and the `to` property, listing the intended recipients. The contents of the scheduling message are expressed in JSCalendar format.

Each scheduling request references an event via the JSCalendar `uid` property, which uniquely identifies the event across calendars and accounts. The `uid` must correspond to an existing `CalendarEvent` or `CalendarSchedulingMessage` in the account. The only exception is when using the `PUBLISH` method, which may refer to an event that does not exist in the user's calendar.

To construct the iTIP message, the client MUST supply either the full event data in the `event` property or a set of modifications in the `eventPatch` property. The server uses this input to build the iTIP message to be delivered to the specified recipients in the `to` property. These two mechanisms are intended to support a range of client capabilities:

* When sending a full event or a new instance of a recurring event, the client MUST use the `event` property to provide the complete JSCalendar representation of the data to be transmitted.

* When sending changes to an existing event or instance (e.g., updates to time, participants, or recurrence rules), the client MUST use the `eventPatch` property to describe only the changes to be sent.

Only one of `event` or `eventPatch` may be included in a single request. If both are present, the server MUST reject the request with an `invalidArguments` SetError.

There is one exception: when the method is `REQUEST`, the client MAY omit both `event` and `eventPatch`. In this case, the server constructs the iTIP message directly from the existing `CalendarEvent` object identified by the given `uid`.

Implementation of the `CalendarSchedulingRequest` data type and related methods is OPTIONAL. Servers are only required to implement `CalendarSchedulingMessage`. Servers indicate their support for sending scheduling messages by setting the `outboundScheduling` property to `true` in the JMAP capabilities object for this extension.

If a server does not support outbound scheduling (`outboundScheduling` set to `false`), clients MUST use the implicit scheduling model defined in JMAP for Calendars and send scheduling messages by setting the `sendSchedulingMessages` property to `true` in a `CalendarEvent/set` request.

Even if a server advertises support for outbound scheduling via `CalendarSchedulingRequest`, clients MAY continue to use the implicit scheduling model instead, depending on their design preferences or requirements.

A `CalendarSchedulingRequest` object represents an outgoing scheduling request message. This object has the following properties:

- `id`: `Id`
   > The id of the `CalendarSchedulingRequest`.

- `uid`: `String|null`
    > The JSCalendar `uid` of the event referenced by this message, or `null` if the message is not associated with a specific event (e.g., when using the `PUBLISH` method).

- `to`: `Person[]`
    > Who the iTIP message is addressed to. The `Person` object is defined in JMAP for Calendars.

- `comment`: `String|null`
    > Comment sent along with the change by the user that made it. (e.g. `COMMENT` property in an iTIP message), if any.

- `method`: `String`
    > The method of the scheduling message. One of `REQUEST`, `REPLY`, `CANCEL`, `ADD`, `COUNTER`, `DECLINECOUNTER`, `REFRESH`, `PUBLISH`.

- `event`: `JSCalendar Event|null`
    > The event in JSCalendar format or null if the `eventPatch` is provided instead.

- `eventPatch`: `PatchObject|null`
    > A patch object representing the changes to be sent in the iTIP message.

- `createdAt`: `UTCDateTime`
    > The time this message was created.

- `deliveryStatus`: `String[DeliveryStatus]|null` (server-set)
    > This represents the delivery status for each of the iTIP message's external recipients, if known. The `DeliveryStatus` object is defined in RFC8621.

### 3.1. `CalendarSchedulingRequest/set`

This is a standard "/set" method as described in Section 5.3 of [RFC8620].

The `CalendarSchedulingRequest/set` method is used to send outbound iTIP \[RFC5546] messages, including invitations (`REQUEST`), replies (`REPLY`), cancellations (`CANCEL`), counter-proposals (`COUNTER`), publications (`PUBLISH`), and other supported scheduling actions.

To send a new event invitation using the `REQUEST` method, the client sets the `method` property to `"REQUEST"`, supplies the `uid` referencing the relevant `CalendarEvent`, and omits both the `event` and `eventPatch` properties. In this case, the server constructs the iTIP message directly from the referenced event.

For replies, updates, counters, and similar actions, the client must specify the appropriate `method` value and provide either a complete `event` object or an `eventPatch` describing the changes to be sent. These mechanisms are described in Section 3.

To send a `PUBLISH` message, the client sets the `method` to `"PUBLISH"`, MUST set `uid` to `null`, and MUST include the event data in the `event` property. The `eventPatch` mechanism is not permitted for `PUBLISH`.

The server is responsible for validating the provided data, generating a valid iTIP message, and delivering it to the intended recipients using the appropriate transport mechanism (e.g., iMIP or other scheduling gateways).

Example:

```javascript
[[ "CalendarSchedulingRequest/set", {
  "accountId": "a0x9",
  "create": {
    "123": {
      "method": "REQUEST",
      "uid": "event-123-abc-456",
      "to": [{
        "name": "Attendee Name",
        "email": "attendee@example.com"
      }],
      "comment": "Please join our meeting",
    }
  }
}, "0" ]]
```

### 3.2. `CalendarSchedulingRequest/get`

This is a standard "/get" method as described in Section 5.1 of [RFC8620].

### 3.3. `CalendarSchedulingRequest/query`

This is a standard "/query" method as described in Section 5.5 of [RFC8620].

A `FilterCondition` object has the following properties:

- `after`: `UTCDateTime|null`
    > Only return messages sent after this date.
- `before`: `UTCDateTime|null`
    > Only return messages sent before this date.
- `uid`: `String|null`
    > Only return messages with this JSCalendar UID.
- `method`: `String|null`
    > Only return messages with this iTIP method. One of `REQUEST`, `REPLY`, `CANCEL`, `ADD`, `COUNTER`, `DECLINECOUNTER`, `REFRESH`, `PUBLISH`.
- `to`: `String|null`
    > Only return messages sent to this person.

## 4. Additional Calendar Object properties

This document also defines two new JMAP for Calendar properties in the Calendar object for use in JMAP for Calendar Scheduling. These properties allow clients to control whether and how the server automatically processes incoming iTIP scheduling messages for the calendar.


### 4.1. `implicitSchedulingCreate`

Type: `Boolean`

The `implicitSchedulingCreate` property determines whether new scheduling messages received via iTIP that do not reference an existing event (such as the `REQUEST` method) are automatically processed by the server and result in new events being added to the calendar. By default, this property is set to `false`, meaning such messages are not processed unless explicitly handled by the client.

 If set to `true`, the server will automatically process qualifying messages and add the corresponding events to the calendar. Only one calendar in the account may have `implicitSchedulingCreate` set to `true` at any given time. If a client attempts to enable this property on a second calendar while another already has it enabled, the server MUST reject the request with an `invalidArguments` error.

### 4.2. `implicitSchedulingUpdate`

Type: `Boolean`

The `implicitSchedulingUpdate` property controls whether the server should automatically apply changes from iTIP messages that reference existing events in the calendar. These may include methods such as `REPLY`, `CANCEL`, or `REQUEST` targeting a known UID. 

When this property is set to `true`, the server automatically updates the referenced calendar event with the changes described in the iTIP message. This property is also set to `false` by default, requiring the client to process such messages explicitly.

### 4.3. Disabling Explicit Scheduling

If both `implicitSchedulingCreate` and `implicitSchedulingUpdate` are set to `true`, the calendar operates in fully implicit scheduling mode, and the client disables all of the functionality provided by this extension. In this configuration, the server handles the automatic processing of all incoming iTIP messages relevant to this calendar. 

However, even in implicit mode, the server MAY still provide `CalendarSchedulingMessage` objects for received scheduling messages, allowing clients to inspect the original message for auditing, logging, or user interface purposes.
