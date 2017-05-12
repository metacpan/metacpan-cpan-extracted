#!perl -w
use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::OpenGLFrame qw(w32gSwapBuffers);
use OpenGL qw(:all);
use Math::Trig;

# gears.c
# 3-D gear wheels.  This program is in the public domain.
# Brian Paul
# Conversion to GLUT by Mark J. Kilgard
#
# Translated from C to Perl by J-L Morel (jl_morel@bribes.org)
# < http://www.bribes.org/perl/wopengl.html >
#
# Adapted to Win32::GUI::OpenGLFrame by Robert May (robertmay@cpan.org)

# Win32::GUI Virtual Key constants
sub VK_ESCAPE() {27}
sub VK_LEFT()   {37}
sub VK_UP()     {38}
sub VK_RIGHT()  {39}
sub VK_DOWN()   {40}

#  Draw a gear wheel.  You'll probably want to call this function when
#  building a display list since we do a lot of trig here.
#
#  Input:  inner_radius - radius of hole at center
#          outer_radius - radius at center of teeth
#          width - width of gear
#          teeth - number of teeth
#          tooth_depth - depth of tooth

sub gear {
  my($inner_radius, $outer_radius, $width, $teeth, $tooth_depth) = @_;
  my($r0, $r1, $r2, $angle, $da, $u, $v, $len);

  $r0 = $inner_radius;
  $r1 = $outer_radius - $tooth_depth / 2.0;
  $r2 = $outer_radius + $tooth_depth / 2.0;

  $da = 2.0 * pi / $teeth / 4.0;

  glShadeModel(GL_FLAT);

  glNormal3d(0.0, 0.0, 1.0);

  # draw front face
  glBegin(GL_QUAD_STRIP);
  for (my $i = 0; $i <= $teeth; $i++) {
    $angle = $i * 2.0 * pi / $teeth;
    glVertex3d($r0 * cos($angle), $r0 * sin($angle), $width * 0.5);
    glVertex3d($r1 * cos($angle), $r1 * sin($angle), $width * 0.5);
    glVertex3d($r0 * cos($angle), $r0 * sin($angle), $width * 0.5);
    glVertex3d($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da), $width * 0.5);
  }
  glEnd();

  # draw front sides of teeth
  glBegin(GL_QUADS);
  $da = 2.0 * pi / $teeth / 4.0;
  for (my $i = 0; $i <= $teeth; $i++) {
    $angle = $i * 2.0 * pi / $teeth;
    glVertex3d($r1 * cos($angle), $r1 * sin($angle), $width * 0.5);
    glVertex3d($r2 * cos($angle+$da), $r2 * sin($angle+$da), $width * 0.5);
    glVertex3d($r2 * cos($angle+2*$da), $r2 * sin($angle+2*$da), $width * 0.5);
    glVertex3d($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da), $width * 0.5);
  }
  glEnd();

  glNormal3d(0.0, 0.0, -1.0);

  # draw back face
  glBegin(GL_QUAD_STRIP);
  for (my $i = 0; $i <= $teeth; $i++) {
    $angle = $i * 2.0 * pi / $teeth;
    glVertex3d($r1 * cos($angle), $r1 * sin($angle), -$width * 0.5);
    glVertex3d($r0 * cos($angle), $r0 * sin($angle), -$width * 0.5);
    glVertex3d($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da), -$width * 0.5);
    glVertex3d($r0 * cos($angle), $r0 * sin($angle), -$width * 0.5);
  }
  glEnd();

  # draw back sides of teeth
  glBegin(GL_QUADS);
  $da = 2.0 * pi / $teeth / 4.0;
  for (my $i = 0; $i <= $teeth; $i++) {
    $angle = $i * 2.0 * pi / $teeth;
    glVertex3d($r1 * cos($angle+3*$da), $r1 * sin($angle+3*$da), -$width * 0.5);
    glVertex3d($r2 * cos($angle+2*$da), $r2 * sin($angle+2*$da), -$width * 0.5);
    glVertex3d($r2 * cos($angle+$da), $r2 * sin($angle+$da), -$width * 0.5);
    glVertex3d($r1 * cos($angle), $r1 * sin($angle), -$width * 0.5);
  }
  glEnd();


  # draw outward faces of teeth
  glBegin(GL_QUAD_STRIP);
  for (my $i = 0; $i < $teeth; $i++) {
    $angle = $i * 2.0 * pi / $teeth;

    glVertex3d($r1 * cos($angle), $r1 * sin($angle), $width * 0.5);
    glVertex3d($r1 * cos($angle), $r1 * sin($angle), -$width * 0.5);
    $u = $r2 * cos($angle + $da) - $r1 * cos($angle);
    $v = $r2 * sin($angle + $da) - $r1 * sin($angle);
    $len = sqrt($u * $u + $v * $v);
    $u /= $len;
    $v /= $len;
    glNormal3d($v, -$u, 0.0);
    glVertex3d($r2 * cos($angle + $da), $r2 * sin($angle + $da), $width * 0.5);
    glVertex3d($r2 * cos($angle + $da), $r2 * sin($angle + $da), -$width * 0.5);
    glNormal3d(cos($angle), sin($angle), 0.0);
    glVertex3d($r2 * cos($angle + 2 * $da), $r2 * sin($angle + 2 * $da), $width * 0.5);
    glVertex3d($r2 * cos($angle + 2 * $da), $r2 * sin($angle + 2 * $da), -$width * 0.5);
    $u = $r1 * cos($angle + 3 * $da) - $r2 * cos($angle + 2 * $da);
    $v = $r1 * sin($angle + 3 * $da) - $r2 * sin($angle + 2 * $da);
    glNormal3d($v, -$u, 0.0);
    glVertex3d($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da), $width * 0.5);
    glVertex3d($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da), -$width * 0.5);
    glNormal3d(cos($angle), sin($angle), 0.0);
  }

  glVertex3d($r1 * cos(0), $r1 * sin(0), $width * 0.5);
  glVertex3d($r1 * cos(0), $r1 * sin(0), -$width * 0.5);

  glEnd();

  glShadeModel(GL_SMOOTH);

  # draw inside radius cylinder
  glBegin(GL_QUAD_STRIP);
  for (my $i = 0; $i <= $teeth; $i++) {
    $angle = $i * 2.0 * pi / $teeth;
    glNormal3d(-cos($angle), -sin($angle), 0.0);
    glVertex3d($r0 * cos($angle), $r0 * sin($angle), -$width * 0.5);
    glVertex3d($r0 * cos($angle), $r0 * sin($angle), $width * 0.5);
  }
  glEnd();
}

