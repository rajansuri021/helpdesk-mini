import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.routes';
import ticketRoutes from './routes/ticket.routes';
import healthRoutes from './routes/health.routes';
import adminRoutes from './routes/admin.routes';
import { errorHandler } from './middleware/errorHandler';
import { setupRateLimiter } from './middleware/rateLimiter';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiter setup
setupRateLimiter(app);

// API Routes - MUST come before static files
app.use('/api/auth', authRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api', healthRoutes);

// Serve static files (frontend) - comes AFTER API routes
app.use(express.static('public'));

// Serve hackathon manifest
app.get('/.well-known/hackathon.json', (req, res) => {
  res.json({
    problem: 3,
    name: "HelpDesk Mini",
    version: "1.0.0",
    authors: ["Hackathon Participant"],
    endpoints: [
      "POST /api/auth/register",
      "POST /api/auth/login",
      "POST /api/tickets",
      "GET /api/tickets",
      "GET /api/tickets/:id",
      "PATCH /api/tickets/:id",
      "POST /api/tickets/:id/comments",
      "GET /api/health",
      "GET /api/_meta"
    ],
    features: [
      "Role-based access control (USER, AGENT, ADMIN)",
      "SLA tracking with breach detection",
      "Optimistic locking for ticket updates",
      "Threaded comments system",
      "Searchable timeline",
      "Pagination support",
      "Idempotency key handling",
      "Rate limiting (60 req/min/user)"
    ]
  });
});

// Error handling
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`🚀 HelpDesk Mini server running on port ${PORT}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV}`);
  console.log(`🔗 API: http://localhost:${PORT}/api`);
  console.log(`🏥 Health: http://localhost:${PORT}/api/health`);
});

export default app;
