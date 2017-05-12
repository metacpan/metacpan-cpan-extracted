#!perl -w
use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::OpenGLFrame qw(w32gSwapBuffers);
use OpenGL qw/ :all /;
use Math::Trig;

# program : glutmech V1.1
# author  : Simon Parkinson-Bates.
# E-mail  : sapb@yallara.cs.rmit.edu.au
# Copyright Simon Parkinson-Bates.
# "source if freely avaliable to anyone to copy as long as they
# acknowledge me in their work."
#
# Translated from C to Perl by J-L Morel (jl_morel@bribes.org)
# < http://www.bribes.org/perl/wopengl.html >
#
# Hacked to work with Win32::GUI::OpenGLFrame by Robert May
#
# Funtional features
# ------------------
# * online menu system avaliable by pressing left mouse button
# * online cascading help system avaliable, providing information on
#   the several  key strokes and what they do.
# * animation sequence coded which makes the mech walk through an
#   environment.  Shadows will soon be added to make it look
#   more realistic.
# * menu control to view mech in wireframe or sold mode.
# * various key strokes avaliable to control idependently the mechs
#   many joints.
# * various key strokes avaliable to view mech and environment from
#   different angles
# * various key strokes avaliable to alter positioning of the single
#   light source.

# Program features
# ----------------
# * uses double buffering
# * uses display lists
# * uses glut to manage windows, callbacks, and online menu.
# * uses glpolygonfill() to maintain colors in wireframe and solid mode.

# Win32::GUI Virtual Key constants
sub VK_ESCAPE() {27}
sub VK_PRIOR()  {33}
sub VK_LEFT()   {37}
sub VK_UP()     {38}
sub VK_RIGHT()  {39}
sub VK_DOWN()   {40}
sub CW_USEDEFAULT {0x80000000}

# start of display list definitions
use constant {
  SOLID_MECH_TORSO     => 1,
  SOLID_MECH_HIP       => 2,
  SOLID_MECH_SHOULDER  => 3,
  SOLID_MECH_UPPER_ARM => 4,
  SOLID_MECH_FOREARM   => 5,
  SOLID_MECH_UPPER_LEG => 6,
  SOLID_MECH_FOOT      => 7,
  SOLID_MECH_ROCKET    => 8,
  SOLID_MECH_VULCAN    => 9,
  SOLID_ENVIRO         => 10,
};
# end of display list definitions

# start of motion rate variables
use constant {
  ANKLE_RATE            => 3,
  HEEL_RATE             => 3,
  ROTATE_RATE           => 10,
  TILT_RATE             => 10,
  ELBOW_RATE            => 2,
  SHOULDER_RATE         => 5,
  LAT_RATE              => 5,
  CANNON_RATE           => 40,
  UPPER_LEG_RATE        => 3,
  UPPER_LEG_RATE_GROIN  => 10,
  LIGHT_TURN_RATE       => 10,
  VIEW_TURN_RATE        => 10,
};
# end of motion rate variables

# start of motion  variables

my $qobj;

my $leg = 0;
my $shoulder1 = 0;
my $shoulder2 = 0;
my $shoulder3 = 0;
my $shoulder4 = 0;
my $lat1 = 20;
my $lat2 = 20;
my $elbow1 = 0;
my $elbow2 = 0;
my $pivot = 0;
my $tilt = 10;
my $ankle1 = 0;
my $ankle2 = 0;
my $heel1 = 0;
my $heel2 = 0;
my $hip11 = 0;
my $hip12 = 10;
my $hip21 = 0;
my $hip22 = 10;
my $fire = 0;
my $solid_part = 1;
my $run_animation = 1;
my $anim = 0;
my $turn = 0;
my $turn1 = 0;
my $lightturn = 0;
my $lightturn1 = 0;

my $elevation = 0.0;
my $distance = 0.0;
my $frame = 3.0;
# end of motion variables

# start of material definitions

my @mat_specular = (0.628281, 0.555802, 0.366065, 1.0);
my @mat_ambient = (0.24725, 0.1995, 0.0745, 1.0);
my @mat_diffuse = (0.75164, 0.60648, 0.22648, 1.0);
my @mat_shininess = (128.0 * 0.4);

my @mat_specular2 = (0.508273, 0.508273, 0.508373, 1.0);
my @mat_ambient2 = (0.19225, 0.19225, 0.19225, 1.0);
my @mat_diffuse2 = (0.50754, 0.50754, 0.50754, 1.0);
my @mat_shininess2 = (128.0 * 0.6);

my @mat_specular3 = (0.296648, 0.296648, 0.296648, 1.0);
my @mat_ambient3 = (0.25, 0.20725, 0.20725, 1.0);
my @mat_diffuse3 = (1, 0.829, 0.829, 1.0);
my @mat_shininess3 = (128.0 * 0.088);

my @mat_specular4 = (0.633, 0.727811, 0.633, 1.0);
my @mat_ambient4 = (0.0215, 0.1745, 0.0215, 1.0);
my @mat_diffuse4 = (0.07568, 0.61424, 0.07568, 1.0);
my @mat_shininess4 = (128 * 0.6);

my @mat_specular5 = (0.60, 0.60, 0.50, 1.0);
my @mat_ambient5 = (0.0, 0.0, 0.0, 1.0);
my @mat_diffuse5 = (0.5, 0.5, 0.0, 1.0);
my @mat_shininess5 = (128.0 * 0.25);

# end of material definitions

# start of the body motion functions

sub Heel1Add {
  $heel1 = ($heel1 + HEEL_RATE) % 360;
}

sub Heel1Subtract {
  $heel1 = ($heel1 - HEEL_RATE) % 360;
}

sub Heel2Add {
  $heel2 = ($heel2 + HEEL_RATE) % 360;
}

sub Heel2Subtract {
  $heel2 = ($heel2 - HEEL_RATE) % 360;
}

