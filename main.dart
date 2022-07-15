import "dart:io";
import 'package:xml/xml.dart';

class EnumValue {
  final int value;
  final String name;
  const EnumValue(this.value, this.name);
}

parseEnums(XmlDocument document, List<EnumValue> list) {
  final enums = document.findAllElements('enums');

  enums.map((XmlElement node) => node).forEach((node) {
    var comment = node.getAttribute("comment");

    node.children.forEach((child) {
      String value = child.getAttribute("value");
      if (value == null) return;
      list.add(EnumValue(int.parse(child.getAttribute("value")), child.getAttribute("name").replaceAll("GL_", "")));
    });
  });
}

void main() {
  List<EnumValue> enumList = [];

  final file = new File('dependencies/gl/xml/gl.xml');
  final document = XmlDocument.parse(file.readAsStringSync());

  parseEnums(document, enumList);

  enumList.forEach((element) {
    print("const " + element.name + " = " + element.value.toString());
  });
}
