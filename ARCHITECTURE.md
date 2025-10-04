# HelpDesk Mini - System Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         CLIENT                               │
│                    (Browser / API Client)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTP/HTTPS
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                    EXPRESS SERVER                            │
│                   (Node.js + TypeScript)                     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │              MIDDLEWARE CHAIN                       │    │
│  │                                                     │    │
│  │  1. CORS                                           │    │
│  │  2. JSON Parser                                    │    │
│  │  3. Rate Limiter (Redis)                           │    │
│  │  4. Authentication (JWT)                           │    │
│  │  5. Authorization (RBAC)                           │    │
│  │  6. Idempotency Check                              │    │
│  └────────────────────────────────────────────────────┘    │
│                          │                                   │
│  ┌────────────────────────────────────────────────────┐    │
│  │                  ROUTES LAYER                       │    │
│  │                                                     │    │
│  │  • /api/auth/*      - Authentication               │    │
│  │  • /api/tickets/*   - Ticket Operations            │    │
│  │  • /api/health      - Health Check                 │    │
│  │  • /api/_meta       - Metadata                     │    │
│  └────────────────────────────────────────────────────┘    │
│                          │                                   │
│  ┌────────────────────────────────────────────────────┐    │
│  │              BUSINESS LOGIC LAYER                   │    │
│  │                                                     │    │
│  │  • Validation (express-validator)                  │    │
│  │  • SLA Calculation                                 │    │
│  │  • Timeline Management                             │    │
│  │  • Optimistic Locking                              │    │
│  └────────────────────────────────────────────────────┘    │
│                          │                                   │
│  ┌────────────────────────────────────────────────────┐    │
│  │                DATA ACCESS LAYER                    │    │
│  │                  (Prisma ORM)                       │    │
│  │                                                     │    │
│  │  • Type-safe queries                               │    │
│  │  • Transaction support                             │    │
│  │  • Connection pooling                              │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────┬───────────────────┘
                      │                   │
            ┌─────────▼─────────┐  ┌──────▼──────┐
            │   PostgreSQL      │  │    Redis    │
            │                   │  │             │
            │  • Users          │  │ • Rate      │
            │  • Tickets        │  │   Limits    │
            │  • Comments       │  │             │
            │  • Timeline       │  │             │
            │  • Idempotency    │  │             │
            └───────────────────┘  └─────────────┘
```

## Request Flow

### 1. Create Ticket Request Flow

```
Client
  │
  │ POST /api/tickets
  │ Headers: Authorization, Idempotency-Key
  │ Body: { title, description, priority }
  │
  ▼
CORS Middleware
  │ ✓ Check origin
  │
  ▼
Rate Limiter
  │ ✓ Check Redis counter
  │ ✓ Increment counter
  │
  ▼
Authentication Middleware
  │ ✓ Extract JWT token
  │ ✓ Verify signature
  │ ✓ Decode user info
  │
  ▼
Idempotency Middleware
  │ ✓ Check if key exists in DB
  │ ✗ Return cached response (if exists)
  │ ✓ Continue (if new)
  │
  ▼
Route Handler (POST /api/tickets)
  │ ✓ Validate input
  │ ✓ Calculate SLA deadline
  │
  ▼
Prisma Transaction
  │ 1. Create ticket
  │ 2. Create timeline event (CREATED)
  │ ✓ Commit
  │
  ▼
Response
  │ • Save idempotency key + response
  │ • Return 201 with ticket data
  │
  ▼
Client receives ticket
```

### 2. Update Ticket Request Flow (Optimistic Locking)

```
Client
  │
  │ PATCH /api/tickets/:id
  │ Body: { version: 3, status: "RESOLVED" }
  │
  ▼
Middleware Chain
  │ (Same as above)
  │
  ▼
Route Handler
  │ 1. Get current ticket from DB
  │ 2. Check version matches
  │    ✗ version != current → 409 STALE_VERSION
  │    ✓ version == current → continue
  │ 3. Validate changes
  │
  ▼
Prisma Transaction
  │ 1. Update ticket (increment version)
  │ 2. Add timeline events:
  │    • STATUS_CHANGED (OPEN → RESOLVED)
  │    • RESOLVED
  │ 3. Update timestamps
  │ ✓ Commit
  │
  ▼
Response
  │ • Return 200 with updated ticket
  │
  ▼
Client receives updated ticket (version: 4)
```

## Database Schema Relationships

```
┌─────────────┐
│    User     │
│             │
│ • id        │◄────────┐
│ • email     │         │
│ • password  │         │
│ • name      │         │
│ • role      │         │
└─────────────┘         │
       ▲                │
       │                │
       │ creator    assignee
       │                │
       │                │
┌──────┴────────────────┴──┐
│        Ticket             │
│                           │
│ • id                      │◄──────┐
│ • title                   │       │
│ • description             │       │
│ • status                  │       │
│ • priority                │       │
│ • version (locking)       │       │
│ • slaDeadline             │       │
│ • slaBreached             │       │
│ • creatorId (FK)          │       │
│ • assigneeId (FK)         │       │
└───────────────────────────┘       │
       ▲                            │
       │                            │
       │                            │
   ┌───┴────────┐            ┌──────┴──────┐
   │  Comment   │            │   Timeline  │
   │            │            │             │
   │ • id       │            │ • id        │
   │ • content  │            │ • action    │
   │ • ticketId │            │ • oldValue  │
   │ • authorId │            │ • newValue  │
   └────────────┘            │ • ticketId  │
                             │ • userId    │
                             └─────────────┘
```

## Role-Based Access Control (RBAC)

```
┌─────────────────────────────────────────────────────────┐
│                         ADMIN                            │
│                                                          │
│  ✓ All AGENT permissions                                │
│  ✓ Manage users                                         │
│  ✓ System configuration                                 │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│                         AGENT                            │
│                                                          │
│  ✓ View all tickets                                     │
│  ✓ Create tickets                                       │
│  ✓ Update any ticket                                    │
│  ✓ Assign tickets                                       │
│  ✓ Comment on any ticket                                │
│  ✓ Resolve/Close tickets                                │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│                          USER                            │
│                                                          │
│  ✓ View own tickets                                     │
│  ✓ Create tickets                                       │
│  ✓ Comment on own tickets                               │
│  ✗ Cannot assign tickets                                │
│  ✗ Cannot view others' tickets                          │
│  ✗ Cannot update ticket status                          │
└─────────────────────────────────────────────────────────┘
```

## SLA Calculation Logic

```
Ticket Created
    │
    ▼
Get Priority
    │
    ├─► CRITICAL → SLA = Current Time + 4 hours
    │
    ├─► HIGH     → SLA = Current Time + 24 hours
    │
    ├─► MEDIUM   → SLA = Current Time + 72 hours (3 days)
    │
    └─► LOW      → SLA = Current Time + 168 hours (7 days)
    
    │
    ▼
Store SLA Deadline in Ticket
    │
    ▼
On Each Ticket Access:
    │
    ├─► Current Time > SLA Deadline?
    │   ├─► YES → Mark slaBreached = true
    │   │         Add Timeline Event: SLA_BREACHED
    │   └─► NO  → Continue
```

## Timeline Event Types

```
┌─────────────────────────────────────────────────────────┐
│                   Timeline Events                        │
│                                                          │
│  CREATED          → Ticket is created                   │
│  STATUS_CHANGED   → Status updated (e.g., OPEN→RESOLVED)│
│  PRIORITY_CHANGED → Priority updated                    │
│  ASSIGNED         → Agent assigned to ticket            │
│  UNASSIGNED       → Agent removed from ticket           │
│  COMMENTED        → Comment added                       │
│  SLA_BREACHED     → SLA deadline exceeded               │
│  RESOLVED         → Ticket marked as resolved           │
│  CLOSED           → Ticket marked as closed             │
└─────────────────────────────────────────────────────────┘
```

## Idempotency Mechanism

```
Client sends POST request
    │
    ▼
Header: Idempotency-Key: "unique-key-123"
    │
    ▼
Middleware checks database
    │
    ├─► Key exists?
    │   ├─► YES → Return cached response (same status code & body)
    │   │         No database operation performed
    │   │
    │   └─► NO  → Continue to route handler
    │           │
    │           ▼
    │      Process request normally
    │           │
    │           ▼
    │      Store key + response in DB
    │      (Expires after 24 hours)
    │           │
    │           ▼
    │      Return response to client
```

## Rate Limiting Flow

```
Request arrives
    │
    ▼
Extract user ID (from JWT) or IP address
    │
    ▼
Redis: Check counter for key "rl:user-id"
    │
    ├─► Counter < 60?
    │   ├─► YES → Increment counter
    │   │         Set TTL = 60 seconds (if new)
    │   │         Continue to next middleware
    │   │
    │   └─► NO  → Return 429 Too Many Requests
    │             { error: { code: "RATE_LIMIT" } }
    │
    ▼
Request processed
```

## Error Handling Flow

```
Request Processing
    │
    ▼
Error occurs?
    │
    ├─► Validation Error
    │   └─► Return 400
    │       { error: { code: "VALIDATION_ERROR", field: "...", message: "..." } }
    │
    ├─► Authentication Error
    │   └─► Return 401
    │       { error: { code: "AUTH_REQUIRED", message: "..." } }
    │
    ├─► Authorization Error
    │   └─► Return 403
    │       { error: { code: "FORBIDDEN", message: "..." } }
    │
    ├─► Not Found
    │   └─► Return 404
    │       { error: { code: "NOT_FOUND", message: "..." } }
    │
    ├─► Optimistic Lock Failure
    │   └─► Return 409
    │       { error: { code: "STALE_VERSION", message: "..." } }
    │
    ├─► Rate Limit Exceeded
    │   └─► Return 429
    │       { error: { code: "RATE_LIMIT", message: "..." } }
    │
    └─► Unexpected Error
        └─► Return 500
            { error: { code: "INTERNAL_ERROR", message: "..." } }
```

## Data Flow for Search Query

```
GET /api/tickets?q=database&status=OPEN&limit=10
    │
    ▼
Build WHERE clause:
    │
    ├─► status = 'OPEN'
    │
    └─► (title ILIKE '%database%' OR
         description ILIKE '%database%' OR
         comments.content ILIKE '%database%')
    │
    ▼
Apply RBAC filter:
    │
    ├─► USER role? → Add: creatorId = current_user.id
    └─► AGENT/ADMIN? → No additional filter
    │
    ▼
Execute query with:
    • WHERE clause
    • ORDER BY createdAt DESC
    • LIMIT 10
    • OFFSET 0
    │
    ▼
Check for SLA breaches in results
    │
    ▼
Return:
    {
      items: [...],
      total: 25,
      limit: 10,
      offset: 0,
      next_offset: 10
    }
```

## Technology Stack Diagram

```
┌─────────────────────────────────────────────────────────┐
│                      FRONTEND                            │
│                                                          │
│  HTML5 + Tailwind CSS + Vanilla JavaScript              │
│  (Single Page Application)                              │
└──────────────────────┬──────────────────────────────────┘
                       │ REST API (JSON)
┌──────────────────────▼──────────────────────────────────┐
│                      BACKEND                             │
│                                                          │
│  Node.js 18+                                            │
│  Express.js (Web Framework)                             │
│  TypeScript (Type Safety)                               │
│                                                          │
│  Middleware:                                            │
│  • express-validator (Input Validation)                │
│  • jsonwebtoken (JWT Auth)                             │
│  • bcryptjs (Password Hashing)                         │
│  • express-rate-limit (Rate Limiting)                  │
│  • cors (CORS Handling)                                │
└──────────────────────┬──────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼────────┐           ┌────────▼────────┐
│  PostgreSQL 14 │           │    Redis 7      │
│                │           │                 │
│  Prisma ORM    │           │  Rate Limiting  │
│  Migrations    │           │  Storage        │
└────────────────┘           └─────────────────┘
```

---

**Legend:**
- `▼` : Data flow direction
- `◄` : Relationship/Reference
- `✓` : Success path
- `✗` : Error/Alternative path
- `•` : List item
