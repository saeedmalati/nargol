// سرور فروشگاه محصولات خانگی نارگل
// اجرا:  ADMIN_PASSWORD=... ZARINPAL_MERCHANT=... PUBLIC_URL=https://... node server.js
const express = require('express');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { DatabaseSync } = require('node:sqlite');

const PORT = Number(process.env.PORT || 3000);
const PUBLIC_URL = (process.env.PUBLIC_URL || `http://localhost:${PORT}`).replace(/\/$/, '');
const MERCHANT = process.env.ZARINPAL_MERCHANT || '';
const SANDBOX = !MERCHANT || process.env.ZARINPAL_SANDBOX === '1';
const ZP_HOST = SANDBOX ? 'https://sandbox.zarinpal.com' : 'https://payment.zarinpal.com';
const ZP_MERCHANT = MERCHANT || '00000000-0000-0000-0000-000000000000';
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const IMG_DIR = path.join(__dirname, 'public', 'images');

fs.mkdirSync(DATA_DIR, { recursive: true });
const db = new DatabaseSync(path.join(DATA_DIR, 'nargol.db'));
db.exec(`
  CREATE TABLE IF NOT EXISTS kv (key TEXT PRIMARY KEY, value TEXT NOT NULL);
  CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    token TEXT NOT NULL UNIQUE,
    data TEXT NOT NULL,
    status TEXT NOT NULL,
    authority TEXT,
    created_at TEXT NOT NULL
  );
`);
// شماره سفارش‌ها از ۱۰۰۱ شروع شود
if (!db.prepare("SELECT 1 FROM sqlite_sequence WHERE name='orders'").get()) {
  db.exec("INSERT INTO sqlite_sequence (name, seq) VALUES ('orders', 1000)");
}

const kvGet = (k) => { const r = db.prepare('SELECT value FROM kv WHERE key=?').get(k); return r ? JSON.parse(r.value) : null; };
const kvSet = (k, v) => db.prepare('INSERT INTO kv (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value').run(k, JSON.stringify(v));

// ---------- داده اولیه از کاتالوگ اپ
if (!kvGet('catalog')) {
  const seed = JSON.parse(fs.readFileSync(path.join(__dirname, 'seed', 'catalog.json'), 'utf8'));
  for (const p of seed.products) if (p.image && !p.image.startsWith('/')) p.image = `/images/${p.image}`;
  kvSet('catalog', seed);
}
const hashPass = (pass, salt = crypto.randomBytes(16).toString('hex')) =>
  `${salt}:${crypto.scryptSync(pass, salt, 32).toString('hex')}`;
const checkPass = (pass, stored) => {
  const [salt, hash] = stored.split(':');
  const h = crypto.scryptSync(pass, salt, 32);
  return crypto.timingSafeEqual(h, Buffer.from(hash, 'hex'));
};
if (!kvGet('adminPass')) {
  if (!process.env.ADMIN_PASSWORD) { console.error('ADMIN_PASSWORD را برای اولین اجرا تعیین کنید'); process.exit(1); }
  kvSet('adminPass', hashPass(process.env.ADMIN_PASSWORD));
}

const catalog = () => kvGet('catalog');
const saveCatalog = (c) => kvSet('catalog', c);

// ---------- ورود مدیر
const sessions = new Map(); // token -> expiry
const SESSION_MS = 1000 * 60 * 60 * 24 * 7;
const loginAttempts = new Map(); // ip -> {n, until}

function requireAdmin(req, res, next) {
  const t = (req.headers.authorization || '').replace(/^Bearer /, '');
  const exp = sessions.get(t);
  if (!exp || exp < Date.now()) return res.status(401).json({ error: 'لطفاً دوباره وارد پنل مدیریت شوید' });
  next();
}

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '1mb' }));
app.use((req, res, next) => { // اجازه دسترسی نسخه وب اپ
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});
app.use('/images', express.static(IMG_DIR, { maxAge: '30d' }));

const bad = (res, msg, code = 400) => res.status(code).json({ error: msg });

