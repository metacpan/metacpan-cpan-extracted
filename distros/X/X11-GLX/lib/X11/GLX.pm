package X11::GLX;
$X11::GLX::VERSION = '0.03';
use strict;
use warnings;
use X11::Xlib 0.11;

# ABSTRACT: GLX API (OpenGL on X11)

use Exporter 'import';
our %EXPORT_TAGS= (
# BEGIN GENERATED XS CONSTANT LIST
  constants => [qw( GLX_ACCUM_ALPHA_SIZE GLX_ACCUM_BLUE_SIZE
    GLX_ACCUM_BUFFER_BIT GLX_ACCUM_GREEN_SIZE GLX_ACCUM_RED_SIZE
    GLX_ALPHA_SIZE GLX_AUX0_EXT GLX_AUX1_EXT GLX_AUX2_EXT GLX_AUX3_EXT
    GLX_AUX4_EXT GLX_AUX5_EXT GLX_AUX6_EXT GLX_AUX7_EXT GLX_AUX8_EXT
    GLX_AUX9_EXT GLX_AUX_BUFFERS GLX_AUX_BUFFERS_BIT GLX_BACK_EXT
    GLX_BACK_LEFT_BUFFER_BIT GLX_BACK_LEFT_EXT GLX_BACK_RIGHT_BUFFER_BIT
    GLX_BACK_RIGHT_EXT GLX_BAD_ATTRIBUTE GLX_BAD_CONTEXT GLX_BAD_ENUM
    GLX_BAD_SCREEN GLX_BAD_VALUE GLX_BAD_VISUAL GLX_BIND_TO_MIPMAP_TEXTURE_EXT
    GLX_BIND_TO_TEXTURE_RGBA_EXT GLX_BIND_TO_TEXTURE_RGB_EXT
    GLX_BIND_TO_TEXTURE_TARGETS_EXT GLX_BLUE_SIZE GLX_BUFFER_SIZE
    GLX_COLOR_INDEX_BIT GLX_COLOR_INDEX_TYPE GLX_CONFIG_CAVEAT GLX_DAMAGED
    GLX_DEPTH_BUFFER_BIT GLX_DEPTH_SIZE GLX_DIRECT_COLOR GLX_DONT_CARE
    GLX_DOUBLEBUFFER GLX_DRAWABLE_TYPE GLX_EVENT_MASK GLX_EXTENSIONS
    GLX_FBCONFIG_ID GLX_FLOAT_COMPONENTS_NV GLX_FRONT_EXT
    GLX_FRONT_LEFT_BUFFER_BIT GLX_FRONT_LEFT_EXT GLX_FRONT_RIGHT_BUFFER_BIT
    GLX_FRONT_RIGHT_EXT GLX_GRAY_SCALE GLX_GREEN_SIZE GLX_HEIGHT
    GLX_LARGEST_PBUFFER GLX_LEVEL GLX_MAX_PBUFFER_HEIGHT
    GLX_MAX_PBUFFER_PIXELS GLX_MAX_PBUFFER_WIDTH GLX_MIPMAP_TEXTURE_EXT
    GLX_NONE GLX_NON_CONFORMANT_CONFIG GLX_NO_EXTENSION GLX_PBUFFER
    GLX_PBUFFER_BIT GLX_PBUFFER_CLOBBER_MASK GLX_PBUFFER_HEIGHT
    GLX_PBUFFER_WIDTH GLX_PIXMAP_BIT GLX_PRESERVED_CONTENTS GLX_PSEUDO_COLOR
    GLX_RED_SIZE GLX_RENDERER_ACCELERATED_MESA GLX_RENDERER_DEVICE_ID_MESA
    GLX_RENDERER_ID_MESA
    GLX_RENDERER_OPENGL_COMPATIBILITY_PROFILE_VERSION_MESA
    GLX_RENDERER_OPENGL_CORE_PROFILE_VERSION_MESA
    GLX_RENDERER_OPENGL_ES2_PROFILE_VERSION_MESA
    GLX_RENDERER_OPENGL_ES_PROFILE_VERSION_MESA
    GLX_RENDERER_PREFERRED_PROFILE_MESA
    GLX_RENDERER_UNIFIED_MEMORY_ARCHITECTURE_MESA GLX_RENDERER_VENDOR_ID_MESA
    GLX_RENDERER_VERSION_MESA GLX_RENDERER_VIDEO_MEMORY_MESA GLX_RENDER_TYPE
    GLX_RGBA GLX_RGBA_BIT GLX_RGBA_TYPE GLX_SAMPLES GLX_SAMPLE_BUFFERS
    GLX_SAVED GLX_SCREEN GLX_SCREEN_EXT GLX_SLOW_CONFIG GLX_STATIC_COLOR
    GLX_STATIC_GRAY GLX_STENCIL_BUFFER_BIT GLX_STENCIL_SIZE GLX_STEREO
    GLX_TEXTURE_1D_BIT_EXT GLX_TEXTURE_1D_EXT GLX_TEXTURE_2D_BIT_EXT
    GLX_TEXTURE_2D_EXT GLX_TEXTURE_FORMAT_EXT GLX_TEXTURE_FORMAT_NONE_EXT
    GLX_TEXTURE_FORMAT_RGBA_EXT GLX_TEXTURE_FORMAT_RGB_EXT
    GLX_TEXTURE_RECTANGLE_BIT_EXT GLX_TEXTURE_RECTANGLE_EXT
    GLX_TEXTURE_TARGET_EXT GLX_TRANSPARENT_ALPHA_VALUE
    GLX_TRANSPARENT_BLUE_VALUE GLX_TRANSPARENT_GREEN_VALUE
    GLX_TRANSPARENT_INDEX GLX_TRANSPARENT_INDEX_VALUE
    GLX_TRANSPARENT_RED_VALUE GLX_TRANSPARENT_RGB GLX_TRANSPARENT_TYPE
    GLX_TRUE_COLOR GLX_USE_GL GLX_VENDOR GLX_VERSION GLX_VISUAL_ID
    GLX_VISUAL_ID_EXT GLX_WIDTH GLX_WINDOW GLX_WINDOW_BIT GLX_X_RENDERABLE
    GLX_X_VISUAL_TYPE GLX_Y_INVERTED_EXT )],
# END GENERATED XS CONSTANT LIST
# BEGIN GENERATED XS FUNCTION LIST
  fn_import_cx => [qw( glXFreeContextEXT glXGetContextIDEXT glXImportContextEXT
    glXQueryContextInfoEXT )],
  fn_std => [qw( glXChooseFBConfig glXChooseVisual glXCreateContext
    glXCreateGLXPixmap glXCreateNewContext glXDestroyContext
    glXDestroyGLXPixmap glXGetFBConfigAttrib glXGetFBConfigs
    glXGetVisualFromFBConfig glXMakeCurrent glXQueryExtensionsString
    glXQueryVersion glXSwapBuffers )],
# END GENERATED XS FUNCTION LIST
);
our @EXPORT_OK= map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{functions}= [ grep { /^glX'/ } @EXPORT_OK ];
$EXPORT_TAGS{constants}= [ grep { /^GLX/ } @EXPORT_OK ];
$EXPORT_TAGS{all}= \@EXPORT_OK;

require XSLoader;
XSLoader::load('X11::GLX', $X11::GLX::VERSION);

require X11::GLX::Context;
require X11::GLX::Pixmap;
require X11::GLX::FBConfig;

__END__

=pod

=encoding UTF-8

=head1 NAME

X11::GLX - GLX API (OpenGL on X11)

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This module acts as an extension to L<X11::Xlib>, providing the API that
sets up OpenGL on X11.  The L<OpenGL> perl module can provide some of this
API, but doesn't in it's default configuration.

This is the C-style API.  For something more friendly, see L<X11::GLX::DWIM>.

=head1 METHODS

=for Pod::Coverage GLX_SCREEN_EXT GLX_VISUAL_ID_EXT GLX_ALPHA_SIZE GLX_BLUE_SIZE GLX_DOUBLEBUFFER GLX_GREEN_SIZE GLX_RED_SIZE GLX_RGBA GLX_USE_GL

=head2 glXQueryVersion

  X11::GLX::glXQueryVersion($display, my ($major, $minor))
	or die "glXQueryVersion	failed";
  print "GLX Version $major.$minor\n";

=head2 glXQueryExtensionsString

  my $str= glXQueryExtensionsString($display, $screen_num);
  my $str= glXQueryExtensionsString($display); # default screen

Get a string of all the GL extensions available.

=head2 glXChooseVisual

  my $vis_info= glXChooseVisual($display, $screen, \@attributes);
  my $vis_info= glXChooseVisual($display, $screen);
  my $vis_info= glXChooseVisual($display); # default screen

This function picks an OpenGL-compatible visual.  C<@attributes> is an array
of integers (see GLX documentation).  The terminating "None" is added
automatically.  If undefined, this module uses a default of:

  [ GLX_USE_GL, GLX_RGBA, GLX_DOUBLEBUFFER,
    GLX_RED_SIZE, 8, GLX_GREEN_SIZE, 8, GLX_BLUE_SIZE, 8, GLX_ALPHA_SIZE, 8 ]

Returns an L<XVisualInfo|X11::Xlib::XVisualInfo>, or empty list on failure.

This method is deprecated in GLX 1.3 in favor of glXChooseFBConfig.

=head2 glXChooseFBConfig

  if ($glx_version >= 1.3) {
	my @configs= glXChooseFBConfig($display, $screen, \@attributes);
  }

Return a list of compatible framebuffer configurations (L<GLXFBConfig|X11::GLX::GLXFBConfig>)
matching the desired C<@attributes>.
This method deals with lower level details than glXChooseVisual,
needed for more advanced GL usage like rendering a fully transparent window.
For C<@attributes>, consult the L<khronos docs|http://www.khronos.org/registry/OpenGL-Refpages/gl2.1/xhtml/glXChooseFBConfig.xml>

Returns an empty list on failure.

=head2 glXGetFBConfigs

  my @fbconfigs= glXGetFBConfigs($display, $screen);

Return all GLXFBConfig available on this screen.

=head2 glXGetFBConfigAttrib

  glXGetFBConfigAttrib($display, $fbconfig, $attr_id, my $value) == Success
	or die "glXGetFBConfigAttrib failed";

Yes you read that right.  Horribly awkward interface for accessing attributes
of a struct.  Use the attributes of L<GLXFBConfig|X11::GLX::GLXFBConfig> instead.

=head2 glXGetVisualFromFBConfig

  if ($glx_version >= 1.3) {
	my $vis_info= glXGetVisualFromFBConfig($display, $glxfbconfig);
	# It's an XVisualInfo, not Visual, despite the name
  }

Return the L<XVisualInfo|X11::Xlib::XVisualInfo> associated with the
L<FBConfig|X11::GLX::GLXFBConfig>.

=head2 glXCreateContext

  my $context= glXCreateContext($display, $visual_info, $shared_with, $direct);

C<$visual_info> is an instance of L<XVisualInfo|X11::Xlib::XVisualInfo>, most
likely returned by L<glXChooseVisual>.

C<$shared_with> is an optional L<X11::GLX::GLXContext> with which to share
display lists, and possibly other objects like textures.  See L</Shared GL Contexts>.

C<$direct> is a boolean indicating whether you would like a direct rendering
context.  i.e. have the application directly open a handle to the graphics
hardware that bypasses X11 protocol.  You are not guaranteed to get a direct
context if setting it to true, and indeed won't if you are connected to a
remote X11 server.  However if you set it to false this call may fail entirely
if you are connected to a X11 server which has disabled indirect rendering.

=head2 glXCreateNewContext

  my $context= glXCreateNewContext($display, $fbconfig, $render_type, $share, $direct);

Like L</glXCreateContext>, except it takes a C<X11::GLX::FBConfig> instead of
a C<X11::Xlib::XVisualInfo>.  There is also a C<$render_type> that can be
C<GLX_RGBA_TYPE> or C<GLX_COLOR_INDEX_TYPE>, but I'm not sure why anyone
would ever be using the second one ;-)

=head2 glXMakeCurrent

  glXMakeCurrent($display, $drawable, $glcontext)
    or die "glXMakeCurrent failed";

Set the target drawable (window or GLX pixmap) to which this GL context should
render.  Note that pixmaps must have been created with L</glXCreateGLXPixmap>
and can't be just regular X11 pixmaps.

=head2 glXSwapBuffers

  glXSwapBuffers($display, $glxcontext)

For a double-buffered drawable, show the back buffer and begin rendering to
the former front buffer.

=head2 glXDestroyContext

  glXDestroyContext($display, $glxcontext);

Destroy a context created by glXCreateContext.  This destroys it on the server
side.

=head2 glXCreateGLXPixmap

  my $glxpixmap= glXCreateGLXPixmap($display, $visualinfo, $pixmap)

Create a new pixmap from an existing pixmap which has the extra GLX baggage
necessary to use it as a rendering target.

=head2 glXDestroyGLXPixmap

  glXDestroyGLXPixmap($display, $glxpixmap)

Free a GLX pixmap.  You need to call this function instead of the usual
XDestroyPixmap.

=head1 Extension GLX_EXT_import_context

These functions are only available if C<X11::GLX::glXQueryExtensionsString>
includes "GLX_EXT_import_context".  See L</Shared GL Contexts>.

=head2 glXGetContextIDEXT

  my $xid= glXGetContextIDEXT($glxcontext)

Returns the X11 display object ID of the GL context.  This XID can be passed
to L</glXImportContextEXT> by any other process to get a GLXContext pointer
in their address space for this context.

=head2 glXImportContextEXT

  my $glx_context= glXImportContextEXT($display, $context_xid);

Create a local GLXContext data structure that references a shared indirect
GLXContext on the X11 server.

=head2 glXFreeContextEXT

  glXFreeContextEXT($glx_context);

Free the context data structures created by L</glXImportContextEXT>.

=head2 glXQueryContextInfoEXT

  glXQueryContextInfoEXT($display, $glxcontext, $attr, my $attr_val)
	or die "glXQueryContextInfoEXT failed";

Retrieve the value of an attribute of the GLX Context.  The attribute is
returned in the final argument.  The return value is a boolean indicating
success.

Attributes:

  GLX_VISUAL_ID_EXT      - Returns the XID of the GLX Visual associated with ctx.
  GLX_SCREEN_EXT         - Returns the screen number associated with ctx.

=head1 Shared GL Contexts

Sometimes you want to let more than one thread or process access the same
OpenGL objects, like Display Lists, Textures, etc.
For threads, all you have to do is pass the first thread's context pointer to
glXCreateContext for the second thread.

For processes, it is more difficult.  To set it up, each process must create
an indirect context (to the same Display obviously), and the server and both
clients must support the extension C<GLX_EXT_import_context>.  Client #1
creates an indirect context, finds the ID, passes that to Client #2 via some
method, then client #2 imports the context, then creates a new context
shared with the imported one, then frees the imported one.  To make a long
story short, see test case C<03-import-context.t> for an example.

Note that many distros have started disabling indirect mode (as of 2016) for
OpenGL on Xorg, for security concerns.  You can enable it by passing "+iglx"
to the Xorg command line.  (finding where to specify the commandline for Xorg
can be an exercise in frustration... good luck.  On Linux Mint it is found in
/etc/X11/xinit/xserverrc.  The quick and dirty approach is to rename the Xorg
binary and stick a script in its place that exec's the original with the
desired command line.)

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
