import { Router, Request, Response } from 'express';
import { query } from '../config/db.js';

const router = Router();

// GET / - Root Welcome & Service Info
router.get('/', (req: Request, res: Response) => {
  res.status(200).json({
    name: 'Viraly Backend API',
    version: '1.0.0',
    status: 'online',
    description: 'The Open Creator Bounty & Performance Virality Engine for Nigeria',
    endpoints: {
      health: '/health',
      campaigns: '/api/campaigns',
      submissions: '/api/submissions',
      wallets: '/api/wallets',
      redirectShortlink: '/r/:slug'
    }
  });
});

// GET /health - Render Health Check & Supabase Status
router.get('/health', async (req: Request, res: Response) => {
  try {
    const dbResult = await query('SELECT NOW() as current_time');
    res.status(200).json({
      status: 'ok',
      service: 'viraly-api',
      timestamp: new Date().toISOString(),
      database: 'connected',
      dbTime: dbResult.rows[0]?.current_time
    });
  } catch (error: any) {
    res.status(500).json({
      status: 'error',
      service: 'viraly-api',
      database: 'disconnected',
      error: error.message
    });
  }
});

export default router;
