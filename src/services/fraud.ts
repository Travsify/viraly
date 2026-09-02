import crypto from 'crypto';

export function hashIp(ip: string): string {
  const salt = process.env.IP_SALT || 'viraly-salt-nigeria-2026';
  return crypto.createHmac('sha256', salt).update(ip).digest('hex');
}

export function evaluateClickLegitimacy(ipHash: string, userAgent: string | undefined): { isQualified: boolean; reason?: string } {
  if (!userAgent || userAgent.length < 10) {
    return { isQualified: false, reason: 'Missing or malformed user agent' };
  }

  const botPatterns = ['bot', 'crawler', 'spider', 'curl', 'wget', 'python', 'postman', 'headless'];
  const lowerAgent = userAgent.toLowerCase();
  for (const bot of botPatterns) {
    if (lowerAgent.includes(bot)) {
      return { isQualified: false, reason: 'Automated crawler or bot detected' };
    }
  }

  return { isQualified: true };
}
