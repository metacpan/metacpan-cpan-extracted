#!perl -w
# Win32::GUI::Scintilla test suite
# $Id: 02_new.t,v 1.2 2008/01/31 00:34:20 robertemay Exp $
#
# - check we can create a new Scintilla object

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 6;

use Win32::GUI qw();
use Win32::GUI::Scintilla qw();
use Win32::GUI::Scintilla::Perl qw();

can_ok('Win32::GUI::Scintilla', 'new');
can_ok('Win32::GUI::Window', 'AddScintilla');
can_ok('Win32::GUI::Scintilla::Perl', 'new');
can_ok('Win32::GUI::Window', 'AddScintillaPerl');

my $W = Win32::GUI::Window->new();

my $S = $W->AddScintilla();
isa_ok($S, 'Win32::GUI::Scintilla', 'Correct object type created');

my $P = $W->AddScintillaPerl();
isa_ok($P, 'Win32::GUI::Scintilla', 'Correct object type created');
