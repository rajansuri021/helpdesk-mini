-- CreateTable-- CreateTable

CREATE TABLE "users" (CREATE TABLE "users" (

    "id" TEXT NOT NULL,    "id" TEXT NOT NULL,

    "email" TEXT NOT NULL,    "email" TEXT NOT NULL,

    "password" TEXT NOT NULL,    "password" TEXT NOT NULL,

    "name" TEXT NOT NULL,    "name" TEXT NOT NULL,

    "role" TEXT NOT NULL DEFAULT 'USER',    "role" TEXT NOT NULL DEFAULT 'USER',

    "isApproved" BOOLEAN NOT NULL DEFAULT true,    "isApproved" BOOLEAN NOT NULL DEFAULT true,

    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    "updatedAt" TIMESTAMP(3) NOT NULL,    "updatedAt" TIMESTAMP(3) NOT NULL,



    CONSTRAINT "users_pkey" PRIMARY KEY ("id")    CONSTRAINT "users_pkey" PRIMARY KEY ("id")

););



-- CreateTable-- CreateTable

CREATE TABLE "tickets" (CREATE TABLE "tickets" (

    "id" TEXT NOT NULL,    "id" TEXT NOT NULL,

    "title" TEXT NOT NULL,    "title" TEXT NOT NULL,

    "description" TEXT NOT NULL,    "description" TEXT NOT NULL,

    "status" TEXT NOT NULL DEFAULT 'OPEN',    "status" TEXT NOT NULL DEFAULT 'OPEN',

    "priority" TEXT NOT NULL DEFAULT 'MEDIUM',    "priority" TEXT NOT NULL DEFAULT 'MEDIUM',

    "version" INTEGER NOT NULL DEFAULT 1,    "version" INTEGER NOT NULL DEFAULT 1,

    "slaDeadline" TIMESTAMP(3),    "slaDeadline" TIMESTAMP(3),

    "slaBreached" BOOLEAN NOT NULL DEFAULT false,    "slaBreached" BOOLEAN NOT NULL DEFAULT false,

    "resolvedAt" TIMESTAMP(3),    "resolvedAt" TIMESTAMP(3),

    "closedAt" TIMESTAMP(3),    "closedAt" TIMESTAMP(3),

    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    "updatedAt" TIMESTAMP(3) NOT NULL,    "updatedAt" TIMESTAMP(3) NOT NULL,

    "creatorId" TEXT NOT NULL,    "creatorId" TEXT NOT NULL,

    "assigneeId" TEXT,    "assigneeId" TEXT,



    CONSTRAINT "tickets_pkey" PRIMARY KEY ("id")    CONSTRAINT "tickets_pkey" PRIMARY KEY ("id")

););



-- CreateTable-- CreateTable

CREATE TABLE "comments" (CREATE TABLE "comments" (

    "id" TEXT NOT NULL,    "id" TEXT NOT NULL,

    "content" TEXT NOT NULL,    "content" TEXT NOT NULL,

    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    "updatedAt" TIMESTAMP(3) NOT NULL,    "updatedAt" TIMESTAMP(3) NOT NULL,

    "ticketId" TEXT NOT NULL,    "ticketId" TEXT NOT NULL,

    "authorId" TEXT NOT NULL,    "authorId" TEXT NOT NULL,



    CONSTRAINT "comments_pkey" PRIMARY KEY ("id")    CONSTRAINT "comments_pkey" PRIMARY KEY ("id")

););



-- CreateTable-- CreateTable

CREATE TABLE "ticket_timeline" (CREATE TABLE "ticket_timeline" (

    "id" TEXT NOT NULL,    "id" TEXT NOT NULL,

    "action" TEXT NOT NULL,    "action" TEXT NOT NULL,

    "oldValue" TEXT,    "oldValue" TEXT,

    "newValue" TEXT,    "newValue" TEXT,

    "metadata" TEXT,    "metadata" TEXT,

    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    "ticketId" TEXT NOT NULL,    "ticketId" TEXT NOT NULL,

    "userId" TEXT,    "userId" TEXT,



    CONSTRAINT "ticket_timeline_pkey" PRIMARY KEY ("id")    CONSTRAINT "ticket_timeline_pkey" PRIMARY KEY ("id")

););



-- CreateTable-- CreateTable

CREATE TABLE "idempotency_keys" (CREATE TABLE "idempotency_keys" (

    "id" TEXT NOT NULL,    "id" TEXT NOT NULL,

    "key" TEXT NOT NULL,    "key" TEXT NOT NULL,

    "response" TEXT NOT NULL,    "response" TEXT NOT NULL,

    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    "expiresAt" TIMESTAMP(3) NOT NULL,    "expiresAt" TIMESTAMP(3) NOT NULL,



    CONSTRAINT "idempotency_keys_pkey" PRIMARY KEY ("id")    CONSTRAINT "idempotency_keys_pkey" PRIMARY KEY ("id")

););