sub Ankle1Add {
  $ankle1 = ($ankle1 + ANKLE_RATE) % 360;
}

sub Ankle1Subtract {
  $ankle1 = ($ankle1 - ANKLE_RATE) % 360;
}

sub Ankle2Add {
  $ankle2 = ($ankle2 + ANKLE_RATE) % 360;
}

sub Ankle2Subtract {
  $ankle2 = ($ankle2 - ANKLE_RATE) % 360;
}

sub RotateAdd {
  $pivot = ($pivot + ROTATE_RATE) % 360;
}

sub RotateSubtract {
  $pivot = ($pivot - ROTATE_RATE) % 360;
}

sub MechTiltSubtract {
  $tilt = ($tilt - TILT_RATE) % 360;
}

sub MechTiltAdd {
  $tilt = ($tilt + TILT_RATE) % 360;
}

sub elbow1Add {
  $elbow1 = ($elbow1 + ELBOW_RATE) % 360;
}

sub elbow1Subtract {
  $elbow1 = ($elbow1 - ELBOW_RATE) % 360;
}

sub elbow2Add {
  $elbow2 = ($elbow2 + ELBOW_RATE) % 360;
}

sub elbow2Subtract {
  $elbow2 = ($elbow2 - ELBOW_RATE) % 360;
}

sub shoulder1Add {
  $shoulder1 = ($shoulder1 + SHOULDER_RATE) % 360;
}

sub shoulder1Subtract {
  $shoulder1 = ($shoulder1 - SHOULDER_RATE) % 360;
}

sub shoulder2Add {
  $shoulder2 = ($shoulder2 + SHOULDER_RATE) % 360;
}

sub shoulder2Subtract {
  $shoulder2 = ($shoulder2 - SHOULDER_RATE) % 360;
}

sub shoulder3Add {
  $shoulder3 = ($shoulder3 + SHOULDER_RATE) % 360;
}

sub shoulder3Subtract {
  $shoulder3 = ($shoulder3 - SHOULDER_RATE) % 360;
}

sub shoulder4Add {
  $shoulder4 = ($shoulder4 + SHOULDER_RATE) % 360;
}

sub shoulder4Subtract {
  $shoulder4 = ($shoulder4 - SHOULDER_RATE) % 360;
}

sub lat1Raise {
  $lat1 = ($lat1 + LAT_RATE) % 360;
}

sub lat1Lower {
  $lat1 = ($lat1 - LAT_RATE) % 360;
}

sub lat2Raise {
  $lat2 = ($lat2 + LAT_RATE) % 360;
}

sub lat2Lower {
  $lat2 = ($lat2 - LAT_RATE) % 360;
}

sub FireCannon {
  $fire = ($fire + CANNON_RATE) % 360;
}

sub RaiseLeg1Forward {
  $hip11 = ($hip11 + UPPER_LEG_RATE) % 360;
}

sub LowerLeg1Backwards {
  $hip11 = ($hip11 - UPPER_LEG_RATE) % 360;
}

sub RaiseLeg1Outwards {
  $hip12 = ($hip12 + UPPER_LEG_RATE_GROIN) % 360;
}

sub LowerLeg1Inwards {
  $hip12 = ($hip12 - UPPER_LEG_RATE_GROIN) % 360;
}

sub RaiseLeg2Forward {
  $hip21 = ($hip21 + UPPER_LEG_RATE) % 360;
}

sub LowerLeg2Backwards {
  $hip21 = ($hip21 - UPPER_LEG_RATE) % 360;
}

sub RaiseLeg2Outwards {
  $hip22 = ($hip22 + UPPER_LEG_RATE_GROIN) % 360;
}

sub LowerLeg2Inwards {
  $hip22 = ($hip22 - UPPER_LEG_RATE_GROIN) % 360;
}

# end of body motion functions

# start of light source position functions

sub TurnRight {
  $turn = ($turn - VIEW_TURN_RATE) % 360;
}

sub TurnLeft {
  $turn = ($turn + VIEW_TURN_RATE) % 360;
}

sub TurnForwards {
  $turn1 = ($turn1 - VIEW_TURN_RATE) % 360;
}

sub TurnBackwards {
  $turn1 = ($turn1 + VIEW_TURN_RATE) % 360;
}

sub LightTurnRight {
  $lightturn = ($lightturn + LIGHT_TURN_RATE) % 360;
}

sub LightTurnLeft {
  $lightturn = ($lightturn - LIGHT_TURN_RATE) % 360;
}

sub LightForwards {
  $lightturn1 = ($lightturn1 + LIGHT_TURN_RATE) % 360;
}

sub LightBackwards {
  $lightturn1 = ($lightturn1 - LIGHT_TURN_RATE) % 360;
}

# end of light source position functions

# start of geometric shape functions

