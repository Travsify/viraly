import axios from 'axios';

export interface TikTokVideoMetrics {
  videoId: string;
  authorName: string;
  authorHandle: string;
  title: string;
  thumbnailUrl: string;
  views: number;
  likes: number;
  comments: number;
  shares: number;
}

export function extractTikTokVideoId(url: string): string | null {
  try {
    const parsed = new URL(url);
    const path = parsed.pathname;

    // Matches /@user/video/1234567890123456789
    const videoMatch = path.match(/\/video\/(\d+)/);
    if (videoMatch && videoMatch[1]) {
      return videoMatch[1];
    }

    // Matches shortlinks e.g. vm.tiktok.com/ZM... or vt.tiktok.com/...
    return path.replace('/', '').trim() || null;
  } catch {
    return null;
  }
}

export async function fetchLiveTikTokMetrics(videoUrl: string): Promise<TikTokVideoMetrics | null> {
  try {
    const videoId = extractTikTokVideoId(videoUrl) || 'unknown';

    // 1. Fetch metadata via official oEmbed API
    const oembedUrl = `https://www.tiktok.com/oembed?url=${encodeURIComponent(videoUrl)}`;
    const oembedRes = await axios.get(oembedUrl, {
      timeout: 8000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });

    const oembedData = oembedRes.data;
    const authorName = oembedData?.author_name || '';
    const title = oembedData?.title || '';
    const thumbnailUrl = oembedData?.thumbnail_url || '';
    const authorHandle = oembedData?.author_unique_id || authorName.replace(/\s+/g, '').toLowerCase();

    // 2. Fetch live metrics (plays, likes, comments) from public HTML page
    let views = 0;
    let likes = 0;
    let comments = 0;
    let shares = 0;

    try {
      const pageRes = await axios.get(videoUrl, {
        timeout: 10000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': 'https://www.google.com/'
        }
      });

      const html = pageRes.data;

      // Extract JSON state blob from __UNIVERSAL_DATA_FOR_REHYDRATION__ or SIGI_STATE
      const jsonMatch = html.match(/<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__"[^>]*>([\s\S]*?)<\/script>/);
      if (jsonMatch && jsonMatch[1]) {
        try {
          const parsedData = JSON.parse(jsonMatch[1]);
          const itemStruct = parsedData?.__DEFAULT_SCOPE__?.['webapp.video-detail']?.itemInfo?.itemStruct;
          if (itemStruct && itemStruct.stats) {
            views = Number(itemStruct.stats.playCount || 0);
            likes = Number(itemStruct.stats.diggCount || 0);
            comments = Number(itemStruct.stats.commentCount || 0);
            shares = Number(itemStruct.stats.shareCount || 0);
          }
        } catch {
          // JSON parsing failed, fallback to regex
        }
      }

      // Regex fallback for playCount
      if (views === 0) {
        const playMatch = html.match(/"playCount":\s*(\d+)/);
        if (playMatch && playMatch[1]) views = parseInt(playMatch[1], 10);

        const diggMatch = html.match(/"diggCount":\s*(\d+)/);
        if (diggMatch && diggMatch[1]) likes = parseInt(diggMatch[1], 10);

        const commentMatch = html.match(/"commentCount":\s*(\d+)/);
        if (commentMatch && commentMatch[1]) comments = parseInt(commentMatch[1], 10);
      }
    } catch (scrapeErr) {
      console.warn(`[TikTok Scraper] Direct page scrape note for ${videoUrl}:`, (scrapeErr as any).message);
    }

    return {
      videoId,
      authorName,
      authorHandle,
      title,
      thumbnailUrl,
      views,
      likes,
      comments,
      shares
    };
  } catch (error) {
    console.error(`[TikTok Scraper] Error fetching metrics for ${videoUrl}:`, (error as any).message);
    return null;
  }
}

export async function verifyTikTokVideo(url: string) {
  return fetchLiveTikTokMetrics(url);
}
