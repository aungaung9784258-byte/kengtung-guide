import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum PlaceCategory {
  place('place', Icons.landscape_rounded, AppColors.cPlace),
  pagoda('pagoda', Icons.temple_buddhist_rounded, AppColors.cPagoda),
  market('market', Icons.storefront_rounded, AppColors.cMarket),
  transport('transport', Icons.directions_bus_rounded, AppColors.cTransport),
  hotel('hotel', Icons.hotel_rounded, AppColors.cHotel),
  restaurant('restaurant', Icons.restaurant_rounded, AppColors.cRestaurant),
  emergency('emergency', Icons.local_hospital_rounded, AppColors.cEmergency);

  final String id;
  final IconData icon;
  final Color color;

  const PlaceCategory(this.id, this.icon, this.color);

  /// i18n key, e.g. `cat_pagoda`
  String get labelKey => 'cat_$id';

  static PlaceCategory fromId(String id) => PlaceCategory.values.firstWhere(
        (c) => c.id == id,
        orElse: () => PlaceCategory.place,
      );
}
