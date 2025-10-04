# API Examples & Test Cases

## Authentication Examples

### 1. Register New User

**Request:**
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "newuser@example.com",
  "password": "secure123",
  "name": "New User",
  "role": "USER"
}
```

**Response (201 Created):**
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "newuser@example.com",
    "name": "New User",
    "role": "USER"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": {
    "code": "EMAIL_EXISTS",
    "field": "email",
    "message": "Email already registered"
  }
}
```

### 2. Login

**Request:**
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "admin@helpdesk.com",
  "password": "admin123"
}
```

**Response (200 OK):**
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "admin@helpdesk.com",
    "name": "Admin User",
    "role": "ADMIN"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## Ticket Management Examples

### 3. Create Ticket (with Idempotency)

**Request:**
```http
POST /api/tickets
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Idempotency-Key: ticket-2025-10-04-001
Content-Type: application/json

{
  "title": "Database connection timeout",
  "description": "Users are experiencing timeout errors when accessing the dashboard. The issue started at 10:00 AM today.",
  "priority": "CRITICAL"
}
```

**Response (201 Created):**
```json
{
  "id": "650e8400-e29b-41d4-a716-446655440001",
  "title": "Database connection timeout",
  "description": "Users are experiencing timeout errors when accessing the dashboard. The issue started at 10:00 AM today.",
  "status": "OPEN",
  "priority": "CRITICAL",
  "version": 1,
  "slaDeadline": "2025-10-04T16:00:00.000Z",
  "slaBreached": false,
  "resolvedAt": null,
  "closedAt": null,
  "createdAt": "2025-10-04T12:00:00.000Z",
  "updatedAt": "2025-10-04T12:00:00.000Z",
  "creatorId": "550e8400-e29b-41d4-a716-446655440000",
  "assigneeId": null,
  "creator": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "user1@example.com",
    "role": "USER"
  },
  "assignee": null
}
```

**Idempotent Request (same key):**
If you send the same request with the same `Idempotency-Key` within 24 hours, you'll receive the cached response instead of creating a duplicate ticket.

### 4. List Tickets with Filters & Pagination

**Request:**
```http
GET /api/tickets?status=OPEN&priority=HIGH&limit=20&offset=0&slaBreached=false&q=database
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "650e8400-e29b-41d4-a716-446655440001",
      "title": "Database connection timeout",
      "description": "Users are experiencing timeout errors...",
      "status": "OPEN",
      "priority": "HIGH",
      "version": 1,
      "slaDeadline": "2025-10-05T12:00:00.000Z",
      "slaBreached": false,
      "createdAt": "2025-10-04T12:00:00.000Z",
      "updatedAt": "2025-10-04T12:00:00.000Z",
      "creator": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "John Doe",
        "email": "user1@example.com",
        "role": "USER"
      },
      "assignee": null,
      "_count": {
        "comments": 0
      }
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0,
  "next_offset": null
}
```

### 5. Get Ticket Details (with Timeline & Comments)

**Request:**
```http
GET /api/tickets/650e8400-e29b-41d4-a716-446655440001
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200 OK):**
```json
{
  "id": "650e8400-e29b-41d4-a716-446655440001",
  "title": "Database connection timeout",
  "description": "Users are experiencing timeout errors...",
  "status": "IN_PROGRESS",
  "priority": "CRITICAL",
  "version": 3,
  "slaDeadline": "2025-10-04T16:00:00.000Z",
  "slaBreached": false,
  "resolvedAt": null,
  "closedAt": null,
  "createdAt": "2025-10-04T12:00:00.000Z",
  "updatedAt": "2025-10-04T13:30:00.000Z",
  "creator": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "user1@example.com",
    "role": "USER"
  },
  "assignee": {
    "id": "650e8400-e29b-41d4-a716-446655440002",
    "name": "Agent One",
    "email": "agent1@helpdesk.com",
    "role": "AGENT"
  },
  "comments": [
    {
      "id": "750e8400-e29b-41d4-a716-446655440001",
      "content": "Looking into this issue now. Checking database logs.",
      "createdAt": "2025-10-04T13:00:00.000Z",
      "updatedAt": "2025-10-04T13:00:00.000Z",
      "author": {
        "id": "650e8400-e29b-41d4-a716-446655440002",
        "name": "Agent One",
        "email": "agent1@helpdesk.com",
        "role": "AGENT"
      }
    },
    {
      "id": "750e8400-e29b-41d4-a716-446655440002",
      "content": "Found the issue - connection pool exhausted. Increasing pool size.",
      "createdAt": "2025-10-04T13:25:00.000Z",
      "updatedAt": "2025-10-04T13:25:00.000Z",
      "author": {
        "id": "650e8400-e29b-41d4-a716-446655440002",
        "name": "Agent One",
        "email": "agent1@helpdesk.com",
        "role": "AGENT"
      }
    }
  ],
  "timeline": [
    {
      "id": "850e8400-e29b-41d4-a716-446655440001",
      "action": "CREATED",
      "oldValue": null,
      "newValue": null,
      "metadata": null,
      "createdAt": "2025-10-04T12:00:00.000Z",
      "user": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "John Doe",
        "email": "user1@example.com"
      }
    },
    {
      "id": "850e8400-e29b-41d4-a716-446655440002",
      "action": "ASSIGNED",
      "oldValue": null,
      "newValue": "650e8400-e29b-41d4-a716-446655440002",
      "metadata": null,
      "createdAt": "2025-10-04T12:30:00.000Z",
      "user": {
        "id": "550e8400-e29b-41d4-a716-446655440003",
        "name": "Admin User",
        "email": "admin@helpdesk.com"
      }
    },
    {
      "id": "850e8400-e29b-41d4-a716-446655440003",
      "action": "STATUS_CHANGED",
      "oldValue": "OPEN",
      "newValue": "IN_PROGRESS",
      "metadata": null,
      "createdAt": "2025-10-04T13:00:00.000Z",
      "user": {
        "id": "650e8400-e29b-41d4-a716-446655440002",
        "name": "Agent One",
        "email": "agent1@helpdesk.com"
      }
    },
    {
      "id": "850e8400-e29b-41d4-a716-446655440004",
      "action": "COMMENTED",
      "oldValue": null,
      "newValue": null,
      "metadata": null,
      "createdAt": "2025-10-04T13:00:00.000Z",
      "user": {
        "id": "650e8400-e29b-41d4-a716-446655440002",
        "name": "Agent One",
        "email": "agent1@helpdesk.com"
      }
    }
  ]
}
```

