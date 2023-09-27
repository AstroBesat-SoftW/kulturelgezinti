class Yer {
  final String baslik;
  final String aciklama;
  final double latitude;
  final double longitude;
  final String gorselUrl;

  Yer({
    required this.baslik,
    required this.aciklama,
    required this.latitude,
    required this.longitude,
    required this.gorselUrl,
  });
}

// Örnek yerlerin listesi
List<Yer> yerlerListesi = [
  Yer(
    baslik: 'Çanakkale Kale',
    aciklama: 'Çanakkale Kalesi açıklaması buraya yazılabilir.',
    latitude: 40.1548,
    longitude: 26.4143,
    gorselUrl: 'https://www.kulturportali.gov.tr/repoKulturPortali/large/SehirRehberi//GezilecekYer/20180319134434287_KILITBAHIR.jpg?format=jpg&quality=50',
  ),
  Yer(
    baslik: 'Çanakkale Saat Kulesi',
    aciklama: 'Çanakkale Saat Kulesi açıklaması buraya yazılabilir.',
    latitude: 40.1550,
    longitude: 26.4130,
    gorselUrl: 'https://www.gezilesiyer.com/wp-content/uploads/2015/03/canakkale-saat-kulesi-gezilesiyer.jpg',
  ),
  // Diğer yerleri buraya ekleyebilirsiniz
];