-- CreateIndex-- CreateIndex

CREATE UNIQUE INDEX "users_email_key" ON "users"("email");CREATE UNIQUE INDEX "users_email_key" ON "users"("email");



-- CreateIndex-- CreateIndex

CREATE INDEX "tickets_status_idx" ON "tickets"("status");CREATE INDEX "tickets_status_idx" ON "tickets"("status");



-- CreateIndex-- CreateIndex

CREATE INDEX "tickets_priority_idx" ON "tickets"("priority");CREATE INDEX "tickets_priority_idx" ON "tickets"("priority");



-- CreateIndex-- CreateIndex

CREATE INDEX "tickets_creatorId_idx" ON "tickets"("creatorId");CREATE INDEX "tickets_creatorId_idx" ON "tickets"("creatorId");



-- CreateIndex-- CreateIndex

CREATE INDEX "tickets_assigneeId_idx" ON "tickets"("assigneeId");CREATE INDEX "tickets_assigneeId_idx" ON "tickets"("assigneeId");



-- CreateIndex-- CreateIndex

CREATE INDEX "tickets_slaBreached_idx" ON "tickets"("slaBreached");CREATE INDEX "tickets_slaBreached_idx" ON "tickets"("slaBreached");



-- CreateIndex-- CreateIndex

CREATE INDEX "tickets_createdAt_idx" ON "tickets"("createdAt");CREATE INDEX "tickets_createdAt_idx" ON "tickets"("createdAt");



-- CreateIndex-- CreateIndex

CREATE INDEX "comments_ticketId_idx" ON "comments"("ticketId");CREATE INDEX "comments_ticketId_idx" ON "comments"("ticketId");



-- CreateIndex-- CreateIndex

CREATE INDEX "comments_createdAt_idx" ON "comments"("createdAt");CREATE INDEX "comments_createdAt_idx" ON "comments"("createdAt");



-- CreateIndex-- CreateIndex

CREATE INDEX "ticket_timeline_ticketId_idx" ON "ticket_timeline"("ticketId");CREATE INDEX "ticket_timeline_ticketId_idx" ON "ticket_timeline"("ticketId");



-- CreateIndex-- CreateIndex

CREATE INDEX "ticket_timeline_createdAt_idx" ON "ticket_timeline"("createdAt");CREATE INDEX "ticket_timeline_createdAt_idx" ON "ticket_timeline"("createdAt");



-- CreateIndex-- CreateIndex

CREATE UNIQUE INDEX "idempotency_keys_key_key" ON "idempotency_keys"("key");CREATE UNIQUE INDEX "idempotency_keys_key_key" ON "idempotency_keys"("key");



-- CreateIndex-- CreateIndex

CREATE INDEX "idempotency_keys_expiresAt_idx" ON "idempotency_keys"("expiresAt");CREATE INDEX "idempotency_keys_expiresAt_idx" ON "idempotency_keys"("expiresAt");



-- AddForeignKey-- AddForeignKey

ALTER TABLE "tickets" ADD CONSTRAINT "tickets_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;ALTER TABLE "tickets" ADD CONSTRAINT "tickets_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;



-- AddForeignKey-- AddForeignKey

ALTER TABLE "tickets" ADD CONSTRAINT "tickets_assigneeId_fkey" FOREIGN KEY ("assigneeId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;ALTER TABLE "tickets" ADD CONSTRAINT "tickets_assigneeId_fkey" FOREIGN KEY ("assigneeId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;



-- AddForeignKey-- AddForeignKey

ALTER TABLE "comments" ADD CONSTRAINT "comments_ticketId_fkey" FOREIGN KEY ("ticketId") REFERENCES "tickets"("id") ON DELETE CASCADE ON UPDATE CASCADE;ALTER TABLE "comments" ADD CONSTRAINT "comments_ticketId_fkey" FOREIGN KEY ("ticketId") REFERENCES "tickets"("id") ON DELETE CASCADE ON UPDATE CASCADE;



-- AddForeignKey-- AddForeignKey

ALTER TABLE "comments" ADD CONSTRAINT "comments_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;ALTER TABLE "comments" ADD CONSTRAINT "comments_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;



-- AddForeignKey-- AddForeignKey

ALTER TABLE "ticket_timeline" ADD CONSTRAINT "ticket_timeline_ticketId_fkey" FOREIGN KEY ("ticketId") REFERENCES "tickets"("id") ON DELETE CASCADE ON UPDATE CASCADE;ALTER TABLE "ticket_timeline" ADD CONSTRAINT "ticket_timeline_ticketId_fkey" FOREIGN KEY ("ticketId") REFERENCES "tickets"("id") ON DELETE CASCADE ON UPDATE CASCADE;



-- AddForeignKey-- AddForeignKey

ALTER TABLE "ticket_timeline" ADD CONSTRAINT "ticket_timeline_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;ALTER TABLE "ticket_timeline" ADD CONSTRAINT "ticket_timeline_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;


