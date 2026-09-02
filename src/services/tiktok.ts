import axios from 'axios';

export interface TikTokMetadata {
  videoId: string;
  authorName: string;
  title: string;
  thumbnailUrl: string;
  html?: string;
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

export async function verifyTikTokVideo(url: string): Promise<TikTokMetadata | null> {
  try {
    const oembedUrl = `https://www.tiktok.com/oembed?url=${encodeURIComponent(url)}`;
    const response = await axios.get(oembedUrl, { timeout: 6000 });

    if (response.status === 200 && response.data) {
      const data = response.data;
      const videoId = extractTikTokVideoId(url) || 'unknown_id';
      return {
        videoId,
        authorName: data.author_name || '',
        title: data.title || '',
        thumbnailUrl: data.thumbnail_url || '',
        html: data.html || ''
      };
    }
    return null;
  } catch (error) {
    console.error('Error verifying TikTok video URL:', error);
    return null;
  }
}
