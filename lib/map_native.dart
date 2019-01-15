library map_native;

import 'package:flutter/material.dart';
import 'dart:math';

class TileIndex {
  double x;
  double y;

  TileIndex(this.x, this.y);
}

class LatLong {
  final double lat;
  final double long;

  const LatLong(this.lat, this.long);
}

abstract class Projection {
  TileIndex fromLngLatToTileIndex(LatLong location);
  LatLong fromTileIndexToLngLat(TileIndex tile);

  TileIndex fromLngLatToTileIndexWithZoom(LatLong location, double zoom) {
    var ret = fromLngLatToTileIndex(location);

    var mapSize = pow(2.0, zoom);

    return new TileIndex(ret.x * mapSize, ret.y * mapSize);
  }

  LatLong fromTileIndexToLngLatWithZoom(TileIndex tile, double zoom) {
    var mapSize = pow(2, zoom);

    final x = tile.x / mapSize;
    final y = tile.y / mapSize;

    final normalTile = new TileIndex(x, y);

    return fromTileIndexToLngLat(normalTile);
  }
}

class EPSG4326 extends Projection {
  static final EPSG4326 instance = new EPSG4326();

  @override
  TileIndex fromLngLatToTileIndex(LatLong location) {
    final lng = location.long;
    final lat = location.lat;

    double x = (lng + 180.0) / 360.0;
    double sinLatitude = sin(lat * pi / 180.0);
    double y =
        0.5 - log((1.0 + sinLatitude) / (1.0 - sinLatitude)) / (4.0 * pi);

    return new TileIndex(x, y);
  }

  @override
  LatLong fromTileIndexToLngLat(TileIndex tile) {
    final x = tile.x;
    final y = tile.y;

    final xx = x - 0.5;
    final yy = 0.5 - y;

    final lat = 90.0 - 360.0 * atan(exp(-yy * 2.0 * pi)) / pi;
    final lng = 360.0 * xx;

    return LatLong(lat, lng);
  }
}

abstract class MapProvider {
  const MapProvider();

  String getTile(int x, int y, int z);
}

class OsmProvider extends MapProvider {
  const OsmProvider();

  @override
  String getTile(int x, int y, int z) {
    return 'http://a.tile.osm.org/$z/$x/$y.png';
  }
}

class GoogleProvider extends MapProvider {
  const GoogleProvider();

  @override
  String getTile(int x, int y, int z) {
    return 'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425';
  }
}

class MapView extends StatefulWidget {
  final LatLong initialLocation;
  final double inititialZoom;
  final List<Marker> markers;
  final void Function() onTap;
  final void Function(TapDownDetails) onTapDown;
  final void Function(TapUpDetails) onTapUp;
  final void Function() onLongPress;
  final void Function() onLongPressUp;

