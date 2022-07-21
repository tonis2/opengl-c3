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
    return C3Type(type) + " " + renameParameter(name);
  }
}

class Command {
  final String returnType;
  final String name;
  final List<Param> params;
  const Command(this.returnType, this.name, this.params);

  String toString() {
    var fnName = name.substring(2);
    return "fn " +
        C3Type(returnType) +
        " " +
        fnName[0].toLowerCase() +
        fnName.substring(1) +
        "(" +
        params.map((e) => e.toString()).join(", ") +
        ") @extname(" +
        "\"" +
        name +
        "\"" +
        ");";
  }
}

// Some parameter names cause issues on C3
String renameParameter(String value) {
  switch (value) {
    case "func":
      return 'func_param';
    default:
      return value;
  }
}

// enum C_types {
//   GLsizei,
//   GLuint,
//   GLfloat,
//   GLclampf,
//   GLenum,
//   GLuint64EXT,
//   GLubyte,
//   GLdouble,
//   GLchar,
//   GLshort,
//   GLboolean,
//   GLint,
//   GLuint64,
//   GLfixed,
//   GLsizeiptr,
//   GLbyte,
// }

// extension C3Type on C_types {
//   String get name {
//     switch (this) {
//       case C_types.GLsizei:
//         return 'isize';
//       case C_types.GLuint:
//         return 'uint';
//       case C_types.GLfloat:
//         return 'float';
//       case C_types.GLclampf:
//         return 'float';
//       case C_types.GLenum:
//         return 'int';
//       case C_types.GLuint64EXT:
//         return 'int';
//       case C_types.GLubyte:
//         return 'uint';
//       case C_types.GLdouble:
//         return 'double';
//       case C_types.GLchar:
//         return 'char';
//       case C_types.GLshort:
//         return 'uint';
//       case C_types.GLboolean:
//         return 'bool';
//       default:
//         return null;
//     }
//   }
// }

// Change GL_types to regular C3 types
String C3Type(String value) {
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
    case "GLint64":
      return "int";
    case "GLfixed":
      return "int";
    case "GLsizeiptr":
      return "int";
    case "GLbyte":
      return "ushort";
    case "GLushort":
      return "ushort";
    case "const":
      return "int*";
    case "GLDEBUGPROC":
      return "void*";
    case "GLsync":
      return "void*";
    case "GLintptr":
      return "iptr**";
    case "GLbitfield":
      return "int";
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
          var fnName = proto.getElement("name").text;
          var returnType = proto.text.split(" ")[0];
          var paramsRaw = node.findAllElements("param");

          List<Param> params = paramsRaw.map((XmlElement value) {
            var valueText = value.text;
            var type = value.getElement("ptype");
            var splitValueText = valueText.split(" ");
            var paramName = splitValueText[splitValueText.length - 1];

            if (valueText == "const void *data") {
              return Param("double[]", paramName.replaceAll("*", ""));
            }

            // Replace *const* with just **
            if (paramName.contains("*const*")) {
              paramName = paramName.replaceAll("*const*", "**");
            }

            if (type == null)
              return Param(valueText.split(" ")[0], paramName);
            else {
              return Param(type.text, paramName);
            }
          }).toList();

          return Command(returnType, fnName, params);
        }
      })
      .where((element) => element != null)
      .toList();
}

void write_C3file(List<Command> commands, List<EnumValue> enums) async {
  var file = File('./build/gl.c3');
  file.writeAsStringSync("");

  // Create Functions list
  String fnData = "// Functions \n \n" + commands.map((element) => element.toString()).join("\n");

  // Create Constants list
  String constants = "// Constants \n \n" +
      enums.map((element) {
        return "const " + element.name.toUpperCase() + " = " + element.value + ";";
      }).join("\n");

  // Write the whole file
  file.writeAsStringSync("module gl;" + "\n \n" + fnData + "\n \n" + constants);
}

void main() {
  const versions = [
    "GL_VERSION_1_0",
    "GL_VERSION_1_1",
    "GL_VERSION_1_5",
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

  // Parse all commands and enums
  List<Command> commandList = parseCommands(document);
  List<EnumValue> enumList = parseEnums(document);

  // Filter out the versions required
  List<String> versionEnums = [];
  List<String> versionCommands = [];
  document.findAllElements('feature').forEach((XmlElement node) {
    var featureName = node.getAttribute("name");

    if (versions.contains(featureName)) {
      versionEnums.addAll(node.findAllElements("enum").map((value) => value.getAttribute("name")));
      versionCommands.addAll(node.findAllElements("command").map((value) => value.getAttribute("name")));
    }
  });

  // Filtered commands and enums
  var commands = commandList.where((element) => versionCommands.contains(element.name)).toList();
  var enums = enumList.where((element) => versionEnums.contains(element.name)).toList();

  // Write to file
  write_C3file(commands, enums);
}
