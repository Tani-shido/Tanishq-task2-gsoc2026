class KmlGenerator {
  // This function returns a BIG string of XML
  static String createPin(String name, double lat, double lng) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>$name</name> <Point>
        <coordinates>$lng,$lat,0</coordinates> </Point>
    </Placemark>
  </Document>
</kml>
    ''';
  }
}
