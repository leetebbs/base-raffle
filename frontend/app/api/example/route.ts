import { NextResponse } from 'next/server';
import { Network, Alchemy } from 'alchemy-sdk';
import { alchemy } from '@/config';

export async function GET() {
  try {
    // const blockNumber: number = await alchemy.core.getBlockNumber();
    // console.log('Block number:', blockNumber);
    
    return NextResponse.json({ 
      message: 'API is working!',
      timestamp: new Date().toISOString(),
      // blockNumber,
      testData: {
        number: 42,
        text: 'Hello from the API'
      }
    });
  } catch (error) {
    console.error('Error in /api/example:', error);
    return NextResponse.json(
      { error: 'Failed to process request' },
      { status: 500 }
    );
  }
}