### 6. Update Ticket (with Optimistic Locking)

**Request:**
```http
PATCH /api/tickets/650e8400-e29b-41d4-a716-446655440001
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "version": 3,
  "status": "RESOLVED",
  "priority": "HIGH"
}
```

**Response (200 OK):**
```json
{
  "id": "650e8400-e29b-41d4-a716-446655440001",
  "title": "Database connection timeout",
  "description": "Users are experiencing timeout errors...",
  "status": "RESOLVED",
  "priority": "HIGH",
  "version": 4,
  "slaDeadline": "2025-10-05T12:00:00.000Z",
  "slaBreached": false,
  "resolvedAt": "2025-10-04T14:00:00.000Z",
  "closedAt": null,
  "createdAt": "2025-10-04T12:00:00.000Z",
  "updatedAt": "2025-10-04T14:00:00.000Z",
  "creator": { ... },
  "assignee": { ... }
}
```

**Error Response (409 Conflict - Stale Version):**
```json
{
  "error": {
    "code": "STALE_VERSION",
    "message": "Ticket was modified by another user. Please refresh and try again."
  }
}
```

### 7. Add Comment to Ticket

**Request:**
```http
POST /api/tickets/650e8400-e29b-41d4-a716-446655440001/comments
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Idempotency-Key: comment-2025-10-04-001
Content-Type: application/json

{
  "content": "The fix has been deployed. Can you please verify that the issue is resolved?"
}
```

**Response (201 Created):**
```json
{
  "id": "750e8400-e29b-41d4-a716-446655440003",
  "content": "The fix has been deployed. Can you please verify that the issue is resolved?",
  "createdAt": "2025-10-04T14:00:00.000Z",
  "updatedAt": "2025-10-04T14:00:00.000Z",
  "ticketId": "650e8400-e29b-41d4-a716-446655440001",
  "authorId": "650e8400-e29b-41d4-a716-446655440002",
  "author": {
    "id": "650e8400-e29b-41d4-a716-446655440002",
    "name": "Agent One",
    "email": "agent1@helpdesk.com",
    "role": "AGENT"
  }
}
```

## Rate Limiting Example

