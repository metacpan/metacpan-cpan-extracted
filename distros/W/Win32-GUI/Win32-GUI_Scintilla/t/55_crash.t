#!perl -wT
# Win32::GUI::Scintilla test suite
# $Id: 55_crash.t,v 1.1 2008/01/31 00:34:20 robertemay Exp $
#

# These tests performed at the end, as they may well crash.

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 1;

use Win32::GUI qw();
use Win32::GUI::Scintilla qw();

# cygwin (only) crashes with 1.05 at demos/Editor.pl and 
# scripts/win32-gui-demos in the scintilla callback.
# Was due to #define PERL_NO_GET_CONTEXT in Scintilla.h
# causing perlud to be different sizes for Win32::GUI and
# Win32::GUI::Scintilla.
Win32::GUI::Window->new->AddScintilla()->SetFocus(0);
pass("Didn't crash");
