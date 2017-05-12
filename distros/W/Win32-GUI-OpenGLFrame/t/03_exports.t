#!perl -wT
use strict;
use warnings;

use Test::More (tests => 2);

#Check that Win32::GUI::OpenGLFrame exports w32gSwapBuffers
#as advertised.
BEGIN {
    use Win32::GUI::OpenGLFrame;
    ok(!defined &main::w32gSwapBuffers, "w32gSwapBuffers not exported by default");
}

use Win32::GUI::OpenGLFrame qw(w32gSwapBuffers);
ok(defined &main::w32gSwapBuffers, "w32gSwapBuffers exported on request");
