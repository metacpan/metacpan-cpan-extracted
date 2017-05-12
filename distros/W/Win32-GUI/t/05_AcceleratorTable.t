#!perl -wT
# Win32::GUI test suite.
# $Id: 05_AcceleratorTable.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# test coverage of Accelerator tables

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 4;

use Win32::GUI();

my $W = new Win32::GUI::Window(
    -name => "TestWindow",
    -pos  => [  0,   0],
    -size => [100, 100],
    -text => "TestWindow",
);
isa_ok($W, "Win32::GUI::Window", "\$W");

my $ctrl = "AcceleratorTable";
my $C = new Win32::GUI::AcceleratorTable(
         "Ctrl-X"       => "Close",
         "Shift-N"      => "New",
         "Ctrl-Alt-Del" => "Reboot",
         "Shift-A"      => sub { print "Hello\n"; },
    );
isa_ok($C, "Win32::GUI::$ctrl", "new Win32::GUI::$ctrl");

$W->Change(-accel => $C, );

is($W->{-accel}, $C->{-handle}, "Accelerator handle stored in parent");

$C->DESTROY();

TODO: {
	local $TODO = "Accelerator DESTROY method needs to remove accelerator from parent?";
	ok(!defined $W->{-accel}, "Accelerator handle removed from parent");
}

