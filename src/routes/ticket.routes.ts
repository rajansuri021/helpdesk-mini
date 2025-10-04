import { Router, Response, NextFunction } from 'express';
import { PrismaClient, Prisma } from '@prisma/client';
import { body, validationResult, query } from 'express-validator';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { handleIdempotency } from '../middleware/idempotency';
import { AppError } from '../middleware/errorHandler';
import { calculateSLADeadline } from '../utils/sla';

const router = Router();
const prisma = new PrismaClient();

// All routes require authentication
router.use(authenticate);

// Validation rules
const createTicketValidation = [
  body('title').notEmpty().withMessage('Title is required'),
  body('description').notEmpty().withMessage('Description is required'),
  body('priority').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']).withMessage('Invalid priority')
];

const updateTicketValidation = [
  body('title').optional().notEmpty().withMessage('Title cannot be empty'),
  body('description').optional().notEmpty().withMessage('Description cannot be empty'),
  body('status').optional().isIn(['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED']).withMessage('Invalid status'),
  body('priority').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']).withMessage('Invalid priority'),
  body('assigneeId').optional().isString(),
  body('version').isInt({ min: 1 }).withMessage('Version is required for optimistic locking')
];

const commentValidation = [
  body('content').notEmpty().withMessage('Comment content is required')
];

const paginationValidation = [
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('offset').optional().isInt({ min: 0 }).withMessage('Offset must be >= 0')
];

// POST /api/tickets - Create a new ticket
router.post('/', handleIdempotency, createTicketValidation, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const firstError = errors.array()[0];
      throw new AppError(400, firstError.msg, 'VALIDATION_ERROR', (firstError as any).path);
    }

    const { title, description, priority } = req.body;
    const userId = req.user!.id;

    // Calculate SLA deadline based on priority
    const slaDeadline = calculateSLADeadline(priority || 'MEDIUM');

    // Create ticket with initial timeline event
    const ticket = await prisma.ticket.create({
      data: {
        title,
        description,
        priority: priority || 'MEDIUM',
        creatorId: userId,
        slaDeadline,
        timeline: {
          create: {
            action: 'CREATED',
            userId
          }
        }
      },
      include: {
        creator: {
          select: {
            id: true,
            name: true,
            email: true,
            role: true
          }
        },
        assignee: {
          select: {
            id: true,
            name: true,
            email: true,
            role: true
          }
        }
      }
    });

    res.status(201).json(ticket);
  } catch (error) {
    next(error);
  }
});

