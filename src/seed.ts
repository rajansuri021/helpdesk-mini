import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function seed() {
  console.log('🌱 Starting seed...');

  try {
    // Create users
    console.log('Creating users...');
    
    const adminPassword = await bcrypt.hash('admin123', 10);
    const agentPassword = await bcrypt.hash('agent123', 10);
    const userPassword = await bcrypt.hash('user123', 10);

    const admin = await prisma.user.upsert({
      where: { email: 'admin@helpdesk.com' },
      update: {},
      create: {
        email: 'admin@helpdesk.com',
        password: adminPassword,
        name: 'Admin User',
        role: 'ADMIN'
      }
    });

    const agent1 = await prisma.user.upsert({
      where: { email: 'agent1@helpdesk.com' },
      update: {},
      create: {
        email: 'agent1@helpdesk.com',
        password: agentPassword,
        name: 'Agent One',
        role: 'AGENT'
      }
    });

    const agent2 = await prisma.user.upsert({
      where: { email: 'agent2@helpdesk.com' },
      update: {},
      create: {
        email: 'agent2@helpdesk.com',
        password: agentPassword,
        name: 'Agent Two',
        role: 'AGENT'
      }
    });

    const user1 = await prisma.user.upsert({
      where: { email: 'user1@example.com' },
      update: {},
      create: {
        email: 'user1@example.com',
        password: userPassword,
        name: 'John Doe',
        role: 'USER'
      }
    });

    const user2 = await prisma.user.upsert({
      where: { email: 'user2@example.com' },
      update: {},
      create: {
        email: 'user2@example.com',
        password: userPassword,
        name: 'Jane Smith',
        role: 'USER'
      }
    });

    console.log('✅ Users created');

    // Create sample tickets
    console.log('Creating tickets...');

    const calculateSLA = (priority: string) => {
      const now = new Date();
      const hours = priority === 'CRITICAL' ? 4 : priority === 'HIGH' ? 24 : priority === 'MEDIUM' ? 72 : 168;
      return new Date(now.getTime() + hours * 60 * 60 * 1000);
    };

    // Ticket 1 - Open, Critical, Assigned
    const ticket1 = await prisma.ticket.create({
      data: {
        title: 'Critical: Database Connection Failure',
        description: 'Production database is not responding. Multiple users affected.',
        priority: 'CRITICAL',
        status: 'IN_PROGRESS',
        creatorId: user1.id,
        assigneeId: agent1.id,
        slaDeadline: calculateSLA('CRITICAL'),
        timeline: {
          create: [
            {
              action: 'CREATED',
              userId: user1.id
            },
            {
              action: 'ASSIGNED',
              newValue: agent1.id,
              userId: admin.id
            },
            {
              action: 'STATUS_CHANGED',
              oldValue: 'OPEN',
              newValue: 'IN_PROGRESS',
              userId: agent1.id
            }
          ]
        },
        comments: {
          create: [
            {
              content: 'I can confirm the issue. Investigating now.',
              authorId: agent1.id
            },
            {
              content: 'Found the root cause. Working on a fix.',
              authorId: agent1.id
            }
          ]
        }
      }
    });

    // Ticket 2 - Open, High Priority
    const ticket2 = await prisma.ticket.create({
      data: {
        title: 'Login page not loading',
        description: 'Users are reporting that the login page shows a blank screen.',
        priority: 'HIGH',
        status: 'OPEN',
        creatorId: user2.id,
        slaDeadline: calculateSLA('HIGH'),
        timeline: {
          create: {
            action: 'CREATED',
            userId: user2.id
          }
        }
      }
    });

    // Ticket 3 - Resolved
    const resolvedDate = new Date();
    const ticket3 = await prisma.ticket.create({
      data: {
        title: 'Password reset email not received',
        description: 'I requested a password reset but did not receive the email.',
        priority: 'MEDIUM',
        status: 'RESOLVED',
        creatorId: user1.id,
        assigneeId: agent2.id,
        resolvedAt: resolvedDate,
        slaDeadline: calculateSLA('MEDIUM'),
        timeline: {
          create: [
            {
              action: 'CREATED',
              userId: user1.id
            },
            {
              action: 'ASSIGNED',
              newValue: agent2.id,
              userId: admin.id
            },
            {
              action: 'STATUS_CHANGED',
              oldValue: 'OPEN',
              newValue: 'IN_PROGRESS',
              userId: agent2.id
            },
            {
              action: 'STATUS_CHANGED',
              oldValue: 'IN_PROGRESS',
              newValue: 'RESOLVED',
              userId: agent2.id
            },
            {
              action: 'RESOLVED',
              userId: agent2.id
            }
          ]
        },
        comments: {
          create: [
            {
              content: 'Looking into this now.',
              authorId: agent2.id
            },
            {
              content: 'Found the issue - your email was in spam. I have resent it. Please check.',
              authorId: agent2.id
            },
            {
              content: 'Got it! Thank you.',
              authorId: user1.id
            }
          ]
        }
      }
    });

    // Ticket 4 - Breached SLA
    const breachedDate = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000); // 5 days ago
    const ticket4 = await prisma.ticket.create({
      data: {
        title: 'Feature request: Dark mode',
        description: 'It would be great to have a dark mode option for the dashboard.',
        priority: 'LOW',
        status: 'OPEN',
        creatorId: user2.id,
        slaDeadline: breachedDate,
        slaBreached: true,
        createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000),
        timeline: {
          create: [
            {
              action: 'CREATED',
              userId: user2.id,
              createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000)
            },
            {
              action: 'SLA_BREACHED',
              createdAt: breachedDate
            }
          ]
        }
      }
    });

    // Ticket 5 - Closed
    const ticket5 = await prisma.ticket.create({
      data: {
        title: 'Cannot export reports to PDF',
        description: 'The export to PDF button is not working in the reports section.',
        priority: 'MEDIUM',
        status: 'CLOSED',
        creatorId: user1.id,
        assigneeId: agent1.id,
        resolvedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
        closedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
        slaDeadline: calculateSLA('MEDIUM'),
        timeline: {
          create: [
            {
              action: 'CREATED',
              userId: user1.id,
              createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000)
            },
            {
              action: 'ASSIGNED',
              newValue: agent1.id,
              userId: admin.id,
              createdAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000)
            },
            {
              action: 'STATUS_CHANGED',
              oldValue: 'OPEN',
              newValue: 'IN_PROGRESS',
              userId: agent1.id,
              createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
            },
            {
              action: 'STATUS_CHANGED',
              oldValue: 'IN_PROGRESS',
              newValue: 'RESOLVED',
              userId: agent1.id,
              createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
            },
            {
              action: 'RESOLVED',
              userId: agent1.id,
              createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
            },
            {
              action: 'STATUS_CHANGED',
              oldValue: 'RESOLVED',
              newValue: 'CLOSED',
              userId: user1.id,
              createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000)
            },
            {
              action: 'CLOSED',
              userId: user1.id,
              createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000)
            }
          ]
        },
        comments: {
          create: [
            {
              content: 'Fixed the issue. Can you please verify?',
              authorId: agent1.id,
              createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
            },
            {
              content: 'Works perfectly now. Thank you!',
              authorId: user1.id,
              createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000)
            }
          ]
        }
      }
    });

    console.log('✅ Tickets created');

    console.log('\n🎉 Seed completed successfully!');
    console.log('📝 Demo accounts created for testing\n');

  } catch (error) {
    console.error('❌ Seed failed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

seed();