sub Box {
  my ($width, $height, $depth, $solid)= @_;
  my $i;
  my $j = 0;
  my $x = $width / 2.0;
  my $y = $height / 2.0;
  my $z = $depth / 2.0;

  for ($i = 0; $i < 4; $i++) {
    glRotatef(90.0, 0.0, 0.0, 1.0);
    if ($j) {
      if (!$solid) {
        glBegin(GL_LINE_LOOP);
      }
      else {
        glBegin(GL_QUADS);
      }
      glNormal3f(-1.0, 0.0, 0.0);
      glVertex3f(-$x, $y, $z);
      glVertex3f(-$x, -$y, $z);
      glVertex3f(-$x, -$y, -$z);
      glVertex3f(-$x, $y, -$z);
      glEnd();
      if ($solid) {
        glBegin(GL_TRIANGLES);
        glNormal3f(0.0, 0.0, 1.0);
        glVertex3f(0.0, 0.0, $z);
        glVertex3f(-$x, $y, $z);
        glVertex3f(-$x, -$y, $z);
        glNormal3f(0.0, 0.0, -1.0);
        glVertex3f(0.0, 0.0, -$z);
        glVertex3f(-$x, -$y, -$z);
        glVertex3f(-$x, $y, -$z);
        glEnd();
      }
      $j = 0;
    }
    else {
      if (!$solid) {
        glBegin(GL_LINE_LOOP);
      }
      else {
        glBegin(GL_QUADS);
      }
      glNormal3f(-1.0, 0.0, 0.0);
      glVertex3f(-$y, $x, $z);
      glVertex3f(-$y, -$x, $z);
      glVertex3f(-$y, -$x, -$z);
      glVertex3f(-$y, $x, -$z);
      glEnd();
      if ($solid) {
        glBegin(GL_TRIANGLES);
        glNormal3f(0.0, 0.0, 1.0);
        glVertex3f(0.0, 0.0, $z);
        glVertex3f(-$y, $x, $z);
        glVertex3f(-$y, -$x, $z);
        glNormal3f(0.0, 0.0, -1.0);
        glVertex3f(0.0, 0.0, -$z);
        glVertex3f(-$y, -$x, -$z);
        glVertex3f(-$y, $x, -$z);
        glEnd();
      }
      $j = 1;
    }
  }
}

sub Octagon {
  my ($side, $height, $solid) = @_;
  my $x = sin(0.785398163) * $side;
  my $y = $side / 2.0;
  my $z = $height / 2.0;
  my $c = $x + $y;
  for (my $j = 0; $j < 8; $j++) {
    glTranslatef(-$c, 0.0, 0.0);
    if (!$solid) {
      glBegin(GL_LINE_LOOP);
    }
    else {
      glBegin(GL_QUADS);
    }
    glNormal3f(-1.0, 0.0, 0.0);
    glVertex3f(0.0, -$y, $z);
    glVertex3f(0.0, $y, $z);
    glVertex3f(0.0, $y, -$z);
    glVertex3f(0.0, -$y, -$z);
    glEnd();
    glTranslatef($c, 0.0, 0.0);
    if ($solid) {
      glBegin(GL_TRIANGLES);
      glNormal3f(0.0, 0.0, 1.0);
      glVertex3f(0.0, 0.0, $z);
      glVertex3f(-$c, -$y, $z);
      glVertex3f(-$c, $y, $z);
      glNormal3f(0.0, 0.0, -1.0);
      glVertex3f(0.0, 0.0, -$z);
      glVertex3f(-$c, $y, -$z);
      glVertex3f(-$c, -$y, -$z);
      glEnd();
    }
    glRotatef(45.0, 0.0, 0.0, 1.0);
  }
}

# end of geometric shape functions

sub SetMaterial {
  my ($r_spec, $r_amb, $r_diff, $r_shin) = @_;
  glMaterialfv_p(GL_FRONT, GL_SPECULAR, @$r_spec);
  glMaterialfv_p(GL_FRONT, GL_SHININESS, @$r_shin);
  glMaterialfv_p(GL_FRONT, GL_AMBIENT, @$r_amb);
  glMaterialfv_p(GL_FRONT, GL_DIFFUSE, @$r_diff);
}

sub MechTorso {
  my $solid = shift;

  glNewList(SOLID_MECH_TORSO, GL_COMPILE);
  SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
  glColor3f(1.0, 1.0, 0.0);
  Box(1.0, 1.0, 3.0, $solid);
  glTranslatef(0.75, 0.0, 0.0);
  SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
  glColor3f(0.5, 0.5, 0.5);
  Box(0.5, 0.6, 2.0, $solid);
  glTranslatef(-1.5, 0.0, 0.0);
  Box(0.5, 0.6, 2.0, $solid);
  glTranslatef(0.75, 0.0, 0.0);
  glEndList();
}

sub MechHip {
  my $solid = shift;

  glNewList(SOLID_MECH_HIP, GL_COMPILE);
  SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
  glColor3f(1.0, 1.0, 0.0);
  Octagon(0.7, 0.5, $solid);
  for (my $i = 0; $i < 2; $i++) {
    glScalef(-1.0, 1.0, 1.0) if $i;
    glTranslatef(1.0, 0.0, 0.0);
    SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
    glColor3f(0.5, 0.5, 0.5);
    gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
    gluSphere($qobj, 0.2, 16, 16);
    glTranslatef(-1.0, 0.0, 0.0);
  }
  glScalef(-1.0, 1.0, 1.0);
  glEndList();
}

sub Shoulder {
  my $solid = shift;

  glNewList(SOLID_MECH_SHOULDER, GL_COMPILE);
  SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
  glColor3f(1.0, 1.0, 0.0);
  Box(1.0, 0.5, 0.5, $solid);
  glTranslatef(0.9, 0.0, 0.0);
  SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
  glColor3f(0.5, 0.5, 0.5);
  gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
  gluSphere($qobj, 0.6, 16, 16);
  glTranslatef(-0.9, 0.0, 0.0);
  glEndList();
}