my $view_rotx = 20.0;
my $view_roty = 30.0;
my $view_rotz = 0.0;
my ($gear1, $gear2, $gear3);
my $angle = 0.0;

my $limit;
my $count = 1;

sub draw {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  glPushMatrix();
  glRotated($view_rotx, 1.0, 0.0, 0.0);
  glRotated($view_roty, 0.0, 1.0, 0.0);
  glRotated($view_rotz, 0.0, 0.0, 1.0);

  glPushMatrix();
  glTranslated(-3.0, -2.0, 0.0);
  glRotated($angle, 0.0, 0.0, 1.0);
  glCallList($gear1);
  glPopMatrix();

  glPushMatrix();
  glTranslated(3.1, -2.0, 0.0);
  glRotated(-2.0 * $angle - 9.0, 0.0, 0.0, 1.0);
  glCallList($gear2);
  glPopMatrix();

  glPushMatrix();
  glTranslated(-3.1, 4.2, 0.0);
  glRotated(-2.0 * $angle - 25.0, 0.0, 0.0, 1.0);
  glCallList($gear3);
  glPopMatrix();
  glPopMatrix();
  w32gSwapBuffers();

  $count++;
  if ($count == $limit) {
    return(-1);
  }
}

sub KeyPressed {
  my ($win, undef, $vkey) = @_;

  if ($vkey == VK_ESCAPE) {
    return -1;
  }
  elsif ($vkey == VK_UP) {
    $view_rotx += 5.0;
  }
  elsif ($vkey == VK_DOWN) {
    $view_rotx -= 5.0;
  }
  elsif ($vkey == VK_LEFT) {
    $view_roty += 5.0;
  }
  elsif ($vkey == VK_RIGHT) {
    $view_roty -= 5.0;
  }

  return;
}

sub Char {
  my ($win, undef, $char) = @_;

  if ($char == ord 'Z') {
    $view_rotz -= 5.0;
  }
  elsif ($char == ord 'z') {
    $view_rotz += 5.0;
  }

  return;
}

# new window size or exposure
sub reshape {
  my($width, $height) = @_;
  my $h = $width ? $height/$width : 0;

  glViewport(0, 0, $width, $height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glFrustum(-1.0, 1.0, -$h, $h, 5.0, 60.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glTranslated(0.0, 0.0, -40.0);
}

sub init {
  my(@pos) = (5.0, 5.0, 10.0, 0.0);
  my(@red) = (0.8, 0.1, 0.0, 1.0);
  my(@green) = (0.0, 0.8, 0.2, 1.0);
  my(@blue) = (0.2, 0.2, 1.0, 1.0);

  glLightfv_p(GL_LIGHT0, GL_POSITION, @pos);
  glEnable(GL_CULL_FACE);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_DEPTH_TEST);

  # make the gears
  $gear1 = glGenLists(1);
  glNewList($gear1, GL_COMPILE);
  glMaterialfv_p(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @red);
  gear(1.0, 4.0, 1.0, 20, 0.7);
  glEndList();

  $gear2 = glGenLists(1);
  glNewList($gear2, GL_COMPILE);
  glMaterialfv_p(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @green);
  gear(0.5, 2.0, 2.0, 10, 0.7);
  glEndList();

  $gear3 = glGenLists(1);
  glNewList($gear3, GL_COMPILE);
  glMaterialfv_p(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @blue);
  gear(1.3, 2.0, 0.5, 10, 0.7);
  glEndList();

  glEnable(GL_NORMALIZE);
}

if (@ARGV) {
    # do 'n' frames then exit
    $limit = $ARGV[0] + 1;
} 
else {
    $limit = 0;
}

my $mw = Win32::GUI::Window->new(
  -title     => "Gears",
  -pos       => [0,0],
  -size      => [300,300],
  -pushstyle => WS_CLIPCHILDREN,  # stop flickering
  -onResize  => \&mainWinResize,
  -onKeyDown => \&KeyPressed,
  -onChar    => \&Char,
);

my $glw = $mw->AddOpenGLFrame(
  -name    => 'oglwin',
  -width   => $mw->ScaleWidth(),
  -height  => $mw->ScaleHeight(),
  -doubleBuffer => 1,
  -depth   => 0,
  -init    => \&init,
  -display => \&draw,
  -reshape => \&reshape,
);

$mw->Show();
while(Win32::GUI::DoEvents() != -1) {
  $angle += 2.0;
  $glw->InvalidateRect(0);
}
$mw->Hide();
exit(0);

sub mainWinResize {
  my $win = shift;

  $win->oglwin->Resize($win->ScaleWidth(), $win->ScaleHeight());

  return 0;
}
__END__
