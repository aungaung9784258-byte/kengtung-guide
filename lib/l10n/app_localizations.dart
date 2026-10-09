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
    'appName': 'KyaingTong Guide',
    'exploreIn': "Let's explore in",
    'cityName': 'Kyaing Tong',
    'search': 'Search places, hotels, food...',
    'popularPlaces': 'Popular Places',
    'categories': 'Categories',
    'all': 'All',
    'home': 'Home',
    'map': 'Map',
    'favourites': 'Favourites',
    'profile': 'Settings',
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
    'tagline': 'Traveling guide app for Kyaing Tong, Eastern Shan State, Myanmar',
    'cat_place': 'Places to Visit',
    'cat_pagoda': 'Pagodas',
    'cat_market': 'Markets',
    'cat_transport': 'Transportation',
    'cat_hotel': 'Hotels',
    'cat_restaurant': 'Restaurants',
    'cat_emergency': 'Emergency',
    'distanceKm': 'km',
    'locating': 'Getting your location...',
    'locationDenied': 'Location permission denied',
    'routeFailed': 'Could not calculate the route',
    'clearRoute': 'Clear route',
    'about': 'About',
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
    'profile': 'ဆက်တင်များ',
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
    'tagline': 'ရှမ်းရှေ့ပိုင်း ကျိုင်းတုံမြို့ လမ်းညွန် အက်ပ်',
    'cat_place': 'လည်ပတ်စရာနေရာများ',
    'cat_pagoda': 'ဘုရားများ',
    'cat_market': 'ဈေးများ',
    'cat_transport': 'သယ်ယူပို့ဆောင်ရေး',
    'cat_hotel': 'ဟိုတယ်များ',
    'cat_restaurant': 'စားသောက်ဆိုင်များ',
    'cat_emergency': 'အရေးပေါ်',
    'distanceKm': 'ကီလိုမီတာ',
    'locating': 'တည်နေရာ ရယူနေသည်...',
    'locationDenied': 'တည်နေရာ ခွင့်ပြုချက် ငြင်းပယ်ခံရသည်',
    'routeFailed': 'လမ်းကြောင်း တွက်ချက်၍မရပါ',
    'clearRoute': 'လမ်းကြောင်း ဖျက်ရန်',
    'about': 'အကြောင်း',
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
