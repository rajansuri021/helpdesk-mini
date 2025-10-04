# API Test Script - HelpDesk Mini
# This script tests all major endpoints

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "HelpDesk Mini - API Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$API_BASE = "http://localhost:3000/api"
$testsPassed = 0
$testsFailed = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null
    )
    
    Write-Host "Testing: $Name..." -ForegroundColor Yellow -NoNewline
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
        }
        
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = "application/json"
        }
        
        $response = Invoke-RestMethod @params -ErrorAction Stop
        Write-Host " ✓ PASSED" -ForegroundColor Green
        $script:testsPassed++
        return $response
    }
    catch {
        Write-Host " ✗ FAILED" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $script:testsFailed++
        return $null
    }
}

# Test 1: Health Check
Write-Host "`n[1/15] Health Check" -ForegroundColor Cyan
$health = Test-Endpoint -Name "GET /api/health" -Method Get -Url "$API_BASE/health"
if ($health -and $health.status -eq "healthy") {
    Write-Host "  Status: $($health.status)" -ForegroundColor Green
}

# Test 2: Metadata
Write-Host "`n[2/15] Metadata" -ForegroundColor Cyan
$meta = Test-Endpoint -Name "GET /api/_meta" -Method Get -Url "$API_BASE/_meta"
if ($meta) {
    Write-Host "  Name: $($meta.name)" -ForegroundColor Green
    Write-Host "  Version: $($meta.version)" -ForegroundColor Green
}

# Test 3: Hackathon Manifest
Write-Host "`n[3/15] Hackathon Manifest" -ForegroundColor Cyan
$manifest = Test-Endpoint -Name "GET /.well-known/hackathon.json" -Method Get -Url "http://localhost:3000/.well-known/hackathon.json"
if ($manifest) {
    Write-Host "  Problem: $($manifest.problem)" -ForegroundColor Green
}

# Test 4: Register User
Write-Host "`n[4/15] User Registration" -ForegroundColor Cyan
$registerBody = @{
    email = "test-$(Get-Random)@example.com"
    password = "test123"
    name = "Test User"
    role = "USER"
} | ConvertTo-Json

$registerResponse = Test-Endpoint -Name "POST /api/auth/register" -Method Post -Url "$API_BASE/auth/register" -Body $registerBody
$testUserEmail = $null
$testUserToken = $null
if ($registerResponse) {
    Write-Host "  User ID: $($registerResponse.user.id)" -ForegroundColor Green
    Write-Host "  Email: $($registerResponse.user.email)" -ForegroundColor Green
    $testUserEmail = $registerResponse.user.email
    $testUserToken = $registerResponse.token
}

# Test 5: Login
Write-Host "`n[5/15] User Login" -ForegroundColor Cyan
$loginBody = @{
    email = "admin@helpdesk.com"
    password = "admin123"
} | ConvertTo-Json

$loginResponse = Test-Endpoint -Name "POST /api/auth/login" -Method Post -Url "$API_BASE/auth/login" -Body $loginBody
$adminToken = $null
if ($loginResponse) {
    Write-Host "  Role: $($loginResponse.user.role)" -ForegroundColor Green
    Write-Host "  Token received: Yes" -ForegroundColor Green
    $adminToken = $loginResponse.token
}

if (-not $adminToken) {
    Write-Host "`nERROR: Could not obtain admin token. Stopping tests." -ForegroundColor Red
    exit 1
}

# Test 6: Create Ticket (with Idempotency)
Write-Host "`n[6/15] Create Ticket" -ForegroundColor Cyan
$ticketBody = @{
    title = "Test Ticket - API Test"
    description = "This is a test ticket created by the API test script"
    priority = "HIGH"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Idempotency-Key" = "test-$(Get-Random)"
}

$ticket = Test-Endpoint -Name "POST /api/tickets" -Method Post -Url "$API_BASE/tickets" -Headers $headers -Body $ticketBody
$ticketId = $null
$ticketVersion = $null
if ($ticket) {
    Write-Host "  Ticket ID: $($ticket.id)" -ForegroundColor Green
    Write-Host "  Status: $($ticket.status)" -ForegroundColor Green
    Write-Host "  Priority: $($ticket.priority)" -ForegroundColor Green
    Write-Host "  Version: $($ticket.version)" -ForegroundColor Green
    $ticketId = $ticket.id
    $ticketVersion = $ticket.version
}

# Test 7: List Tickets
Write-Host "`n[7/15] List Tickets (with pagination)" -ForegroundColor Cyan
$headers = @{
    "Authorization" = "Bearer $adminToken"
}

$tickets = Test-Endpoint -Name "GET /api/tickets?limit=5&offset=0" -Method Get -Url "$API_BASE/tickets?limit=5&offset=0" -Headers $headers
if ($tickets) {
    Write-Host "  Total tickets: $($tickets.total)" -ForegroundColor Green
    Write-Host "  Returned: $($tickets.items.Count)" -ForegroundColor Green
    Write-Host "  Next offset: $($tickets.next_offset)" -ForegroundColor Green
}

