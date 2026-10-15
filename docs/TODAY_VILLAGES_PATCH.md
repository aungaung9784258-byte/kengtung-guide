# Today + Villages — ထည့်သွင်းနည်း (၄ ဆင့်)

ဖိုင်အသစ် ၇ ခု ကူးထည့်ပြီးနောက်၊ ရှိပြီးသား ဖိုင် ၄ ခုကို အနည်းငယ် ပြင်ရပါမယ်။
ပြင်ရမယ့် နေရာတိုင်းကို အောက်မှာ အတိအကျ ပြထားပါတယ်။

---

## ၁။ `lib/app/router.dart`

### (က) import ၂ ကြောင်း ထပ်ထည့်

**ရှာပါ —**

```dart
import '../features/settings/settings_screen.dart';
```

**အောက်မှာ ဒီ ၃ ကြောင်း ထပ်ထည့်ပါ —**

```dart
import '../features/today/today_screen.dart';
import '../features/villages/village_detail_screen.dart';
import '../features/villages/villages_screen.dart';
```

### (ခ) root route ၂ ခု ထပ်ထည့်

**ရှာပါ —**

```dart
    GoRoute(
      path: '/place/:id',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(
        s,
        PlaceDetailScreen(placeId: s.pathParameters['id']!),
      ),
    ),
```

**အောက်မှာ ဒါကို ထပ်ထည့်ပါ —**

```dart
    GoRoute(
      path: '/villages',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(s, const VillagesScreen()),
    ),
    GoRoute(
      path: '/village/:id',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(
        s,
        VillageDetailScreen(villageId: s.pathParameters['id']!),
      ),
    ),
```

### (ဂ) Today tab branch ကို **အလယ်** မှာ ထည့်

Today ကို nav bar ရဲ့ အလယ် (၃ ခုမြောက်) မှာ ထားမှာမို့ branch ကိုလည်း
Map ပြီးနောက်၊ Favourites မတိုင်ခင်မှာ ထည့်ရပါမယ်။

**ရှာပါ — `/map` branch ရဲ့ အဆုံး၊ `/favourites` branch မတိုင်မီ —**

```dart
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/favourites',
              pageBuilder: (c, s) => _fade(s, const FavouritesScreen())),
        ]),
```

**ဒီ branch အသစ်ကို အဲဒါရဲ့ အပေါ်မှာ ထည့်ပါ —**

```dart
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/today',
              pageBuilder: (c, s) => _fade(s, const TodayScreen())),
        ]),
```

ရလဒ် branch အစီအစဉ် — `/home` · `/map` · `/today` · `/favourites` · `/settings`

> မှတ်ချက် — Favourites နဲ့ Settings ရဲ့ tab index က ၂ → ၃၊ ၃ → ၄ ရွှေ့သွားပါတယ်။
> ခင်ဗျားကုဒ်မှာ navigation အားလုံးက `context.go('/map')` လိုမျိုး **path နဲ့**
> သွားတာမို့ ဘာမှ ထိခိုက်မှု မရှိပါဘူး။

---

## ၂။ `lib/app/shell.dart`

### (က) destination ကို အလယ်မှာ ထည့်

**ရှာပါ —**

```dart
              _dest(Icons.near_me_rounded, Icons.near_me_outlined, t.map),
```

**အောက်မှာ ဒီတစ်ကြောင်း ထပ်ထည့်ပါ —**

```dart
              _dest(Icons.today_rounded, Icons.today_outlined, t.t('todayTab')),
```

destinations စာရင်းက ဒီအတိုင်း ဖြစ်သွားရပါမယ် —

```dart
            destinations: [
              _dest(Icons.home_rounded, Icons.home_outlined, t.home),
              _dest(Icons.near_me_rounded, Icons.near_me_outlined, t.map),
              _dest(Icons.today_rounded, Icons.today_outlined, t.t('todayTab')),
              _dest(Icons.favorite_rounded, Icons.favorite_border_rounded,
                  t.favourites),
              _dest(Icons.settings_rounded, Icons.settings_outlined,
                  t.settings),
            ],
```

> branch အစီအစဉ်နဲ့ destination အစီအစဉ် **အတူတူ ဖြစ်ရပါမယ်** — မတူရင်
> Today ကိုနှိပ်လျှင် Favourites ပွင့်သွားပါလိမ့်မယ်။

### (ခ) label ရှည်လွန်းမှု ကာကွယ်ရန်

tab ၅ ခု ဖြစ်သွားပြီ၊ မြန်မာလို label တွေက ရှည်ပါတယ်။
`NavigationBar(` စာကြောင်းရဲ့ အောက်မှာ ဒီ ၂ ကြောင်း ထပ်ထည့်ပါ —

```dart
            labelBehavior:
                NavigationDestinationLabelBehavior.onlyShowSelected,
            height: 68,
```

ဒါဆိုရင် ရွေးထားတဲ့ tab ရဲ့ စာသားပဲ ပေါ်မယ် — ကျန်တာက icon သက်သက်။
မြန်မာစာ "ကိုယ်ရေးအချက်အလက်" မျိုး ရှည်တဲ့အခါ ပြိုကျတာ မဖြစ်တော့ပါဘူး။

---

## ၃။ `lib/l10n/app_localizations.dart`

`_en` map ရဲ့ အဆုံး `};` **မတိုင်မီမှာ** `today_villages_en.txt` ထဲက စာကြောင်းများကို paste လုပ်ပါ။
`_my` map ရဲ့ အဆုံး `};` **မတိုင်မီမှာ** `today_villages_my.txt` ထဲက စာကြောင်းများကို paste လုပ်ပါ။

typed getter တစ်ခုမှ ထပ်ထည့်စရာ မလိုပါ — အားလုံးကို `t('...')` နဲ့ ခေါ်ထားပါတယ်။

---

## ၄။ `pubspec.yaml`

`flutter:` block ကို အောက်ပါအတိုင်း ဖြစ်အောင် ပြင်ပါ (`fonts:` နေရာလွဲနေတာကို ပြင်တာနဲ့
`assets/images/villages/` ထည့်တာ) —

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/data/
    - assets/images/
    - assets/images/villages/
    - assets/lottie/

  fonts:
    - family: Padauk
      fonts:
        - asset: assets/fonts/Padauk-Regular.ttf
          weight: 400
        - asset: assets/fonts/Padauk-Bold.ttf
          weight: 700
```

---

## ၅။ run

asset အသစ်နဲ့ pubspec ပြောင်းထားတဲ့အတွက် **hot reload (`r`) နဲ့ မရပါဘူး**။
`q` နှိပ်ပြီး အစကနေ ပြန် run ရပါမယ် —

```
cd /d D:\projects\kengtung-guide && flutter run -d 4d6ef13a
```

---

## ဖိုင်အသစ် စာရင်း (၇ ခု)

```
assets/data/villages.json
assets/data/festivals.json
assets/data/markets.json
lib/core/services/market_cycle.dart
lib/core/providers/today_providers.dart
lib/data/models/village.dart
lib/data/repositories/guide_repository.dart
lib/shared/widgets/confidence_badge.dart
lib/features/today/today_screen.dart
lib/features/villages/villages_screen.dart
lib/features/villages/village_detail_screen.dart
```

ဓာတ်ပုံ ၃ ပုံ — `assets/images/villages/` အောက်မှာ။
