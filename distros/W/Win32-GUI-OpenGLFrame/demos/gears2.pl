#!perl -w
use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::OpenGLFrame qw(w32gSwapBuffers);
use OpenGL qw/ :all /;
use Math::Trig;

my $d_near = 1.0;
my $d_far = 2000;
my $poo = 0;
my $circle_subdiv;
my $mode = GLUT_DOUBLE;

# Win32::GUI Virtual Key constants
sub VK_ESCAPE() {27}

sub gear {
  my ($nt, $wd, $ir, $or, $tp, $tip, @ip) = @_;

  # nt - number of teeth
  # wd - width of gear at teeth
  # ir - inside radius absolute scale
  # or - radius at outside of wheel (tip of tooth) ratio of ir
  # tp - ratio of tooth in slice of circle (0..1] (1 = teeth are touching at base)
  # tip - ratio of tip of tooth (0..tp] (cant be wider that base of tooth)
  # @ip - list of float pairs {start radius, width, ...} (width is ratio to wd)

  # gear lying on xy plane, z for width. all normals calulated (normalized)

  my $ns = scalar @ip / 2;
  my $prev;
  my $t;

  # estimat # times to divide circle
  if ($nt <= 0) {
    $circle_subdiv = 64;
  }
  else {
    # lowest multiple of number of teeth
    $circle_subdiv = $nt;
    $circle_subdiv += $nt while $circle_subdiv < 64;
  }

  # --- draw wheel face ---

    # draw horzontal, vertical faces for each section. if first
    #section radius not zero, use wd for 0.. first if ns == 0
    #use wd for whole face. last width used to edge.

  if ($ns <= 0) {
    flat_face(0.0, $ir, $wd);
  }
  else {
    # draw first flat_face, then continue in loop
    if ($ip[2*0] > 0.0) {
      flat_face(0.0, $ip[2*0] * $ir, $wd);
      $prev = $wd;
      $t = 0;
    }
    else {
      flat_face(0.0, $ip[2*1] * $ir, $ip[2*0+1] * $wd);
      $prev = $ip[2*0+1];
      $t = 1;
    }
    for (my $k = $t; $k < $ns; $k++) {
      if ($prev < $ip[2*$k]+1) {
        draw_inside($prev * $wd, $ip[2*$k+1] * $wd, $ip[2*$k] * $ir);
      }
      else {
        draw_outside($prev * $wd, $ip[2*$k+1] * $wd, $ip[2*$k] * $ir);
      }
      $prev = $ip[2*$k+1];
      # - draw to edge of wheel, add final face if needed -
      if ($k == $ns - 1) {
        flat_face($ip[2*$k] * $ir, $ir, $ip[2*$k+1] * $wd);

        # now draw side to match tooth rim
        if ($ip[2*$k+1] < 1.0) {
          draw_inside($ip[2*$k+1] * $wd, $wd, $ir);
        }
        else {
          draw_outside($ip[2*$k+1] * $wd, $wd, $ir);
        }
      }
      else {
        flat_face($ip[2*$k] * $ir, $ip[2*($k + 1)] * $ir, $ip[2*$k+1] * $wd);
      }
    }
  }

  # --- tooth side faces ---
  tooth_side($nt, $ir, $or, $tp, $tip, $wd);

  # --- tooth hill surface ---
}

