import { Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';
import { AppError } from './errorHandler';

const prisma = new PrismaClient();

export const handleIdempotency = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const idempotencyKey = req.headers['idempotency-key'] as string;

  if (!idempotencyKey) {
    return next();
  }

  try {
    // Check if this key was used before
    const existing = await prisma.idempotencyKey.findUnique({
      where: { key: idempotencyKey }
    });

    if (existing) {
      // Return cached response
      const cachedResponse = JSON.parse(existing.response);
      return res.status(cachedResponse.statusCode).json(cachedResponse.body);
    }

    // Store original res.json to intercept response
    const originalJson = res.json.bind(res);
    
    res.json = function (body: any) {
      // Save the response for this idempotency key
      const statusCode = res.statusCode;
      
      prisma.idempotencyKey.create({
        data: {
          key: idempotencyKey,
          response: JSON.stringify({ statusCode, body }),
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
        }
      }).catch((err: any) => {
        console.error('Failed to store idempotency key:', err);
      });

      return originalJson(body);
    } as any;

    next();
  } catch (error) {
    next(error);
  }
};

// Cleanup expired idempotency keys (run periodically)
export const cleanupExpiredKeys = async () => {
  try {
    await prisma.idempotencyKey.deleteMany({
      where: {
        expiresAt: {
          lt: new Date()
        }
      }
    });
  } catch (error) {
    console.error('Failed to cleanup expired idempotency keys:', error);
  }
};

// Run cleanup every hour
setInterval(cleanupExpiredKeys, 60 * 60 * 1000);