// ---------- عمومی
app.get('/api/catalog', (req, res) => res.json(catalog()));

app.post('/api/orders', async (req, res) => {
  const { customerName, phone, address = '', note = '', method, branchIndex, items } = req.body || {};
  const c = catalog();
  const s = c.settings;
  if (!customerName || String(customerName).trim().length < 2) return bad(res, 'نام را وارد کنید');
  if (!/^09\d{9}$/.test(String(phone || ''))) return bad(res, 'شماره موبایل معتبر نیست');
  if (method === 'delivery' ? !s.deliveryEnabled : method === 'pickup' ? !s.pickupEnabled : true) return bad(res, 'روش دریافت نامعتبر است');
  if (method === 'delivery' && String(address).trim().length < 10) return bad(res, 'آدرس کامل را وارد کنید');
  if (method === 'pickup' && !(Number.isInteger(branchIndex) && s.branches[branchIndex])) return bad(res, 'شعبه را انتخاب کنید');
  if (!Array.isArray(items) || !items.length || items.length > 100) return bad(res, 'سبد خرید خالی است');

  // قیمت‌ها همیشه از کاتالوگ سرور محاسبه می‌شود، نه از اپ
  const lines = [];
  for (const it of items) {
    const p = c.products.find((x) => x.id === it.productId);
    const v = p && p.variants.find((x) => x.id === it.variantId);
    const qty = Number(it.qty);
    if (!p || !v || !p.available || !v.available) return bad(res, 'بعضی محصولات سبد خرید دیگر موجود نیستند. لطفاً سبد را بررسی کنید.');
    if (!Number.isInteger(qty) || qty < 1 || qty > 100) return bad(res, 'تعداد نامعتبر است');
    lines.push({ productId: p.id, variantId: v.id, name: p.name, label: v.label, price: v.price, qty });
  }
  const subtotal = lines.reduce((a, l) => a + l.price * l.qty, 0);
  if (s.minOrder > 0 && subtotal < s.minOrder) return bad(res, `حداقل مبلغ سفارش ${s.minOrder.toLocaleString('fa-IR')} تومان است`);
  const deliveryFee = method === 'delivery' && !(s.freeDeliveryOver > 0 && subtotal >= s.freeDeliveryOver) ? s.deliveryFee : 0;
  const total = subtotal + deliveryFee;

  const token = crypto.randomBytes(18).toString('hex');
  const createdAt = new Date().toISOString();
  const data = {
    token, customerName: String(customerName).trim().slice(0, 100), phone, address: String(address).trim().slice(0, 500),
    note: String(note).trim().slice(0, 500), method, branchIndex: method === 'pickup' ? branchIndex : null,
    lines, subtotal, deliveryFee, total, createdAt,
  };
  const { lastInsertRowid: id } = db.prepare('INSERT INTO orders (token, data, status, created_at) VALUES (?, ?, ?, ?)')
    .run(token, JSON.stringify(data), 'pending_payment', createdAt);

  // درخواست پرداخت از زرین‌پال (مبلغ به تومان)
  try {
    const r = await fetch(`${ZP_HOST}/pg/v4/payment/request.json`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({
        merchant_id: ZP_MERCHANT, amount: total, currency: 'IRT',
        callback_url: `${PUBLIC_URL}/pay/callback?order=${id}`,
        description: `سفارش ${id} - ${s.shopName}`, metadata: { mobile: phone },
      }),
    });
    const j = await r.json();
    if (!j.data || j.data.code !== 100) throw new Error(JSON.stringify(j.errors || j));
    db.prepare('UPDATE orders SET authority=? WHERE id=?').run(j.data.authority, id);
    res.json(orderOut(getOrder(id)));
  } catch (e) {
    console.error('zarinpal request failed', e.message);
    bad(res, 'اتصال به درگاه پرداخت انجام نشد. لطفاً دوباره تلاش کنید.', 502);
  }
});