sub tooth_side {
  my ($nt, $ir, $or, $tp, $tip, $wd) = @_;
  my $end = 2.0 * pi / $nt;
  my @x;
  my @y;
  my @s;
  my @c;

  $or = $or * $ir;         # $or is really $a ratio of $ir
  for (my $i = 0; $i < 2.0 * pi - $end / 4.0; $i += $end) {

    $c[0] = cos($i);
    $s[0] = sin($i);
    $c[1] = cos($i + $end * (0.5 - $tip / 2));
    $s[1] = sin($i + $end * (0.5 - $tip / 2));
    $c[2] = cos($i + $end * (0.5 + $tp / 2));
    $s[2] = sin($i + $end * (0.5 + $tp / 2));

    $x[0] = $ir * $c[0];
    $y[0] = $ir * $s[0];
    $x[5] = $ir * cos($i + $end);
    $y[5] = $ir * sin($i + $end);
    # ---treat vertices 1,4 special to match strait edge of face
    $x[1] = $x[0] + ($x[5] - $x[0]) * (0.5 - $tp / 2);
    $y[1] = $y[0] + ($y[5] - $y[0]) * (0.5 - $tp / 2);
    $x[4] = $x[0] + ($x[5] - $x[0]) * (0.5 + $tp / 2);
    $y[4] = $y[0] + ($y[5] - $y[0]) * (0.5 + $tp / 2);
    $x[2] = $or * cos($i + $end * (0.5 - $tip / 2));
    $y[2] = $or * sin($i + $end * (0.5 - $tip / 2));
    $x[3] = $or * cos($i + $end * (0.5 + $tip / 2));
    $y[3] = $or * sin($i + $end * (0.5 + $tip / 2));

    # draw face trapezoids as 2 tmesh
    glNormal3f(0.0, 0.0, 1.0);
    glBegin(GL_TRIANGLE_STRIP);
    glVertex3f($x[2], $y[2], $wd / 2);
    glVertex3f($x[1], $y[1], $wd / 2);
    glVertex3f($x[3], $y[3], $wd / 2);
    glVertex3f($x[4], $y[4], $wd / 2);
    glEnd();

    glNormal3f(0.0, 0.0, -1.0);
    glBegin(GL_TRIANGLE_STRIP);
    glVertex3f($x[2], $y[2], -$wd / 2);
    glVertex3f($x[1], $y[1], -$wd / 2);
    glVertex3f($x[3], $y[3], -$wd / 2);
    glVertex3f($x[4], $y[4], -$wd / 2);
    glEnd();

    # draw inside rim pieces
    glNormal3f($c[0], $s[0], 0.0);
    glBegin(GL_TRIANGLE_STRIP);
    glVertex3f($x[0], $y[0], -$wd / 2);
    glVertex3f($x[1], $y[1], -$wd / 2);
    glVertex3f($x[0], $y[0], $wd / 2);
    glVertex3f($x[1], $y[1], $wd / 2);
    glEnd();

    # draw up hill side
    {
      # calculate normal of face
      my $a = $x[2] - $x[1];
      my $b = $y[2] - $y[1];
      my $n = 1.0 / sqrt($a * $a + $b * $b);
      $a *= $n;
      $b *= $n;
      glNormal3f($b, -$a, 0.0);
    }
    glBegin(GL_TRIANGLE_STRIP);
    glVertex3f($x[1], $y[1], -$wd / 2);
    glVertex3f($x[2], $y[2], -$wd / 2);
    glVertex3f($x[1], $y[1], $wd / 2);
    glVertex3f($x[2], $y[2], $wd / 2);
    glEnd();
    # draw top of hill
    glNormal3f($c[1], $s[1], 0.0);
    glBegin(GL_TRIANGLE_STRIP);
    glVertex3f($x[2], $y[2], -$wd / 2);
    glVertex3f($x[3], $y[3], -$wd / 2);
    glVertex3f($x[2], $y[2], $wd / 2);
    glVertex3f($x[3], $y[3], $wd / 2);
    glEnd();

    # draw down hill side
    {
      # calculate normal of face
      my $a = $x[4] - $x[3];
      my $b = $y[4] - $y[3];
      my $c = 1.0 / sqrt($a * $a + $b * $b);
      $a *= $c;
      $b *= $c;
      glNormal3f($b, -$a, 0.0);
    }
    glBegin(GL_TRIANGLE_STRIP);
    glVertex3f($x[3], $y[3], -$wd / 2);
    glVertex3f($x[4], $y[4], -$wd / 2);
    glVertex3f($x[3], $y[3], $wd / 2);
    glVertex3f($x[4], $y[4], $wd / 2);
    glEnd();
    # inside rim part
    glNormal3f($c[2], $s[2], 0.0);
    glBegin(GL_TRIANGLE_STRIP);
    glVertex3f($x[4], $y[4], -$wd / 2);
    glVertex3f($x[5], $y[5], -$wd / 2);
    glVertex3f($x[4], $y[4], $wd / 2);
    glVertex3f($x[5], $y[5], $wd / 2);
    glEnd();
  }
}

