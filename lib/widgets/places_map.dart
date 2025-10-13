import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

class PlacesMap extends StatefulWidget {
  final Position userPosition;
  final List<Place> places;

  const PlacesMap({
    super.key,
    required this.userPosition,
    required this.places,
  });

  @override
  State<PlacesMap> createState() => _PlacesMapState();
}

class _PlacesMapState extends State<PlacesMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void didUpdateWidget(PlacesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places) {
      _createMarkers();
    }
  }

  void _createMarkers() {
    final markers = <Marker>{};

    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
          widget.userPosition.latitude,
          widget.userPosition.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add place markers
    for (var i = 0; i < widget.places.length; i++) {
      final place = widget.places[i];
      if (place.latitude != null && place.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('place_$i'),
            position: LatLng(place.latitude!, place.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: place.name,
              snippet: place.distanceInKm,
            ),
          ),
        );
      }
    }

    setState(() => _markers = markers);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitAllMarkers();
  }

  void _fitAllMarkers() {
    if (_markers.isEmpty) return;

    double minLat = widget.userPosition.latitude;
    double maxLat = widget.userPosition.latitude;
    double minLng = widget.userPosition.longitude;
    double maxLng = widget.userPosition.longitude;

    for (var marker in _markers) {
      minLat = minLat < marker.position.latitude
          ? minLat
          : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude
          ? maxLat
          : marker.position.latitude;
      minLng = minLng < marker.position.longitude
          ? minLng
          : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude
          ? maxLng
          : marker.position.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 400,
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.userPosition.latitude,
              widget.userPosition.longitude,
            ),
            zoom: 14,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