sub UpperArm {
  my $solid = shift;

  glNewList(SOLID_MECH_UPPER_ARM, GL_COMPILE);
  SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
  glColor3f(1.0, 1.0, 0.0);
  Box(1.0, 2.0, 1.0, $solid);
  glTranslatef(0.0, -0.95, 0.0);
  glRotatef(90.0, 1.0, 0.0, 0.0);
  SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
  glColor3f(0.5, 0.5, 0.5);
  gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
  gluCylinder($qobj, 0.4, 0.4, 1.5, 16, 10);
  SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
  glColor3f(1.0, 1.0, 0.0);
  glRotatef(-90.0, 1.0, 0.0, 0.0);
  glTranslatef(-0.4, -1.85, 0.0);
  glRotatef(90.0, 0.0, 1.0, 0.0);
  for (my $i = 0; $i < 2; $i++) {
    gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
    if ($i) {
      gluCylinder($qobj, 0.5, 0.5, 0.8, 16, 10);
    }
    else {
      gluCylinder($qobj, 0.2, 0.2, 0.8, 16, 10);
    }
  }
  for (my $i = 0; $i < 2; $i++) {
    glScalef(-1.0, 1.0, 1.0) if $i;
    gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
    glTranslatef(0.0, 0.0, 0.8) if $i;
    gluDisk($qobj, 0.2, 0.5, 16, 10);
    glTranslatef(0.0, 0.0, -0.8) if $i;
  }
  glScalef(-1.0, 1.0, 1.0);
  glRotatef(-90.0, 0.0, 1.0, 0.0);
  glTranslatef(0.4, 2.9, 0.0);
  glEndList();
}

sub VulcanGun {
  my $solid = shift;

  glNewList(SOLID_MECH_VULCAN, GL_COMPILE);
  SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
  glColor3f(0.5, 0.5, 0.5);
  gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
  gluCylinder($qobj, 0.5, 0.5, 0.5, 16, 10);
  glTranslatef(0.0, 0.0, 0.5);
  gluDisk($qobj, 0.0, 0.5, 16, 10);

  for (my $i = 0; $i < 5; $i++) {
    glRotatef(72.0, 0.0, 0.0, 1.0);
    glTranslatef(0.0, 0.3, 0.0);
    gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
    gluCylinder($qobj, 0.15, 0.15, 2.0, 16, 10);
    gluCylinder($qobj, 0.06, 0.06, 2.0, 16, 10);
    glTranslatef(0.0, 0.0, 2.0);
    gluDisk($qobj, 0.1, 0.15, 16, 10);
    gluCylinder($qobj, 0.1, 0.1, 0.1, 16, 5);
    glTranslatef(0.0, 0.0, 0.1);
    gluDisk($qobj, 0.06, 0.1, 16, 5);
    glTranslatef(0.0, -0.3, -2.1);
  }
  glEndList();
}

sub ForeArm {
  my $solid = shift;

  glNewList(SOLID_MECH_FOREARM, GL_COMPILE);
  SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
  glColor3f(1.0, 1.0, 0.0);
  for (my $i = 0; $i < 5; $i++) {
    glTranslatef(0.0, -0.1, -0.15);
    Box(0.6, 0.8, 0.2, $solid);
    glTranslatef(0.0, 0.1, -0.15);
    Box(0.4, 0.6, 0.1, $solid);
  }
  glTranslatef(0.0, 0.0, 2.45);
  Box(1.0, 1.0, 2.0, $solid);
  glTranslatef(0.0, 0.0, -1.0);
  glEndList();
}

sub UpperLeg {
  my $solid = shift;

  glNewList(SOLID_MECH_UPPER_LEG, GL_COMPILE);
  SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
  glColor3f(1.0, 1.0, 0.0);
  gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
  glTranslatef(0.0, -1.0, 0.0);
  Box(0.4, 1.0, 0.7, $solid);
  glTranslatef(0.0, -0.65, 0.0);
  for (my $i = 0; $i < 5; $i++) {
    Box(1.2, 0.3, 1.2, $solid);
    glTranslatef(0.0, -0.2, 0.0);
    Box(1.0, 0.1, 1.0, $solid);
    glTranslatef(0.0, -0.2, 0.0);
  }
  glTranslatef(0.0, -0.15, -0.4);
  Box(2.0, 0.5, 2.0, $solid);
  glTranslatef(0.0, -0.3, -0.2);
  glRotatef(90.0, 1.0, 0.0, 0.0);
  SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
  glColor3f(0.5, 0.5, 0.5);
  gluCylinder($qobj, 0.6, 0.6, 3.0, 16, 10);
  SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
  glColor3f(1.0, 1.0, 0.0);
  glRotatef(-90.0, 1.0, 0.0, 0.0);
  glTranslatef(0.0, -1.5, 1.0);
  Box(1.5, 3.0, 0.5, $solid);
  glTranslatef(0.0, -1.75, -0.8);
  Box(2.0, 0.5, 2.0, $solid);
  glTranslatef(0.0, -0.9, -0.85);
  SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
  glColor3f(0.5, 0.5, 0.5);
  gluCylinder($qobj, 0.8, 0.8, 1.8, 16, 10);
  for (my $i = 0; $i < 2; $i++) {
    glScalef(-1.0, 1.0, 1.0) if $i;
    gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
    glTranslatef(0.0, 0.0, 1.8) if $i;
    gluDisk($qobj, 0.0, 0.8, 16, 10);
    glTranslatef(0.0, 0.0, -1.8) if $i;
  }
  glScalef(-1.0, 1.0, 1.0);
  glEndList();
}

sub Foot {
  my $solid = shift;

  glNewList(SOLID_MECH_FOOT, GL_COMPILE);
  SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
  glColor3f(0.5, 0.5, 0.5);
  glRotatef(90.0, 1.0, 0.0, 0.0);
  Octagon(1.5, 0.6, $solid);
  glRotatef(-90.0, 1.0, 0.0, 0.0);
  glEndList();
}

