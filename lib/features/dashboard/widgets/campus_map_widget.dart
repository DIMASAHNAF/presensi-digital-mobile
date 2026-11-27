import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/session_model.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_theme.dart';

enum _MapLayerStyle { street, satellite }

/// Interactive real-tile campus geofence map (FlutterMap + CartoDB Voyager/Dark + Esri Satellite)
/// with offline campus backdrop, live student GPS marker & accuracy halo, exact polygon/radius zone,
/// and tap-to-expand fullscreen inspection modal.
class CampusMapWidget extends StatefulWidget {
  final GeofenceConfig? geofencing;
  final GeofenceResult? geofenceResult;
  final ValueListenable<GeofenceResult?>? geofenceListenable;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback? onBadgeTap;
  final VoidCallback? onOpenGoogleMaps;

  const CampusMapWidget({
    super.key,
    required this.geofencing,
    required this.geofenceResult,
    this.geofenceListenable,
    this.isRefreshingLocation = false,
    this.onRefreshLocation,
    this.onBadgeTap,
    this.onOpenGoogleMaps,
  });

  @override
  State<CampusMapWidget> createState() => _CampusMapWidgetState();
}

class _CampusMapWidgetState extends State<CampusMapWidget>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  _MapLayerStyle _layerStyle = _MapLayerStyle.street;
  bool _mapReady = false;
  LatLng? _lastFittedStudentPos;

  static const LatLng _fallbackSchoolCenter = LatLng(3.5864674, 98.8810585);
  static const String _userAgent = 'id.sch.smknegeri1beringin.presensi';

  bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CampusMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapReady) return;
    final pos = widget.geofenceResult?.position;
    final mocked = widget.geofenceResult?.isMocked ?? false;
    if (pos != null && !mocked) {
      final next = LatLng(pos.latitude, pos.longitude);
      final movedEnough = _lastFittedStudentPos == null ||
          LocationService.haversineDistance(
                _lastFittedStudentPos!.latitude,
                _lastFittedStudentPos!.longitude,
                next.latitude,
                next.longitude,
              ) >
              12.0;
      if (movedEnough) {
        _lastFittedStudentPos = next;
        _fitCompactCamera(studentPos: next);
      }
    }
  }

  LatLng _schoolCenter() {
    final cfg = widget.geofencing;
    if (cfg == null) return _fallbackSchoolCenter;
    if (cfg.mode == 'polygon' && cfg.polygonPoints.length >= 3) {
      double sumLat = 0;
      double sumLng = 0;
      for (final p in cfg.polygonPoints) {
        sumLat += p.lat;
        sumLng += p.lng;
      }
      return LatLng(
        sumLat / cfg.polygonPoints.length,
        sumLng / cfg.polygonPoints.length,
      );
    }
    return LatLng(cfg.latitude, cfg.longitude);
  }

  LatLng _schoolPinLocation() {
    final cfg = widget.geofencing;
    if (cfg == null) return _fallbackSchoolCenter;
    return LatLng(cfg.latitude, cfg.longitude);
  }

  List<LatLng> _polygonLatLngs() {
    final cfg = widget.geofencing;
    if (cfg == null || cfg.mode != 'polygon' || cfg.polygonPoints.length < 3) {
      return const [];
    }
    return cfg.polygonPoints.map((p) => LatLng(p.lat, p.lng)).toList();
  }

  void _fitCompactCamera({LatLng? studentPos}) {
    if (!_mapReady || !mounted) return;
    final center = _schoolCenter();
    final poly = _polygonLatLngs();
    final points = <LatLng>[
      if (poly.isNotEmpty) ...poly else center,
    ];

    if (studentPos != null) {
      final dist = LocationService.haversineDistance(
        studentPos.latitude,
        studentPos.longitude,
        center.latitude,
        center.longitude,
      );
      if (dist <= 650) {
        points.add(studentPos);
      }
    }

    try {
      if (points.length >= 2) {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(32, 46, 32, 42),
            maxZoom: 17.6,
            minZoom: 14.2,
          ),
        );
      } else {
        _mapController.move(center, 17.0);
      }
    } catch (_) {}
  }

  Color _zoneAccentColor(GeofenceResult? geo) {
    if (geo == null) return AppColors.primaryBlue;
    if (geo.isMocked) return AppColors.danger;
    if (geo.isInside) return AppColors.success;
    if (geo.issue == LocationIssue.outsideArea) return AppColors.warning;
    return AppColors.primaryBlue;
  }

  void _openFullscreenMap() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CampusMapFullscreenSheet(
        geofencing: widget.geofencing,
        initialResult: widget.geofenceResult,
        geofenceListenable: widget.geofenceListenable,
        initialStyle: _layerStyle,
        onStyleChanged: (style) {
          if (mounted) setState(() => _layerStyle = style);
        },
        onRefreshLocation: widget.onRefreshLocation,
        onOpenGoogleMaps: widget.onOpenGoogleMaps,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final geoCfg = widget.geofencing;
    final geo = widget.geofenceResult;
    final pos = (geo != null && !geo.isMocked) ? geo.position : null;
    final isPolygon =
        geoCfg != null && geoCfg.mode == 'polygon' && geoCfg.polygonPoints.length >= 3;
    final radiusM = geoCfg?.radiusMeters.toInt() ?? 120;
    final zoneColor = _zoneAccentColor(geo);
    final schoolCenter = _schoolCenter();
    final schoolPin = _schoolPinLocation();
    final polygonPts = _polygonLatLngs();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 196,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Instant offline/loading campus backdrop so container is never blank grey
            Image.asset(
              'assets/images/map_campus_v2.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/map_campus.png',
                fit: BoxFit.cover,
              ),
            ),
            if (AppColors.isDark && _layerStyle == _MapLayerStyle.street)
              Container(color: Colors.black.withOpacity(0.45)),

            // Real interactive FlutterMap layer (compact mode locks scroll gesture so
            // vertical scrolling on Beranda stays silky; tapping opens fullscreen map)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: schoolCenter,
                initialZoom: 17.0,
                minZoom: 13.0,
                maxZoom: 19.0,
                backgroundColor: Colors.transparent,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
                onTap: (_, __) => _openFullscreenMap(),
                onMapReady: () {
                  _mapReady = true;
                  final studentPos =
                      pos != null ? LatLng(pos.latitude, pos.longitude) : null;
                  _lastFittedStudentPos = studentPos;
                  _fitCompactCamera(studentPos: studentPos);
                },
              ),
              children: [
                if (!_isWidgetTest) _buildTileLayer(_layerStyle),

                // School Geofence Zone (Exact Polygon OR Metric Circle)
                if (isPolygon)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: polygonPts,
                        color: zoneColor.withOpacity(0.20),
                        borderColor: zoneColor,
                        borderStrokeWidth: 2.2,
                      ),
                    ],
                  )
                else
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: schoolPin,
                        radius: geoCfg?.radiusMeters ?? 120.0,
                        useRadiusInMeter: true,
                        color: zoneColor.withOpacity(0.18),
                        borderColor: zoneColor,
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),

                // Real GPS accuracy halo around student's live dot
                if (pos != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(pos.latitude, pos.longitude),
                        radius: pos.accuracy.clamp(4.0, 120.0),
                        useRadiusInMeter: true,
                        color: (geo!.isInside
                                ? AppColors.success
                                : AppColors.warning)
                            .withOpacity(0.16),
                        borderColor: (geo.isInside
                                ? AppColors.success
                                : AppColors.warning)
                            .withOpacity(0.45),
                        borderStrokeWidth: 1.2,
                      ),
                    ],
                  ),

                // School beacon + live student dot markers
                MarkerLayer(
                  markers: [
                    Marker(
                      point: schoolPin,
                      width: 64,
                      height: 64,
                      child: _SchoolBeaconMarker(
                        pulseController: _pulseController,
                        compact: true,
                      ),
                    ),
                    if (pos != null)
                      Marker(
                        point: LatLng(pos.latitude, pos.longitude),
                        width: 38,
                        height: 38,
                        child: _StudentLiveMarker(
                          pulseController: _pulseController,
                          isInside: geo!.isInside,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Subtle top & bottom gradient scrims for legible floating pills over satellite tiles
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.28, 0.72, 1.0],
                    colors: [
                      Colors.black.withOpacity(0.22),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.26),
                    ],
                  ),
                ),
              ),
            ),

            // Top-center live geofence/WiFi/GPS pill (tappable)
            Positioned(
              top: 10,
              left: 10,
              right: 78,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: widget.onBadgeTap,
                  behavior: HitTestBehavior.opaque,
                  child: _MapStatusPill(
                    geo: geo,
                    isRefreshing: widget.isRefreshingLocation,
                  ),
                ),
              ),
            ),

            // Top-right compact action buttons: Satellite toggle + Expand fullscreen
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapCircleButton(
                    tooltip: _layerStyle == _MapLayerStyle.satellite
                        ? 'Mode Peta'
                        : 'Mode Satelit',
                    icon: _layerStyle == _MapLayerStyle.satellite
                        ? CupertinoIcons.map_fill
                        : CupertinoIcons.layers_alt_fill,
                    iconColor: _layerStyle == _MapLayerStyle.satellite
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _layerStyle = _layerStyle == _MapLayerStyle.street
                            ? _MapLayerStyle.satellite
                            : _MapLayerStyle.street;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _MapCircleButton(
                    tooltip: 'Perbesar Peta',
                    icon: CupertinoIcons.arrow_up_left_arrow_down_right,
                    iconColor: AppColors.textSecondary,
                    onTap: _openFullscreenMap,
                  ),
                ],
              ),
            ),

            // Bottom-left school zone summary badge (zero OSM/© strings)
            Positioned(
              bottom: 10,
              left: 10,
              right: 54,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _openFullscreenMap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.66),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.shield_fill,
                          size: 11,
                          color: zoneColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isPolygon
                                ? 'SMKN 1 Beringin • Zona Area'
                                : 'SMKN 1 Beringin • ${radiusM}m',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (pos != null && pos.accuracy > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '±${pos.accuracy.round()}m',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.82),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom-right circular refresh/locate button
            if (widget.onRefreshLocation != null)
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: widget.onBadgeTap ?? widget.onRefreshLocation,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.96),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isRefreshingLocation
                          ? SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : Icon(
                              CupertinoIcons.location_fill,
                              size: 16,
                              color: AppColors.primaryBlue,
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static TileLayer _buildTileLayer(_MapLayerStyle style) {
    if (style == _MapLayerStyle.satellite) {
      return TileLayer(
        urlTemplate:
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: _userAgent,
        maxNativeZoom: 18,
        maxZoom: 19,
        keepBuffer: 2,
        errorTileCallback: (_, __, ___) {},
      );
    }
    final isDark = AppColors.isDark;
    return TileLayer(
      urlTemplate: isDark
          ? 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png'
          : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      retinaMode: true,
      userAgentPackageName: _userAgent,
      maxNativeZoom: 19,
      maxZoom: 19,
      keepBuffer: 2,
      errorTileCallback: (_, __, ___) {},
    );
  }
}

