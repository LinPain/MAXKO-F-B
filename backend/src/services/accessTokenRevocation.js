const revokedUntil = new Map();

function revoke(jti, expiresAt) {
  if (!jti) return;
  const expiry = Number(expiresAt) * 1000;
  if (!Number.isFinite(expiry) || expiry <= Date.now()) return;
  revokedUntil.set(jti, expiry);
}

function isRevoked(jti) {
  if (!jti) return false;
  const expiry = revokedUntil.get(jti);
  if (!expiry) return false;
  if (expiry <= Date.now()) {
    revokedUntil.delete(jti);
    return false;
  }
  return true;
}

// Opportunistic cleanup keeps the process-local blacklist bounded by token lifetime.
setInterval(() => {
  const now = Date.now();
  for (const [jti, expiry] of revokedUntil) if (expiry <= now) revokedUntil.delete(jti);
}, 60_000).unref();

module.exports = { revoke, isRevoked };