sub LowerLeg {
  my $solid = shift;

  SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
  glColor3f(1.0, 1.0, 0.0);
  for (my $k = 0.0; $k < 2.0; $k++) {
    for (my $l = 0.0; $l < 2.0; $l++) {
      glPushMatrix();
      glTranslatef($k, 0.0, $l);
      SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
      glColor3f(1.0, 1.0, 0.0);
      Box(1.0, 0.5, 1.0, $solid);
      glTranslatef(0.0, -0.45, 0.0);
      SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
      glColor3f(0.5, 0.5, 0.5);
      if (!$solid) {
        glutWireSphere(0.2, 16, 10);
      }
      else {
        glutSolidSphere(0.2, 16, 10);
      }
      if ($leg) {
        glRotatef($heel1, 1.0, 0.0, 0.0);
      }
      else {
        glRotatef($heel2, 1.0, 0.0, 0.0);
      }
      glTranslatef(0.0, -1.7, 0.0);
      SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
      glColor3f(1.0, 1.0, 0.0);
      Box(0.25, 3.0, 0.25, $solid);
      glTranslatef(0.0, -1.7, 0.0);
      SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
      glColor3f(0.5, 0.5, 0.5);
      if (!$solid) {
        glutWireSphere(0.2, 16, 10);
      }
      else {
        glutSolidSphere(0.2, 16, 10);
      }
      if ($leg) {
        glRotatef(- $heel1, 1.0, 0.0, 0.0);
      }
      else {
        glRotatef(- $heel2, 1.0, 0.0, 0.0);
      }
      glTranslatef(0.0, -0.45, 0.0);
      SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
      glColor3f(1.0, 1.0, 0.0);
      Box(1.0, 0.5, 1.0, $solid);
      if (!$k && !$l) {
        glTranslatef(-0.4, -0.8, 0.5);
        if ($leg) {
          glRotatef($ankle1, 1.0, 0.0, 0.0);
        }
        else {
          glRotatef($ankle2, 1.0, 0.0, 0.0);
        }
        glRotatef(90.0, 0.0, 1.0, 0.0);
        gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
        gluCylinder($qobj, 0.8, 0.8, 1.8, 16, 10);
        for (my $j = 0; $j < 2; $j++) {
          gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
          if ($j) {
            glScalef(-1.0, 1.0, 1.0);
            glTranslatef(0.0, 0.0, 1.8);
          }
          gluDisk($qobj, 0.0, 0.8, 16, 10);
          glTranslatef(0.0, 0.0, -1.8) if $j;
        }
        glScalef(-1.0, 1.0, 1.0);
        glRotatef(-90.0, 0.0, 1.0, 0.0);
        glTranslatef(0.95, -0.8, 0.0);
        glCallList(SOLID_MECH_FOOT);
      }
      glPopMatrix();
    }
  }
}

sub RocketPod {
  my $solid = shift;
  my $k = 0;

  glNewList(SOLID_MECH_ROCKET, GL_COMPILE);
  SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
  glColor3f(0.5, 0.5, 0.5);
  glScalef(0.4, 0.4, 0.4);
  glRotatef(45.0, 0.0, 0.0, 1.0);
  glTranslatef(1.0, 0.0, 0.0);
  Box(2.0, 0.5, 3.0, $solid);
  glTranslatef(1.0, 0.0, 0.0);
  glRotatef(45.0, 0.0, 0.0, 1.0);
  glTranslatef(0.5, 0.0, 0.0);
  Box(1.2, 0.5, 3.0, $solid);
  glTranslatef(2.1, 0.0, 0.0);
  glRotatef(-90.0, 0.0, 0.0, 1.0);
  SetMaterial(\@mat_specular, \@mat_ambient, \@mat_diffuse, \@mat_shininess);
  glColor3f(1.0, 1.0, 0.0);
  Box(2.0, 3.0, 4.0, $solid);
  glTranslatef(-0.5, -1.0, 1.3);
  for (my $i = 0; $i < 2; $i++) {
    for (my $j = 0; $j < 3; $j++) {
      gluQuadricDrawStyle($qobj, GLU_LINE) if (!$solid);
      glTranslatef($i, $j, 0.6);
      SetMaterial(\@mat_specular3, \@mat_ambient3, \@mat_diffuse3, \@mat_shininess3);
      glColor3f(1.0, 1.0, 1.0);
      gluCylinder($qobj, 0.4, 0.4, 0.3, 16, 10);
      glTranslatef(0.0, 0.0, 0.3);
      SetMaterial(\@mat_specular4, \@mat_ambient4, \@mat_diffuse4, \@mat_shininess4);
      glColor3f(0.0, 1.0, 0.0);
      gluCylinder($qobj, 0.4, 0.0, 0.5, 16, 10);
      $k++;
      glTranslatef(-$i, -$j, -0.9);
    }
  }
  glEndList();
}

sub Enviro {
  my $solid = shift;

  glNewList(SOLID_ENVIRO, GL_COMPILE);
  SetMaterial(\@mat_specular4, \@mat_ambient4, \@mat_diffuse4, \@mat_shininess4);
  glColor3f(0.0, 1.0, 0.0);
  Box(20.0, 0.5, 30.0, $solid);
  SetMaterial(\@mat_specular4, \@mat_ambient3, \@mat_diffuse2, \@mat_shininess);
  glColor3f(0.6, 0.6, 0.6);
  glTranslatef(0.0, 0.0, -10.0);
  for (my $j = 0; $j < 6; $j++) {
    for (my $i = 0; $i < 2; $i++) {
      glScalef(-1.0, 1.0, 1.0) if $i;
      glTranslatef(10.0, 4.0, 0.0);
      Box(4.0, 8.0, 2.0, $solid);
      glTranslatef(0.0, -1.0, -3.0);
      Box(4.0, 6.0, 2.0, $solid);
      glTranslatef(-10.0, -3.0, 3.0);
    }
    glScalef(-1.0, 1.0, 1.0);
    glTranslatef(0.0, 0.0, 5.0);
  }
  glEndList();
}

sub disable {
  glDisable(GL_LIGHTING);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_NORMALIZE);
  glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
}

