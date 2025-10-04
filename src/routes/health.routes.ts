import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const router = Router();
const prisma = new PrismaClient();

// GET /api/health
router.get('/health', async (req: Request, res: Response) => {
  try {
    // Check database connection
    await prisma.$queryRaw`SELECT 1`;
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      database: 'disconnected'
    });
  }
});

// GET /api/_meta
router.get('/_meta', async (req: Request, res: Response) => {
  try {
    const [userCount, ticketCount, commentCount] = await Promise.all([
      prisma.user.count(),
      prisma.ticket.count(),
      prisma.comment.count()
    ]);

    res.json({
      name: 'HelpDesk Mini',
      version: '1.0.0',
      problem: 3,
      description: 'Ticketing System with SLA, Comments & RBAC',
      features: [
        'Role-based access control (USER, AGENT, ADMIN)',
        'SLA tracking with breach detection',
        'Optimistic locking for ticket updates',
        'Threaded comments system',
        'Searchable timeline',
        'Pagination support',
        'Idempotency key handling',
        'Rate limiting (60 req/min/user)'
      ],
      stats: {
        users: userCount,
        tickets: ticketCount,
        comments: commentCount
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to retrieve metadata'
      }
    });
  }
});

export default router;
