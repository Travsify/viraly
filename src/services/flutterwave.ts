import dotenv from 'dotenv';
dotenv.config();

const FLW_BASE_URL = process.env.FLUTTERWAVE_BASE_URL || 'https://api.flutterwave.com/v3';
const FLW_SECRET_KEY = process.env.FLUTTERWAVE_SECRET_KEY || '';

export class FlutterwaveService {
  private static getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.FLUTTERWAVE_SECRET_KEY || FLW_SECRET_KEY}`,
    };
  }

  // 1. Initialize Flutterwave Hosted Payment for Agency Campaign Escrow
  static async initializePayment(params: {
    campaignId: string;
    campaignTitle: string;
    amount: number;
    email: string;
    name?: string;
    redirectUrl?: string;
  }): Promise<{
    status: boolean;
    link?: string;
    txRef?: string;
    message?: string;
  }> {
    const txRef = `viraly_flw_${params.campaignId.substring(0, 8)}_${Date.now()}`;
    const redirectUrl = params.redirectUrl || `${process.env.BACKEND_URL || 'https://iswitch-l82a.onrender.com'}/api/agency/campaigns/flutterwave-callback?campaign_id=${params.campaignId}`;

    try {
      console.log(`[Flutterwave] Initializing payment for campaign ${params.campaignId} (₦${params.amount})...`);
      const response = await fetch(`${FLW_BASE_URL}/payments`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({
          tx_ref: txRef,
          amount: params.amount,
          currency: 'NGN',
          redirect_url: redirectUrl,
          customer: {
            email: params.email,
            name: params.name || 'Viraly Brand Partner',
          },
          meta: {
            campaign_id: params.campaignId,
            platform: 'viraly_mobile',
          },
          customizations: {
            title: 'Viraly Creator Escrow',
            description: `Escrow pool funding for "${params.campaignTitle}"`,
            logo: 'https://iswitch-l82a.onrender.com/logo.png',
          },
        }),
      });

      const resJson: any = await response.json();

      if (response.ok && resJson.status === 'success' && resJson.data?.link) {
        return {
          status: true,
          link: resJson.data.link,
          txRef,
        };
      }

      return {
        status: false,
        message: resJson.message || 'Failed to generate Flutterwave checkout link',
      };
    } catch (error: any) {
      console.error('[Flutterwave] Payment init error:', error);
      return {
        status: false,
        message: error.message || 'Network error connecting to Flutterwave',
      };
    }
  }

  // 2. Verify Flutterwave Transaction by ID
  static async verifyTransaction(transactionId: string): Promise<{
    status: boolean;
    data?: any;
    message?: string;
  }> {
    try {
      const response = await fetch(`${FLW_BASE_URL}/transactions/${transactionId}/verify`, {
        headers: this.getHeaders(),
      });

      const resJson: any = await response.json();
      if (response.ok && resJson.status === 'success') {
        return {
          status: true,
          data: resJson.data,
        };
      }

      return {
        status: false,
        message: resJson.message || 'Transaction verification failed',
      };
    } catch (error: any) {
      return {
        status: false,
        message: error.message || 'Error verifying transaction',
      };
    }
  }
}
