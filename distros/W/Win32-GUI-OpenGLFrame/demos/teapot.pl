#!perl -w
use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::OpenGLFrame qw(w32gSwapBuffers);
use OpenGL qw(:glfunctions :glconstants :glufunctions :glutfunctions);

my $spin = 0.0;
my $toggle = 0;

my @light0_position    = (2.0, 8.0, 2.0, 0.0);
my @mat_specular       = (1.0, 1.0, 1.0, 1.0);
my @mat_shininess      = (50.0);
my @mat_amb_diff_color = (0.5, 0.7, 0.5, 0.5);
my @light_diffuse      = (1.0, 1.0, 1.0, 1.0);
my @light_ambient      = (0.15, 0.15, 0.15, 0.15);
my @light_specular     = (1.0, 1.0, 1.0, 1.0);

my $mw = Win32::GUI::Window->new(
	-title => "OpenGL Demonstration",
	-pos   => [100,100],
	-size  => [400,400],
	-pushstyle => WS_CLIPCHILDREN,  # stop flickering on resize
	-onResize  => \&mainWinResize,
);

my $glw = $mw->AddOpenGLFrame(
	-name    => 'oglwin',
	-width   => $mw->ScaleWidth(),
	-height  => $mw->ScaleHeight() - 50,
	-display => \&display,
	-init    => \&Init,
	-reshape => \&reshape,
	-onTimer  => \&spinDisplay,
	-onMouseDown => \&stopSpin,
	-onMouseRightDown => \&startSpin,
	-doubleBuffer => 1,
);

my $timer = $glw->AddTimer('SpinTimer', 25);

$mw->AddButton(
	-name => 'but',
	-text => 'Close',
	-left => $mw->ScaleWidth()-50,
	-top  => $mw->ScaleHeight()-30,
	-onClick => sub{-1},
);

$mw->Show();
Win32::GUI::Dialog();
$mw->Hide();
exit(0);

sub mainWinResize {
	my $win = shift;

	$win->oglwin->Resize($win->ScaleWidth(), $win->ScaleHeight()-50);
	$win->but->Move($win->ScaleWidth()-50, $win->ScaleHeight()-30);

	return 0;
}

sub reshape {
	my ($w, $h) = @_;

	glViewport(0, 0, $w, $h);
	glMatrixMode (GL_PROJECTION);	
	glLoadIdentity ();	#  define the projection
	gluPerspective(45.0, $h ? $w/$h : 0, 1.0, 20.0);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	return 0;
}

sub Init {
    glutInit();

	glClearColor(1.0, 1.0, 1.0, 1.0);
	glShadeModel(GL_SMOOTH);   
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0); 
}

sub display {
	my $obj = shift;

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLightfv_p(GL_LIGHT0, GL_POSITION, @light0_position);
	glLightfv_p(GL_LIGHT0, GL_DIFFUSE, @light_diffuse);
	glLightfv_p(GL_LIGHT0, GL_AMBIENT, @light_ambient); 
	glLightfv_p(GL_LIGHT0, GL_SPECULAR, @light_specular);
	glMaterialfv_p(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @mat_amb_diff_color);
	glLoadIdentity();
	gluLookAt(2.0, 4.0, 10.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
	glPushMatrix();
	glScalef(2.0, 2.0, 2.0);
	glRotatef($spin, 0.0, 1.0, 0.0);
	glutSolidTeapot(1.0);
	glPopMatrix();

	w32gSwapBuffers();
}

sub spinDisplay {
	my $win = shift;
	$spin += 1.0;
	$spin = $spin - 360.0 if ($spin >360.0);
	$win->InvalidateRect(0);
}

sub stopSpin {
	my $win = shift;
	$win->SpinTimer->Interval(0);
}

sub startSpin {
	my $win = shift;
	$win->SpinTimer->Interval(25);
}