// GET /api/tickets - List tickets with filtering and pagination
router.get('/', paginationValidation, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const firstError = errors.array()[0];
      throw new AppError(400, firstError.msg, 'VALIDATION_ERROR', (firstError as any).path);
    }

    const limit = parseInt(req.query.limit as string) || 20;
    const offset = parseInt(req.query.offset as string) || 0;
    
    // Build filter conditions
    const where: any = {};
    
    // Filter by status
    if (req.query.status) {
      where.status = req.query.status as any;
    }
    
    // Filter by priority
    if (req.query.priority) {
      where.priority = req.query.priority as any;
    }
    
    // Filter by assignee
    if (req.query.assigneeId) {
      where.assigneeId = req.query.assigneeId as string;
    }
    
    // Filter by creator
    if (req.query.creatorId) {
      where.creatorId = req.query.creatorId as string;
    }
    
    // Filter by SLA breached
    if (req.query.slaBreached === 'true') {
      where.slaBreached = true;
    }
    
    // Search in title, description, or latest comment
    if (req.query.q) {
      const searchTerm = req.query.q as string;
      where.OR = [
        { title: { contains: searchTerm, mode: 'insensitive' } },
        { description: { contains: searchTerm, mode: 'insensitive' } },
        { 
          comments: {
            some: {
              content: { contains: searchTerm, mode: 'insensitive' }
            }
          }
        }
      ];
    }

    // Apply role-based filtering
    if (req.user!.role === 'USER') {
      // Users can only see their own tickets
      where.creatorId = req.user!.id;
    }

    // Fetch tickets
    const [tickets, total] = await Promise.all([
      prisma.ticket.findMany({
        where,
        skip: offset,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          creator: {
            select: {
              id: true,
              name: true,
              email: true,
              role: true
            }
          },
          assignee: {
            select: {
              id: true,
              name: true,
              email: true,
              role: true
            }
          },
          _count: {
            select: { comments: true }
          }
        }
      }),
      prisma.ticket.count({ where })
    ]);

    // Check for SLA breaches
    const now = new Date();
    for (const ticket of tickets) {
      if (ticket.slaDeadline && !ticket.slaBreached && now > ticket.slaDeadline) {
        // Mark as breached
        await prisma.$transaction([
          prisma.ticket.update({
            where: { id: ticket.id },
            data: { slaBreached: true }
          }),
          prisma.ticketTimeline.create({
            data: {
              ticketId: ticket.id,
              action: 'SLA_BREACHED'
            }
          })
        ]);
        ticket.slaBreached = true;
      }
    }

    const hasMore = offset + tickets.length < total;
    const nextOffset = hasMore ? offset + limit : null;

    res.json({
      items: tickets,
      total,
      limit,
      offset,
      next_offset: nextOffset
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/tickets/:id - Get ticket by ID with timeline
router.get('/:id', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    const ticket = await prisma.ticket.findUnique({
      where: { id },
      include: {
        creator: {
          select: {
            id: true,
            name: true,
            email: true,
            role: true
          }
        },
        assignee: {
          select: {
            id: true,
            name: true,
            email: true,
            role: true
          }
        },
        comments: {
          orderBy: { createdAt: 'asc' },
          include: {
            author: {
              select: {
                id: true,
                name: true,
                email: true,
                role: true
              }
            }
          }
        },
        timeline: {
          orderBy: { createdAt: 'asc' },
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true
              }
            }
          }
        }
      }
    });

    if (!ticket) {
      throw new AppError(404, 'Ticket not found', 'NOT_FOUND');
    }

    // Check access permissions
    if (req.user!.role === 'USER' && ticket.creatorId !== req.user!.id) {
      throw new AppError(403, 'Access denied', 'FORBIDDEN');
    }

    // Check for SLA breach
    const now = new Date();
    if (ticket.slaDeadline && !ticket.slaBreached && now > ticket.slaDeadline) {
      await prisma.$transaction([
        prisma.ticket.update({
          where: { id: ticket.id },
          data: { slaBreached: true }
        }),
        prisma.ticketTimeline.create({
          data: {
            ticketId: ticket.id,
            action: 'SLA_BREACHED'
          }
        })
      ]);
      ticket.slaBreached = true;
    }

    res.json(ticket);
  } catch (error) {
    next(error);
  }
});

