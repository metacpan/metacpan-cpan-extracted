#!/usr/bin/perl -w
use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN WS_OVERLAPPEDWINDOW WS_POPUPWINDOW);
use Win32::GUI::OpenGLFrame();
use OpenGL qw/ :all /;
use Math::Trig;

print "<ESC> to exit\n";
sleep(2);

# noof.c
# A demo included with GLUT;
# Author: Mark Kilgard <mjk@nvidia.com>
#
# Translated from C to Perl by J-L Morel <jl_morel@bribes.org>
# ( http://www.bribes.org/perl/wopengl.html )
#
# Modified to use Win32::GUI::OpenGLFrame by Robert May

# Win32::GUI Virtual Key constants
sub VK_ESCAPE() {27}

# XXX Very crufty code follows.

# --- shape parameters def'n ---

use constant N_SHAPES => 7;

my @pos;
my @dir;
my @acc;
my @col;
my @hsv;
my @hpr;
my @ang;
my @spn;
my @sca;
my @geep;
my @peep;
my @speedsq;
my @blad;

my ($ht, $wd);

sub initshapes {
  my $i = shift;
  my $f;

  # random init of $pos, $dir, $color
  for (my $k = $i * 3; $k <= $i * 3 + 2; $k++) {
    $f = rand();
    $pos[$k] = $f;
    $f = rand();
    $f = ($f - 0.5) * 0.05;
    $dir[$k] = $f;
    $f = rand();
    $f = ($f - 0.5) * 0.0002;
    $acc[$k] = $f;
    $f = rand();
    $col[$k] = $f;
  }

  $speedsq[$i] = $dir[$i * 3] * $dir[$i * 3] + $dir[$i * 3 + 1] * $dir[$i * 3 + 1];
  $f = rand();
  $blad[$i] = 2 + int($f * 17.0);
  $f = rand();
  $ang[$i] = $f;
  $f = rand();
  $spn[$i] = ($f - 0.5) * 40.0 / (10 + $blad[$i]);
  $f = rand();
  $sca[$i] = ($f * 0.1 + 0.08);
  $dir[$i * 3] *= $sca[$i];
  $dir[$i * 3 + 1] *= $sca[$i];

  $f = rand();
  $hsv[$i * 3] = $f * 360.0;

  $f = rand();
  $hsv[$i * 3 + 1] = $f * 0.6 + 0.4;

  $f = rand();
  $hsv[$i * 3 + 2] = $f * 0.7 + 0.3;

  $f = rand();
  $hpr[$i * 3] = $f * 0.005 * 360.0;
  $f = rand();
  $hpr[$i * 3 + 1] = $f * 0.03;
  $f = rand();
  $hpr[$i * 3 + 2] = $f * 0.02;

  $geep[$i] = 0;
  $f = rand();
  $peep[$i] = 0.01 + $f * 0.2;
}

my $tko = 0;

my @bladeratio =
(
  # nblades = 2..7
  0.0, 0.0, 3.00000, 1.73205, 1.00000, 0.72654, 0.57735, 0.48157,
  # 8..13
  0.41421, 0.36397, 0.19076, 0.29363, 0.26795, 0.24648,
  # 14..19
  0.22824, 0.21256, 0.19891, 0.18693, 0.17633, 0.16687,
);


sub drawleaf {
  my $l = shift;
  my ($x, $y);
  my $wobble;

  my $blades = $blad[$l];

  $y = 0.10 * sin($geep[$l] * pi / 180.0) + 0.099 * sin($geep[$l] * 5.12 * pi / 180.0);
  $y = -$y if ($y < 0);
  $x = 0.15 * cos($geep[$l] * pi / 180.0) + 0.149 * cos($geep[$l] * 5.12 * pi / 180.0);
  $x = 0.0 - $x if ($x < 0.0);
  if ($y < 0.001 && $x > 0.000002 && (($tko & 0x1) == 0)) {
    initshapes($l);      # let it become reborn as something else
    $tko++;
    return;
  }
  my $w1 = sin($geep[$l] * 15.3 * pi / 180.0);
  $wobble = 3.0 + 2.00 * sin($geep[$l] * 0.4 * pi / 180.0) + 3.94261 * $w1;

  $y = $x * $bladeratio[$blades] if ($y > $x * $bladeratio[$blades]);

  for (my $b = 0; $b < $blades; $b++) {
    glPushMatrix();
    glTranslatef($pos[$l * 3], $pos[$l * 3 + 1], $pos[$l * 3 + 2]);
    glRotatef($ang[$l] + $b * (360.0 / $blades), 0.0, 0.0, 1.0);
    glScalef($wobble * $sca[$l], $wobble * $sca[$l], $wobble * $sca[$l]);
    glColor4ub(0, 0, 0, 0x60);

    # constrain geep cooridinates here XXX
    glEnable(GL_BLEND);

    glBegin(GL_TRIANGLE_STRIP);
    glVertex2f($x * $sca[$l], 0.0);
    glVertex2f($x, $y);
    glVertex2f($x, -$y);   # C
    glVertex2f(0.3, 0.0);  # D
    glEnd();

    glColor3f($col[$l * 3], $col[$l * 3 + 1], $col[$l * 3 + 2]);
    glBegin(GL_LINE_LOOP);
    glVertex2f($x * $sca[$l], 0.0);
    glVertex2f($x, $y);
    glVertex2f(0.3, 0.0);  # D
    glVertex2f($x, -$y);   # C
    glEnd();
    glDisable(GL_BLEND);

    glPopMatrix();
  }
}

