function createTokenBucket({ capacity, refillPerSecond }) {
  const buckets = new Map();
  const refillPerMs = refillPerSecond / 1000;

  const cleanup = setInterval(() => {
    const staleBefore = Date.now() - 60 * 60 * 1000;
    for (const [key, bucket] of buckets) if (bucket.updatedAt < staleBefore) buckets.delete(key);
  }, 10 * 60 * 1000);
  cleanup.unref();

  return (req, res, next) => {
    const now = Date.now();
    const key = req.ip || req.socket.remoteAddress || 'unknown';
    const bucket = buckets.get(key) || { tokens: capacity, updatedAt: now };
    bucket.tokens = Math.min(capacity, bucket.tokens + (now - bucket.updatedAt) * refillPerMs);
    bucket.updatedAt = now;
    if (bucket.tokens < 1) {
      const waitSeconds = Math.max(1, Math.ceil((1 - bucket.tokens) / refillPerSecond));
      res.setHeader('Retry-After', String(waitSeconds));
      res.setHeader('X-RateLimit-Limit', String(capacity));
      res.setHeader('X-RateLimit-Remaining', '0');
      return res.status(429).json({
        success: false,
        code: 'TOO_MANY_REQUESTS',
        error: 'Bạn thao tác quá nhanh. Vui lòng thử lại sau.',
        message: 'Bạn thao tác quá nhanh. Vui lòng thử lại sau.',
        traceId: req.traceId,
      });
    }
    bucket.tokens -= 1;
    buckets.set(key, bucket);
    res.setHeader('X-RateLimit-Limit', String(capacity));
    res.setHeader('X-RateLimit-Remaining', String(Math.floor(bucket.tokens)));
    next();
  };
}

module.exports = { createTokenBucket };
