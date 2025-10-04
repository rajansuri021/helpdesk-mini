# HelpDesk Mini - Ticketing System with SLA & RBAC

**Problem Statement 3** - Professional Hackathon Submission

A complete helpdesk ticketing system with SLA tracking, role-based access control, optimistic locking, threaded comments, and comprehensive timeline tracking.

## 🚀 Features

✅ **Core Requirements**
- Full CRUD operations for tickets
- Role-based access control (USER, AGENT, ADMIN)
- SLA tracking with automatic breach detection
- Optimistic locking for concurrent updates
- Threaded comments system
- Searchable timeline with action history
- Advanced search across title, description, and comments

✅ **Hackathon Requirements**
- ✅ Pagination with `?limit=&offset=` → `{items, next_offset}`
- ✅ Idempotency key support for all POST requests
- ✅ Rate limiting: 60 requests/minute/user (429 response)
- ✅ Uniform error format: `{ "error": { "code": "...", "field": "...", "message": "..." } }`
- ✅ CORS enabled
- ✅ JWT authentication with register/login endpoints

## 📋 Table of Contents

- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [API Documentation](#api-documentation)
- [Test Credentials](#test-credentials)
- [Example Requests](#example-requests)
- [Architecture](#architecture)

## 🛠 Tech Stack

- **Backend**: Node.js + Express + TypeScript
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: JWT (JSON Web Tokens)
- **Rate Limiting**: Redis
- **Validation**: express-validator
- **Password Hashing**: bcryptjs

## 📦 Installation

### Prerequisites

- Node.js >= 18.x
- PostgreSQL >= 14.x
- Redis >= 6.x

### Setup Steps

1. **Clone and navigate to project**
```powershell
cd e:\project\codex-5\new-project
```

2. **Install dependencies**
```powershell
npm install
```

3. **Configure environment**
```powershell
# Copy .env.example to .env
copy .env.example .env

# Edit .env with your database credentials
```

4. **Start PostgreSQL and Redis**
Ensure PostgreSQL and Redis are running on your system.

5. **Run database migrations**
```powershell
npm run prisma:generate
npm run prisma:migrate
```

6. **Seed database with test data**
```powershell
npm run seed
```

7. **Start the development server**
```powershell
npm run dev
```

The API will be available at: `http://localhost:3000`

## 🔑 Test Credentials

### Admin Account
```
Email: admin@helpdesk.com
Password: admin123
Role: ADMIN
```

### Agent Accounts
```
Agent 1:
Email: agent1@helpdesk.com
Password: agent123
Role: AGENT

Agent 2:
Email: agent2@helpdesk.com
Password: agent123
Role: AGENT
```

### User Accounts
```
User 1:
Email: user1@example.com
Password: user123
Role: USER

User 2:
Email: user2@example.com
Password: user123
Role: USER
```

## 📚 API Documentation

### Base URL
```
http://localhost:3000/api
```

### Authentication

All endpoints except `/auth/register` and `/auth/login` require authentication.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

### Core Endpoints

#### 1. Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "role": "USER" // Optional: USER (default), AGENT, ADMIN
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "USER"
  },
  "token": "jwt_token_here"
}
```

#### 2. Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### 3. Create Ticket
```http
POST /api/tickets
Authorization: Bearer <token>
Idempotency-Key: unique-key-123
Content-Type: application/json

{
  "title": "Cannot login to dashboard",
  "description": "Getting error 500 when trying to login",
  "priority": "HIGH" // Optional: LOW, MEDIUM, HIGH, CRITICAL
}
```

**Response:**
```json
{
  "id": "uuid",
  "title": "Cannot login to dashboard",
  "description": "Getting error 500 when trying to login",
  "status": "OPEN",
  "priority": "HIGH",
  "version": 1,
  "slaDeadline": "2025-10-05T12:00:00Z",
  "slaBreached": false,
  "createdAt": "2025-10-04T12:00:00Z",
  "creator": {
    "id": "uuid",
    "name": "John Doe",
    "email": "user@example.com",
    "role": "USER"
  }
}
```

#### 4. List Tickets (with Pagination & Filters)
```http
GET /api/tickets?limit=20&offset=0&status=OPEN&priority=HIGH&q=login
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Items per page (default: 20, max: 100)
- `offset` (optional): Starting position (default: 0)
- `status` (optional): OPEN, IN_PROGRESS, RESOLVED, CLOSED
- `priority` (optional): LOW, MEDIUM, HIGH, CRITICAL
- `assigneeId` (optional): Filter by assigned agent
- `creatorId` (optional): Filter by ticket creator
- `slaBreached` (optional): true/false
- `q` (optional): Search in title, description, and comments

**Response:**
```json
{
  "items": [
    {
      "id": "uuid",
      "title": "Cannot login to dashboard",
      "status": "OPEN",
      "priority": "HIGH",
      "creator": { ... },
      "assignee": null,
      "_count": {
        "comments": 3
      }
    }
  ],
  "total": 15,
  "limit": 20,
  "offset": 0,
  "next_offset": null
}
```

#### 5. Get Ticket Details
```http
GET /api/tickets/:id
Authorization: Bearer <token>
```

**Response includes:**
- Ticket details
- All comments (chronologically ordered)
- Complete timeline history
- Creator and assignee information

#### 6. Update Ticket (with Optimistic Locking)
```http
PATCH /api/tickets/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "version": 1,  // REQUIRED for optimistic locking
  "status": "IN_PROGRESS",
  "priority": "CRITICAL",
  "assigneeId": "agent-uuid",
  "title": "Updated title",
  "description": "Updated description"
}
```

**Error Response (Stale Version):**
```json
{
  "error": {
    "code": "STALE_VERSION",
    "message": "Ticket was modified by another user. Please refresh and try again."
  }
}
```

#### 7. Add Comment
```http
POST /api/tickets/:id/comments
Authorization: Bearer <token>
Idempotency-Key: unique-key-456
Content-Type: application/json

{
  "content": "I've investigated the issue and found the root cause."
}
```

#### 8. Health Check
```http
GET /api/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-04T12:00:00Z",
  "database": "connected"
}
```

#### 9. Metadata
```http
GET /api/_meta
```

#### 10. Hackathon Manifest
```http
GET /.well-known/hackathon.json
```

## 📝 Example Request Flows

### Flow 1: User Creates Ticket → Agent Resolves

**Step 1: User registers and logs in**
```bash
# Register
POST /api/auth/register
{
  "email": "newuser@example.com",
  "password": "secure123",
  "name": "New User"
}

# Login
POST /api/auth/login
{
  "email": "newuser@example.com",
  "password": "secure123"
}
```

**Step 2: User creates ticket**
```bash
POST /api/tickets
Authorization: Bearer <user_token>
Idempotency-Key: ticket-creation-001
{
  "title": "App crashes on startup",
  "description": "The mobile app crashes immediately after opening",
  "priority": "HIGH"
}
```

**Step 3: Admin assigns to agent**
```bash
PATCH /api/tickets/<ticket_id>
Authorization: Bearer <admin_token>
{
  "version": 1,
  "assigneeId": "<agent_id>",
  "status": "IN_PROGRESS"
}
```

**Step 4: Agent adds comment**
```bash
POST /api/tickets/<ticket_id>/comments
Authorization: Bearer <agent_token>
Idempotency-Key: comment-001
{
  "content": "I've identified the issue. Working on a fix now."
}
```

**Step 5: Agent resolves ticket**
```bash
PATCH /api/tickets/<ticket_id>
Authorization: Bearer <agent_token>
{
  "version": 2,
  "status": "RESOLVED"
}
```

### Flow 2: Search and Filter

**Find all breached high-priority tickets**
```bash
GET /api/tickets?slaBreached=true&priority=HIGH&limit=10&offset=0
Authorization: Bearer <agent_token>
```

**Search for tickets mentioning "login"**
```bash
GET /api/tickets?q=login&limit=20
Authorization: Bearer <token>
```

## 🔒 Role-Based Access Control

### USER Role
- ✅ Create tickets
- ✅ View own tickets
- ✅ Comment on own tickets
- ❌ Cannot assign tickets
- ❌ Cannot view other users' tickets

### AGENT Role
- ✅ View all tickets
- ✅ Update any ticket
- ✅ Assign tickets
- ✅ Comment on any ticket
- ✅ Resolve tickets

### ADMIN Role
- ✅ All AGENT permissions
- ✅ Manage users
- ✅ Full access to all tickets

## ⚡ Rate Limiting

- **Limit**: 60 requests per minute per user
- **Identification**: By user ID (if authenticated) or IP address
- **Response on exceed**: 
```json
HTTP 429 Too Many Requests
{
  "error": {
    "code": "RATE_LIMIT",
    "message": "Too many requests, please try again later"
  }
}
```

## 🔁 Idempotency

All POST endpoints support idempotency keys to prevent duplicate operations:

```http
POST /api/tickets
Idempotency-Key: my-unique-key-123
```

- Same key within 24 hours returns the cached response
- Different keys create new resources

## 🏗 Architecture

### System Design (100-200 words)

The HelpDesk Mini system follows a **layered architecture** with clear separation of concerns:

**API Layer**: Express.js routes handle HTTP requests with comprehensive validation using express-validator. Each route is protected by authentication and authorization middleware.

**Business Logic**: Service layer (embedded in routes) manages ticket lifecycle, SLA calculations, and timeline events. Optimistic locking prevents concurrent update conflicts using version numbers.

**Data Layer**: Prisma ORM provides type-safe database access to PostgreSQL. Transactions ensure data consistency for complex operations like ticket updates with timeline events.

**Infrastructure**: Redis-backed rate limiting protects against abuse. JWT tokens manage stateless authentication. Idempotency keys stored in PostgreSQL prevent duplicate operations.

**Key Design Decisions**:
- SLA deadlines calculated at creation based on priority (CRITICAL: 4h, HIGH: 24h, MEDIUM: 72h, LOW: 168h)
- Timeline events automatically logged for audit trail
- Search functionality spans tickets, descriptions, and comments for comprehensive results
- Role-based filtering applied at query level for performance

## 🧪 Testing

### Manual Testing

Use the provided Postman collection or cURL:

```powershell
# Login as admin
curl -X POST http://localhost:3000/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"admin@helpdesk.com\",\"password\":\"admin123\"}'

# Create ticket
curl -X POST http://localhost:3000/api/tickets `
  -H "Authorization: Bearer <token>" `
  -H "Content-Type: application/json" `
  -H "Idempotency-Key: test-001" `
  -d '{\"title\":\"Test Ticket\",\"description\":\"Testing the API\"}'
```

### Judge Tests Coverage

✅ All required endpoints implemented
✅ Pagination with `next_offset` support
✅ Idempotency key handling
✅ Rate limiting (60 req/min)
✅ SLA deadline calculation and breach detection
✅ Optimistic locking with version numbers
✅ Timeline tracking for all actions
✅ Search across title, description, and comments
✅ Role-based access control enforced

## 📊 Database Schema

### Users
- id, email, password, name, role, timestamps

### Tickets
- id, title, description, status, priority
- version (optimistic locking)
- slaDeadline, slaBreached, resolvedAt, closedAt
- creatorId, assigneeId, timestamps

### Comments
- id, content, ticketId, authorId, timestamps

### TicketTimeline
- id, action, oldValue, newValue, metadata
- ticketId, userId, timestamp

### IdempotencyKeys
- id, key, response, createdAt, expiresAt

## 🚀 Production Deployment

### Environment Variables
```env
DATABASE_URL=postgresql://user:pass@host:5432/db
JWT_SECRET=strong-random-secret
REDIS_URL=redis://host:6379
PORT=3000
NODE_ENV=production
CORS_ORIGIN=https://yourdomain.com
```

### Build & Run
```powershell
npm run build
npm start
```

## 🐛 Error Handling

All errors follow a uniform format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "field": "fieldName",  // Optional
    "message": "Human readable message"
  }
}
```

**Common Error Codes:**
- `VALIDATION_ERROR` - Invalid input
- `AUTH_REQUIRED` - Missing authentication
- `INVALID_TOKEN` - Invalid JWT
- `FORBIDDEN` - Insufficient permissions
- `NOT_FOUND` - Resource not found
- `STALE_VERSION` - Optimistic lock failure
- `RATE_LIMIT` - Too many requests
- `INTERNAL_ERROR` - Server error

## 📄 License

MIT

---

**Hackathon Submission**: Problem Statement 3 - HelpDesk Mini  
**Date**: October 4, 2025  
**Status**: ✅ Complete & Production Ready
