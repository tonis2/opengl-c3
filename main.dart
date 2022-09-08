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
    return "${type}${renameParameter(name)}";
  }
}

class Command {
  final String returnType;
  final String name;
  final List<Param> params;
  const Command(this.returnType, this.name, this.params);

  String toString() {
    var fnName = name.substring(2);
    return "fn" +
        returnType +
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

  String shortName(bool uppercase) {
    String short = name.substring(2);
    if (uppercase) {
      return short[0].toUpperCase() + short.substring(1);
    } else {
      return short[0].toLowerCase() + short.substring(1);
    }
  }

  String defineName() {
    return "GL_" + shortName(true);
  }

  String toDefinition() {
    return "define " +
        defineName() +
        " = fn " +
        returnType +
        " (" +
        params.map((e) => e.toString()).join(", ") +
        " );";
  }

  String toBinding() {
    return defineName() + " " + shortName(false) + ";";
  }

  String toCallFn() {
    return "fn ${returnType} ${shortName(false)} (${params.map((e) => e.toString()).join(", ")}) { return bindings.${shortName(false)}(${params.map((e) => renameParameter(e.name)).join(",")}); }";
  }

  String getProc() {
    return "bindings.${shortName(false)} = (${defineName()})procAddress(\"${name}\");";
  }
}

// Some parameter names cause issues on C3
String renameParameter(String value) {
  switch (value) {
    case "func":
      return 'func_param';
    case "type":
      return 'value_type';  
    default:
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
          var name = proto.getElement("name").text;
       
          var type = proto.text.replaceAll("const", "");
          var paramsRaw = node.findAllElements("param");
        
          List<Param> params = paramsRaw.map((XmlElement value) {
            var name = value.getElement("name").text;
            var type = value.text.replaceAll("const", "");

            type = type.replaceAll("GLDEBUGPROC", "GLdebugproc");
            type = type.replaceAll("GLDEBUGPROCARB", "GLdebugprocarb");
            type = type.replaceAll("GLDEBUGPROCKHR", "GLdebugprockhr");
          
            return Param(type.substring(0, type.length - name.length), name);
          }).toList();

          return Command(type.substring(0, type.length - name.length), name, params);
        }
      })
      .where((element) => element != null)
      .toList();
}

String Comment(String value) {
  return "\n\n/** \n* $value \n*/ \n";
}


const C3_types = """
define GLenum = CUInt;
define GLboolean = bool;
define GLbitfield = CUInt;
define GLbyte = ichar;
define GLubyte = char;
define GLshort = short;
define GLushort = ushort;
define GLint = CInt;
define GLuint = CUInt;
define GLclampx = int;
define GLsizei = CInt;
define GLfloat = float;
define GLclampf = float;
define GLdouble = double;
define GLclampd = double;
define GLeglClientBufferEXT = void;
define GLeglImageOES = void;
define GLchar = char;
define GLcharARB = char;

define GLhalf = ushort;
define GLhalfARB = ushort;
define GLfixed = int;
define GLintptr = usize;
define GLintptrARB = usize;
define GLsizeiptr = isize;
define GLsizeiptrARB = isize;
define GLint64 = long;
define GLint64EXT = long;
define GLuint64 = ulong;
define GLuint64EXT = ulong;
define GLsync = void*;
define GLdebugproc = void*;
define GLdebugprocarb = void*;
define GLdebugprockhr = void*;
""";

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

  // Parse all commands and enums from XML
  final file = new File('dependencies/gl/xml/gl.xml');
  final document = XmlDocument.parse(file.readAsStringSync());

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
  var commands = commandList.where((value) => versionCommands.contains(value.name)).toList();
  var enums = enumList.where((value) => versionEnums.contains(value.name)).toList();

  // This is where the converting to output string happens, very messy.

  // Write to output file

  var output = File('./build/gl.c3');
  output.writeAsStringSync("");

  // Create function bindings placeholder
  String bindingsPlaceholder = Comment("Bindings") +
      "struct GL_bindings\n{\n" +
      commands.map((value) => value.toBinding()).join("\n") +
      "\n}" +
      Comment("Bindings memory") +
      "\nGL_bindings bindings;";

  // Create Function definitions
  String fnDefinitions = Comment("Function definitions") +
      commands.map((value) => value.toDefinition()).join("\n") +
      Comment("GLFW proc definitions") +
      "\ndefine ProcFN = fn void* (char*);\n\n";

  // Create Constants list
  String constants = Comment("Constants") +
      enums.map((value) {
        return "const " + value.name.toUpperCase() + " = " + value.value + ";";
      }).join("\n");

  // Init function

  String initFunction =
      "fn void init(ProcFN procAddress) {\n${commands.map((value) => value.getProc()).join("  \n")}\n} \n";

  String callFunctions = commands.map((value) => value.toCallFn()).join("\n");

  // Write the whole C3 output file
  output.writeAsStringSync("module gl;" +
      "\n \n" +
      C3_types +
      "\n \n" +
      constants +
      "\n \n" +
      fnDefinitions +
      "\n \n" +
      bindingsPlaceholder +
      "\n \n" +
      initFunction + "\n \n" + callFunctions
      );
}
