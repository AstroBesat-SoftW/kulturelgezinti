import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'yerler.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'dart:convert';

//import 'package:geocoding/geocoding.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LocationData? currentLocation;

  TextEditingController searchController = TextEditingController();
  final Set<Marker> markers = Set<Marker>();

  int _currentIndex = 0; // Varsayılan olarak ilk seçenek seçili

  final List<BottomNavigationBarItem> bottomNavigationBarItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Ana Sayfa',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Ara',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    // Konum servislerinin etkin olup olmadığını kontrol edin
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Konum izinlerini kontrol edin
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Konum verilerini alın
    _locationData = await location.getLocation();
    setState(() {
      currentLocation = _locationData;
    });
  }





  Future<Uint8List> getImageBytes(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final originalImage = img.decodeImage(response.bodyBytes);
      final screenWidth = 1920; // Ekran genişliği varsayılan olarak 1920 olarak kabul ediliyor.
      final screenHeight = 1080; // Ekran yüksekliği varsayılan olarak 1080 olarak kabul ediliyor.

      if (originalImage != null) {
        // Ekranın %8'ini kaplamak için yeni boyutları hesaplayın.
        final newWidth = (screenWidth * 0.10).toInt();
        final newHeight = (screenHeight * 0.10).toInt();

        // Görüntüyü yeniden boyutlandırın.
        final resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);

        // Yeniden boyutlandırılmış görüntüyü Uint8List'e dönüştürün.
        final resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));

        return resizedBytes;
      } else {
        throw Exception('Image decoding failed');
      }
    } else {
      throw Exception('Image download failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gez ve gör || Kültürel Şok'),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: bottomNavigationBarItems,
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return FutureBuilder<List<Marker>>(
          // Replace this with your actual asynchronous data loading function
          future: loadMarkers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Display a loading indicator while waiting for data
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // Handle error case
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              // Data is ready, build the GoogleMap widget
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        currentLocation?.latitude ?? 37.7749,
                        currentLocation?.longitude ?? -122.4194,
                      ),
                      zoom: 15.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    markers: {
                      if (currentLocation != null)
                        Marker(
                          markerId: MarkerId('current_location'),
                          position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          infoWindow: InfoWindow(title: 'Kendi Konumunuz'),
                        ),
                    }..addAll(Set<Marker>.from(snapshot.data!)),
                  ),

                  /* bu eksi olan  kendi konumuda gösterme eklecem o yüzden saklıyorum
                    GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        currentLocation?.latitude ?? 37.7749,
                        currentLocation?.longitude ?? -122.4194,
                      ),
                      zoom: 15.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    markers: Set<Marker>.from(snapshot.data!),
                  ), */
                  _buildSearchBar(), // Ekranın üst kısmına arama çubuğunu ekler
                ],
              );
            }
          },
        );
      case 1:
        return _buildSearchScreen();
      case 2:
        return Center(
          child: Text('Profil Ekranı'),
        );
      default:
        return Center(
          child: Text('Ana Sayfa Ekranı'),
        );
    }
  }
  Widget _buildSearchBar() {
    return Positioned(
      top: 16.0, // Arama çubuğunu haritanın üst kısmına yerleştirir
      left: 16.0,
      right: 16.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextField(
          onChanged: (query) async {
            // Kullanıcı her yazdığında burada arama sorgusunu işleyebilirsiniz
            // Örneğin, Places API'yi kullanarak yer araması yapabilirsiniz
            // ve bulunan yeri haritada işaretleyebilirsiniz.

          },
          decoration: InputDecoration(
            hintText: 'Ara...',
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }
  // bu üst arama yaptığında cıkıcak ekran
  //alt farklı orta ekran

  Widget _buildSearchScreen() {
    return FutureBuilder<List<Marker>>(
      // Replace this with your actual asynchronous data loading function
      future: loadMarkers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a loading indicator while waiting for data
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Handle error case
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          // Data is ready, build the GoogleMap widget
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                currentLocation?.latitude ?? 37.7749,
                currentLocation?.longitude ?? -122.4194,
              ),
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            markers: Set<Marker>.from(snapshot.data!),
          );
        }
      },
    );
  }

  Future<void> _searchCity(String cityName) async {
   // arama özelliği eklenirse
  }

  Future<List<Marker>> loadMarkers() async {
    // Replace this with your actual marker loading logic
    List<Marker> markers = [];

    for (var yer in yerlerListesi) {
      final imageBytes = await getImageBytes(yer.gorselUrl);
      markers.add(
        Marker(
          markerId: MarkerId(yer.baslik),
          position: LatLng(yer.latitude, yer.longitude),
          icon: BitmapDescriptor.fromBytes(imageBytes),
          infoWindow: InfoWindow(
            title: yer.baslik,
          ),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: Text(yer.baslik),
                      onTap: () {
                        // Burada ilgili konumun detay sayfasına yönlendirebilirsiniz
                        Navigator.pop(context);
                      },
                    ),
                    Image.network(
                      yer.gorselUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Text("\n" + yer.aciklama),
                    const Text(" \n\n\n"),
                  ],
                );
              },
            );
          },
        ),
      );
    }

    return markers;
  }
}