# Test 8: Filter Tickets by Status
Write-Host "`n[8/15] Filter Tickets by Status" -ForegroundColor Cyan
$filtered = Test-Endpoint -Name "GET /api/tickets?status=OPEN&limit=5" -Method Get -Url "$API_BASE/tickets?status=OPEN&limit=5" -Headers $headers
if ($filtered) {
    Write-Host "  Open tickets: $($filtered.items.Count)" -ForegroundColor Green
}

# Test 9: Search Tickets
Write-Host "`n[9/15] Search Tickets" -ForegroundColor Cyan
$searched = Test-Endpoint -Name "GET /api/tickets?q=test&limit=5" -Method Get -Url "$API_BASE/tickets?q=test&limit=5" -Headers $headers
if ($searched) {
    Write-Host "  Search results: $($searched.items.Count)" -ForegroundColor Green
}

# Test 10: Get Ticket Details
Write-Host "`n[10/15] Get Ticket Details" -ForegroundColor Cyan
if ($ticketId) {
    $ticketDetail = Test-Endpoint -Name "GET /api/tickets/:id" -Method Get -Url "$API_BASE/tickets/$ticketId" -Headers $headers
    if ($ticketDetail) {
        Write-Host "  Comments: $($ticketDetail.comments.Count)" -ForegroundColor Green
        Write-Host "  Timeline events: $($ticketDetail.timeline.Count)" -ForegroundColor Green
    }
}
else {
    Write-Host "  Skipped (no ticket ID)" -ForegroundColor Yellow
}

# Test 11: Add Comment
Write-Host "`n[11/15] Add Comment to Ticket" -ForegroundColor Cyan
if ($ticketId) {
    $commentBody = @{
        content = "This is a test comment added by the API test script"
    } | ConvertTo-Json
    
    $headers["Idempotency-Key"] = "comment-$(Get-Random)"
    
    $comment = Test-Endpoint -Name "POST /api/tickets/:id/comments" -Method Post -Url "$API_BASE/tickets/$ticketId/comments" -Headers $headers -Body $commentBody
    if ($comment) {
        Write-Host "  Comment ID: $($comment.id)" -ForegroundColor Green
    }
}
else {
    Write-Host "  Skipped (no ticket ID)" -ForegroundColor Yellow
}

# Test 12: Update Ticket (with Optimistic Locking)
Write-Host "`n[12/15] Update Ticket (Optimistic Locking)" -ForegroundColor Cyan
if ($ticketId -and $ticketVersion) {
    $updateBody = @{
        version = $ticketVersion
        status = "IN_PROGRESS"
        priority = "MEDIUM"
    } | ConvertTo-Json
    
    $headers.Remove("Idempotency-Key")
    
    $updated = Test-Endpoint -Name "PATCH /api/tickets/:id" -Method Patch -Url "$API_BASE/tickets/$ticketId" -Headers $headers -Body $updateBody
    if ($updated) {
        Write-Host "  New status: $($updated.status)" -ForegroundColor Green
        Write-Host "  New priority: $($updated.priority)" -ForegroundColor Green
        Write-Host "  New version: $($updated.version)" -ForegroundColor Green
    }
}
else {
    Write-Host "  Skipped (no ticket ID or version)" -ForegroundColor Yellow
}

# Test 13: Test Stale Version (should fail with 409)
Write-Host "`n[13/15] Test Stale Version (Expected Failure)" -ForegroundColor Cyan
if ($ticketId) {
    $staleBody = @{
        version = 1  # Old version
        status = "CLOSED"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_BASE/tickets/$ticketId" -Method Patch -Headers $headers -Body $staleBody -ContentType "application/json" -ErrorAction Stop
        Write-Host "  ✗ FAILED - Should have returned 409" -ForegroundColor Red
        $script:testsFailed++
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-Host "  ✓ PASSED - Correctly returned 409 Conflict" -ForegroundColor Green
            $script:testsPassed++
        }
        else {
            Write-Host "  ✗ FAILED - Wrong status code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
            $script:testsFailed++
        }
    }
}
else {
    Write-Host "  Skipped (no ticket ID)" -ForegroundColor Yellow
}

# Test 14: Test Unauthorized Access (should fail with 401)
Write-Host "`n[14/15] Test Unauthorized Access (Expected Failure)" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$API_BASE/tickets" -Method Get -ErrorAction Stop
    Write-Host "  ✗ FAILED - Should have returned 401" -ForegroundColor Red
    $script:testsFailed++
}
catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "  ✓ PASSED - Correctly returned 401 Unauthorized" -ForegroundColor Green
        $script:testsPassed++
    }
    else {
        Write-Host "  ✗ FAILED - Wrong status code" -ForegroundColor Red
        $script:testsFailed++
    }
}

# Test 15: Test Rate Limiting (optional - takes time)
Write-Host "`n[15/15] Test Rate Limiting (Skipped - would take ~1 minute)" -ForegroundColor Cyan
Write-Host "  To test rate limiting manually, make 61 requests within 1 minute" -ForegroundColor Yellow

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tests Passed: $testsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $testsFailed" -ForegroundColor Red
Write-Host "Total Tests: $($testsPassed + $testsFailed)" -ForegroundColor White
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "🎉 All tests passed!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "⚠️  Some tests failed. Check the output above." -ForegroundColor Yellow
    exit 1
}
