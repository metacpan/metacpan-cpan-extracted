#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use X11::GLX ':constants';
use X11::GLX::DWIM;
use Log::Any::Adapter 'TAP';
use FindBin;
use lib "$FindBin::Bin/lib";
use OpenGL qw( :glconstants :glfunctions );
use OpenGL::Model::Cube;

plan skip_all => "No X11 Server available"
	unless defined $ENV{DISPLAY};

my $dpy= X11::Xlib->new;
my ($glmajor, $glminor);

plan skip_all => "Display doesn't have GLX 1.3"
	unless X11::GLX::glXQueryVersion($dpy, $glmajor, $glminor)
		and sprintf("%d%02d", $glmajor, $glminor) >= 103;

my @glx_fbconfig= (
	GLX_RENDER_TYPE, GLX_RGBA_BIT,
	GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT,
	GLX_DOUBLEBUFFER, 1,
	GLX_RED_SIZE, 8,
	GLX_GREEN_SIZE, 8,
	GLX_BLUE_SIZE, 8,
	GLX_ALPHA_SIZE, 8,
	GLX_DEPTH_SIZE, 16,
);
my $dwim= new_ok( 'X11::GLX::DWIM', [
	display => $dpy,
	fbconfig => \@glx_fbconfig,
	target => {
		window => {
			x => 50, y => 50, width => 500, height => 500,
		}
	},
	gl_projection => {}
] );

ok( $dwim->fbconfig, 'found fbconfig' );
ok( $dwim->glx_context, 'allocated context' ); $dpy->flush_sync;
ok( $dwim->target, 'created target' ); $dpy->flush_sync;

set_gl_options();

for (1..60) {
	$dwim->begin_frame;
	glLoadIdentity();
	glTranslated(0,0,-3);
	glDisable(GL_TEXTURE_2D);
	glRotated($_*3, 1, 1.5, 1);
	cube();
	$dwim->end_frame;
}

my $cube_dlist;
sub cube {
	if ($cube_dlist) {
		glCallList($cube_dlist);
	} else {
		$cube_dlist= glGenLists(1);
		glNewList($cube_dlist, GL_COMPILE_AND_EXECUTE);
		OpenGL::Model::Cube->draw;
		glEndList();
	}
}
sub set_gl_options {
	glClearColor(0, 0, 0, 0);
	glClearDepth(1);
	glColor4d(1,1,1,1);
	glDepthFunc(GL_LEQUAL);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
	glShadeModel(GL_SMOOTH);
	glEnable(GL_BLEND);
	glEnable(GL_TEXTURE_2D);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
}

done_testing;
