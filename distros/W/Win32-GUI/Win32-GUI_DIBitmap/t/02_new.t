#!perl -wT
# Win32::GUI::DIBitmap test suite
# $Id: 02_new.t,v 1.1 2006/06/11 16:34:48 robertemay Exp $
#
# - check we can create a new DIBitmap object

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 2;
use Win32::GUI();
use Win32::GUI::DIBitmap();

my $W = Win32::GUI::Window->new();
can_ok('Win32::GUI::DIBitmap', 'new');
my $S = Win32::GUI::DIBitmap->newFromWindow($W);
isa_ok($S, 'Win32::GUI::DIBitmap', 'Correct object type created');
