import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

import healthRouter from './routes/health.js';
import redirectRouter from './routes/redirect.js';
import campaignsRouter from './routes/campaigns.js';
import submissionsRouter from './routes/submissions.js';
import walletsRouter from './routes/wallets.js';
import webhooksRouter from './routes/webhooks.js';
import { errorHandler } from './middleware/error.js';
import { startBackgroundWorker } from './services/cron.js';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Security & utility middleware
app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 1. Root & Health Check
app.use('/', healthRouter);

// 2. High-Performance Smart Referral Link Redirection (e.g. /r/rentilly-chuka)
app.use('/', redirectRouter);

// 3. API Routes
app.use('/api/campaigns', campaignsRouter);
app.use('/api/submissions', submissionsRouter);
app.use('/api/wallets', walletsRouter);
app.use('/api/webhooks', webhooksRouter);

// 4. Global Error Handler
app.use(errorHandler);

// Start the background auditor
startBackgroundWorker();

app.listen(port, () => {
  console.log(`🚀 Viraly Backend Engine running on port ${port}`);
  console.log(`📡 Connected to Supabase at: ${process.env.SUPABASE_URL || 'https://ffpcnnxoyklepylgywnt.supabase.co'}`);
});

export default app;