**Request (61st request within 1 minute):**
```http
GET /api/tickets
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (429 Too Many Requests):**
```json
{
  "error": {
    "code": "RATE_LIMIT",
    "message": "Too many requests, please try again later"
  }
}
```

**Headers:**
```
RateLimit-Limit: 60
RateLimit-Remaining: 0
RateLimit-Reset: 1696426800
```

## Validation Error Examples

### Missing Required Field

**Request:**
```http
POST /api/tickets
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "description": "Some description"
}
```

**Response (400 Bad Request):**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "field": "title",
    "message": "Title is required"
  }
}
```

### Invalid Priority

**Request:**
```http
POST /api/tickets
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "title": "Test",
  "description": "Test description",
  "priority": "URGENT"
}
```

**Response (400 Bad Request):**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "field": "priority",
    "message": "Invalid priority"
  }
}
```

## Authorization Error Examples

### Missing Token

**Request:**
```http
GET /api/tickets
```

**Response (401 Unauthorized):**
```json
{
  "error": {
    "code": "AUTH_REQUIRED",
    "message": "Authentication required"
  }
}
```

### Invalid Token

**Request:**
```http
GET /api/tickets
Authorization: Bearer invalid.token.here
```

**Response (401 Unauthorized):**
```json
{
  "error": {
    "code": "INVALID_TOKEN",
    "message": "Invalid token"
  }
}
```

### Insufficient Permissions

**Request (USER trying to update ticket):**
```http
PATCH /api/tickets/650e8400-e29b-41d4-a716-446655440001
Authorization: Bearer <user_token>
Content-Type: application/json

{
  "version": 1,
  "status": "RESOLVED"
}
```

**Response (403 Forbidden):**
```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "Only agents and admins can update tickets"
  }
}
```

## Complete Test Scenario

This scenario demonstrates all major features:

```bash
# 1. Register new user
POST /api/auth/register
{
  "email": "testuser@example.com",
  "password": "test123",
  "name": "Test User"
}

# 2. Login
POST /api/auth/login
{
  "email": "testuser@example.com",
  "password": "test123"
}
# Save token from response

# 3. Create ticket
POST /api/tickets
Headers: Authorization: Bearer <token>, Idempotency-Key: test-001
{
  "title": "Cannot export reports",
  "description": "Export button not working",
  "priority": "MEDIUM"
}
# Save ticket ID and version

# 4. Login as agent
POST /api/auth/login
{
  "email": "agent1@helpdesk.com",
  "password": "agent123"
}
# Save agent token

# 5. Assign ticket and update status
PATCH /api/tickets/<ticket_id>
Headers: Authorization: Bearer <agent_token>
{
  "version": 1,
  "status": "IN_PROGRESS",
  "assigneeId": "<agent_id>"
}

# 6. Add comment
POST /api/tickets/<ticket_id>/comments
Headers: Authorization: Bearer <agent_token>, Idempotency-Key: comment-001
{
  "content": "Working on this issue"
}

# 7. Resolve ticket
PATCH /api/tickets/<ticket_id>
Headers: Authorization: Bearer <agent_token>
{
  "version": 2,
  "status": "RESOLVED"
}

# 8. View full ticket details with timeline
GET /api/tickets/<ticket_id>
Headers: Authorization: Bearer <token>

# 9. Search tickets
GET /api/tickets?q=export&limit=10&offset=0
Headers: Authorization: Bearer <token>

# 10. Filter breached tickets
GET /api/tickets?slaBreached=true
Headers: Authorization: Bearer <agent_token>
```

## SLA Calculation Reference

| Priority  | SLA Duration | Breach Time After Creation |
|-----------|-------------|----------------------------|
| CRITICAL  | 4 hours     | T + 4h                    |
| HIGH      | 24 hours    | T + 24h                   |
| MEDIUM    | 72 hours    | T + 72h (3 days)          |
| LOW       | 168 hours   | T + 168h (7 days)         |

## Judge Test Checklist

- ✅ User registration works
- ✅ Login returns valid JWT token
- ✅ Create ticket with idempotency key
- ✅ List tickets with pagination (items, next_offset)
- ✅ Filter by status, priority, SLA breach
- ✅ Search across title, description, comments
- ✅ Update ticket with optimistic locking (version check)
- ✅ Stale version returns 409 error
- ✅ Add comments to tickets
- ✅ Timeline tracks all actions
- ✅ SLA deadlines calculated correctly
- ✅ SLA breach detected and logged
- ✅ Rate limit enforced (429 after 60 req/min)
- ✅ RBAC enforced (USER can't see others' tickets)
- ✅ All errors follow uniform format
- ✅ CORS enabled
- ✅ /api/health returns status
- ✅ /api/_meta returns metadata
- ✅ /.well-known/hackathon.json exists
