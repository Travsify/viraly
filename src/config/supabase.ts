import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://ffpcnnxoyklepylgywnt.supabase.co';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 'sb_publishable_86lbbyxWOSKZhbxnP9r1cw_wuAUYEq7';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
