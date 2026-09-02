import { Request, Response, NextFunction } from 'express';
import { supabase } from '../config/supabase.js';
import { query } from '../config/db.js';

export interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
    email?: string;
    role?: string;
  };
}

// 1. General User Authentication (Creators & Agencies)
export const requireAuth = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Authentication required. Please log in.' });
    }

    const token = authHeader.split(' ')[1];
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ success: false, message: 'Invalid or expired session token.' });
    }

    // Fetch user role from profiles table
    const profileRes = await query('SELECT role FROM public.profiles WHERE id = $1', [user.id]);
    const role = profileRes.rows[0]?.role || 'creator';

    req.user = {
      id: user.id,
      email: user.email,
      role
    };
    next();
  } catch (error) {
    next(error);
  }
};

// 2. Strict Admin Role Guard
export const requireAdmin = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Admin authentication required.' });
    }

    const token = authHeader.split(' ')[1];
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ success: false, message: 'Invalid or expired admin session token.' });
    }

    // Verify user has admin privileges in public.profiles table
    const profileRes = await query('SELECT role, email FROM public.profiles WHERE id = $1', [user.id]);
    const profile = profileRes.rows[0];

    // If profile is explicitly admin or master account
    if (!profile || profile.role !== 'admin') {
      // Check if there are zero admins in the system (bootstrap first admin)
      const adminCountRes = await query("SELECT COUNT(*) FROM public.profiles WHERE role = 'admin'");
      const adminCount = parseInt(adminCountRes.rows[0]?.count || '0', 10);

      if (adminCount === 0) {
        // Auto-promote the first authenticated user to admin
        await query("UPDATE public.profiles SET role = 'admin' WHERE id = $1", [user.id]);
        req.user = { id: user.id, email: user.email, role: 'admin' };
        return next();
      }

      return res.status(403).json({
        success: false,
        message: 'Access Denied: Only administrators have access to this portal.'
      });
    }

    req.user = {
      id: user.id,
      email: user.email,
      role: profile.role
    };
    next();
  } catch (error) {
    next(error);
  }
};
