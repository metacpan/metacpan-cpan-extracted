#!perl -wT
# Win32::GUI::Grid test suite
# $Id: 02_new.t,v 1.1 2006/06/11 16:42:16 robertemay Exp $
#
# - check we can create a new Grid object

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 2;
use Win32::GUI();
use Win32::GUI::Grid();

can_ok('Win32::GUI::Grid', 'new');
my $W = Win32::GUI::Window->new();
my $S = $W->AddGrid(-name => 'MyGrid');
isa_ok($S, 'Win32::GUI::Grid', 'Correct object type created');