sub motionUpdate {
  my $t = shift;
  print "wd !!\n" unless defined $wd;
  print "sca[t] !!\n" unless defined $sca[$t];
  if ($pos[$t * 3] < -$sca[$t] * $wd && $dir[$t * 3] < 0.0) {
    $dir[$t * 3] = -$dir[$t * 3];  
  } 
  elsif ($pos[$t * 3] > (1 + $sca[$t]) * $wd && $dir[$t * 3] > 0.0) {
    $dir[$t * 3] = -$dir[$t * 3];
  }
  elsif ($pos[$t * 3 + 1] < -$sca[$t] * $ht && $dir[$t * 3 + 1] < 0.0) {
    $dir[$t * 3 + 1] = -$dir[$t * 3 + 1];    
  } 
  elsif ($pos[$t * 3 + 1] > (1 + $sca[$t]) * $ht && $dir[$t * 3 + 1] > 0.0) {
    $dir[$t * 3 + 1] = -$dir[$t * 3 + 1];
  }

  $pos[$t * 3] += $dir[$t * 3];
  $pos[$t * 3 + 1] += $dir[$t * 3 + 1];
  
  $ang[$t] += $spn[$t];
  $geep[$t] += $peep[$t];
  
  $geep[$t] -= 360 * 5.0 if $geep[$t] > 360 * 5.0;
  $ang[$t] += 360.0 if $ang[$t] < 0.0;
  $ang[$t] -= 360.0 if $ang[$t] > 360.0;
}

sub colorUpdate {
  my $i = shift;

  $hpr[$i * 3 + 1] = -$hpr[$i * 3 + 1] 
    if ($hsv[$i * 3 + 1] <= 0.5 && $hpr[$i * 3 + 1] < 0.0);  # adjust s  
  $hpr[$i * 3 + 1] = -$hpr[$i * 3 + 1] 
    if ($hsv[$i * 3 + 1] >= 1.0 && $hpr[$i * 3 + 1] > 0.0);  # adjust s
  $hpr[$i * 3 + 2] = -$hpr[$i * 3 + 2] 
    if ($hsv[$i * 3 + 2] <= 0.4 && $hpr[$i * 3 + 2] < 0.0);  # adjust s
  $hpr[$i * 3 + 2] = -$hpr[$i * 3 + 2] 
    if ($hsv[$i * 3 + 2] >= 1.0 && $hpr[$i * 3 + 2] > 0.0);  # adjust s

  $hsv[$i * 3] += $hpr[$i * 3];
  $hsv[$i * 3 + 1] += $hpr[$i * 3 + 1];
  $hsv[$i * 3 + 2] += $hpr[$i * 3 + 2];

  $hsv[$i*3+2] = 0.0 if ($hsv[$i*3+2] < 0.0);
  $hsv[$i*3+2] = 1.0 if ($hsv[$i*3+2] > 1.0);
  if ($hsv[$i*3+1] <= 0.0) {
    $col[$i*3] = $hsv[$i*3+2];
    $col[$i*3+1] = $hsv[$i*3+2];
    $col[$i*3+2] = $hsv[$i*3+2];
  } 
  else {    
    $hsv[$i*3] += 360.0 while ($hsv[$i*3] < 0.0);    
    $hsv[$i*3] -= 360.0 while ($hsv[$i*3] >= 360.0);    
    $hsv[$i*3+1] = 0.0 if ($hsv[$i*3+1] < 0.0);    
    $hsv[$i*3+1] = 1.0 if ($hsv[$i*3+1] > 1.0);

    my $h = $hsv[$i*3] / 60.0;
    my $hi = int($h);
    my $f = $h - $hi;
    my $v = $hsv[$i*3+2];
    my $p = $hsv[$i*3+2] * (1 - $hsv[$i*3+1]);
    my $q = $hsv[$i*3+2] * (1 - $hsv[$i*3+1] * $f);
    my $t = $hsv[$i*3+2] * (1 - $hsv[$i*3+1] * (1 - $f));

    if ($hi <= 0) {
      $col[$i*3] = $v;
      $col[$i*3+1] = $t;
      $col[$i*3+2] = $p;
    } 
    elsif ($hi == 1) {
      $col[$i*3] = $q;
      $col[$i*3+1] = $v;
      $col[$i*3+2] = $p;
    } 
    elsif ($hi == 2) {
      $col[$i*3] = $p;
      $col[$i*3+1] = $v;
      $col[$i*3+2] = $t;
    } 
    elsif ($hi == 3) {
      $col[$i*3] = $p;
      $col[$i*3+1] = $q;
      $col[$i*3+2] = $v;
    } 
    elsif ($hi == 4) {
      $col[$i*3] = $t;
      $col[$i*3+1] = $p;
      $col[$i*3+2] = $v;
    } 
    else {
      $col[$i*3] = $v;
      $col[$i*3+1] = $p;
      $col[$i*3+2] = $q;
    }
  }
}

