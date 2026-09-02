import { Router, Request, Response } from 'express';
import { query } from '../config/db.js';

const router = Router();

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