/// Full-screen interactive pan & zoom map sheet for detailed geofence inspection.
class _CampusMapFullscreenSheet extends StatefulWidget {
  final GeofenceConfig? geofencing;
  final GeofenceResult? initialResult;
  final ValueListenable<GeofenceResult?>? geofenceListenable;
  final _MapLayerStyle initialStyle;
  final ValueChanged<_MapLayerStyle> onStyleChanged;
  final VoidCallback? onRefreshLocation;
  final VoidCallback? onOpenGoogleMaps;

  const _CampusMapFullscreenSheet({
    required this.geofencing,
    required this.initialResult,
    required this.geofenceListenable,
    required this.initialStyle,
    required this.onStyleChanged,
    required this.onRefreshLocation,
    required this.onOpenGoogleMaps,
  });

  @override
  State<_CampusMapFullscreenSheet> createState() =>
      _CampusMapFullscreenSheetState();
}

class _CampusMapFullscreenSheetState extends State<_CampusMapFullscreenSheet>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  late _MapLayerStyle _style;
  bool _mapReady = false;
  bool _isRefreshing = false;

  static const LatLng _fallbackCenter = LatLng(3.5864674, 98.8810585);

  bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _style = widget.initialStyle;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng _schoolPin() {
    final cfg = widget.geofencing;
    if (cfg == null) return _fallbackCenter;
    return LatLng(cfg.latitude, cfg.longitude);
  }

  List<LatLng> _polygonPts() {
    final cfg = widget.geofencing;
    if (cfg == null || cfg.mode != 'polygon' || cfg.polygonPoints.length < 3) {
      return const [];
    }
    return cfg.polygonPoints.map((p) => LatLng(p.lat, p.lng)).toList();
  }

  void _focusSchool() {
    if (!_mapReady) return;
    final poly = _polygonPts();
    try {
      if (poly.length >= 3) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(poly),
            padding: const EdgeInsets.all(54),
            maxZoom: 18.0,
          ),
        );
      } else {
        _mapController.move(_schoolPin(), 17.2);
      }
    } catch (_) {}
  }

  void _focusStudent(GeofenceResult? geo) {
    if (!_mapReady) return;
    final pos = geo?.position;
    if (pos == null || (geo?.isMocked ?? false)) {
      _focusSchool();
      return;
    }
    try {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 18.0);
    } catch (_) {}
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    try {
      final cam = _mapController.camera;
      _mapController.move(cam.center, (cam.zoom + delta).clamp(13.0, 19.0));
    } catch (_) {}
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final listenable = widget.geofenceListenable;
    if (listenable != null) {
      return ValueListenableBuilder<GeofenceResult?>(
        valueListenable: listenable,
        builder: (context, liveGeo, _) => _buildSheetBody(context, liveGeo),
      );
    }
    return _buildSheetBody(context, widget.initialResult);
  }

  Widget _buildSheetBody(BuildContext context, GeofenceResult? geo) {
    final geoCfg = widget.geofencing;
    final pos = (geo != null && !geo.isMocked) ? geo.position : null;
    final polygonPts = _polygonPts();
    final isPolygon = polygonPts.length >= 3;
    final zoneColor = geo == null
        ? AppColors.primaryBlue
        : geo.isMocked
            ? AppColors.danger
            : geo.isInside
                ? AppColors.success
                : geo.issue == LocationIssue.outsideArea
                    ? AppColors.warning
                    : AppColors.primaryBlue;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Full interactive map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _schoolPin(),
              initialZoom: 17.2,
              minZoom: 13.0,
              maxZoom: 19.0,
              backgroundColor: AppColors.background,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                _mapReady = true;
                _focusSchool();
              },
            ),
            children: [
              if (!_isWidgetTest) _CampusMapWidgetState._buildTileLayer(_style),
              if (isPolygon)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: polygonPts,
                      color: zoneColor.withOpacity(0.20),
                      borderColor: zoneColor,
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                )
              else
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _schoolPin(),
                      radius: geoCfg?.radiusMeters ?? 120.0,
                      useRadiusInMeter: true,
                      color: zoneColor.withOpacity(0.18),
                      borderColor: zoneColor,
                      borderStrokeWidth: 2.2,
                    ),
                  ],
                ),
              if (pos != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(pos.latitude, pos.longitude),
                      radius: pos.accuracy.clamp(4.0, 150.0),
                      useRadiusInMeter: true,
                      color: (geo!.isInside
                              ? AppColors.success
                              : AppColors.warning)
                          .withOpacity(0.16),
                      borderColor: (geo.isInside
                              ? AppColors.success
                              : AppColors.warning)
                          .withOpacity(0.45),
                      borderStrokeWidth: 1.4,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _schoolPin(),
                    width: 72,
                    height: 72,
                    child: _SchoolBeaconMarker(
                      pulseController: _pulseController,
                      compact: false,
                    ),
                  ),
                  if (pos != null)
                    Marker(
                      point: LatLng(pos.latitude, pos.longitude),
                      width: 42,
                      height: 42,
                      child: _StudentLiveMarker(
                        pulseController: _pulseController,
                        isInside: geo!.isInside,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top header overlay (status pill + close)
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _MapStatusPill(geo: geo, isRefreshing: _isRefreshing),
                  ),
                ),
                const SizedBox(width: 8),
                _MapCircleButton(
                  size: 36,
                  tooltip: 'Tutup Peta',
                  icon: CupertinoIcons.xmark,
                  iconColor: AppColors.textMain,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Right-side floating map controls
          Positioned(
            top: 64,
            right: 14,
            child: Column(
              children: [
                _MapCircleButton(
                  size: 38,
                  tooltip: _style == _MapLayerStyle.satellite
                      ? 'Mode Peta'
                      : 'Mode Satelit',
                  icon: _style == _MapLayerStyle.satellite
                      ? CupertinoIcons.map_fill
                      : CupertinoIcons.layers_alt_fill,
                  iconColor: _style == _MapLayerStyle.satellite
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final next = _style == _MapLayerStyle.street
                        ? _MapLayerStyle.satellite
                        : _MapLayerStyle.street;
                    setState(() => _style = next);
                    widget.onStyleChanged(next);
                  },
                ),
                const SizedBox(height: 8),
                _MapCircleButton(
                  size: 38,
                  tooltip: 'Fokus Lokasi Saya',
                  icon: CupertinoIcons.location_fill,
                  iconColor: AppColors.primaryBlue,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _focusStudent(geo);
                  },
                ),
                const SizedBox(height: 8),
                _MapCircleButton(
                  size: 38,
                  tooltip: 'Fokus Area Sekolah',
                  icon: Icons.school_rounded,
                  iconColor: AppColors.primaryIndigo,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _focusSchool();
                  },
                ),
                const SizedBox(height: 12),
                _MapCircleButton(
                  size: 36,
                  tooltip: 'Perbesar',
                  icon: CupertinoIcons.plus,
                  iconColor: AppColors.textMain,
                  onTap: () => _zoomBy(1.0),
                ),
                const SizedBox(height: 6),
                _MapCircleButton(
                  size: 36,
                  tooltip: 'Perkecil',
                  icon: CupertinoIcons.minus,
                  iconColor: AppColors.textMain,
                  onTap: () => _zoomBy(-1.0),
                ),
              ],
            ),
          ),

          // Bottom telemetry & actions card
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.97),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              geoCfg?.schoolName ?? 'SMK Negeri 1 Beringin',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPolygon
                                  ? 'Mode Polygon (${polygonPts.length} titik batas resmi)'
                                  : 'Mode Radius (${geoCfg?.radiusMeters.toInt() ?? 120}m)',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pos != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: (pos.accuracy <= 30
                                    ? AppColors.success
                                    : pos.accuracy <= 80
                                        ? AppColors.primaryBlue
                                        : AppColors.warning)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'GPS ±${pos.accuracy.round()}m',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: pos.accuracy <= 30
                                  ? AppColors.success
                                  : pos.accuracy <= 80
                                      ? AppColors.primaryBlue
                                      : AppColors.warning,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TelemetryChip(
                          label: isPolygon && geo != null && !geo.isInside
                              ? 'Jarak ke Batas'
                              : 'Jarak ke Sekolah',
                          value: geo == null
                              ? 'Menghitung...'
                              : geo.verifiedByWifi
                                  ? 'WiFi Sekolah'
                                  : _formatDistance(geo.distanceMeters),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TelemetryChip(
                          label: 'Koordinat Anda',
                          value: pos != null
                              ? '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
                              : 'Belum terkunci',
                        ),
                      ),
                    ],
                  ),
                  if (geo?.errorMessage != null && !(geo?.isInside ?? true)) ...[
                    const SizedBox(height: 8),
                    Text(
                      geo!.errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: geo.isMocked
                            ? AppColors.danger
                            : AppColors.amberDeep,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (widget.onRefreshLocation != null)
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: _isRefreshing
                                  ? null
                                  : () async {
                                      setState(() => _isRefreshing = true);
                                      widget.onRefreshLocation!();
                                      await Future.delayed(
                                          const Duration(milliseconds: 1400));
                                      if (mounted) {
                                        setState(() => _isRefreshing = false);
                                      }
                                    },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isRefreshing)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      CupertinoIcons.refresh,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Perbarui GPS',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (widget.onRefreshLocation != null &&
                          widget.onOpenGoogleMaps != null)
                        const SizedBox(width: 8),
                      if (widget.onOpenGoogleMaps != null)
                        SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: widget.onOpenGoogleMaps,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textMain,
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            icon: const Icon(CupertinoIcons.map_pin_ellipse,
                                size: 15),
                            label: Text(
                              'Google Maps',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final double size;
  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _MapCircleButton({
    this.size = 30,
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: size * 0.48, color: iconColor),
        ),
      ),
    );
  }
}

