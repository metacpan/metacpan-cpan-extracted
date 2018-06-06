#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use X11::GLX::DWIM;
use Log::Any::Adapter 'TAP';
use FindBin;
use lib "$FindBin::Bin/lib";
use OpenGL qw( :glconstants :glfunctions );
use OpenGL::Model::Cube;

plan skip_all => "No X11 Server available"
	unless defined $ENV{DISPLAY};

my $dwim= new_ok( 'X11::GLX::DWIM', [ gl_projection => {} ] );

ok( $dwim->display, 'open display' ); 
ok( $dwim->glx_context, 'create gl context' ); $dwim->display->flush_sync;
ok( $dwim->target, 'initialize gl target' ); $dwim->display->flush_sync;

# Generate a GL error, and make sure error diags are working
glEnable(-1);
is_deeply( [sort values %{ $dwim->get_gl_errors }], ['GL_INVALID_ENUM'], 'detect error GL_INVALID_ENUM' );

glPopMatrix();
is_deeply( [sort values %{ $dwim->get_gl_errors }], ['GL_STACK_UNDERFLOW'], 'detect error GL_STACK_UNDERFLOW' );

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
	glClearColor(0, 0, 0, 1);
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
