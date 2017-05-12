#!perl -wT
# Win32::GUI test suite.
# $Id: 06_Cursor.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# test coverage of Cursors

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 1;

use Win32::GUI();

my $filename = "hsplit.cur";

# Control requiring a filename as first arg
my $C = new Win32::GUI::Cursor($filename, -name => "TestCursor");
isa_ok($C, "Win32::GUI::Cursor", "new Win32::GUI::Cursor");

# TODO destruction?
#$C->DESTROY() if $C;
# ok((ref($C) ne "Win32::GUI::Cursor"), "Cursor->DESTROY");