sub lighting {
  my @position = (0.0, 0.0, 2.0, 1.0);

  glRotatef($lightturn1, 1.0, 0.0, 0.0);
  glRotatef($lightturn, 0.0, 1.0, 0.0);
  glRotatef(0.0, 1.0, 0.0, 0.0);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_NORMALIZE);
  glDepthFunc(GL_LESS);
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

  glLightfv_p(GL_LIGHT0, GL_POSITION, @position);
  glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 80.0);

  glTranslatef(0.0, 0.0, 2.0);
  glDisable(GL_LIGHTING);
  Box(0.1, 0.1, 0.1, 0);
  glEnable(GL_LIGHTING);
}

sub DrawMech {
  glScalef(0.5, 0.5, 0.5);
  glPushMatrix();
  glTranslatef(0.0, -0.75, 0.0);
  glRotatef($tilt, 1.0, 0.0, 0.0);

  glRotatef(90.0, 1.0, 0.0, 0.0);
  glCallList(SOLID_MECH_HIP);
  glRotatef(-90.0, 1.0, 0.0, 0.0);

  glTranslatef(0.0, 0.75, 0.0);
  glPushMatrix();
  glRotatef($pivot, 0.0, 1.0, 0.0);
  glPushMatrix();
  glCallList(SOLID_MECH_TORSO);
  glPopMatrix();
  glPushMatrix();
  glTranslatef(0.5, 0.5, 0.0);
  glCallList(SOLID_MECH_ROCKET);
  glPopMatrix();
  for (my $i = 0; $i < 2; $i++) {
    glPushMatrix();
    glScalef(-1.0, 1.0, 1.0) if $i;
    glTranslatef(1.5, 0.0, 0.0);
    glCallList(SOLID_MECH_SHOULDER);
    glTranslatef(0.9, 0.0, 0.0);
    if ($i) {
      glRotatef($lat1, 0.0, 0.0, 1.0);
      glRotatef($shoulder1, 1.0, 0.0, 0.0);
      glRotatef($shoulder3, 0.0, 1.0, 0.0);
    } else {
      glRotatef($lat2, 0.0, 0.0, 1.0);
      glRotatef($shoulder2, 1.0, 0.0, 0.0);
      glRotatef($shoulder4, 0.0, 1.0, 0.0);
    }
    glTranslatef(0.0, -1.4, 0.0);
    glCallList(SOLID_MECH_UPPER_ARM);
    glTranslatef(0.0, -2.9, 0.0);
    if ($i) {
      glRotatef($elbow1, 1.0, 0.0, 0.0);
    }
    else {
      glRotatef($elbow2, 1.0, 0.0, 0.0);
    }
    glTranslatef(0.0, -0.9, -0.2);
    glCallList(SOLID_MECH_FOREARM);
    glPushMatrix();
    glTranslatef(0.0, 0.0, 2.0);
    glRotatef($fire, 0.0, 0.0, 1.0);
    glCallList(SOLID_MECH_VULCAN);
    glPopMatrix();
    glPopMatrix();
  }
  glPopMatrix();

  glPopMatrix();

  for (my $j = 0; $j < 2; $j++) {
    glPushMatrix();
    if ($j) {
      glScalef(-0.5, 0.5, 0.5);
      $leg = 1;
    }
    else {
      glScalef(0.5, 0.5, 0.5);
      $leg = 0;
    }
    glTranslatef(2.0, -1.5, 0.0);
    if ($j) {
      glRotatef($hip11, 1.0, 0.0, 0.0);
      glRotatef($hip12, 0.0, 0.0, 1.0);
    }
    else {
      glRotatef($hip21, 1.0, 0.0, 0.0);
      glRotatef($hip22, 0.0, 0.0, 1.0);
    }
    glTranslatef(0.0, 0.3, 0.0);
    glPushMatrix();
    glCallList(SOLID_MECH_UPPER_LEG);
    glPopMatrix();
    glTranslatef(0.0, -8.3, -0.4);
    if ($j) {
      glRotatef(- $hip12, 0.0, 0.0, 1.0);
    }
    else {
      glRotatef(- $hip22, 0.0, 0.0, 1.0);
    }
    glTranslatef(-0.5, -0.85, -0.5);
    LowerLeg(1);
    glPopMatrix();
  }
}

sub display {
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glEnable(GL_DEPTH_TEST);

  glPushMatrix();
  glRotatef($turn, 0.0, 1.0, 0.0);
  glRotatef($turn1, 1.0, 0.0, 0.0);
  if ($solid_part) {
    glPushMatrix();
    lighting();
    glPopMatrix();
  }
  else {
    disable();
  }

  glPushMatrix();
  glTranslatef(0.0, $elevation, 0.0);
  DrawMech();
  glPopMatrix();

  glPushMatrix();
  $distance = 0.0 if $distance >= 20.136;
  glTranslatef(0.0, -5.0, -$distance);
  glCallList(SOLID_ENVIRO);
  glTranslatef(0.0, 0.0, 10.0);
  glCallList(SOLID_ENVIRO);
  glPopMatrix();
  glPopMatrix();
  glFlush();
  w32gSwapBuffers();
}

sub myinit {
  my $i = 1;

  glutInit();

  $qobj = gluNewQuadric();
  SetMaterial(\@mat_specular2, \@mat_ambient2, \@mat_diffuse2, \@mat_shininess2);
  glEnable(GL_DEPTH_TEST);
  MechTorso($i);
  MechHip($i);
  Shoulder($i);
  RocketPod($i);
  UpperArm($i);
  ForeArm($i);
  UpperLeg($i);
  Foot($i);
  VulcanGun($i);
  Enviro($i);
}

