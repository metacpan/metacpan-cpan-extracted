#!perl -wT
# Win32::GUI::Scintilla test suite
# $Id: 03_LoadFile.t,v 1.1 2008/01/31 00:34:20 robertemay Exp $
#
# cygwin (only) crashes with 1.05 at demos/Editor.pl and 
# scripts/win32-gui-demos in the scintilla callback.

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 5;
use Win32::GUI qw();
use Win32::GUI::Scintilla qw();
use Win32::GUI::Scintilla::Perl qw();

can_ok('Win32::GUI::Scintilla', 'LoadFile');

my $W = Win32::GUI::Window->new();
my $S = $W->AddScintilla();
my $P = $W->AddScintillaPerl();

isa_ok($S, 'Win32::GUI::Scintilla', 'Correct object type created');
isa_ok($P, 'Win32::GUI::Scintilla', 'Correct object type created');

ok($P->LoadFile(__FILE__), 'Scintilla can load a file');
ok($S->LoadFile(__FILE__), 'ScintillaPerl can load a file');
