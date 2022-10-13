### Build

Get [C3 lang](http://www.c3-lang.org/) installed

_Required dependencies_

`GLFW` and `OpenGL`

To compile run on command line:


Triangle example
`c3c compile ./triangle.c3 ./glfw.c3 ../build/gl.c3 -l glfw -o ./triangle`

Then run `./triangle`


Cube example
`c3c compile ./cube.c3 ./glfw.c3 ./utils.c3 ../build/gl.c3 -l glfw -o ./cube`