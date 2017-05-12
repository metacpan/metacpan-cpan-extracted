#!perl -w

use FindBin();
use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::OpenGLFrame qw(w32gSwapBuffers);
use OpenGL qw(:all);

# Win32::GUI Virtual Key constants
sub VK_ESCAPE() {27}
sub VK_LEFT()   {37}
sub VK_UP()     {38}
sub VK_RIGHT()  {39}
sub VK_DOWN()   {40}

$speed_test = GL_FALSE;
$use_vertex_arrays = GL_TRUE;

$doubleBuffer = GL_TRUE;

$smooth = GL_TRUE;
$lighting = GL_TRUE;

$MAXVERTS = 10000;

$verts = new OpenGL::Array $MAXVERTS * 3, GL_FLOAT;
$norms = new OpenGL::Array $MAXVERTS * 3, GL_FLOAT;
$numverts = 0;

$xrot=0;
$yrot=0;

sub read_surface_dat {
  my ($filename) = @_;

  open(F, "<$filename") || die "couldn't read $filename\n";
  
  $numverts = 0;
  while ($numverts < $MAXVERTS and defined($_ = <F>)) {
    chop;
    @d = split(/\s+/, $_);
    $verts->assign($numverts*3, @d[0..2]);
    $norms->assign($numverts*3, @d[3..5]);
    $numverts++;
  }
  
  $numverts--;
  
  printf "%d vertices, %d triangles\n", $numverts, $numverts-2;

  close(F);
}

sub read_surface_bin {
  my ($filename) = @_;
  
  open(F, "<$filename") || die "couldn't read $filename\n";
  
  $numverts = 0;
  while ($numverts < $MAXVERTS and read(F, $_, 12)==12) {
    @d = map(($_-32000) / 10000 , unpack("nnnnnn", $_));
    $verts->assign($numverts*3, @d[0..2]);
    $norms->assign($numverts*3, @d[3..5]);
    $numverts++;
  }
  
  $numverts--;
  
  printf "%d vertices, %d triangles\n", $numverts, $numverts-2;
  
  close(F);
}

sub draw_surface {
  my ($i);

#  glDrawArrays(GL_TRIANGLE_STRIP, 0, $numverts);

  if ($use_vertex_arrays) {
    glDrawArraysEXT( GL_TRIANGLE_STRIP, 0, $numverts );
  }
  else {
    glBegin( GL_TRIANGLE_STRIP );
    for ($i=0;$i<$numverts;$i++) {
      glNormal3d( $norms->retrieve($i*3, 3) );
      glVertex3d( $verts->retrieve($i*3, 3) );
    }
    glEnd();
  }
}

sub draw1 {

  glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
  glPushMatrix();
  glRotated( $yrot, 0.0, 1.0, 0.0 );
  glRotated( $xrot, 1.0, 0.0, 0.0 );

  draw_surface();

  glPopMatrix();

  glFlush();
  if ($doubleBuffer) {
    w32gSwapBuffers();
  }
}


sub Draw {
  if ($speed_test) {
    for ($xrot=0.0;$xrot<=360.0;$xrot+=10.0) {
      draw1();
    }
    return(-1);
  }
  else {
    draw1();
  }
}

sub InitMaterials {

  my(@ambient) = (0.1, 0.1, 0.1, 1.0);
  my(@diffuse) = (0.5, 1.0, 1.0, 1.0);
  my (@position0) = (0.0, 0.0, 20.0, 0.0);
  my (@position1) = (0.0, 0.0, -20.0, 0.0);
  my (@front_mat_shininess) = (60.0);
  my (@front_mat_specular) = (0.2, 0.2, 0.2, 1.0);
  my (@front_mat_diffuse) = (0.5, 0.28, 0.38, 1.0);
#  /*
#  my (@back_mat_shininess) = (60.0);
#  my (@back_mat_specular) = (0.5, 0.5, 0.2, 1.0);
#  my (@back_mat_diffuse) = (1.0, 1.0, 0.2, 1.0);
#  */
  my (@lmodel_ambient) = (1.0, 1.0, 1.0, 1.0);
  my (@lmodel_twoside) = (GL_FALSE);

  glLightfv_p(GL_LIGHT0, GL_AMBIENT, @ambient);
  glLightfv_p(GL_LIGHT0, GL_DIFFUSE, @diffuse);
  glLightfv_p(GL_LIGHT0, GL_POSITION, @position0);
  glEnable(GL_LIGHT0);
    
  glLightfv_p(GL_LIGHT1, GL_AMBIENT, @ambient);
  glLightfv_p(GL_LIGHT1, GL_DIFFUSE, @diffuse);
  glLightfv_p(GL_LIGHT1, GL_POSITION, @position1);
  glEnable(GL_LIGHT1);
    
  glLightModelfv_p(GL_LIGHT_MODEL_AMBIENT, @lmodel_ambient);
  glLightModelfv_p(GL_LIGHT_MODEL_TWO_SIDE, @lmodel_twoside);
  glEnable(GL_LIGHTING);

  glMaterialfv_p(GL_FRONT_AND_BACK, GL_SHININESS, @front_mat_shininess);
  glMaterialfv_p(GL_FRONT_AND_BACK, GL_SPECULAR, @front_mat_specular);
  glMaterialfv_p(GL_FRONT_AND_BACK, GL_DIFFUSE, @front_mat_diffuse);
}

