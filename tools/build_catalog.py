"""Build catalog JSON + compressed product images from the raw photo folders."""
import json, re, sys, glob, os
from PIL import Image, ImageOps

SRC = sys.argv[1]          # dir containing part0*/Part 0*/...
OUT_IMG = sys.argv[2]      # output image dir
OUT_JSON = sys.argv[3]

files = {}
for f in glob.glob(os.path.join(SRC, 'part0*', '*', '*')):
    m = re.match(r'(\d+)\s+(.+)\.(jpg|jpeg|png|webp)$', os.path.basename(f), re.I)
    if m:
        files[int(m.group(1))] = (m.group(2).strip(), f)
assert len(files) == 182, len(files)

CATS = [
  ('ready',   'خورش و غذای آماده', [102,113,104,106,107,112,122,164,127,155,118,114,86,87,97,110,111,141]),
  ('fried',   'سرخ‌شده و بخارپز', [45,46,47,88,98,99,103,115,138,156,158,167,182,105,116,140,90]),
  ('frozen',  'همبرگر و منجمد', [89,92,176,91,94,93,95,96,101,100]),
  ('herbs',   'سبزی تازه خردشده', [108,109,120,126,128,129,130,131,132,136,121,123]),
  ('veg',     'صیفی آماده', [117,119,124,125,133,134,135,137,139,146,142,143,144,145,147]),
  ('dried',   'سبزی خشک', [58,59,60,61,62,63,64,65,66,2]),
  ('pickles', 'ترشی و شور', [1,3,10,177,23,24,25,36,35,162,175,26,32,33,34,37,38,39,40,44,49,50,68,71,72,157,172,174,170,173,171,178,180]),
  ('sauces',  'رب، سس و سرکه', [51,52,53,54,77,78,79,80,81,69,55,70,179,56,57,28,82,29,30,31]),
  ('jam',     'مربا، عسل و شربت', [67,73,74,75,76,165,166,169,83,84]),
  ('spices',  'ادویه و عطاری', [20,11,15,14,18,12,19,13,17,16,4,5,7,8,9,42,27,160,161,181]),
  ('legumes', 'حبوبات و غلات', [148,149,150,151,152,153,154,41,43]),
  ('pantry',  'سایر محصولات', [21,22,48,6,85,159,163,168]),
]
# merged products: first number's photo is used; (number, variant label)
MERGE = {
  'ادویه کاری': [(11,'بسته‌ای'),(15,'شیشه‌ای')],
  'ادویه قیمه': [(14,'بسته‌ای'),(18,'شیشه‌ای')],
  'ادویه مرغ و ماهی': [(12,'بسته‌ای'),(19,'شیشه‌ای')],
  'ادویه لازانیا و ماکارونی': [(13,'بسته‌ای'),(17,'شیشه‌ای')],
  'خیارشور': [(25,'۵۰۰ گرم'),(175,'۳۷۰ گرم'),(36,'متوسط'),(35,'بزرگ'),(162,None)],
  'سیر ترشی': [(10,'۵۰۰ گرم'),(177,'۱ کیلو')],
  'کشک بز و گوسفندی عشایر': [(22,'۵۰۰ گرم'),(48,None)],
  'سس فلفل': [(70,'۵۰۰ گرم'),(179,None)],
  'ترشی ناز خاتون': [(72,'۳۰۰ گرم'),(71,'۵۰۰ گرم')],
  'زیتون ویژه بدون هسته': [(170,'۳۵۰ گرم'),(173,'۶۵۰ گرم')],
  'ترشی مخلوط': [(172,'۳۵۰ گرم'),(174,'۶۵۰ گرم'),(157,'۱ کیلو')],
}
FA = str.maketrans('0123456789', '۰۱۲۳۴۵۶۷۸۹')
DEFAULT_PRICE = 100000

def clean(name):
    """Return (display name, weight label or None) parsed from a file name."""
    name = re.sub(r'\s+', ' ', name).replace('( ', '(').replace(' )', ')')
    m = re.search(r'\s*(\d+|یک)\s*(گرم|کیلو)\s*$', name)
    w = None
    if m:
        n = '1' if m.group(1) == 'یک' else m.group(1)
        w = f'{n} {m.group(2)}'.translate(FA)
        name = name[:m.start()].strip()
    name = name.replace(' 99 درصد', ' ۹۹٪').replace(' 65 درصد', ' ۶۵٪')
    return name, w

merged_nums = {n: title for title, lst in MERGE.items() for n, _ in lst}
cat_of = {n: cid for cid, _, nums in CATS for n in nums}
assert set(cat_of) == set(files), set(files) ^ set(cat_of)

os.makedirs(OUT_IMG, exist_ok=True)
def save_img(num):
    _, path = files[num]
    im = ImageOps.exif_transpose(Image.open(path)).convert('RGB')
    im.thumbnail((800, 800))
    out = f'p{num}.jpg'
    im.save(os.path.join(OUT_IMG, out), 'JPEG', quality=78, optimize=True, progressive=True)
    return out

products, done, sort = [], set(), 0
for cid, _, nums in CATS:
    for n in nums:
        if n in done: continue
        sort += 1
        if n in merged_nums:
            title = merged_nums[n]
            group = MERGE[title]
            done.update(x for x, _ in group)
            variants = [{'label': lbl, 'price': DEFAULT_PRICE} for _, lbl in group if lbl]
            img = save_img(group[0][0])
        else:
            done.add(n)
            title, w = clean(files[n][0])
            variants = [{'label': w or '۵۰۰ گرم', 'price': DEFAULT_PRICE}]
            img = save_img(n)
        for i, v in enumerate(variants):
            v['id'] = f'v{n}_{i}'; v['available'] = True
        products.append({'id': f'p{n}', 'name': title, 'categoryId': cat_of[n], 'image': img,
                         'description': '', 'available': True, 'sort': sort, 'variants': variants})

catalog = {
  'categories': [{'id': c, 'name': nm, 'sort': i} for i, (c, nm, _) in enumerate(CATS)],
  'products': products,
  'settings': {
    'shopName': 'محصولات خانگی نارگل', 'slogan': 'از دیدنت خوشحالم',
    'deliveryFee': 50000, 'freeDeliveryOver': 1000000, 'minOrder': 200000,
    'deliveryEnabled': True, 'pickupEnabled': True,
    'healthCertificate': '24568354', 'healthCard': '1111817779',
    'branches': [
      {'name': 'شعبه ۱ - چیتگر', 'address': 'شهرک مسکونی چیتگر، خیابان ارغوان ۱، بین برج ارکیده ۲ و ۳', 'phone': '09196052479'},
      {'name': 'شعبه ۲ - تهرانسر', 'address': 'تهرانسر، بالاتر از میدان کمال‌الملک، روماک مال، طبقه منفی ۱، جنب هایپر، راهرو مهتاب ۵، پلاک ۲۷', 'phone': '09378282022'},
    ],
  },
}
json.dump(catalog, open(OUT_JSON, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print(len(products), 'products')
