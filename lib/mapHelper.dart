import 'package:google_maps_flutter/google_maps_flutter.dart';

void setMapTheme(GoogleMapController mapController, bool bool) {
  if(bool){
    mapController!.setMapStyle('''
                      [
                            {
                              "elementType": "geometry",
                              "stylers": [
                                {
                                  "color": "#1d2c4d"
                                }
                              ]
                            },
                            {
                              "elementType": "labels.text.fill",
                              "stylers": [
                                {
                                  "color": "#8ec3b9"
                                }
                              ]
                            },
                            {
                              "elementType": "labels.text.stroke",
                              "stylers": [
                                {
                                  "color": "#1a3646"
                                }
                              ]
                            },
                            {
                              "featureType": "administrative.country",
                              "elementType": "geometry.stroke",
                              "stylers": [
                                {
                                  "color": "#4b6878"
                                }
                              ]
                            },
                            {
                              "featureType": "administrative.land_parcel",
                              "elementType": "labels.text.fill",
                              "stylers": [
                                {
                                  "color": "#64779e"
                                }
                              ]
                            },
                            {
                              "featureType": "administrative.province",
                              "elementType": "geometry.stroke",
                              "stylers": [
                                {
                                  "color": "#4b6878"
                                }
                              ]
                            },
                            {
                              "featureType": "landscape.man_made",
                              "elementType": "geometry.stroke",
                              "stylers": [
                                {
                                  "color": "#334e87"
                                }
                              ]
                            },
                            {
                              "featureType": "landscape.natural",
                              "elementType": "geometry",
                              "stylers": [
                                {
                                  "color": "#023e58"
                                }
                              ]
                            },
                            {
                              "featureType": "poi",
                              "elementType": "geometry",
                              "stylers": [
                                {
                                  "color": "#283d6a"
                                }
                              ]
                            },
                            {
                              "featureType": "poi",
                              "elementType": "labels.text.fill",
                              "stylers": [
                                {
                                  "color": "#6f9ba5"
                                }
                              ]
                            },
                            {
                              "featureType": "poi",
                              "elementType": "labels.text.stroke",
                              "stylers": [
                                {
                                  "color": "#1d2c4d"
                                }
                              ]
                            },
                            {
                              "featureType": "poi.park",
                              "elementType": "geometry.fill",
                              "stylers": [
                                {
                                  "color": "#023e58"
                                }
                              ]
                            },
                            {
                              "featureType": "poi.park",
                              "elementType": "labels.text.fill",
                              "stylers": [
                                {
                                  "color": "#3C7680"
                                }
                              ]
                            },
                            {
                              "featureType": "road",
                              "elementType": "geometry",
                              "stylers": [
                                {
                                  "color": "#304a7d"
                                }
                              ]
                            },
                            {
                              "featureType": "road",
                              "elementType": "labels.text.fill",
                              "stylers": [
                                {
                                  "color": "#98a5be"
                                }
                              ]
                            },
                            {
                              "featureType": "road",
                              "elementType": "labels.text.stroke",
                              "stylers": [
                                {
                                  "color": "#1d2c4d"
                                }
                              ]
                            },
                            {
                              "featureType": "road.highway",
                              "elementType": "geometry",
                              "stylers": [
                                {
                                  "color": "#2c6675"
                                }
                              ]
                            },
                            {
                              "featureType": "road.highway",
                              "elementType": "geometry.stroke",
                              "stylers": [
                                {
                                  "color": "#255763"
                                }
                              ]
                            },
                            {
                              "featureType": "road.highway",
                              "elementType": "labels.text.fill",
                              "stylers": [
                                {
                                  "color": "#b0d5ce"
                                }
                              ]
                            },
                            {
                              "featureType": "road.highway",
                              "elementType": "labels.text.stroke",
                              "stylers": [
                                {
                                  "color": "#023e58"
                                }
                              ]
                            },
                            {
                              "featureType": "transit",
                              "elementType": "labels.text.fill",
                              "stylers": [
                                {
                                  "color": "#98a5be"
                                }
                              ]
                            },
                            {
                              "featureType": "transit",
                              "elementType": "labels.text.stroke",
                              "stylers": [
                                {
                                  "color": "#1d2c4d"
                                }
                              ]
                            },
                            {
                              "featureType": "transit.line",
                              "elementType": "geometry.fill",
                              "stylers": [
                                {
                                  "color": "#283d6a"
                                }
                              ]
                            },
                            {
                              "featureType": "transit.station",
                              "elementType": "geometry",
                              "stylers": [
                                {
                                  "color": "#3a4762"
                                }
                              ]
                            },
                            {
                              "featureType": "water",
                              "elementType": "geometry",
                              "stylers": [
                                {
                                  "color": "#0e1626"
                                }
                              ]
                            },
                            {
                              "featureType": "water",
                              "elementType": "labels.text.fill",
                              "stylers": [
                                {
                                  "color": "#4e6d70"
                                }
                              ]
                            }
                          ]
                      ''');
  }else{
    mapController!.setMapStyle('''[]''');
  }
}

class EntryMarker {
  final String entryId;
  final String latitude;
  final String longitude;
  final String time;
  final String date;
  final String content;
  final String authorUsername;
  final String authorUserId;
  double distanceToUser = 0.0; // Add this field

  EntryMarker({
    required this.entryId,
    required this.latitude,
    required this.longitude,
    required this.time,
    required this.date,
    required this.content,
    required this.authorUsername,
    required this.authorUserId,
  });

  factory EntryMarker.fromMap(Map<String, dynamic> map) {
    return EntryMarker(
      entryId: map['entry_id'],
      latitude: map['lat'],
      longitude: map['long'],
      time: map['time'],
      date: map['date'],
      content: map['content'],
      authorUsername: map['author_username'],
      authorUserId: map['author_user_id'],
    );
  }

  Marker toMarker() {
    return Marker(
      markerId: MarkerId(entryId.toString()),
      position: LatLng(double.parse(latitude), double.parse(longitude)),
      infoWindow: InfoWindow(
        title: 'Entry #$entryId',
        snippet: 'Author: $authorUsername\nContent: $content\nDistance to User: ${distanceToUser.toStringAsFixed(2)} meters',
      ),
    );
  }
}
