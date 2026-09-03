import dotenv from 'dotenv';
dotenv.config();

const PREMBLY_BASE_URL = process.env.PREMBLY_BASE_URL || 'https://api.prembly.com';
const PREMBLY_API_KEY = process.env.PREMBLY_API_KEY || '';
const PREMBLY_APP_ID = process.env.PREMBLY_APP_ID || '';

export class PremblyService {
  private static getHeaders() {
    return {
      'Content-Type': 'application/json',
      'x-api-key': process.env.PREMBLY_API_KEY || PREMBLY_API_KEY,
      'app-id': process.env.PREMBLY_APP_ID || PREMBLY_APP_ID,
    };
  }

  // 1. Verify Bank Verification Number (BVN) via NIBSS
  static async verifyBVN(bvnNumber: string): Promise<{
    status: boolean;
    data?: {
      firstName: string;
      lastName: string;
      fullName: string;
      phone: string;
      dateOfBirth: string;
      bvn: string;
    };
    raw?: any;
    message?: string;
  }> {
    try {
      const cleanBvn = bvnNumber.trim();
      const response = await fetch(`${PREMBLY_BASE_URL}/identitypass/verification/bvn`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({ number: cleanBvn }),
      });

      const resJson: any = await response.json();

      if (response.ok && (resJson.status === true || resJson.response_code === '00')) {
        const bvnData = resJson.bvn_data || resJson.data || {};
        const firstName = bvnData.firstName || bvnData.first_name || '';
        const lastName = bvnData.lastName || bvnData.last_name || '';
        return {
          status: true,
          data: {
            firstName,
            lastName,
            fullName: `${firstName} ${lastName}`.trim(),
            phone: bvnData.phoneNumber1 || bvnData.phone_number || '',
            dateOfBirth: bvnData.dateOfBirth || bvnData.dob || '',
            bvn: cleanBvn,
          },
          raw: resJson,
        };
      } else {
        return {
          status: false,
          message: resJson.message || resJson.detail || 'BVN verification failed with NIBSS/Prembly',
        };
      }
    } catch (err: any) {
      console.error('[Prembly] BVN verification error:', err);
      return {
        status: false,
        message: `Prembly connection error: ${err.message}`,
      };
    }
  }

  // 2. Verify National Identification Number (NIN) via NIMC
  static async verifyNIN(ninNumber: string): Promise<{
    status: boolean;
    data?: {
      firstName: string;
      lastName: string;
      fullName: string;
      phone: string;
      dateOfBirth: string;
      photo?: string;
    };
    message?: string;
  }> {
    try {
      const cleanNin = ninNumber.trim();
      const response = await fetch(`${PREMBLY_BASE_URL}/identitypass/verification/nin`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({ number: cleanNin, number_nin: cleanNin }),
      });

      const resJson: any = await response.json();

      if (response.ok && (resJson.status === true || resJson.response_code === '00')) {
        const ninData = resJson.nin_data || resJson.data || {};
        return {
          status: true,
          data: {
            firstName: ninData.firstname || ninData.first_name || '',
            lastName: ninData.surname || ninData.last_name || '',
            fullName: `${ninData.firstname || ''} ${ninData.surname || ''}`.trim(),
            phone: ninData.telephoneno || ninData.phone_number || '',
            dateOfBirth: ninData.birthdate || ninData.dob || '',
            photo: ninData.photo || ninData.image || '',
          },
        };
      }

      return {
        status: false,
        message: resJson.message || 'NIN verification record not found with NIMC',
      };
    } catch (err: any) {
      return {
        status: false,
        message: `Prembly connection error: ${err.message}`,
      };
    }
  }
}