sub gravity {
  my $fx = shift;
  for (my $a = 0; $a < N_SHAPES; $a++) {
    for (my $b = 0; $b < $a; $b++) {
      my $t = $pos[$b * 3] - $pos[$a * 3];
      my $d2 = $t * $t;
      $t = $pos[$b * 3 + 1] - $pos[$a * 3 + 1];
      $d2 += $t * $t;     
      $d2 = 0.00001 if $d2 < 0.000001;
      if ($d2 < 0.1) {
        my $v0 = $pos[$b * 3] - $pos[$a * 3];
        my $v1 = $pos[$b * 3 + 1] - $pos[$a * 3 + 1];
        my $z = 0.00000001 * $fx / $d2;
        $dir[$a * 3] += $v0 * $z * $sca[$b];
        $dir[$b * 3] += -$v0 * $z * $sca[$a];
        $dir[$a * 3 + 1] += $v1 * $z * $sca[$b];
        $dir[$b * 3 + 1] += -$v1 * $z * $sca[$a];
      }
    }
  }
}

sub oneFrame {
  gravity(-2.0);
  for (my $i = 0; $i < N_SHAPES; $i++) {
    motionUpdate($i);
    colorUpdate($i);
    drawleaf($i);
  }
  glFlush();
}

sub display {
  glClear(GL_COLOR_BUFFER_BIT);
}

sub myReshape {
  my ($w, $h) = @_;
  glViewport(0, 0, $w, $h);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  if ($w <= $h) {
    $wd = 1.0;
    $ht = $w?$h/$w:0;
  } 
  else {
    $wd = $h?$w/$h:0;
    $ht = 1.0;
  }
  glOrtho(0.0, $wd, 0.0, $ht, -16.0, 4.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glClear(GL_COLOR_BUFFER_BIT);
}

# TODO support this?
#sub visibility {
#  my $status = shift;
#  if ($status == GLUT_VISIBLE) {
#    glutIdleFunc(\&oneFrame);
#  }
#  else {
#    glutIdleFunc(undef);
#  }
#}

sub myinit {
  glClearColor(0.0, 0.0, 0.0, 1.0);
  glEnable(GL_LINE_SMOOTH);
  glShadeModel(GL_FLAT);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  for (my $i = 0; $i < N_SHAPES; $i++) {
    initshapes($i);
  }
  myReshape(200, 200);
}

sub keyboard {
  my ($win, undef, $vkey) = @_;
  if ($vkey == VK_ESCAPE) {
	  return -1;
  }
}

my $mw = Win32::GUI::Window->new(
	-title     => 'noof',

	# fullscreen options
	-pos       => [0,0],
	-width     => Win32::GUI::GetSystemMetrics(0), #SM_CXSCREEN
	-height    => Win32::GUI::GetSystemMetrics(1), #SM_CYSCREEN
	-popstyle  => WS_OVERLAPPEDWINDOW,
	-pushstyle => WS_POPUPWINDOW,
	-topmost   => 1,

	-onKeyDown => \&keyboard,
);

my $glw = $mw->AddOpenGLFrame(
	-name         => 'oglwin',
	-width        => $mw->ScaleWidth(),
	-height       => $mw->ScaleHeight(),
	-init         => \&myinit,
	-display      => \&oneFrame,
	-reshape      => \&myReshape,
);

$mw->Show();
while(Win32::GUI::DoEvents() != -1) {
	$glw->InvalidateRect(0);
}
$mw->Hide();
exit(0);

__END__
