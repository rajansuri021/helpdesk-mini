import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

// Get all users (admin only)
router.get('/users', authenticate, authorize('ADMIN'), async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        isApproved: true,
        createdAt: true,
        _count: {
          select: {
            ticketsCreated: true,
            ticketsAssigned: true,
            comments: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ users });
  } catch (error: any) {
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: error.message
      }
    });
  }
});

// Get pending agent approvals
router.get('/pending-agents', authenticate, authorize('ADMIN'), async (req, res) => {
  try {
    const pendingAgents = await prisma.user.findMany({
      where: {
        role: 'AGENT',
        isApproved: false
      },
      select: {
        id: true,
        name: true,
        email: true,
        createdAt: true
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ 
      pending_agents: pendingAgents,
      count: pendingAgents.length 
    });
  } catch (error: any) {
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: error.message
      }
    });
  }
});

// Approve agent
router.post('/approve-agent/:userId', authenticate, authorize('ADMIN'), async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({
        error: {
          code: 'NOT_FOUND',
          message: 'User not found'
        }
      });
    }

    if (user.role !== 'AGENT') {
      return res.status(400).json({
        error: {
          code: 'INVALID_REQUEST',
          message: 'User is not an agent'
        }
      });
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { isApproved: true },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        isApproved: true
      }
    });

    res.json({ 
      message: 'Agent approved successfully',
      user: updatedUser 
    });
  } catch (error: any) {
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: error.message
      }
    });
  }
});

// Reject agent
router.post('/reject-agent/:userId', authenticate, authorize('ADMIN'), async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({
        error: {
          code: 'NOT_FOUND',
          message: 'User not found'
        }
      });
    }

    if (user.role !== 'AGENT') {
      return res.status(400).json({
        error: {
          code: 'INVALID_REQUEST',
          message: 'User is not an agent'
        }
      });
    }

    await prisma.user.delete({
      where: { id: userId }
    });

    res.json({ 
      message: 'Agent application rejected and deleted' 
    });
  } catch (error: any) {
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: error.message
      }
    });
  }
});

// Delete user (admin only)
router.delete('/users/:userId', authenticate, authorize('ADMIN'), async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({
        error: {
          code: 'NOT_FOUND',
          message: 'User not found'
        }
      });
    }

    if (user.role === 'ADMIN') {
      return res.status(403).json({
        error: {
          code: 'FORBIDDEN',
          message: 'Cannot delete admin users'
        }
      });
    }

    await prisma.user.delete({
      where: { id: userId }
    });

    res.json({ 
      message: 'User deleted successfully' 
    });
  } catch (error: any) {
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: error.message
      }
    });
  }
});

export default router;
