// This is the Master KML Generator library.

class KmlGenerator {
  // 1st Function: To send the logo on the screen
  static String logoScreenOverlay(String imageUrl, double factor) {
    return '''
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
        <Document>
          <name>LG LOGO</name>
          <ScreenOverlay>
            <name>LG LOGO</name>
            <Icon>
              <href>https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEgXmdNgBTXup6bdWew5RzgCmC9pPb7rK487CpiscWB2S8OlhwFHmeeACHIIjx4B5-Iv-t95mNUx0JhB_oATG3-Tq1gs8Uj0-Xb9Njye6rHtKKsnJQJlzZqJxMDnj_2TXX3eA5x6VSgc8aw/s320-rw/LOGO+LIQUID+GALAXY-sq1000-+OKnoline.png</href>
            </Icon>
            <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
            <screenXY x="0.05" y="0.95" xunits="fraction" yunits="fraction"/>
            <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
            <size x="0.2" y="0.2" xunits="fraction" yunits="fraction"/>
          </ScreenOverlay>
        </Document>
      </kml>
          ''';
  }

  // 2nd Function: To send the Pyramid on the rig
  static String pyramidGenaration(double lat, double lng, double size) {
    double halfSize = size / 2;
    return '''
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Style id="pyramidStyle">
            <lineStyle>
              <color>7fff0000</color>
              <fill>1</fill>
              <outline>1</outline>
            </lineStyle>
          </Style>

          <Placemark>
            <name>Pyramid</name>
            <styleUrl>#pyramidStyle</styleUrl>
            <Polygon>
              <extrude>1</extrude>
              <altitudeMode>relativeToGround</altitudeMode>
              <outerBoundaryIs>
                <LinearRing>
                  <coordinates>
                    ${lng - halfSize},${lat - halfSize},0
                    ${lng + halfSize},${lat - halfSize},0
                    ${lng + halfSize},${lat + halfSize},0
                    ${lng - halfSize},${lat + halfSize},0
                    ${lng - halfSize},${lat - halfSize},0
                  </coordinates>
                </LinearRing>
              </outerBoundaryIs>
            </Polygon>
          </Placemark>
        </Document>
      </kml>
          ''';
  }

  // 3rd Function: To have send a Blank Kml to reset the rig
  static String blankKml(String id) {
    return '''
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document id="$id">
          <name>Blank KML</name>
        </Document>
      </kml>
          ''';
  }
}
