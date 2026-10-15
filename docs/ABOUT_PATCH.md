# ကျိုင်းတုံအကြောင်း — တပ်ဆင်နည်း

ရှိပြီးသား ဖိုင် **၃ ဖိုင်ပဲ** ထိပါတယ်။ တစ်ဖိုင်စီမှာ ထည့်ရမယ့် စာကြောင်းကို `// ADD` နဲ့ မှတ်ထားပါတယ်။
ရှိပြီးသား ကုဒ် တစ်ကြောင်းမှ **ဖျက်စရာ မလိုပါဘူး**။

---

## ၁။ ဖိုင်အသစ် ၄ ခု (copy လုပ်ရုံ)

```
assets/data/about_kengtung.json
lib/data/models/about_content.dart
lib/features/about/about_kengtung_screen.dart
lib/features/about/widgets/frosted_photo.dart
lib/features/about/widgets/about_entry_card.dart
```

ပုံတွေကတော့ `assets/images/about/` ထဲမှာ ရှိပြီးသားပါ —
`haw-palace.jpg` · `standing-buddha.jpg` · `lone-tree-hill.jpg` · `old-gate.jpg`

---

## ၂။ `pubspec.yaml` — စာကြောင်း ၁ ကြောင်း

`assets/data/` က ရှိပြီးသားမို့ JSON က အလိုအလျောက် ပါသွားပါတယ်။
ဒါပေမဲ့ `assets/images/` က **subfolder တွေကို မပါ**ပါဘူး။ ဒါကြောင့် —

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - assets/images/
    - assets/images/about/     # ADD
    - assets/lottie/
```

> ⚠️ သီးခြား ပြဿနာတစ်ခု — `fonts:` က `flutter_launcher_icons:` အောက်မှာ မှားနေပါတယ်။
> `flutter:` အောက်ကို ရွှေ့မှ Padauk font အလုပ်လုပ်ပါမယ်။ ဒီ patch နဲ့ မဆိုင်ပေမယ့် မြန်မာစာ
> အတွက် အရေးကြီးလို့ ပြောထားတာပါ။

---

## ၃။ `lib/app/router.dart` — ၂ နေရာ

အပေါ်ဆုံး import တွေထဲ —

```dart
import '../features/about/about_kengtung_screen.dart';   // ADD
```

`/place/:id` route အောက်မှာ (root route အဖြစ် — nav bar မပါဘဲ စာမျက်နှာ ပြည့်ပြရန်) —

```dart
    GoRoute(                                             // ADD ↓
      path: '/about-kengtung',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(s, const AboutKengtungScreen()),
    ),                                                   // ADD ↑
```

`_slideUp` ကို သုံးတာက detail စာမျက်နှာနဲ့ လှုပ်ရှားမှု တူညီစေဖို့ပါ။

---

## ၄။ `lib/features/home/home_screen.dart` — ၂ နေရာ

import —

```dart
import '../about/widgets/about_entry_card.dart';         // ADD
```

**ရှာဖွေရန် box အောက်၊ category chips အပေါ်** မှာ —

```dart
const AboutEntryCard(),                                  // ADD
```

`CustomScrollView` သုံးထားရင် —

```dart
const SliverToBoxAdapter(child: AboutEntryCard()),       // ADD
```

---

## ၅။ Settings → About (ရွေးချယ်စရာ)

`'about'` key က `app_localizations.dart` မှာ ရှိပြီးသားပါ။ `settings_screen.dart` ထဲ
ရှိပြီးသား About အကွက်ကို နှိပ်ရင် —

```dart
onTap: () => context.push('/about-kengtung'),            // ADD
```

ဝင်ပေါက် ၂ ခုလုံး **route တစ်ခုတည်း** ကို သွားပါတယ်။ ကုဒ် ၂ မျိုး မရေးပါနဲ့။

---

## ၆။ စမ်းရန်

```
flutter pub get
flutter run -d 4d6ef13a
```

စစ်ဆေးရန် ၆ ချက် —

1. Home မှာ Card ပေါ်သလား၊ နှိပ်ရင် ဝင်သွားသလား
2. scroll ဆွဲရင် ပုံတွေ ရွေ့သလား (parallax)
3. ပုံတိုင်းရဲ့ အောက်ခြေ ဝါးပြီး စာ ဖတ်ရလွယ်သလား
4. မြန်မာ ↔ English ပြောင်းရင် စာ အကုန် ပြောင်းသလား
5. Dark Mode မှာ အရောင်တွေ မှန်သလား
6. နောက်ပြန် ← နှိပ်ရင် Home ကို ပြန်ရောက်သလား

---

## ၇။ နောက်ပိုင်း ပြင်ချင်ရင်

| ပြင်ချင်တာ | ဘယ်မှာ | restart လိုလား |
|---|---|---|
| စာသား အားလုံး | `assets/data/about_kengtung.json` | မလို — `R` နှိပ်ရုံ |
| ပုံ | `assets/images/about/` မှာ **အမည်တူ** ဖိုင် အစားထိုး | လို (asset အသစ်) |
| parallax အားပြင်းအား | JSON ထဲ `"parallax": 0.16` | မလို |
| အပိုင်း ရွှေ့/ဖြုတ်/ထည့် | JSON ထဲ `sections[]` အစီအစဉ် | မလို |
| ဝါးတဲ့ အလွှာ အမြင့် | `frosted_photo.dart` → `bandHeight` | မလို |
| ဝါးတဲ့ အတိမ်အနက် | `frosted_photo.dart` → `_blurBand` sigma (2 / 7 / 15) | မလို |

AI ပုံ မှတ်ချက်ကို ဖျက်ချင်ရင် JSON ထဲက `"disclaimer"` key ကို ဖျက်လိုက်ရုံပါပဲ —
Dart ကုဒ် ဘာမှ ပြင်စရာ မလိုပါ။

---

## ၈။ ကျန်နေသေးတာ

- `/today` route မရှိသေးပါ။ အပိုင်း ၀၇ ရဲ့ ခလုတ်က `"route": "/today"` ကို ညွှန်ထားပြီး
  Today tab တင်ပြီးမှ အလုပ်လုပ်ပါမယ်။ အခု စမ်းချင်ရင် JSON ထဲမှာ `/home` လို့ ပြောင်းထားပါ။
- ဟော်နန်းတော် ပြတိုက် ဖွင့်ချိန် မသိရသေးလို့ timeline မှာ `"estimated"` (ရွှေရောင်အစက်)
  ထားထားပါတယ်။ အတည်ပြုပြီးရင် `"verified"` ပြောင်းပါ။
- သမိုင်းအပိုင်းကို Dr. Yin Win Chit ထံ တစ်ခေါက် ပြသင့်ပါတယ် (အထူးသဖြင့် ၁၉၉၁ ဖြိုဖျက်မှု)။
