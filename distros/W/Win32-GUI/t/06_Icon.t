#!perl -wT
# Win32::GUI test suite.
# $Id: 06_Icon.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# test coverage of Icons

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 1;

use Win32::GUI();

my $filename = "guiperl.ico";

# Control requiring a filename as first arg
my $C = new Win32::GUI::Icon($filename, -name => "TestIcon");
isa_ok($C, "Win32::GUI::Icon", "new Win32::GUI::Icon");

# TODO destruction?
#$C->DESTROY() if $C;
# ok((ref($C) ne "Win32::GUI::Icon"), "Icon->DESTROY");

