import 'package:flutter/material.dart';

/// Lightweight hand-rolled localization (no codegen step needed).
/// Add a key to BOTH maps below and it is instantly available as
/// `context.l10n.t('key')` or via the typed getters.
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('my')];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get isMyanmar => locale.languageCode == 'my';

  Map<String, String> get _m => isMyanmar ? _my : _en;

  String t(String key) => _m[key] ?? _en[key] ?? key;

  // Typed shortcuts for the most used strings
  String get appName => t('appName');
  String get exploreIn => t('exploreIn');
  String get search => t('search');
  String get popularPlaces => t('popularPlaces');
  String get categories => t('categories');
  String get all => t('all');
  String get home => t('home');
  String get map => t('map');
  String get favourites => t('favourites');
  String get profile => t('profile');
  String get viewInMap => t('viewInMap');
  String get findPath => t('findPath');
  String get viewDetail => t('viewDetail');
  String get description => t('description');
  String get settings => t('settings');
  String get language => t('language');
  String get theme => t('theme');
  String get lightMode => t('lightMode');
  String get darkMode => t('darkMode');
  String get systemMode => t('systemMode');
  String get emergency => t('emergency');
  String get nearYou => t('nearYou');
  String get noFavourites => t('noFavourites');
  String get call => t('call');
  String get openingHours => t('openingHours');
  String get address => t('address');
  String get letsTour => t('letsTour');
  String get tagline => t('tagline');
  String get about => t('about');

  static const Map<String, String> _en = {
    'appName': 'Kengtung Guide',
    'exploreIn': "Let's explore in",
    'cityName': 'Kengtung',
    'search': 'Search places, hotels, food...',
    'popularPlaces': 'Popular Places',
    'categories': 'Categories',
    'all': 'All',
    'home': 'Home',
    'map': 'Map',
    'favourites': 'Favourites',
    'profile': 'Profile',
    'viewInMap': 'View in Map',
    'findPath': 'Find path',
    'viewDetail': 'View Detail',
    'description': 'Description',
    'settings': 'Settings',
    'language': 'Language',
    'theme': 'Theme',
    'lightMode': 'Light',
    'darkMode': 'Dark',
    'systemMode': 'System',
    'emergency': 'Emergency',
    'nearYou': 'near you',
    'noFavourites': 'No saved places yet',
    'call': 'Call',
    'openingHours': 'Opening hours',
    'address': 'Address',
    'letsTour': "Let's Tour",
    'tagline': 'The Hidden Heart of the Shan Hills',
    'cat_place': 'Places to Visit',
    'cat_pagoda': 'Pagodas',
    'cat_market': 'Markets',
    'cat_transport': 'Transportation',
    'cat_hotel': 'Hotels',
    'cat_restaurant': 'Restaurants',
    'cat_education': 'Education',
    'cat_bank': 'Banks & ATMs',
    'cat_emergency': 'Emergency',
    'distanceKm': 'km',
    'locating': 'Getting your location...',
    'locationDenied': 'Location permission denied',
    'routeFailed': 'Could not calculate the route',
    'clearRoute': 'Clear route',
    'about': 'About',
    'credits': 'App Credits',
    'crSupervisor': 'Project Supervisor',
    'crSupervisorRole': 'Academic Supervisor',
    'crLead': 'Project Lead & Core Developer',
    'crLeadRole': 'App Development & Architecture',
    'crDesign': 'UI / UX Designer',
    'crData': 'Data Collection & Preparation',
    'crQa': 'Quality Assurance & Testing',
    'crWholeTeam': 'The Whole Team',
    'crProudly': 'Proudly developed by',
    'crBatch': '2026\u20132027 Final Year\nPUKT Computer Science Students',
    'crUniversity': 'Polytechnic University (Kyaingtong)',
    'crMadeWith': 'Made with',
    'crMadeIn': 'in Kengtung, Shan State',
    'thanksTo': 'Thanks To',
    'thxOsm': 'Map data \u00a9 OpenStreetMap contributors',
    'thxEsri': 'Satellite imagery \u00a9 Esri',
    'thxMeteo': 'Weather data by Open-Meteo',
    'thxOsrm': 'Routing by OSRM',
    'thxPadauk': 'Myanmar typeface Padauk by SIL',
    'aboutBody':
        'A community travel guide to Kengtung (Kyaing Tong), Eastern Shan State, Myanmar.',
    'offlineMaps': 'Offline maps',
    'offlineMapsHint':
        'Download the map so it keeps working with no internet. Your places, photos and GPS already work offline.',
    'download': 'Download',
    'downloadDone': 'Map downloaded. It now works offline.',
    'storageUsed': 'Storage used',
    'clearOffline': 'Clear',
    'offlineCleared': 'Offline maps cleared',
    'online': 'Online',
    'offline': 'Offline',
    'offlineBanner': "You're offline — showing the saved map",
    'routeApprox': 'Offline: showing direct line and distance only',
    'straightLine': 'direct line',
    'startNavigation': 'Start',
    'noResults': 'No places found',
    'noResultsHint':
        'Try a shorter word, or search by category — pagoda, market, hotel, food, hospital.',
    'results': 'results',
    'stopNavigation': 'Stop',
    'rerouting': 'Finding a new route...',
    'arrived': 'You have arrived at',
    'tapRecenter': 'Tap the location button to follow again',
    'northUp': 'North up',
    'courseUp': 'Course up',
    'mapStreet': 'Map',
    'mapSatellite': 'Satellite',
    'mapHybrid': 'Hybrid',
    'offlineWeb':
        'On the web your browser caches the map automatically — no download needed.',
      // ---- Today tab ----
    'todayTab': 'Today',
    'marketToday': "TODAY'S MARKET",
    'marketUnknownName': 'Market name not recorded yet',
    'marketUnknownHint':
        'A market is held somewhere in the township today — the five-day rotation says so — but we have not recorded which one. Ask at your hotel, then help us fill it in.',
    'nextFiveDays': 'Next five days',
    'comingUp': 'Coming up',
    'villagesNearby': 'Villages nearby',
    'seeAll': 'See all',
    'todayShort': 'Today',
    'tomorrow': 'Tomorrow',
    'daysShort': 'days',
    'minShort': 'min',
    'happeningToday': 'HAPPENING TODAY',
    'dateNotAnnounced': 'Date not announced yet',
    // ---- Confidence ----
    'confVerified': 'Verified',
    'confEstimated': 'Estimated',
    'confUnverified': 'Unconfirmed',
    'howSureLegend': 'How sure are we?',
    'confVerifiedHint': 'From an official calendar or a published report.',
    'confEstimatedHint':
        'From a guidebook or tour operator. Probably right — worth checking locally.',
    'confUnverifiedHint':
        'We do not know this yet. If you find out, please tell us.',
    // ---- Villages ----
    'villagesTitle': 'Hill Tribe Villages',
    'villagesIntro':
        'Thirteen ethnic groups live in the hills around Kengtung. Visiting a village is the reason most travellers come — go with a local guide, go slowly, and ask before you photograph anyone.',
    'villageNotFound': 'Village not found',
    'trekEasy': 'Easy',
    'trekModerate': 'Moderate',
    'trekHard': 'Hard',
    'byCar': 'By car',
    'onFoot': 'On foot',
    'difficulty': 'Difficulty',
    'altitude': 'Altitude',
    'beforeYouGo': 'Before you go',
    'needGuide': 'A local guide is needed — for the language, and because it is polite.',
    'permitYes': 'A permit is required. Arrange it in Kengtung before setting out.',
    'permitNo': 'No permit needed.',
    'permitAsk':
        'Permit rules change. Ask at your hotel or the tourist office before you set out.',
    'bestSeason': 'Best season',
    'noGpsYet':
        'We do not have GPS coordinates for this village yet, so the app cannot navigate you there. The route shown is indicative only.',
    'respectTitle': 'Visiting respectfully',
    'pleaseDo': 'PLEASE DO',
    'pleaseDont': 'PLEASE DO NOT',
    'whereThisComesFrom': 'Where this comes from',
    'sourceUnknown': 'Source not recorded',
    'lastChecked': 'Last checked',

  };

  static const Map<String, String> _my = {
    'appName': 'ကျိုင်းတုံ လမ်းညွှန်',
    'exploreIn': 'လေ့လာကြည့်ရှုရန်',
    'cityName': 'ကျိုင်းတုံ',
    'search': 'နေရာ၊ ဟိုတယ်၊ အစားအစာ ရှာရန်...',
    'popularPlaces': 'ရေပန်းစားသော နေရာများ',
    'categories': 'အမျိုးအစားများ',
    'all': 'အားလုံး',
    'home': 'ပင်မ',
    'map': 'မြေပုံ',
    'favourites': 'စိတ်ကြိုက်',
    'profile': 'ကိုယ်ရေးအချက်အလက်',
    'viewInMap': 'မြေပုံတွင်ကြည့်ရန်',
    'findPath': 'လမ်းကြောင်းရှာရန်',
    'viewDetail': 'အသေးစိတ်ကြည့်ရန်',
    'description': 'ဖော်ပြချက်',
    'settings': 'ဆက်တင်များ',
    'language': 'ဘာသာစကား',
    'theme': 'အသွင်အပြင်',
    'lightMode': 'အလင်း',
    'darkMode': 'အမှောင်',
    'systemMode': 'စနစ်အတိုင်း',
    'emergency': 'အရေးပေါ်',
    'nearYou': 'သင့်အနီး',
    'noFavourites': 'သိမ်းဆည်းထားသော နေရာမရှိသေးပါ',
    'call': 'ဖုန်းခေါ်ရန်',
    'openingHours': 'ဖွင့်ချိန်',
    'address': 'လိပ်စာ',
    'letsTour': 'စတင်ကြည့်ရှုမယ်',
    'tagline': 'ရှမ်းတောင်တန်းများ၏ ဖုံးကွယ်နေသော အနှစ်သာရ',
    'cat_place': 'လည်ပတ်စရာနေရာများ',
    'cat_pagoda': 'ဘုရားများ',
    'cat_market': 'ဈေးများ',
    'cat_transport': 'သယ်ယူပို့ဆောင်ရေး',
    'cat_hotel': 'ဟိုတယ်များ',
    'cat_restaurant': 'စားသောက်ဆိုင်များ',
    'cat_education': 'ပညာရေး',
    'cat_bank': 'ဘဏ်များ',
    'cat_emergency': 'အရေးပေါ်',
    'distanceKm': 'ကီလိုမီတာ',
    'locating': 'တည်နေရာ ရယူနေသည်...',
    'locationDenied': 'တည်နေရာ ခွင့်ပြုချက် ငြင်းပယ်ခံရသည်',
    'routeFailed': 'လမ်းကြောင်း တွက်ချက်၍မရပါ',
    'clearRoute': 'လမ်းကြောင်း ဖျက်ရန်',
    'about': 'အကြောင်း',
    'credits': 'ဖန်တီးသူများ',
    'crSupervisor': 'စီမံကိန်း ကြီးကြပ်သူ',
    'crSupervisorRole': 'ပညာရပ်ဆိုင်ရာ ကြီးကြပ်သူ',
    'crLead': 'စီမံကိန်းခေါင်းဆောင်နှင့် ပင်မဆော့ဖ်ဝဲရေးသားသူ',
    'crLeadRole': ' အက်ပ်ပလီကေးရှင်း ရေးသားမှုနှင့် ဖွဲ့စည်းပုံ',
    'crDesign': 'ဒီဇိုင်းပိုင်း (UI / UX)',
    'crData': 'ဒေတာစုဆောင်းရေးနှင့် ပြင်ဆင်ရေးအဖွဲ့',
    'crQa': 'အရည်အသွေးစစ်ဆေးရေးနှင့် စမ်းသပ်ရေး',
    'crWholeTeam': 'အဖွဲ့သား အားလုံး',
    'crProudly': 'ဂုဏ်ယူစွာ ဖန်တီးသူများ',
    'crBatch': '၂၀၂၆\u2013၂၀၂၇ ပညာသင်နှစ်\nPUKT ကွန်ပျူတာသိပ္ပံ နောက်ဆုံးနှစ် ကျောင်းသားများ',
    'crUniversity': 'နည်းပညာတက္ကသိုလ် (ကျိုင်းတုံ)',
    'crMadeWith': 'မေတ္တာ',
    'crMadeIn': 'ဖြင့် ကျိုင်းတုံမြို့မှ ဖန်တီးသည်',
    'thanksTo': 'ကျေးဇူးတင်လွှာ',
    'thxOsm': 'မြေပုံဒေတာ \u00a9 OpenStreetMap အဖွဲ့ဝင်များ',
    'thxEsri': 'ဂြိုဟ်တုပုံများ \u00a9 Esri',
    'thxMeteo': 'ရာသီဥတုအချက်အလက် Open-Meteo မှ',
    'thxOsrm': 'လမ်းကြောင်းရှာဖွေမှု OSRM မှ',
    'thxPadauk': 'မြန်မာဖောင့် Padauk \u2014 SIL မှ',
    'aboutBody':
        'မြန်မာနိုင်ငံ၊ ရှမ်းပြည်နယ်အရှေ့ပိုင်း၊ ကျိုင်းတုံမြို့အတွက် ခရီးသွားလမ်းညွှန်။',
    'offlineMaps': 'အော့ဖ်လိုင်း မြေပုံများ',
    'offlineMapsHint':
        'အင်တာနက်မရှိလည်း မြေပုံအလုပ်လုပ်စေရန် ဒေါင်းလုဒ်လုပ်ပါ။ နေရာများ၊ ဓာတ်ပုံများနှင့် GPS တို့မှာ အော့ဖ်လိုင်းတွင် အလုပ်လုပ်နှင့်ပြီးဖြစ်သည်။',
    'download': 'ဒေါင်းလုဒ်',
    'downloadDone': 'မြေပုံ ဒေါင်းလုဒ်ပြီးပါပြီ။ အော့ဖ်လိုင်းတွင် အသုံးပြုနိုင်ပါပြီ။',
    'storageUsed': 'သုံးစွဲထားသော နေရာ',
    'clearOffline': 'ရှင်းလင်းရန်',
    'offlineCleared': 'အော့ဖ်လိုင်းမြေပုံများ ရှင်းလင်းပြီးပါပြီ',
    'online': 'အွန်လိုင်း',
    'offline': 'အော့ဖ်လိုင်း',
    'offlineBanner': 'အင်တာနက်မရှိပါ — သိမ်းထားသော မြေပုံကို ပြသနေသည်',
    'routeApprox': 'အော့ဖ်လိုင်း — တိုက်ရိုက်မျဉ်းနှင့် အကွာအဝေးသာ ပြသသည်',
    'straightLine': 'တိုက်ရိုက်မျဉ်း',
    'startNavigation': 'စတင်မည်',
    'noResults': 'ရှာဖွေမှု မတွေ့ရှိပါ',
    'noResultsHint':
        'စာလုံးတိုတို စမ်းကြည့်ပါ၊ သို့မဟုတ် အမျိုးအစားနဲ့ ရှာပါ — ဘုရား၊ ဈေး၊ ဟိုတယ်၊ စားသောက်ဆိုင်၊ ဆေးရုံ။',
    'results': 'ခု တွေ့ရှိ',
    'stopNavigation': 'ရပ်မည်',
    'rerouting': 'လမ်းကြောင်းအသစ် ရှာနေသည်...',
    'arrived': 'ရောက်ရှိပါပြီ —',
    'tapRecenter': 'ပြန်လိုက်ရန် တည်နေရာခလုတ်ကို နှိပ်ပါ',
    'northUp': 'မြောက်ဘက် အပေါ်',
    'courseUp': 'ခရီးလမ်း အပေါ်',
    'mapStreet': 'မြေပုံ',
    'mapSatellite': 'ဂြိုဟ်တု',
    'mapHybrid': 'ပေါင်းစပ်',
    'offlineWeb':
        'ဝဘ်တွင် ဘရောက်ဇာက မြေပုံကို အလိုအလျောက် သိမ်းဆည်းပေးသဖြင့် ဒေါင်းလုဒ်လုပ်ရန် မလိုပါ။',
      // ---- Today tab ----
    'todayTab': 'ယနေ့',
    'marketToday': 'ယနေ့ဈေး',
    'marketUnknownName': 'ဈေးအမည် မှတ်တမ်း မတင်ရသေးပါ',
    'marketUnknownHint':
        'ငါးရက်တစ်ဈေး အလှည့်ကျစနစ်အရ ယနေ့ မြို့နယ်အတွင်း တစ်နေရာရာတွင် ဈေးရှိပါသည် — သို့သော် မည်သည့်ဈေးဖြစ်သည်ကို မှတ်တမ်း မတင်ရသေးပါ။ တည်းခိုခန်းတွင် မေးကြည့်ပြီး ကျွန်ုပ်တို့ကိုလည်း အသိပေးပါ။',
    'nextFiveDays': 'နောက်လာမည့် ငါးရက်',
    'comingUp': 'လာမည့် ပွဲတော်များ',
    'villagesNearby': 'အနီးအနားရှိ ရွာများ',
    'seeAll': 'အားလုံးကြည့်ရန်',
    'todayShort': 'ယနေ့',
    'tomorrow': 'မနက်ဖြန်',
    'daysShort': 'ရက်',
    'minShort': 'မိနစ်',
    'happeningToday': 'ယနေ့ ကျင်းပနေသည်',
    'dateNotAnnounced': 'ရက်စွဲ မကြေညာရသေးပါ',
    // ---- Confidence ----
    'confVerified': 'အတည်ပြုပြီး',
    'confEstimated': 'ခန့်မှန်း',
    'confUnverified': 'မသေချာသေး',
    'howSureLegend': 'ဘယ်လောက် သေချာသလဲ?',
    'confVerifiedHint': 'တရားဝင် ပြက္ခဒိန် သို့မဟုတ် ထုတ်ဝေပြီး သတင်းမှ ရယူထားသည်။',
    'confEstimatedHint':
        'ခရီးသွားလမ်းညွှန်စာအုပ် သို့မဟုတ် ခရီးသွားကုမ္ပဏီမှ ရယူထားသည်။ မှန်ဖွယ်ရှိသော်လည်း ဒေသခံကို ပြန်မေးသင့်သည်။',
    'confUnverifiedHint':
        'ဤအချက်အလက်ကို မသိရသေးပါ။ သိပါက ကျွန်ုပ်တို့ကို အသိပေးပါ။',
    // ---- Villages ----
    'villagesTitle': 'တောင်ပေါ်သား ရွာများ',
    'villagesIntro':
        'ကျိုင်းတုံပတ်လည် တောင်တန်းများတွင် တိုင်းရင်းသားလူမျိုးစု ၁၃ မျိုး နေထိုင်ကြသည်။ ရွာလည်ပတ်ခြင်းသည် ခရီးသွားအများစု လာရောက်ရခြင်း၏ အဓိက အကြောင်းရင်းဖြစ်သည် — ဒေသခံလမ်းပြနှင့် သွားပါ၊ ဖြည်းဖြည်းသွားပါ၊ ဓာတ်ပုံမရိုက်ခင် ခွင့်တောင်းပါ။',
    'villageNotFound': 'ရွာကို ရှာမတွေ့ပါ',
    'trekEasy': 'လွယ်ကူ',
    'trekModerate': 'အလယ်အလတ်',
    'trekHard': 'ခက်ခဲ',
    'byCar': 'ကားဖြင့်',
    'onFoot': 'ခြေလျင်',
    'difficulty': 'ခက်ခဲမှု',
    'altitude': 'အမြင့်',
    'beforeYouGo': 'မသွားခင် သိထားရန်',
    'needGuide': 'ဒေသခံလမ်းပြ လိုအပ်သည် — ဘာသာစကားအတွက်လည်း ဖြစ်သလို ယဉ်ကျေးမှုအရလည်း သင့်လျော်သည်။',
    'permitYes': 'ခွင့်ပြုမိန့် လိုအပ်သည်။ မထွက်ခွာမီ ကျိုင်းတုံတွင် ကြိုတင် စီစဉ်ပါ။',
    'permitNo': 'ခွင့်ပြုမိန့် မလိုပါ။',
    'permitAsk':
        'ခွင့်ပြုမိန့် စည်းမျဉ်းများ ပြောင်းလဲတတ်သည်။ မထွက်ခွာမီ တည်းခိုခန်း သို့မဟုတ် ခရီးသွားရုံးတွင် မေးမြန်းပါ။',
    'bestSeason': 'သွားရန် အသင့်တော်ဆုံး ရာသီ',
    'noGpsYet':
        'ဤရွာအတွက် GPS တည်နေရာ မရရှိသေးသဖြင့် အက်ပ်မှ လမ်းညွှန်ပေး၍ မရသေးပါ။ ပြထားသော လမ်းကြောင်းမှာ ခန့်မှန်းချက်သာ ဖြစ်သည်။',
    'respectTitle': 'ယဉ်ကျေးစွာ လည်ပတ်ခြင်း',
    'pleaseDo': 'လုပ်သင့်သည်',
    'pleaseDont': 'မလုပ်သင့်ပါ',
    'whereThisComesFrom': 'အချက်အလက် ရင်းမြစ်',
    'sourceUnknown': 'ရင်းမြစ် မှတ်တမ်း မတင်ရသေးပါ',
    'lastChecked': 'နောက်ဆုံး စစ်ဆေးချိန်',

  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'my'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
