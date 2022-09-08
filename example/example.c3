import libc;
import glfw;
import gl;

float[] points = { -0.5, -0.5, 0.0,
     0.5, -0.5, 0.0,
     0.0,  0.5, 0.0 };

const char* VERTEX_SHADER = `
  #version 410
  in vec3 vp;
  void main () {
    gl_Position = vec4(vp, 1.0);
  }
`;
  
const char* FRAGMENT_SHADER= `
  #version 410
  out vec4 frag_colour;
  void main () {
    frag_colour = vec4(0.5, 0.0, 0.5, 1.0);
  }
`;


fn int main()   
{
  glfw::init();

  const int WIDTH = 1280;
  const int HEIGHT = 720;
  char* renderer;
  char* version;

  uint vao;
  uint vbo;
  uint shader_programme;
  uint vert_shader;
  uint frag_shader;

  glfw::windowHint(glfw::CONTEXT_VERSION_MAJOR, 4);
  glfw::windowHint(glfw::CONTEXT_VERSION_MINOR, 1);
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
  gl::genBuffers( 1, &vbo );
  gl::bindBuffer( gl::GL_ARRAY_BUFFER, vbo );
  gl::bufferData( gl::GL_ARRAY_BUFFER, 9 * float.sizeof, points, gl::GL_STATIC_DRAW );

  gl::genVertexArrays( 1, &vao );
  gl::bindVertexArray( vao );

  gl::enableVertexAttribArray( 0 );
  gl::bindBuffer( gl::GL_ARRAY_BUFFER, vbo );
  gl::vertexAttribPointer( 0, 3, gl::GL_FLOAT, false, 0, null );

  vert_shader = gl::createShader( gl::GL_VERTEX_SHADER );
  gl::shaderSource( vert_shader, 1, &VERTEX_SHADER, null );
  gl::compileShader( vert_shader );

  frag_shader = gl::createShader( gl::GL_FRAGMENT_SHADER );
  gl::shaderSource( frag_shader, 1, &FRAGMENT_SHADER, null );
  gl::compileShader( frag_shader );

  shader_programme = gl::createProgram();
  gl::attachShader( shader_programme, frag_shader );
  gl::attachShader( shader_programme, vert_shader );
  gl::linkProgram( shader_programme );


  while(!glfw::windowShouldClose(window)) {
    gl::clear( gl::GL_COLOR_BUFFER_BIT | gl::GL_DEPTH_BUFFER_BIT );
    gl::useProgram( shader_programme );
    gl::bindVertexArray( vao );
    gl::drawArrays( gl::GL_TRIANGLES, 0, 3 );

    glfw::pollEvents();
    glfw::swapBuffers(window);
  }

  glfw::destroyWindow(window);
  glfw::terminate();
  return 0;
}