sub flat_face {
  my ($ir, $or, $wd) = @_;
  my $i;
  my $w;

  # draw each face (top & bottom ) *
  printf("Face  : %f..%f wid=%f\n", $ir, $or, $wd) if ($poo);
  return if ($wd == 0.0);
  for ($w = $wd / 2; $w > -$wd; $w -= $wd) {
    if ($w > 0.0) {
      glNormal3f(0.0, 0.0, 1.0);
    }
    else {
      glNormal3f(0.0, 0.0, -1.0);
    }

    if ($ir == 0.0) {
      # draw as $t-fan
      glBegin(GL_TRIANGLE_FAN);
      glVertex3f(0.0, 0.0, $w);  # center
      glVertex3f($or, 0.0, $w);
      for ($i = 1; $i < $circle_subdiv; $i++) {
        glVertex3f(cos(2.0 * pi * $i / $circle_subdiv) * $or,
                   sin(2.0 * pi * $i / $circle_subdiv) * $or, $w);
      }
      glVertex3f($or, 0.0, $w);
      glEnd();
    }
    else {
      # draw as tmesh
      glBegin(GL_TRIANGLE_STRIP);
      glVertex3f($or, 0.0, $w);
      glVertex3f($ir, 0.0, $w);
      for ($i = 1; $i < $circle_subdiv; $i++) {
        glVertex3f(cos(2.0 * pi * $i / $circle_subdiv) * $or,
                   sin(2.0 * pi * $i / $circle_subdiv) * $or, $w);
        glVertex3f(cos(2.0 * pi * $i / $circle_subdiv) * $ir,
                   sin(2.0 * pi * $i / $circle_subdiv) * $ir, $w);
      }
      glVertex3f($or, 0.0, $w);
      glVertex3f($ir, 0.0, $w);
      glEnd();

    }
  }
}

sub draw_inside {
  my ($w1, $w2, $rad) = @_;

  printf("Inside: wid=%f..%f rad=%f\n", $w1, $w2, $rad) if ($poo);
  return if ($w1 == $w2);

  $w1 = $w1 / 2;
  $w2 = $w2 / 2;
  for (my $j = 0; $j < 2; $j++) {
    if ($j == 1) {
      $w1 = -$w1;
      $w2 = -$w2;
    }
    glBegin(GL_TRIANGLE_STRIP);
    glNormal3f(-1.0, 0.0, 0.0);
    glVertex3f($rad, 0.0, $w1);
    glVertex3f($rad, 0.0, $w2);
    for (my $i = 1; $i < $circle_subdiv; $i++) {
      my $c = cos(2.0 * pi * $i / $circle_subdiv);
      my $s = sin(2.0 * pi * $i / $circle_subdiv);
      glNormal3f(-$c, -$s, 0.0);
      glVertex3f($c * $rad,
        $s * $rad,
        $w1);
      glVertex3f($c * $rad,
        $s * $rad,
        $w2);
    }
    glNormal3f(-1.0, 0.0, 0.0);
    glVertex3f($rad, 0.0, $w1);
    glVertex3f($rad, 0.0, $w2);
    glEnd();
  }
}

sub draw_outside {
  my ($w1, $w2, $rad) = @_;
  printf("Outsid: wid=%f..%f rad=%f\n", $w1, $w2, $rad) if ($poo);
  return if ($w1 == $w2);

  $w1 = $w1 / 2;
  $w2 = $w2 / 2;
  for (my $j = 0; $j < 2; $j++) {
    if ($j == 1) {
      $w1 = -$w1;
      $w2 = -$w2;
    }
    glBegin(GL_TRIANGLE_STRIP);
    glNormal3f(1.0, 0.0, 0.0);
    glVertex3f($rad, 0.0, $w1);
    glVertex3f($rad, 0.0, $w2);
    for (my $i = 1; $i < $circle_subdiv; $i++) {
      my $c = cos(2.0 * pi * $i / $circle_subdiv);
      my $s = sin(2.0 * pi * $i / $circle_subdiv);
      glNormal3f($c, $s, 0.0);
      glVertex3f($c * $rad,
        $s * $rad,
        $w1);
      glVertex3f($c * $rad,
        $s * $rad,
        $w2);
    }
    glNormal3f(1.0, 0.0, 0.0);
    glVertex3f($rad, 0.0, $w1);
    glVertex3f($rad, 0.0, $w2);
    glEnd();
  }
}

my @gear_profile =
(0.000, 0.0,
  0.300, 7.0,
  0.340, 0.4,
  0.550, 0.64,
  0.600, 0.4,
  0.950, 1.0
);

my $a1 = 27.0;
my $a2 = 67.0;
my $a3 = 47.0;
my $a4 = 87.0;
my $i1 = 1.2;
my $i2 = 3.1;
my $i3 = 2.3;
my $i4 = 1.1;

