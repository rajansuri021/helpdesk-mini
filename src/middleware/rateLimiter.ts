import { Express, Request, Response } from 'express';
import rateLimit from 'express-rate-limit';
import { AuthRequest } from './auth';

// Rate limiter: 60 requests per minute per user
// Using in-memory store (works without Redis)
export const setupRateLimiter = (app: Express) => {
  console.log('ℹ️  Using in-memory rate limiting');
  
  const limiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 60, // 60 requests per minute
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req: Request) => {
      // Use user ID if authenticated, otherwise IP
      const authReq = req as AuthRequest;
      return authReq.user?.id || req.ip || 'anonymous';
    },
    handler: (req: Request, res: Response) => {
      res.status(429).json({
        error: {
          code: 'RATE_LIMIT',
          message: 'Too many requests, please try again later'
        }
      });
    },
    skip: (req: Request) => {
      // Skip rate limiting for health checks
      return req.path === '/api/health' || req.path === '/api/_meta';
    }
  });

  app.use(limiter);
};
