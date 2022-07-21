import "dart:io";
import 'package:xml/xml.dart';

class EnumValue {
  final String value;
  final String name;
  const EnumValue(this.value, this.name);
}

class Param {
  String name;
  String type;
  Param(this.type, this.name);

  String toString() {
    return toC3_Type(type) + " " + name;
  }
}

class Command {
  final String returnType;
  final String name;
  final List<Param> params;
  const Command(this.returnType, this.name, this.params);
}

enum C_types {
  GLsizei,
  GLuint,
  GLfloat,
  GLclampf,
  GLenum,
  GLuint64EXT,
  GLubyte,
  GLdouble,
  GLchar,
  GLshort,
  GLboolean,
  GLint,
  GLuint64,
  GLfixed,
  GLsizeiptr,
  GLbyte,
}

extension C3Type on C_types {
  String get name {
    switch (this) {
      case C_types.GLsizei:
        return 'isize';
      case C_types.GLuint:
        return 'uint';
      case C_types.GLfloat:
        return 'float';
      case C_types.GLclampf:
        return 'float';
      case C_types.GLenum:
        return 'int';
      case C_types.GLuint64EXT:
        return 'int';
      case C_types.GLubyte:
        return 'uint';
      case C_types.GLdouble:
        return 'double';
      case C_types.GLchar:
        return 'char';
      case C_types.GLshort:
        return 'uint';
      case C_types.GLboolean:
        return 'bool';
      default:
        return null;
    }
  }
}

String toC3_Type(String value) {
  switch (value) {
    case "GLsizei":
      return 'isize';
    case "GLuint":
      return 'uint';
    case "GLfloat":
      return 'float';
    case "GLclampf":
      return 'float';
    case "GLenum":
      return 'int';
    case "GLuint64EXT":
      return 'int';
    case "GLubyte":
      return 'uint';
    case "GLdouble":
      return 'double';
    case "GLchar":
      return 'char';
    case "GLshort":
      return 'short';
    case "GLboolean":
      return 'bool';
    case "GLint":
      return "int";
    case "GLuint64":
      return "ulong";
    case "GLfixed":
      return "int";
    case "GLsizeiptr":
      return "int";
    case "GLbyte":
      return "ushort";
    case "const":
      return "char";
    default:
      // print(value);
      return value;
  }
}

List<EnumValue> parseEnums(XmlDocument document) {
  return document
      .findAllElements('enum')
      .map((XmlElement node) {
        // var comment = node.getAttribute("comment");
        String value = node.getAttribute("value");
        if (value == null) return null;
        return EnumValue(node.getAttribute("value"), node.getAttribute("name"));
      })
      .where((element) => element != null)
      .toList();
}

List<Command> parseCommands(XmlDocument document) {
  return document
      .findAllElements('command')
      .map((XmlElement node) {
        var proto = node.getElement("proto");
        if (proto != null) {
          List<Param> params = node.findAllElements("param").map((XmlElement value) {
            var text = value.text.split(" ");
            var type = value.getElement("ptype");
            if (type == null)
              return Param(text[0], text[text.length - 1]);
            else
              return Param(type.text, text[text.length - 1]);
          }).toList();

          var fnName = proto.text.split(" ");
          return Command(fnName[0], fnName[1], params);
        }
      })
      .where((element) => element != null)
      .toList();
}

void write_C3file(List<Command> commands, List<EnumValue> enums) async {
  var file = File('./build/opengl.c3');
  file.writeAsStringSync("");

  String fnData = "// Functions \n \n" +
      commands.map((element) {
        var fnName = element.name.substring(2);
        return "fn " +
            toC3_Type(element.returnType) +
            " " +
            fnName[0].toLowerCase() +
            fnName.substring(1) +
            "(" +
            element.params.map((e) => e.toString()).join(", ") +
            ") @extname(" +
            "\"" +
            element.name +
            "\"" +
            ");";
      }).join("\n");

  String constants = "// Constants \n \n" +
      enums.map((element) {
        return "const " + element.name.toUpperCase() + " = " + element.value + ";";
      }).join("\n");

  file.writeAsStringSync(fnData + "\n \n" + constants);
}

void buildForVersion(String minVersion) {}

void main() {
  const versions = [
    "GL_VERSION_1_0",
    "GL_VERSION_2_0",
    "GL_VERSION_2_1",
    "GL_VERSION_3_0",
    "GL_VERSION_3_1",
    "GL_VERSION_3_2",
    "GL_VERSION_3_3",
    "GL_VERSION_4_0",
    "GL_VERSION_4_1",
    "GL_VERSION_4_2",
    "GL_VERSION_4_3",
    "GL_VERSION_4_4",
    "GL_VERSION_4_5",
    "GL_VERSION_4_6"
  ];

  final file = new File('dependencies/gl/xml/gl.xml');
  final document = XmlDocument.parse(file.readAsStringSync());

  List<Command> commandList = parseCommands(document);
  List<EnumValue> enumList = parseEnums(document);
  List<String> versionEnums = [];
  List<String> versionCommands = [];

  document.findAllElements('feature').forEach((XmlElement node) {
    var featureName = node.getAttribute("name");

    if (versions.contains(featureName)) {
      versionEnums.addAll(node.findAllElements("enum").map((value) => value.getAttribute("name")));
      versionCommands.addAll(node.findAllElements("command").map((value) => value.getAttribute("name")));
    }
  });

  var commands = commandList.where((element) => versionCommands.contains(element.name)).toList();
  var enums = enumList.where((element) => versionEnums.contains(element.name)).toList();
  write_C3file(commands, enums);
}