// PATCH /api/tickets/:id - Update ticket with optimistic locking
router.patch('/:id', updateTicketValidation, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const firstError = errors.array()[0];
      throw new AppError(400, firstError.msg, 'VALIDATION_ERROR', (firstError as any).path);
    }

    const { id } = req.params;
    const { title, description, status, priority, assigneeId, version } = req.body;
    const userId = req.user!.id;

    // Get current ticket
    const currentTicket = await prisma.ticket.findUnique({
      where: { id }
    });

    if (!currentTicket) {
      throw new AppError(404, 'Ticket not found', 'NOT_FOUND');
    }

    // Check access permissions
    if (req.user!.role === 'USER' && currentTicket.creatorId !== userId) {
      throw new AppError(403, 'Only agents and admins can update tickets', 'FORBIDDEN');
    }

    // Optimistic locking check
    if (currentTicket.version !== version) {
      throw new AppError(409, 'Ticket was modified by another user. Please refresh and try again.', 'STALE_VERSION');
    }

    // Verify assignee exists if provided
    if (assigneeId) {
      const assignee = await prisma.user.findUnique({
        where: { id: assigneeId }
      });
      if (!assignee) {
        throw new AppError(400, 'Assignee not found', 'INVALID_ASSIGNEE', 'assigneeId');
      }
      if (assignee.role === 'USER') {
        throw new AppError(400, 'Cannot assign ticket to a regular user', 'INVALID_ASSIGNEE', 'assigneeId');
      }
    }

    // Prepare update data and timeline events
    const updateData: any = {
      version: { increment: 1 }
    };
    const timelineEvents: any[] = [];

    if (title !== undefined) {
      updateData.title = title;
    }
    if (description !== undefined) {
      updateData.description = description;
    }
    if (status !== undefined && status !== currentTicket.status) {
      updateData.status = status;
      timelineEvents.push({
        action: 'STATUS_CHANGED',
        oldValue: currentTicket.status,
        newValue: status,
        userId
      });

      // Update resolved/closed timestamps
      if (status === 'RESOLVED') {
        updateData.resolvedAt = new Date();
        timelineEvents.push({
          action: 'RESOLVED',
          userId
        });
      } else if (status === 'CLOSED') {
        updateData.closedAt = new Date();
        timelineEvents.push({
          action: 'CLOSED',
          userId
        });
      }
    }
    if (priority !== undefined && priority !== currentTicket.priority) {
      updateData.priority = priority;
      updateData.slaDeadline = calculateSLADeadline(priority);
      timelineEvents.push({
        action: 'PRIORITY_CHANGED',
        oldValue: currentTicket.priority,
        newValue: priority,
        userId
      });
    }
    if (assigneeId !== undefined && assigneeId !== currentTicket.assigneeId) {
      updateData.assigneeId = assigneeId;
      if (assigneeId) {
        timelineEvents.push({
          action: 'ASSIGNED',
          newValue: assigneeId,
          userId
        });
      } else {
        timelineEvents.push({
          action: 'UNASSIGNED',
          oldValue: currentTicket.assigneeId,
          userId
        });
      }
    }

    // Update ticket and add timeline events in a transaction
    const updatedTicket = await prisma.$transaction(async (tx: any) => {
      const ticket = await tx.ticket.update({
        where: { id },
        data: updateData,
        include: {
          creator: {
            select: {
              id: true,
              name: true,
              email: true,
              role: true
            }
          },
          assignee: {
            select: {
              id: true,
              name: true,
              email: true,
              role: true
            }
          }
        }
      });

      // Add timeline events
      for (const event of timelineEvents) {
        await tx.ticketTimeline.create({
          data: {
            ticketId: id,
            ...event
          }
        });
      }

      return ticket;
    });

    res.json(updatedTicket);
  } catch (error) {
    next(error);
  }
});

// POST /api/tickets/:id/comments - Add comment to ticket
router.post('/:id/comments', handleIdempotency, commentValidation, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const firstError = errors.array()[0];
      throw new AppError(400, firstError.msg, 'VALIDATION_ERROR', (firstError as any).path);
    }

    const { id } = req.params;
    const { content } = req.body;
    const userId = req.user!.id;

    // Check if ticket exists
    const ticket = await prisma.ticket.findUnique({
      where: { id }
    });

    if (!ticket) {
      throw new AppError(404, 'Ticket not found', 'NOT_FOUND');
    }

    // Check access permissions
    if (req.user!.role === 'USER' && ticket.creatorId !== userId) {
      throw new AppError(403, 'Access denied', 'FORBIDDEN');
    }

    // Create comment and timeline event in transaction
    const result = await prisma.$transaction(async (tx: any) => {
      const comment = await tx.comment.create({
        data: {
          content,
          ticketId: id,
          authorId: userId
        },
        include: {
          author: {
            select: {
              id: true,
              name: true,
              email: true,
              role: true
            }
          }
        }
      });

      await tx.ticketTimeline.create({
        data: {
          ticketId: id,
          action: 'COMMENTED',
          userId
        }
      });

      return comment;
    });

    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
});

export default router;