app.post('/api/orders/mine', (req, res) => {
  const tokens = Array.isArray(req.body?.tokens) ? req.body.tokens.slice(0, 200).map(String) : [];
  if (!tokens.length) return res.json([]);
  const rows = db.prepare(`SELECT * FROM orders WHERE token IN (${tokens.map(() => '?').join(',')}) ORDER BY id DESC`).all(...tokens);
  res.json(rows.map(orderOut));
});

// بازگشت از درگاه زرین‌پال
app.get('/pay/callback', async (req, res) => {
  const row = getOrder(Number(req.query.order));
  const authority = String(req.query.Authority || '');
  let ok = false, refId = null;
  if (row && row.authority === authority) {
    const data = JSON.parse(row.data);
    if (row.status !== 'pending_payment') ok = row.status !== 'canceled';
    else if (req.query.Status === 'OK') {
      try {
        const r = await fetch(`${ZP_HOST}/pg/v4/payment/verify.json`, {
          method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          body: JSON.stringify({ merchant_id: ZP_MERCHANT, amount: data.total, currency: 'IRT', authority }),
        });
        const j = await r.json();
        if (j.data && (j.data.code === 100 || j.data.code === 101)) {
          ok = true; refId = String(j.data.ref_id);
          db.prepare('UPDATE orders SET status=?, data=? WHERE id=?').run('paid', JSON.stringify({ ...data, refId }), row.id);
        }
      } catch (e) { console.error('verify failed', e.message); }
    }
  }
  const s = catalog().settings;
  res.type('html').send(`<!doctype html><html lang="fa" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>${s.shopName}</title>
<style>body{font-family:Tahoma,sans-serif;background:#FBF6EC;color:#2F2A1E;display:flex;min-height:100vh;align-items:center;justify-content:center;margin:0}
.c{background:#fff;border-radius:18px;padding:32px 24px;max-width:360px;margin:16px;text-align:center;border:1px solid #EFE8D8}
h1{font-size:20px;color:${ok ? '#3E8E41' : '#C0392B'}}p{line-height:1.9;color:#7B7464}</style></head>
<body><div class="c"><h1>${ok ? 'پرداخت با موفقیت انجام شد' : 'پرداخت انجام نشد'}</h1>
<p>${ok ? `شماره سفارش: ${row.id}${refId ? `<br>کد پیگیری: ${refId}` : ''}` : 'اگر مبلغی از حساب شما کم شده، حداکثر تا ۷۲ ساعت برمی‌گردد.'}</p>
<p>اکنون به برنامه <b>${s.shopName}</b> برگردید.</p></div></body></html>`);
});

// ---------- مدیریت
app.post('/api/admin/login', (req, res) => {
  const ip = req.ip;
  const a = loginAttempts.get(ip) || { n: 0, until: 0 };
  if (a.until > Date.now()) return bad(res, 'تلاش‌های زیاد. چند دقیقه دیگر امتحان کنید.', 429);
  if (!checkPass(String(req.body?.password || ''), kvGet('adminPass'))) {
    a.n += 1; if (a.n >= 5) { a.until = Date.now() + 5 * 60 * 1000; a.n = 0; }
    loginAttempts.set(ip, a);
    return bad(res, 'رمز اشتباه است', 401);
  }
  loginAttempts.delete(ip);
  const token = crypto.randomBytes(24).toString('hex');
  sessions.set(token, Date.now() + SESSION_MS);
  res.json({ token });
});

app.post('/api/admin/password', requireAdmin, (req, res) => {
  const p = String(req.body?.password || '');
  if (p.length < 4) return bad(res, 'رمز باید حداقل ۴ حرف باشد');
  kvSet('adminPass', hashPass(p));
  res.json({ ok: true });
});

app.put('/api/admin/products/:id', requireAdmin, (req, res) => {
  const p = req.body;
  if (!p || p.id !== req.params.id || !p.name || !Array.isArray(p.variants) || !p.variants.length) return bad(res, 'اطلاعات محصول ناقص است');
  for (const v of p.variants) if (!v.id || !v.label || !Number.isInteger(v.price) || v.price < 0) return bad(res, 'گزینه‌های وزن و قیمت نامعتبرند');
  const c = catalog();
  const clean = {
    id: p.id, name: String(p.name), categoryId: String(p.categoryId), image: String(p.image || ''),
    description: String(p.description || ''), available: !!p.available, sort: Number(p.sort) || 0,
    variants: p.variants.map((v) => ({ id: String(v.id), label: String(v.label), price: v.price, available: v.available !== false })),
  };
  const i = c.products.findIndex((x) => x.id === p.id);
  if (i >= 0) c.products[i] = clean; else c.products.push(clean);
  saveCatalog(c);
  res.json(clean);
});

