import libc;
import glfw;
import gl;
import util;

const char* VERTEX_SHADER = `
  #version 410
  in vec3 vp;
  void main () {
    gl_Position = vec4(vp, 1.0);
  }
`;

const char* FRAGMENT_SHADER = `
  #version 410
  out vec4 frag_colour;
  void main () {
    frag_colour = vec4(0.5, 0.0, 0.5, 1.0);
  }
`;

float[] cube_data = {
		0.5f, 0.5f, 0.0f,	
		0.5f, -0.5f, 0.0f,	
		-0.5f, -0.5f, 0.0f, 
		-0.5f, 0.5f, 0.0f	
};

float [] indices = {
  0, 1, 3,
	1, 2, 3	
};

fn int main()   
{

  const int WIDTH = 1280;
  const int HEIGHT = 720;
  char* renderer;
  char* version;

  glfw::init();
  glfw::windowHint(glfw::CONTEXT_VERSION_MAJOR, 3);
  glfw::windowHint(glfw::CONTEXT_VERSION_MINOR, 2);
  glfw::windowHint(glfw::OPENGL_PROFILE, glfw::OPENGL_CORE_PROFILE);
  glfw::windowHint(glfw::OPENGL_FORWARD_COMPAT, 1);

  glfw::WindowRef window = glfw::createWindow(WIDTH, HEIGHT, "GLFW OpenGL", null, null);

  if (window == null)
  {
        libc::printf("Failed to init gl window");
        glfw::terminate();
        return 1;
  }

  glfw::makeContextCurrent(window);
  gl::init(&glfw::getProcAddress);

  renderer = gl::getString( gl::GL_RENDERER );
  version  = gl::getString( gl::GL_VERSION );

  libc::printf( "Renderer: %s\n", renderer );
  libc::printf( "OpenGL version supported %s\n", version );

  gl::enable( gl::GL_DEPTH_TEST );
  gl::depthFunc( gl::GL_LESS );
  
  int cube_size = cube_data.len / float.sizeof;


  uint vertexBuffer;

  gl::bindBuffer(gl::GL_ARRAY_BUFFER, vertexBuffer);
  gl::bufferData(gl::GL_ELEMENT_ARRAY_BUFFER, cube_size * 12, cube_data, gl::GL_STATIC_DRAW);


  uint! vertex_shader = util::create_shader(gl::GL_VERTEX_SHADER, &VERTEX_SHADER);
  uint! fragment_shader = util::create_shader(gl::GL_FRAGMENT_SHADER, &FRAGMENT_SHADER);
  uint shader_programme = gl::createProgram();

  if (try vertex_shader && try fragment_shader) {
      gl::attachShader( shader_programme, vertex_shader );
      gl::attachShader( shader_programme, fragment_shader );
      gl::linkProgram( shader_programme );
  }

  gl::useProgram(shader_programme);

  // defer {
  //   gl::deleteShader(vertex_shader);
  //   gl::deleteShader(fragment_shader);
	//   gl::deleteProgram(shader_programme);
  // }


  // int colorbuffer;
  // gl::genBuffers(1, &colorbuffer);
  // gl::bindBuffer(gl::GL_ARRAY_BUFFER, colorbuffer);
  // gl::bufferData(gl::GL_ARRAY_BUFFER, sizeOf(g_color_buffer_data), g_color_buffer_data, gl::GL_STATIC_DRAW);

  // gl::enableVertexAttribArray(1);
  // gl::bindBuffer(gl::GL_ARRAY_BUFFER, colorbuffer);
  // gl::vertexAttribPointer(
  //       1,                                // attribute. No particular reason for 1, but must match the layout in the shader.
  //       3,                                // size
  //       gl::GL_FLOAT,                         // type
  //       0,                         // normalized?
  //       0,                                // stride
  //       (void*)0                          // array buffer offset
  // );

  // while(!glfw::windowShouldClose(window)) {
  //   gl::drawArrays(gl::GL_TRIANGLES, 0, 12*3);
  //   glfw::pollEvents();
  //   glfw::swapBuffers(window);
  // }

  glfw::destroyWindow(window);
  glfw::terminate();
  
  return 0;
}