sub myReshape {
  my ($w, $h) = @_;

  glViewport(0, 0, $w, $h);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(65.0, $h?$w/$h:0, 1.0, 20.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glTranslatef(0.0, 1.2, -5.5);  # viewing transform
}

my $step=0;
sub animation_walk {
  my $angle;

  if ($step == 0 || $step == 2) {
    if ($frame >= 0.0 && $frame <= 21.0) {
      $frame = 3.0 if $frame == 0.0;
      $angle = (180 / pi) * (acos(((cos((pi / 180) * $frame) * 2.043) + 1.1625) / 3.2059));
      if ($frame > 0) {
        $elevation = -(3.2055 - (cos((pi / 180) * $angle) * 3.2055));
      }
      else {
        $elevation = 0.0;
      }
      if ($step == 0) {
        $hip11 = -($frame * 1.7);
        $heel1 = $frame * 1.7 if (1.7 * $frame > 15);
        $heel2 = 0;
        $ankle1 = $frame * 1.7;
        if ($frame > 0) {
          $hip21 = $angle;
        }
        else {
          $hip21 = 0;
        }
        $ankle2 = -$hip21;
        $shoulder1 = $frame * 1.5;
        $shoulder2 = -$frame * 1.5;
        $elbow1 = $frame;
        $elbow2 = -$frame;
      }
      else {
        $hip21 = -($frame * 1.7);
        $heel2 = $frame * 1.7 if 1.7 * $frame > 15;
        $heel1 = 0;
        $ankle2 = $frame * 1.7;
        if ($frame > 0) {
          $hip11 = $angle;
        }
        else {
          $hip11 = 0;
        }
        $ankle1 = -$hip11;
        $shoulder1 = -$frame * 1.5;
        $shoulder2 = $frame * 1.5;
        $elbow1 = -$frame;
        $elbow2 = $frame;
      }

      $step++ if $frame == 21;
      $frame = $frame + 3.0 if $frame < 21;
    }
  }
  if ($step == 1 || $step == 3) {
    if ($frame <= 21.0 && $frame >= 0.0) {
      $angle = (180 / pi) * (acos(((cos((pi / 180) * $frame) * 2.043) + 1.1625) / 3.2029));
      if ($frame > 0) {
        $elevation = -(3.2055 - (cos((pi / 180) * $angle) * 3.2055));
      }
      else {
        $elevation = 0.0;
      }
      if ($step == 1) {
        $elbow2 = $hip11 = -$frame;
        $elbow1 = $heel1 = $frame;
        $heel2 = 15;
        $ankle1 = $frame;
        if ($frame > 0) {
          $hip21 = $angle;
        }
        else {
          $hip21 = 0;
        }
        $ankle2 = -$hip21;
        $shoulder1 = 1.5 * $frame;
        $shoulder2 = -$frame * 1.5;
      }
      else {
        $elbow1 = $hip21 = -$frame;
        $elbow2 = $heel2 = $frame;
        $heel1 = 15;
        $ankle2 = $frame;
        if ($frame > 0) {
          $hip11 = $angle;
        }
        else {
          $hip11 = 0;
        }
        $ankle1 = -$hip11;
        $shoulder1 = -$frame * 1.5;
        $shoulder2 = $frame * 1.5;
      }
      $step++ if $frame == 0.0;
      $frame = $frame - 3.0 if $frame > 0;
    }
  }
  $step = 0 if $step == 4;
  $distance += 0.1678;
}

sub animation {
  animation_walk();
}

# Keyboard handlers:
sub KeyDown {
  my ($win, undef, $vkey) = @_;
  if ($vkey == VK_RIGHT) {
    TurnRight();
  }
  elsif ($vkey == VK_LEFT) {
    TurnLeft();
  }
  elsif ($vkey == VK_DOWN) {
    TurnForwards();
  }
  elsif ($vkey == VK_UP) {
    TurnBackwards();
  }
      # end of view postions functions

      # start of miseclleneous functions
  elsif ($vkey == VK_PRIOR) {
    FireCannon();
  }
      # end of miscelleneous functions */
  else {return}

  $win->oglwin->InvalidateRect(0);
  return;
}

sub Char {
  my ($win, undef, $char) = @_;
  for (chr $char) {
        # start arm control functions
    if    (/q/)  {shoulder2Subtract()}
    elsif (/a/)  {shoulder2Add()}
    elsif (/w/)  {shoulder1Subtract()}
    elsif (/s/)  {shoulder1Add()}
    elsif (/2/)  {shoulder3Add()}
    elsif (/1/)  {shoulder4Add()}
    elsif (/4/)  {shoulder3Subtract()}
    elsif (/3/)  {shoulder4Subtract()}
    elsif (/z/)  {lat2Raise()}
    elsif (/Z/)  {lat2Lower()}
    elsif (/x/)  {lat1Raise()}
    elsif (/X/)  {lat1Lower()}
    elsif (/A/)  {elbow2Add()}
    elsif (/Q/)  {elbow2Subtract()}
    elsif (/S/)  {elbow1Add()}
    elsif (/W/)  {elbow1Subtract()}
        # end of arm control functions

        # start of torso control functions
    elsif (/d/)  {RotateAdd()}
    elsif (/g/)  {RotateSubtract()}
    elsif (/r/)  {MechTiltAdd()}
    elsif (/f/)  {MechTiltSubtract()}
        # end of torso control functions

        # start of leg control functions
    elsif (/h/)  {RaiseLeg2Forward()}
    elsif (/y/)  {LowerLeg2Backwards()}
    elsif (/Y/)  {RaiseLeg2Outwards()}
    elsif (/H/)  {LowerLeg2Inwards()}
    elsif (/j/)  {RaiseLeg1Forward()}
    elsif (/u/)  {LowerLeg1Backwards()}
    elsif (/U/)  {RaiseLeg1Outwards()}
    elsif (/J/)  {LowerLeg1Inwards()}
    elsif (/N/)  {Heel2Add()}
    elsif (/n/)  {Heel2Subtract()}
    elsif (/M/)  {Heel1Add()}
    elsif (/m/)  {Heel1Subtract()}
    elsif (/k/)  {Ankle2Add()}
    elsif (/K/)  {Ankle2Subtract()}
    elsif (/l/)  {Ankle1Add()}
    elsif (/L/)  {Ankle1Subtract()}
        # end of leg control functions

        # start of light source position functions
    elsif (/p/)  {LightTurnRight()}
    elsif (/i/)  {LightTurnLeft()}
    elsif (/o/)  {LightForwards()}
    elsif (/9/)  {LightBackwards()}
        # end of light source position functions

    else         {return}     # default
  }

  $win->oglwin->InvalidateRect(0);
  return;
}

sub showInstructions {

  my $win;
  $win = Win32::GUI::Window->new(
    -title       => "Instructions for glutmech",
    -left        => CW_USEDEFAULT,
    -size        => [230,300],
    -onResize    => sub { $_[0]->TE->Resize($_[0]->ScaleWidth(), $_[0]->ScaleHeight()); return;},
    -onTerminate => sub { undef $win; 0; },
  );

  $win->AddRichEdit(
    -name        => 'TE',
    -vscroll     => 1,
    -autohscroll => 0,
    -readonly    => 1,
    -background  => 0xFFFFFF,
  );

  $win->TE->Text(<<INST);
Start and stop the animated walking, and turn on and off Wireframe mode from the Options menu.

Change the position of parts of the robot using the following keys:

  move the arms..
    at the shoulders?
      forward\tq,w
      backwards\ta,s
      outwards\tz,x
      inwards\tZ,X
    at the elbows?
      upwards\tQ,W
      downwards\tA,S
      outwards\t1,2
      inwards\t3,4

  move the legs..
    at the hip?
      forward\ty,u
      backwards\th.j
      outwards\tY,U
      inwards\tH,J
    at the knees?
      forward\tn,m
      backwards\tN,M
    at the ankles?
      toes up\tK,L
      toes down\tk,l

  move the torso..
    turn left\td
    turn right\tg

  move the hip..
    tilt backwards\tf
    tilt forwards\tr

Other keystrokes can be used to:

  fire the vulcan guns..
    \tPage-up

  rotate the scene..
    right\tright arrow
    left\tleft arrow
    down\tup arrow
    up\tdown arrow

  rotate the light source..
    right\tp
    left\ti
    up\t9
    down\to
INST

  $win->Show();
  return;
}

# Show an About Box:
sub showAbout {
  my $parent = shift;
  my $win = Win32::GUI::Window->new(
    -parent      => $parent,
    -title       => "About glutmech ...",
    -size        => [300,180],
    -maximizebox => 0,
    -minimizebox => 0,
    -resizeable  => 0,
    -dialogui    => 1,
  );

  my $text1 = "glutmech V1.1\r\n";
  $text1   .= "\r\n"; 
  $text1   .= "Author  : Simon Parkinson-Bates.\r\n";
  $text1   .= "Copyright Simon Parkinson-Bates.";

  my $text2 = "Translated from C to Perl by J-L Morel.\r\n";
  $text2   .= "Adapted to Win32::GUI::OpenGLFrame by Robert May.";

  $win->AddLabel(
    -text => $text1,
    -align => 'center',
    -pos    => [10,10],
    -width  => $win->ScaleWidth()-20,
    -height => 70,
  );
  $win->AddLabel(
    -text   => $text2,
    -align  => 'left',
    -pos    => [10,80],
    -width  => $win->ScaleWidth()-20,
    -height => 30,
  );
  $win->AddButton(
    -text    => 'Ok',
    -width   => 50,
    -left    => $win->ScaleWidth()-60,
    -top     => $win->ScaleHeight()-30,
    -default => 1,
    -ok      => 1,
    -onClick => sub {-1},
  );

  $win->Center($parent);
  $win->Show();
  $win->DoModal();
  $win->Hide();
  undef $win;
  return;
}

# start of Win32::GUI menus
my $menu;
$menu = Win32::GUI::Menu->new(
  "File"              =>            "File",
  ">Exit"             => { -name => "Exit",      -onClick => sub {-1} },
  "Options"           =>            "Options",
  ">Walk"             => { -name => "Walk",      -checked => 1,
                           -onClick => sub {$run_animation = !$run_animation;
                                            $menu->{Walk}->Checked($run_animation);
                                            $_[0]->oglwin->InvalidateRect(0);} },
  ">Wireframe"        => { -name => "Wireframe",
                           -onClick => sub {$solid_part = !$solid_part;
                                            $menu->{Wireframe}->Checked(!$solid_part);
                                            $_[0]->oglwin->InvalidateRect(0);} },
  "Help"              =>            "Help",
  ">Instructions ..." => { -name => "Instr",     -onClick => \&showInstructions, },
  ">About"            => { -name => "About",     -onClick => \&showAbout, },
);
# end of Win32::GUI menus

# start of Win32::GUI windowing and control functions

my $mw = Win32::GUI::Window->new(
  -title     => "Vulcan Gunner - Win32::GUI port",
  -left      => CW_USEDEFAULT,
  -size      => [800,600],
  -pushstyle => WS_CLIPCHILDREN,  # stop flickering
  -menu      => $menu,
  -onResize  => sub { $_[0]->oglwin->Resize($_[0]->ScaleWidth(), $_[0]->ScaleHeight()) },
  -onKeyDown => \&KeyDown,
  -onChar    => \&Char,
);

my $glw = $mw->AddOpenGLFrame(
  -name    => 'oglwin',
  -width   => $mw->ScaleWidth(),
  -height  => $mw->ScaleHeight(),
  -doubleBuffer => 1,
  -depth   => 1,
  -init    => \&myinit,
  -display => \&display,
  -reshape => \&myReshape,
);

$mw->Show();
while(Win32::GUI::DoEvents() != -1) {
  if($run_animation) {
    animation();
    $glw->InvalidateRect(0);
  } else {
    Win32::GUI::WaitMessage();
  }
}
$mw->Hide();
undef $mw;
exit(0);
__END__