  MapView({
    Key key,
    this.initialLocation: const LatLong(35.73, 51.40),
    this.inititialZoom: 14.0,
    this.markers: const <Marker>[],
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onLongPress,
    this.onLongPressUp
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => new MapViewState();
}

class MapViewState extends State<MapView> {
  static const double _TILE_SIZE = 256.0;
  LatLong _location = new LatLong(35.71, 51.41);
  double _zoom = 14.0;
  List<Marker> _markers = new List();
  void Function() _onTap;
  void Function(TapDownDetails) _onTapDown;
  void Function(TapUpDetails) _onTapUp;
  void Function() _onLongPress;
  void Function() _onLongPressUp;
  MapProvider provider = new GoogleProvider();

  @override
  void initState() {
    _location = widget.initialLocation;
    _zoom = widget.inititialZoom;
    _markers = widget.markers;
    _onTap = widget.onTap;
    _onTapDown = widget.onTapDown;
    _onLongPress = widget.onLongPress;
    _onLongPressUp = widget.onLongPressUp;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(builder: _build);
  }

  Widget _build(BuildContext context, BoxConstraints constraints) {
    final size = constraints.biggest;

    final screenWidth = size.width;
    final screenHeight = size.height;

    final centerX = screenWidth / 2.0;
    final centerY = screenHeight / 2.0;

    final scale = pow(2.0, _zoom);

    final norm = EPSG4326.instance.fromLngLatToTileIndex(_location);
    final ttl =
        new TileIndex(norm.x * _TILE_SIZE * scale, norm.y * _TILE_SIZE * scale);

    final fixedZoom = (_zoom + 0.0000001).toInt();
    final fixedPowZoom = pow(2, fixedZoom);

    final centerTileIndexX = (norm.x * fixedPowZoom).floor();
    final centerTileIndexY = (norm.y * fixedPowZoom).floor();

    final scaleValue = pow(2.0, (_zoom % 1));
    final tileSize = _TILE_SIZE * scaleValue;
    final numGrids = pow(2.0, _zoom).floor();

    final numTilesX = (screenWidth / _TILE_SIZE / 2.0).ceil();
    final numTilesY = (screenHeight / _TILE_SIZE / 2.0).ceil();

    final children = <Widget>[];

    for (int i = centerTileIndexX - numTilesX;
        i <= centerTileIndexX + numTilesX;
        i++) {
      for (int j = centerTileIndexY - numTilesY;
          j <= centerTileIndexY + numTilesY;
          j++) {
        if (i < 0 || i >= numGrids || j < 0 || j >= numGrids) {
          continue;
        }

        final ox = (i * tileSize) + centerX - ttl.x;
        final oy = (j * tileSize) + centerY - ttl.y;

        final link = provider.getTile(i, j, (_zoom + 0.0000001).floor());

        final child = new Positioned(
            width: tileSize,
            height: tileSize,
            left: ox,
            top: oy,
            child: new Container(
                color: Colors.grey,
                child: new Image.network(link, fit: BoxFit.fill)));

        children.add(child);

        //Render(img, ox - 1, oy - 1, tileSize + 1, tileSize + 1);

      }
    }

    for(Marker marker in _markers) {
      double iconSize = 24.0;
      if (marker.icon.size != null) {
        iconSize = marker.icon.size;
      }
      final tileIndex = EPSG4326.instance.fromLngLatToTileIndex(marker.position);
      final mX = tileIndex.x * fixedPowZoom;
      final mY = tileIndex.y * fixedPowZoom;
      final ox = (mX * tileSize) + centerX - ttl.x - (iconSize / 2);
      final oy = (mY * tileSize) + centerY - ttl.y - iconSize;

      final child = new Positioned(
          left: ox,
          top: oy,
          child: Container(
            child: marker.icon));

      children.add(child);
    }

    final stack = new Stack(children: children);

    final gesture = new GestureDetector(
      child: stack,
      onDoubleTap: _onDoubleTap,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onTap: _onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onLongPress: _onLongPress,
      onLongPressUp: _onLongPressUp
    );
    return gesture;
  }

  void _onDoubleTap() {
    setState(() {
      _zoom += 0.5;
    });
  }

  Offset dragStart;
  double scaleStart = 1.0;
  void _onScaleStart(ScaleStartDetails details) {
    dragStart = details.focalPoint;
    scaleStart = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final scaleDiff = details.scale - scaleStart;
    scaleStart = details.scale;

    if (scaleDiff > 0) {
      setState(() {
        _zoom += 0.02;
      });
    } else if (scaleDiff < 0) {
      setState(() {
        _zoom -= 0.02;
      });
    } else {
      final now = details.focalPoint;
      final diff = now - dragStart;
      dragStart = now;
      drag(diff.dx, diff.dy);
    }
  }

  void drag(double dx, double dy) {
    var tileSize = _TILE_SIZE;

    var scale = pow(2.0, _zoom);
    final mon = EPSG4326.instance.fromLngLatToTileIndex(_location);

    mon.x -= (dx / tileSize) / scale;
    mon.y -= (dy / tileSize) / scale;

    setState(() {
      _location = EPSG4326.instance.fromTileIndexToLngLat(mon);
    });
  }

  LatLong get location {
    return _location;
  }

  set location(LatLong location) {
    setState(() {
      _location = location;
    });
  }

  double get zoom {
    return _zoom;
  }

  set zoom(double zoom) {
    setState(() {
      _zoom = zoom;
    });
  }
}

class Marker extends StatelessWidget {
  final LatLong position;
  final Icon icon;
  
  Marker(
    {Key key,
    @required this.position,
    this.icon: const Icon(Icons.place)
  })
  : super(key: key);

  Widget build(BuildContext context) {
    return icon;
  }
}
