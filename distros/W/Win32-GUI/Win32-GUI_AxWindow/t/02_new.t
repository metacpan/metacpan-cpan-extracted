#!perl -wT
# Win32::GUI::AxWindow test suite
# $Id: 02_new.t,v 1.1 2006/06/11 15:47:24 robertemay Exp $
#
# - check we can create a new AxWindow object

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 2;
use Win32::GUI();
use Win32::GUI::AxWindow();

my $W = Win32::GUI::Window->new();
can_ok('Win32::GUI::AxWindow', 'new');
my $S = Win32::GUI::AxWindow->new(
    -name => 'AxWindow',
    -parent => $W,
    -control => "Shell.Explorer.2",
);
isa_ok($S, 'Win32::GUI::AxWindow', 'Correct object type created');
