#!perl -w
use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::OpenGLFrame qw(w32gSwapBuffers);
use OpenGL qw(:all);

my $rtri = 0;
my $rquad = 0;

sub init {
    glShadeModel(GL_SMOOTH);
    glClearColor(0, 0, 0, 0);
    glClearDepth(1);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    return 1;
}

sub display {
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

    glLoadIdentity();
    glTranslatef(-1.5, 0.0, -6.0);
    glRotatef($rtri, 0, 1, 0);

    glBegin(GL_TRIANGLES);
        glColor3f(1.0, 0.0, 0.0);
        glVertex3f(0.0, 1.0, 0.0);
        glColor3f(0.0, 1.0, 0.0);
    	glVertex3f(-1.0, -1.0, 0.0);
        glColor3f(0.0, 0.0, 1.0);
    	glVertex3f(1.0, -1.0, 0.0);
    glEnd();

    glLoadIdentity();
    glTranslatef(1.5, 0.0, -6.0);
    glRotatef($rquad, 1, 0, 0);

    glColor3f(0.5, 0.5, 1.0);
    glBegin(GL_QUADS);
        glVertex3f(-1.0, 1.0, 0.0);
	    glVertex3f( 1.0, 1.0, 0.0);
	    glVertex3f( 1.0,-1.0, 0.0);
	    glVertex3f(-1.0,-1.0, 0.0);
    glEnd();

    glFlush();
    w32gSwapBuffers();
    return 1;
}

sub reshape1 {
    my ($width, $height) = @_;

    glViewport(0,0,$width,$height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0, $height ? ($width/$height) : 0, 0.1, 100.0);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    return 1;
}

sub reshape2 {
    my ($width, $height) = @_;

    glViewport(0,0,$width,$height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(65.0, $height ? ($width/$height) : 0, 0.1, 100.0);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    return 1;
}

my $mw = Win32::GUI::Window->new(
    -title     => "Win32::GUI OpenGL Example",
    -size      => [800,300],
    -pushstyle => WS_CLIPCHILDREN,  #stop flickering
    -onResize  => \&mwResize,
);

$mw->AddOpenGLFrame(
    -name => 'oglf1',
    -init => \&init,
    -reshape => \&reshape1,
    -display => \&display,
    -doubleBuffer => 1,
    -depth => 1,
);

$mw->AddOpenGLFrame(
    -name => 'oglf2',
    -init => \&init,
    -reshape => \&reshape2,
    -display => \&display,
    -doubleBuffer => 1,
    -depth => 1,
);
$mw->oglf2->UserData(30);

$mw->Show();
#Win32::GUI::Dialog();
while(Win32::GUI::DoEvents() != -1) {
    $rtri += 0.2;
    $rquad -= 0.15;
    $mw->oglf1->InvalidateRect(0);
    $mw->oglf2->InvalidateRect(0);
}
$mw->Hide();
exit(0);

sub mwResize {
    my $win = shift;
    $win->oglf1->Move(0, 0);
    $win->oglf1->Resize($win->ScaleWidth()/2, $win->ScaleHeight());
    $win->oglf2->Move($win->ScaleWidth()/2, 0);
    $win->oglf2->Resize($win->ScaleWidth()/2, $win->ScaleHeight());
    return 0;
}