sub Init {

  glClearColor(0.0, 0.0, 0.0, 0.0);

  glShadeModel(GL_SMOOTH);
  glEnable(GL_DEPTH_TEST);

  InitMaterials();

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glFrustum( -1.0, 1.0, -1.0, 1.0, 5, 25 );

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glTranslated( 0.0, 0.0, -6.0 );
   
#  glVertexPointer_a( 3, GL_FLOAT, 0, $verts );
#  glNormalPointer_a( GL_FLOAT, 0, $norms );
#  glEnable( GL_VERTEX_ARRAY );
#  glEnable( GL_NORMAL_ARRAY );

  if ($use_vertex_arrays) {
    glVertexPointerEXT_c( 3, GL_FLOAT, 0, $numverts, $verts->ptr );
    glNormalPointerEXT_c( GL_FLOAT, 0, $numverts, $norms->ptr );
    glEnable( GL_VERTEX_ARRAY_EXT );
    glEnable( GL_NORMAL_ARRAY_EXT );
  }
}

sub Key{
  my ($win, undef, $vkey) = @_;
  if ($vkey == VK_ESCAPE) {
    return -1;
  }
  elsif ($vkey == ord 'S' ) { # S - Smoothing.
    $smooth = !$smooth;
    glShadeModel($smooth ? GL_SMOOTH : GL_FLAT);
  }
  elsif ($vkey == ord 'L' ) { # L - Lighting.
    $lighting = !$lighting;
    if ($lighting) {
      glEnable(GL_LIGHTING);
    } else {
      glDisable(GL_LIGHTING);
    }
  }
  elsif ($vkey == VK_UP) {
    $xrot += 15.0;
  }
  elsif ($vkey == VK_DOWN) {
    $xrot -= 15.0;
  }
  elsif ($vkey == VK_LEFT) {
    $yrot -= 15.0;
  }
  elsif ($vkey == VK_RIGHT) {
    $yrot += 15.0;
  }
  else {
	  return;
  }

  $win->oglwin->InvalidateRect(0);
  return;
}

read_surface_bin( "$FindBin::Bin/isosurf.bin" );

# Make sure server supports the vertex array extension
$extensions = glGetString( GL_EXTENSIONS );
if ($extensions !~ /\bGL_EXT_vertex_array\b/) {
  $use_vertex_arrays = GL_FALSE;
}

my $mw = Win32::GUI::Window->new(
  -title     => "IsoSurface",
  -pos       => [0,0],
  -size      => [400,400],
  -pushstyle => WS_CLIPCHILDREN,  # stop flickering
  -onResize  => \&mainWinResize,
  -onKeyDown => \&Key,
);

my $glw = $mw->AddOpenGLFrame(
  -name    => 'oglwin',
  -width   => $mw->ScaleWidth(),
  -height  => $mw->ScaleHeight(),
  -doubleBuffer => $doubleBuffer,
  -depth   => 1,
  -init    => \&Init,
  -display => \&Draw,
);

$mw->Show();
Win32::GUI::Dialog();
$mw->Hide();
exit(0);

sub mainWinResize {
  my $win = shift;

  $win->oglwin->Resize($win->ScaleWidth(), $win->ScaleHeight());

  return 0;
}
