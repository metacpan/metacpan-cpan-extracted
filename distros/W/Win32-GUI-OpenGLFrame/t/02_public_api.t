#!perl -wT
use strict;
use warnings;

use Test::More (tests => 2);

#Check that Win32::GUI::OpenGLFrame supplies the public API that
#is advertised.
use Win32::GUI::OpenGLFrame();

can_ok( 'Win32::GUI::OpenGLFrame',
	qw( w32gSwapBuffers
	    new
	   )
      );

can_ok( 'Win32::GUI::Window',
	qw( AddOpenGLFrame
	   )
      );