sub oneFrame {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  glPushMatrix();
  glTranslatef(0.0, 0.0, -4.0);
  glRotatef($a3, 1.0, 1.0, 1.0);
  glRotatef($a4, 0.0, 0.0, -1.0);
  glTranslatef(0.14, 0.2, 0.0);
  gear(76, 0.4, 2.0, 1.1, 0.4, 0.04, @gear_profile);
  glPopMatrix();

  glPushMatrix();
  glTranslatef(0.1, 0.2, -3.8);
  glRotatef($a2, -4.0, 2.0, -1.0);
  glRotatef($a1, 1.0, -3.0, 1.0);
  glTranslatef(0.0, -0.2, 0.0);
  gear(36, 0.4, 2.0, 1.1, 0.7, 0.2, @gear_profile);
  glPopMatrix();

  $a1 += $i1;
  $a1 -= 360.0 if ($a1 > 360.0);
  $a1 -= 360.0 if ($a1 < 0.0);
  $a2 += $i2;
  $a2 -= 360.0 if ($a2 > 360.0);
  $a2 -= 360.0 if ($a2 < 0.0);
  $a3 += $i3;
  $a3 -= 360.0 if ($a3 > 360.0);
  $a3 -= 360.0 if ($a3 < 0.0);
  $a4 += $i4;
  $a4 -= 360.0 if ($a4 > 360.0);
  $a4 -= 360.0 if ($a4 < 0.0);
  if ($mode == GLUT_SINGLE) {
    glFlush();
  }
  else {
	w32gSwapBuffers();
  }
}

sub display {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

sub myReshape {
  my ($w, $h)= @_;
  glViewport(0, 0, $w, $h);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glFrustum(-1.0, 1.0, -1.0, 1.0, $d_near, $d_far);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

sub myinit {
  my @f;
  glClearColor(0.0, 0.0, 0.0, 0.0);
  myReshape(640, 480);
  # glShadeModel(GL_FLAT);
  glEnable(GL_DEPTH_TEST);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  glEnable(GL_LIGHTING);

  glLightf(GL_LIGHT0, GL_SHININESS, 1.0);
  $f[0] = 1.3;
  $f[1] = 1.3;
  $f[2] = -3.3;
  $f[3] = 1.0;
  glLightfv_p(GL_LIGHT0, GL_POSITION, @f);
  $f[0] = 0.8;
  $f[1] = 1.0;
  $f[2] = 0.83;
  $f[3] = 1.0;
  glLightfv_p(GL_LIGHT0, GL_SPECULAR, @f);
  glLightfv_p(GL_LIGHT0, GL_DIFFUSE, @f);
  glEnable(GL_LIGHT0);

  glLightf(GL_LIGHT1, GL_SHININESS, 1.0);
  $f[0] = -2.3;
  $f[1] = 0.3;
  $f[2] = -7.3;
  $f[3] = 1.0;
  glLightfv_p(GL_LIGHT1, GL_POSITION, @f);
  $f[0] = 1.0;
  $f[1] = 0.8;
  $f[2] = 0.93;
  $f[3] = 1.0;
  glLightfv_p(GL_LIGHT1, GL_SPECULAR, @f);
  glLightfv_p(GL_LIGHT1, GL_DIFFUSE, @f);
  glEnable(GL_LIGHT1);

  # gear material
  $f[0] = 0.1;
  $f[1] = 0.15;
  $f[2] = 0.2;
  $f[3] = 1.0;
  glMaterialfv_p(GL_FRONT_AND_BACK, GL_SPECULAR, @f);

  $f[0] = 0.9;
  $f[1] = 0.3;
  $f[2] = 0.3;
  $f[3] = 1.0;
  glMaterialfv_p(GL_FRONT_AND_BACK, GL_DIFFUSE, @f);

  $f[0] = 0.4;
  $f[1] = 0.9;
  $f[2] = 0.6;
  $f[3] = 1.0;
  glMaterialfv_p(GL_FRONT_AND_BACK, GL_AMBIENT, @f);

  glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, 4);
}

sub keyboard {
  my ($win, undef, $vkey) = @_;
  if ($vkey == VK_ESCAPE) {
	  return -1;
  }

  return;
}

my $mw = Win32::GUI::Window->new(
	-title     => "gears",
	-pos       => [100,100],
	-size      => [640,480],
	-pushstyle => WS_CLIPCHILDREN,  #stop flickering
	-onResize  => \&mainWinResize,
	-onKeyDown => \&keyboard,
);

my $glw = $mw->AddOpenGLFrame(
	-name    => 'oglwin',
	-width   => $mw->ScaleWidth(),
	-height  => $mw->ScaleHeight(),
	-doubleBuffer => ($mode == GLUT_SINGLE) ? 0 : 1,
	-depth   => 1,
	-init    => \&myinit,
	-display => \&display,
	-reshape => \&myReshape,
);

$mw->Show();
while(Win32::GUI::DoEvents() != -1) {
	oneFrame();
}
$mw->Hide();
exit(0);

sub mainWinResize {
	my $win = shift;

	$win->oglwin->Resize($win->ScaleWidth(), $win->ScaleHeight());

	return 0;
}
__END__
