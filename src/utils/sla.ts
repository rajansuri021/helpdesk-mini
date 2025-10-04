// SLA calculation based on priority
export function calculateSLADeadline(priority: string): Date {
  const now = new Date();
  const hoursToAdd = getSLAHours(priority);
  return new Date(now.getTime() + hoursToAdd * 60 * 60 * 1000);
}

function getSLAHours(priority: string): number {
  switch (priority) {
    case 'CRITICAL':
      return 4; // 4 hours
    case 'HIGH':
      return 24; // 1 day
    case 'MEDIUM':
      return 72; // 3 days
    case 'LOW':
      return 168; // 7 days
    default:
      return 72; // Default to 3 days
  }
}

export function checkSLABreach(slaDeadline: Date | null): boolean {
  if (!slaDeadline) return false;
  return new Date() > slaDeadline;
}
