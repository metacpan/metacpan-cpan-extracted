#!perl -w
use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::OpenGLFrame qw(w32gSwapBuffers);
use OpenGL qw(:all);

sub display {
    glClear(GL_COLOR_BUFFER_BIT);
    glLoadIdentity();

    glTranslatef(-1.5, 0.0, -6.0);

    glBegin(GL_TRIANGLES);
    glVertex3f(0.0, 1.0, 0.0);
	glVertex3f(-1.0, -1.0, 0.0);
	glVertex3f(1.0, -1.0, 0.0);
    glEnd();

    glTranslatef(3.0, 0.0, 0.0);

    glBegin(GL_QUADS);
    glVertex3f(-1.0, 1.0, 0.0);
	glVertex3f( 1.0, 1.0, 0.0);
	glVertex3f( 1.0,-1.0, 0.0);
	glVertex3f(-1.0,-1.0, 0.0);
    glEnd();

    w32gSwapBuffers();
    return 1;
}

sub reshape {
    my ($width, $height) = @_;

    $height = 1 if $height == 0; # Prevent div by zero below

    glViewport(0,0,$width,$height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0, ($width/$height), 0.1, 100.0);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    return 1;
}

my $mw = Win32::GUI::Window->new(
    -title     => "Win32::GUI OpenGL Example",
    -size      => [400,400],
    -pushstyle => WS_CLIPCHILDREN,  # stop flickering
    -onResize  => \&mwResize,
);

$mw->AddOpenGLFrame(
    -name => 'oglf',
    -reshape => \&reshape,
    -display => \&display,
);

$mw->Show();
Win32::GUI::Dialog();
$mw->Hide();
exit(0);

sub mwResize {
    my $win = shift;
    $win->oglf->Resize($win->ScaleWidth(), $win->ScaleHeight());
    return 0;
}
