import "dart:io";
import 'package:xml/xml.dart';

class EnumValue {
  final int value;
  final String name;
  const EnumValue(this.value, this.name);
}

class Command {
  final String response;
  final String name;
  final Map<String, String> params;
  const Command(this.response, this.name, this.params);
}

parseEnums(XmlDocument document, List<EnumValue> list) {
  final enums = document.findAllElements('enums');

  enums.map((XmlElement node) => node).forEach((node) {
    // var comment = node.getAttribute("comment");

    node.children.forEach((child) {
      String value = child.getAttribute("value");
      if (value == null) return;
      list.add(EnumValue(int.parse(child.getAttribute("value")), child.getAttribute("name").replaceAll("GL_", "")));
    });
  });
}

parseCommands(XmlDocument document, List<Command> list) {
  final commands = document.findAllElements('command');

  commands.map((XmlElement node) => node).forEach((node) {
    var proto = node.getElement("proto");
    var fnName = node.getAttribute("name");
    if (proto != null) print(proto.text.split(" "));

    // print(fnName);
    // node.children.forEach((child) {
    //   String value = child.getAttribute("value");
    //   if (value == null) return;
    //   list.add(EnumValue(int.parse(child.getAttribute("value")), child.getAttribute("name").replaceAll("GL_", "")));
    // });
  });
}

void main() {
  List<EnumValue> enumList = [];
  List<Command> commandList = [];

  final file = new File('dependencies/gl/xml/gl.xml');
  final document = XmlDocument.parse(file.readAsStringSync());

  // parseEnums(document, enumList);
  parseCommands(document, commandList);

  // enumList.forEach((element) {
  //   print("const " + element.name + " = " + element.value.toString());
  // });
}
