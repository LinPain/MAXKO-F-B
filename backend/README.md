# MAXKO F&B customer API

Express and MongoDB API for the MAXKO F&B customer app. It serves the app's catalog, customer accounts, membership and rewards, branch lookup, promotions, delivery checks, checkout, and lucky wheel.

## Run locally

1. Install Node.js and MongoDB, then run `npm install` from this directory.
2. Copy `.env.example` to `.env`. Set `MONGODB_URI`, a random `JWT_SECRET` with at least 32 characters, and SMTP settings if email verification and password reset should send mail.
3. Start MongoDB, then run `npm run dev` from this directory. The API listens on port 5000 by default.
4. The Flutter app defaults to the archive's production API, `https://api.legiapos.vn`. To use this local backend, run Flutter with `--dart-define=API_BASE_URL=http://10.0.2.2:5000` on an Android emulator, or use `http://localhost:5000` for web, iOS simulator, and desktop. A physical phone needs the computer's LAN address and matching CORS settings where applicable.
5. Add approved product, branch, promotion, reward, and lucky-wheel records through the database setup used by your team. The customer API returns empty collections until those records are present. Wheel probabilities are stored server-side and are never sent to the customer app.

## Customer API areas

- `/api/auth/*`: email verification, signup, login, refresh, logout, and password reset.
- `/api/products`, `/api/categories`, `/api/modifier-groups`: catalog, categories, and product options.
- `/api/brands/:id`, `/api/branches`, `/api/branches/:id/menu-matrix`, `/api/geofence/*`: customer brand/branch lookup, branch-filtered menu, and delivery-distance checks.
- `/api/orders/precheck`, `/api/orders/check-stock`, `/api/orders/batch-checkout`, `/api/orders/batch/:batchId`: server-priced cart checks and grouped checkout.
- `/api/customers/me/*`, `/api/customers/rewards`, `/api/customers/redeem-voucher`, `/api/customers/vouchers/*`: profile, membership, saved addresses, rewards, and vouchers.
- `/api/promotions*`, `/api/marketing/lucky-wheel/*`: customer promotions and authenticated wheel spins/history.
- `/api/notifications*`: customer notifications and read state.

Prices, modifier choices, delivery range, discounts, and checkout totals are recalculated by the API. Authentication uses short-lived JWT access tokens and rotating HttpOnly refresh cookies. Configure HTTPS and the production cookie/CORS settings for deployment.

Refresh tokens expire after seven days by default (`REFRESH_TOKEN_TTL_DAYS`, capped at 30) and can be supplied by cookie, request body, or `X-Refresh-Token`. Access-token logout revocation and the rate limiter are process-local; use a shared store before running multiple API instances. Checkout accepts an optional `Idempotency-Key` header or `idempotencyKey` body field; the Flutter checkout sends one and reuses it after a retry.

## Current boundaries

- Checkout currently accepts cash only. Online/VietQR generation returns an unavailable response until a payment provider and verified callback flow are configured.
- Stock checks validate whether a product is enabled for sale at a branch. Ingredient-level inventory and recipe deductions are not connected.
- Branch, product, modifier, promotion, reward, and wheel management require the connected management system or direct database administration; this customer API does not expose staff/admin editing endpoints.
- Brand detail requests need matching `Brand` records. The public profile-360 endpoint is restricted to the signed-in customer's own profile. Wheel spins/history also require sign-in even though the Postman examples mark them public; a phone number alone is not identity verification.
- The proximity endpoint reports the nearest active branch and whether it is inside the proximity radius; sending a push alert still needs a configured notification provider.
- Postman storefront payloads using `orders`, `orderAmount`, and top-level `latitude`/`longitude` are accepted as compatibility aliases.