/* son yedek
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gezveogren/yakinbolge.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'yerler.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

void main() => runApp(MyApp(yerlerListesi: yerlerListesi));

class MyApp extends StatelessWidget {
  final List<Yer> yerlerListesi;



  MyApp({required this.yerlerListesi});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(yerlerListesi: yerlerListesi),
    );
  }
}

class MapScreen extends StatefulWidget {
  final List<Yer> yerlerListesi;


  MapScreen({required this.yerlerListesi});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LocationData? currentLocation;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    // Konum verilerini almak için kullanılan kod
    // (Daha önceki kodu kullanabilirsiniz)
  }

  // gorslı alma işlemleri urlden
  Future<Uint8List> getImageBytes(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final originalImage = img.decodeImage(response.bodyBytes);
      final screenWidth = 1920; // Ekran genişliği varsayılan olarak 1920 olarak kabul ediliyor.
      final screenHeight = 1080; // Ekran yüksekliği varsayılan olarak 1080 olarak kabul ediliyor.

      if (originalImage != null) {
        // Ekranın %8'ini kaplamak için yeni boyutları hesaplayın.
        final newWidth = (screenWidth * 0.10).toInt();
        final newHeight = (screenHeight * 0.10).toInt();

        // Görüntüyü yeniden boyutlandırın.
        final resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);

        // Yeniden boyutlandırılmış görüntüyü Uint8List'e dönüştürün.
        final resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));

        return resizedBytes;
      } else {
        throw Exception('Image decoding failed');
      }
    } else {
      throw Exception('Image download failed');
    }
  }
  // alt menü için
  final List<BottomNavigationBarItem> bottomNavigationBarItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Ana Sayfa',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Ara',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  int _currentIndex = 0; // Varsayılan olarak ilk seçenek seçili

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gez ve gör || Kültürel Şok'),
      ),
      body: FutureBuilder<List<Marker>>(
        // Replace this with your actual asynchronous data loading function
        future: loadMarkers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Display a loading indicator while waiting for data
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            // Handle error case
            return Text('Error: ${snapshot.error}');
          } else {
            // Data is ready, build the GoogleMap widget
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      currentLocation?.latitude ?? 37.7749,
                      currentLocation?.longitude ?? -122.4194,
                    ),
                    zoom: 15.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                  markers: Set<Marker>.from(snapshot.data as Iterable),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // İlgili alt menü seçeneğine göre işlemleri burada yapabilirsiniz
          if (_currentIndex == 0) {
            // İlk seçenek seçildiğinde yapılacak işlemler
          } else if (_currentIndex == 1) {
            // İkinci seçenek seçildiğinde yapılacak işlemler

          @override
          Widget build(BuildContext context) {
          return Scaffold(
          appBar: AppBar(
          title: Text('Yakın Bölgeler'),
          ),
          body: Center(
          child: Text('Hoşgeldin'),
          ),
          );
          }




          } else if (_currentIndex == 2) {
            // Üçüncü seçenek seçildiğinde yapılacak işlemler
          }
        },
        items: bottomNavigationBarItems,
      ),
    );
  }


  Future<List<Marker>> loadMarkers() async {
    // Replace this with your actual marker loading logic
    List<Marker> markers = [];

    for (var yer in widget.yerlerListesi) {
      final imageBytes = await getImageBytes(yer.gorselUrl);
      markers.add(
        Marker(
          markerId: MarkerId(yer.baslik),
          position: LatLng(yer.latitude, yer.longitude),
          icon: BitmapDescriptor.fromBytes(imageBytes),
          infoWindow: InfoWindow(
            title: yer.baslik,
          ),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: Text(yer.baslik),
                      onTap: () {
                        // Burada ilgili konumun detay sayfasına yönlendirebilirsiniz
                        Navigator.pop(context);
                      },
                    ),
                    Image.network(
                      yer.gorselUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Text("\n" + yer.aciklama),
                    const Text(" \n\n\n"),
                  ],
                );
              },
            );



          },
        ),
      );
    }

    return markers;
  }
}


*/
/*
bu güzel fakat konum üstüne tıklayınca sabit veriyor

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final String apiKey = 'AIzaSyAqoYtOZPlJ48ubFAMKi55DJNVexkc3b3U'; // Google Maps API anahtarınızı buraya ekleyin
  LocationData? currentLocation;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  // Konum verilerini almak için kullanılan fonksiyon
  Future<void> _getLocation() async {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    // Konum servislerinin etkin olup olmadığını kontrol edin
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Konum izinlerini kontrol edin
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Konum verilerini alın
    _locationData = await location.getLocation();
    setState(() {
      currentLocation = _locationData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gez ve gör || Kültürel Şok'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            currentLocation?.latitude ?? 37.7749,
            currentLocation?.longitude ?? -122.4194,
          ),
          zoom: 15.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: {
          Marker(
            markerId: MarkerId('marker_1'),
            position: LatLng(
              currentLocation?.latitude ?? 37.7749,
              currentLocation?.longitude ?? -122.4194,
            ),
            infoWindow: InfoWindow(title: 'Konumunuz'),
            onTap: () {
              // Burada konuma tıklandığında yapılacak işlemleri ekleyebilirsiniz.
              // Örneğin, konumun bilgilerini gösteren bir ekranı açabilirsiniz.
              _showLocationInfo(context, "Çanakkale Kalesi", "Çanakkale Kalesi açıklaması",
                  "https://www.kulturportali.gov.tr/repoKulturPortali/large/SehirRehberi//GezilecekYer/20180319134434287_KILITBAHIR.jpg?format=jpg&quality=50");
            },
          ),
        },
      ),
    );
  }
}


  void _showLocationInfo(BuildContext context, String locationName, String description, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(locationName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(description),
              SizedBox(height: 10),
              Image.network(imageUrl), // Resmi görüntülemek için
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'yu kapat
              },
              child: Text('Kapat'),
            ),
          ],
        );
      },
    );
  }



*/





/*  ilk yaptığım harita ksımı

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final String apiKey = 'AIzaSyAqoYtOZPlJ48ubFAMKi55DJNVexkc3b3U'; // API anahtarınızı buraya ekleyin
    // AIzaSyAqoYtOZPlJ48ubFAMKi55DJNVexkc3b3U
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gez ve gör || Kültürel Şok'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(37.7749, -122.4194), // Başlangıç konumu
          zoom: 15.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: {
          Marker(
            markerId: MarkerId('marker_1'),
            position: LatLng(37.7749, -122.4194), // İstediğiniz koordinat
            infoWindow: InfoWindow(title: 'Konumunuz'),
          ),
        },
      ),
    );
  }
}

*/