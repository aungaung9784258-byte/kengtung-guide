import 'package:flutter/material.dart';

/// The three map looks the user can switch between.
///
/// All three are FREE — no API key, no billing account.
/// Google's satellite tiles are deliberately NOT used: scraping them breaks
/// their Terms of Service and the official route requires a billing account.
/// Esri World Imagery is the standard free alternative and covers Kengtung.
enum BasemapStyle {
  street(
    id: 'street',
    labelKey: 'mapStreet',
    icon: Icons.map_rounded,
  ),
  satellite(
    id: 'satellite',
    labelKey: 'mapSatellite',
    icon: Icons.satellite_alt_rounded,
  ),
  hybrid(
    id: 'hybrid',
    labelKey: 'mapHybrid',
    icon: Icons.layers_rounded,
  );

  const BasemapStyle({
    required this.id,
    required this.labelKey,
    required this.icon,
  });

  final String id;
  final String labelKey;
  final IconData icon;

  bool get isSatellite => this != BasemapStyle.street;

  /// Main tile layer URL.
  String get urlTemplate => switch (this) {
        BasemapStyle.street =>
          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        // NOTE: Esri uses {z}/{y}/{x} order, not {z}/{x}/{y}.
        BasemapStyle.satellite || BasemapStyle.hybrid =>
          'https://server.arcgisonline.com/ArcGIS/rest/services/'
              'World_Imagery/MapServer/tile/{z}/{y}/{x}',
      };

  /// Transparent road + place-name layer drawn on top (hybrid only).
  String? get overlayUrlTemplate => this == BasemapStyle.hybrid
      ? 'https://basemaps.cartocdn.com/rastertiles/voyager_only_labels/'
          '{z}/{x}/{y}{r}.png'
      : null;

  /// Highest zoom the source actually has imagery for.
  int get maxNativeZoom => switch (this) {
        BasemapStyle.street => 19,
        // Esri imagery thins out over rural Shan State past ~18.
        BasemapStyle.satellite || BasemapStyle.hybrid => 18,
      };

  String get attribution => switch (this) {
        BasemapStyle.street => 'OpenStreetMap contributors',
        BasemapStyle.satellite => 'Esri, Maxar, Earthstar Geographics',
        BasemapStyle.hybrid => 'Esri, Maxar · CARTO · OpenStreetMap',
      };

  BasemapStyle get next =>
      BasemapStyle.values[(index + 1) % BasemapStyle.values.length];
}
