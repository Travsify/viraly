import axios from 'axios';

const PAYSTACK_BASE_URL = 'https://api.paystack.co';

function getPaystackHeaders() {
  const secretKey = process.env.PAYSTACK_SECRET_KEY || '';
  return {
    Authorization: `Bearer ${secretKey}`,
    'Content-Type': 'application/json'
  };
}

export async function getNigerianBanksList(): Promise<any[]> {
  try {
    const response = await axios.get(`${PAYSTACK_BASE_URL}/bank?country=nigeria`, {
      headers: getPaystackHeaders(),
      timeout: 10000
    });
    if (response.data && response.data.status) {
      return response.data.data;
    }
    return [];
  } catch (error: any) {
    console.warn('[Paystack] Error fetching banks list:', error.message);
    // Fallback list of major Nigerian banks and FinTechs
    return [
      { name: 'OPay Digital Services', code: '999992', slug: 'opay' },
      { name: 'PalmPay', code: '999991', slug: 'palmpay' },
      { name: 'Kuda Bank', code: '50211', slug: 'kuda-bank' },
      { name: 'Moniepoint Microfinance Bank', code: '50515', slug: 'moniepoint-mfb' },
      { name: 'Guaranty Trust Bank (GTB)', code: '058', slug: 'guaranty-trust-bank' },
      { name: 'Zenith Bank', code: '057', slug: 'zenith-bank' },
      { name: 'Access Bank', code: '044', slug: 'access-bank' },
      { name: 'United Bank For Africa (UBA)', code: '033', slug: 'united-bank-for-africa' },
      { name: 'First Bank of Nigeria', code: '011', slug: 'first-bank-of-nigeria' }
    ];
  }
}

export async function resolveBankAccount(accountNumber: string, bankCode: string): Promise<{ account_name: string; account_number: string } | null> {
  try {
    const response = await axios.get(
      `${PAYSTACK_BASE_URL}/bank/resolve?account_number=${accountNumber}&bank_code=${bankCode}`,
      { headers: getPaystackHeaders(), timeout: 10000 }
    );
    if (response.data && response.data.status) {
      return response.data.data;
    }
    return null;
  } catch (error: any) {
    console.error('[Paystack] Error resolving bank account:', error.response?.data || error.message);
    return null;
  }
}

export async function createTransferRecipient(name: string, accountNumber: string, bankCode: string): Promise<string | null> {
  try {
    const response = await axios.post(
      `${PAYSTACK_BASE_URL}/transferrecipient`,
      {
        type: 'nuban',
        name,
        account_number: accountNumber,
        bank_code: bankCode,
        currency: 'NGN'
      },
      { headers: getPaystackHeaders(), timeout: 10000 }
    );
    if (response.data && response.data.status) {
      return response.data.data.recipient_code;
    }
    return null;
  } catch (error: any) {
    console.error('[Paystack] Error creating transfer recipient:', error.response?.data || error.message);
    return null;
  }
}

export async function initiatePaystackTransfer(amountInNaira: number, recipientCode: string, reason: string): Promise<any> {
  try {
    const response = await axios.post(
      `${PAYSTACK_BASE_URL}/transfer`,
      {
        source: 'balance',
        amount: Math.round(amountInNaira * 100), // convert to kobo
        recipient: recipientCode,
        reason
      },
      { headers: getPaystackHeaders(), timeout: 10000 }
    );
    return response.data;
  } catch (error: any) {
    console.error('[Paystack] Error initiating transfer:', error.response?.data || error.message);
    throw new Error(error.response?.data?.message || 'Paystack transfer failed');
  }
}
