# Opengl C3 bindings generator


### Building

Git clone the repository and run `git submodule init && git submodule update` to get OpenGL submodules 

Make sure [dart](https://dart.dev/) is installed 

Install dart packages `dart pub get`

Build C3 binding `dart run main.dart`



### Using 

Download `opengl.c3l` file and then copy it to your C3 project dependencies folder.

C3 project.json example

```
"dependencies": ["opengl"],
"dependency-search-paths": [ "dependencies" ],
```