class _SchoolBeaconMarker extends StatelessWidget {
  final AnimationController pulseController;
  final bool compact;

  const _SchoolBeaconMarker({
    required this.pulseController,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final double core = compact ? 28 : 34;
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, __) {
            final p = pulseController.value;
            final scale = 0.6 + (p * 1.15);
            final opacity = (1.0 - p).clamp(0.0, 1.0) * 0.30;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: core + 10,
                height: core + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withOpacity(opacity),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(opacity * 1.5),
                    width: 1.2,
                  ),
                ),
              ),
            );
          },
        ),
        Container(
          width: core,
          height: core,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.school_rounded,
            size: compact ? 13 : 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _StudentLiveMarker extends StatelessWidget {
  final AnimationController pulseController;
  final bool isInside;

  const _StudentLiveMarker({
    required this.pulseController,
    required this.isInside,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isInside ? AppColors.success : AppColors.warning;
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, __) {
            final p = pulseController.value;
            final scale = 0.7 + (p * 1.2);
            final opacity = (1.0 - p).clamp(0.0, 1.0) * 0.45;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor.withOpacity(opacity),
                ),
              ),
            );
          },
        ),
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  final GeofenceResult? geo;
  final bool isRefreshing;

  const _MapStatusPill({
    required this.geo,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    if (geo == null) {
      return _pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Mengunci Titik GPS...',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      );
    }

    if (geo!.isMocked) {
      return _pill(
        borderColor: AppColors.dangerBg,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.clear_circled_solid,
              size: 12,
              color: AppColors.danger,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Fake GPS Terdeteksi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (geo!.geofencingDisabled) {
      return _pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_alt_circle_fill,
              size: 12,
              color: AppColors.success,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Area Bebas • Geofencing Nonaktif',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (geo!.isInside) {
      final label = geo!.verifiedByWifi
          ? 'WiFi Sekolah • Valid'
          : 'Area Valid • ${geo!.distanceMeters.toStringAsFixed(0)}m';
      return _pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRefreshing)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.success,
                ),
              )
            else
              Icon(
                geo!.verifiedByWifi
                    ? CupertinoIcons.wifi
                    : CupertinoIcons.checkmark_alt_circle_fill,
                size: 12,
                color: AppColors.success,
              ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      );
    }

    String label = 'GPS Belum Akurat';
    Color pillColor = AppColors.textSecondary;
    IconData pillIcon = CupertinoIcons.location;

    if (geo!.issue == LocationIssue.serviceDisabled) {
      label = 'GPS Nonaktif • Aktifkan';
      pillColor = AppColors.warning;
      pillIcon = CupertinoIcons.location_slash_fill;
    } else if (geo!.issue == LocationIssue.permissionDenied) {
      label = 'Izinkan Akses Lokasi';
      pillColor = AppColors.primaryBlue;
      pillIcon = CupertinoIcons.lock_shield_fill;
    } else if (geo!.issue == LocationIssue.permissionDeniedForever) {
      label = 'Buka Pengaturan Lokasi';
      pillColor = AppColors.danger;
      pillIcon = CupertinoIcons.gear_alt_fill;
    } else if (geo!.issue == LocationIssue.outsideArea) {
      final distText = geo!.distanceMeters >= 1000
          ? '${(geo!.distanceMeters / 1000).toStringAsFixed(1)}km'
          : '${geo!.distanceMeters.toStringAsFixed(0)}m';
      label = 'Di Luar Area • $distText';
      pillColor = AppColors.warning;
      pillIcon = CupertinoIcons.location_solid;
    } else if (geo!.issue == LocationIssue.inaccurate &&
        geo!.position != null &&
        geo!.position!.accuracy > 0) {
      label = 'GPS Menstabilkan • ±${geo!.position!.accuracy.round()}m';
      pillColor = AppColors.primaryBlue;
      pillIcon = CupertinoIcons.antenna_radiowaves_left_right;
    }

    return _pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pillIcon, size: 12, color: pillColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: pillColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(100),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
