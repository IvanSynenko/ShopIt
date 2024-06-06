// screens/delivery_address_picker_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/geolocation.dart';
import '../utils/db_utils.dart';

class DeliveryAddressPickerScreen extends StatefulWidget {
  final String deliveryMethod;

  DeliveryAddressPickerScreen({required this.deliveryMethod});

  @override
  _DeliveryAddressPickerScreenState createState() =>
      _DeliveryAddressPickerScreenState();
}

class _DeliveryAddressPickerScreenState
    extends State<DeliveryAddressPickerScreen> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  LatLng? selectedLocation;
  LatLng? _initialPosition;
  final TextEditingController apartmentController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setInitialPosition();
  }

  Future<void> _setInitialPosition() async {
    try {
      Position position = await GeolocationService().getCurrentLocation();
      LatLng userLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _initialPosition = userLatLng;
      });

      if (widget.deliveryMethod == 'Pick up at a delivery point') {
        _generateDeliveryPointMarkers(position);
      } else if (widget.deliveryMethod == 'Pick up at a store') {
        _initializeStoreMarkers(userLatLng);
      }
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  Future<void> _initializeStoreMarkers(LatLng userLatLng) async {
    final conn = await DatabaseUtils.connect();
    var results = await conn
        .execute('SELECT "shopId", ST_AsText("location") FROM public."Shop"');
    await conn.close();

    setState(() {
      markers = results.where((row) {
        var point = _parseGeometry(row[1].toString());
        var latitude = point[0];
        var longitude = point[1];
        double distance = _calculateDistance(
            userLatLng.latitude, userLatLng.longitude, latitude, longitude);
        return distance <= 100; // Only show stores within 100 km
      }).map((row) {
        var point = _parseGeometry(row[1].toString());
        var latitude = point[0];
        var longitude = point[1];

        return Marker(
          markerId: MarkerId(row[0].toString()),
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(title: 'Store ${row[0]}'),
          onTap: () => _onMarkerTapped(LatLng(latitude, longitude)),
        );
      }).toSet();
    });
  }

  Future<void> _checkNearestStoreDistance(LatLng selectedLatLng) async {
    final conn = await DatabaseUtils.connect();
    var results = await conn
        .execute('SELECT "shopId", ST_AsText("location") FROM public."Shop"');
    await conn.close();

    double minDistance = double.infinity;

    for (var row in results) {
      var point = _parseGeometry(row[1].toString());
      var latitude = point[0];
      var longitude = point[1];
      double distance = _calculateDistance(selectedLatLng.latitude,
          selectedLatLng.longitude, latitude, longitude);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    if (minDistance > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Home delivery is not possible as the nearest store is more than 20 km away from the selected location.')),
      );  
    } else {
      Navigator.pop(context, {
        'location': selectedLatLng,
        'apartment': apartmentController.text,
      });
    }
  }

  List<double> _parseGeometry(String geometry) {
    // Parse the POINT geometry from PostGIS
    // Example input: "POINT(-122.4194 37.7749)"
    geometry = geometry.replaceAll('POINT(', '').replaceAll(')', '');
    List<String> coordinates = geometry.split(' ');
    return [double.parse(coordinates[0]), double.parse(coordinates[1])];
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Pi / 180
    const c = cos;
    final a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin(sqrt(a)) with R = 6371 km
  }

  void _generateDeliveryPointMarkers(Position userPosition) {
    final random = Random();
    final radiusInDegrees = 20 / 111.32; // Convert km to degrees

    setState(() {
      markers = List.generate(10, (index) {
        final u = random.nextDouble();
        final v = random.nextDouble();
        final w = radiusInDegrees * sqrt(u);
        final t = 2 * pi * v;
        final x = w * cos(t);
        final y = w * sin(t);

        final newLat = userPosition.latitude + x;
        final newLng = userPosition.longitude + y;

        return Marker(
          markerId: MarkerId('point$index'),
          position: LatLng(newLat, newLng),
          infoWindow: InfoWindow(title: 'Delivery Point $index'),
          onTap: () => _onMarkerTapped(LatLng(newLat, newLng)),
        );
      }).toSet();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_initialPosition != null) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _initialPosition!,
            zoom: 12,
          ),
        ),
      );
    }
  }

  void _onMarkerTapped(LatLng location) {
    setState(() {
      selectedLocation = location;
    });
  }

  void _confirmLocation() async {
    if (widget.deliveryMethod == 'Home delivery' && selectedLocation != null) {
      String? apartment = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter Apartment Number'),
            content: TextField(
              controller: apartmentController,
              decoration:
                  InputDecoration(hintText: 'Apartment Number (Optional)'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, null);
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, apartmentController.text);
                },
                child: Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (apartment != null) {
        await _checkNearestStoreDistance(selectedLocation!);
      }
    } else if (selectedLocation != null) {
      Navigator.pop(context, {'location': selectedLocation});
    }
  }

  void _searchLocation() async {
    String query = searchController.text;
    if (query.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          Location location = locations.first;
          LatLng latLng = LatLng(location.latitude, location.longitude);
          mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
          setState(() {
            selectedLocation = latLng;
            markers.clear();
            markers.add(Marker(
              markerId: MarkerId('searchLocation'),
              position: latLng,
              infoWindow: InfoWindow(title: 'Search Location'),
            ));
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _centerMap() {
    if (_initialPosition != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLng(_initialPosition!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Delivery Address'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          if (widget.deliveryMethod == 'Home delivery')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _searchLocation,
                  ),
                ],
              ),
            ),
          Expanded(
            child: _initialPosition == null
                ? Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: _initialPosition!,
                          zoom: 12,
                        ),
                        markers: markers,
                        onTap: (latLng) {
                          if (widget.deliveryMethod == 'Home delivery') {
                            setState(() {
                              selectedLocation = latLng;
                              markers.clear();
                              markers.add(Marker(
                                markerId: MarkerId('homeDelivery'),
                                position: latLng,
                                infoWindow:
                                    InfoWindow(title: 'Selected Location'),
                              ));
                            });
                          }
                        },
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.pink[800],
                          onPressed: _centerMap,
                          child: Icon(Icons.my_location, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
          ),
          if (selectedLocation != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[800]),
                onPressed: _confirmLocation,
                child: Text('Confirm Location',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