app.delete('/api/admin/products/:id', requireAdmin, (req, res) => {
  const c = catalog();
  c.products = c.products.filter((p) => p.id !== req.params.id);
  saveCatalog(c);
  res.json({ ok: true });
});

app.post('/api/admin/upload', requireAdmin, express.raw({ type: 'image/*', limit: '5mb' }), (req, res) => {
  if (!Buffer.isBuffer(req.body) || !req.body.length) return bad(res, 'عکس دریافت نشد');
  const isJpeg = req.body[0] === 0xff && req.body[1] === 0xd8;
  const isPng = req.body.subarray(0, 4).toString('hex') === '89504e47';
  if (!isJpeg && !isPng) return bad(res, 'فقط عکس JPG یا PNG');
  const name = `u${Date.now()}${crypto.randomBytes(3).toString('hex')}.${isPng ? 'png' : 'jpg'}`;
  fs.writeFileSync(path.join(IMG_DIR, name), req.body);
  res.json({ image: `/images/${name}` });
});

app.put('/api/admin/categories', requireAdmin, (req, res) => {
  if (!Array.isArray(req.body) || !req.body.length) return bad(res, 'دسته‌بندی نامعتبر');
  const c = catalog();
  c.categories = req.body.map((x, i) => ({ id: String(x.id), name: String(x.name), sort: i }));
  saveCatalog(c);
  res.json({ ok: true });
});

app.put('/api/admin/settings', requireAdmin, (req, res) => {
  const s = req.body || {};
  const c = catalog();
  const int = (v) => Math.max(0, parseInt(v, 10) || 0);
  c.settings = {
    ...c.settings,
    shopName: String(s.shopName || c.settings.shopName), slogan: String(s.slogan ?? ''),
    healthCertificate: String(s.healthCertificate ?? ''), healthCard: String(s.healthCard ?? ''),
    deliveryFee: int(s.deliveryFee), freeDeliveryOver: int(s.freeDeliveryOver), minOrder: int(s.minOrder),
    deliveryEnabled: !!s.deliveryEnabled, pickupEnabled: !!s.pickupEnabled,
    branches: Array.isArray(s.branches) ? s.branches.map((b) => ({ name: String(b.name), address: String(b.address), phone: String(b.phone) })) : c.settings.branches,
  };
  saveCatalog(c);
  res.json(c.settings);
});

app.get('/api/admin/orders', requireAdmin, (req, res) => {
  res.json(db.prepare('SELECT * FROM orders ORDER BY id DESC LIMIT 500').all().map(orderOut));
});

app.patch('/api/admin/orders/:id', requireAdmin, (req, res) => {
  const allowed = ['pending_payment', 'paid', 'preparing', 'sending', 'ready', 'done', 'canceled'];
  if (!allowed.includes(req.body?.status)) return bad(res, 'وضعیت نامعتبر');
  db.prepare('UPDATE orders SET status=? WHERE id=?').run(req.body.status, Number(req.params.id));
  res.json({ ok: true });
});

function getOrder(id) { return db.prepare('SELECT * FROM orders WHERE id=?').get(id); }
function orderOut(row) {
  const d = JSON.parse(row.data);
  return {
    ...d, id: String(row.id), status: row.status,
    paymentUrl: row.status === 'pending_payment' && row.authority ? `${ZP_HOST}/pg/StartPay/${row.authority}` : null,
  };
}

app.listen(PORT, () => console.log(`Nargol server on :${PORT} (zarinpal ${SANDBOX ? 'SANDBOX' : 'LIVE'})`));
