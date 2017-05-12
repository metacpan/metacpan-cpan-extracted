#!perl -wT
# Win32::GUI test suite.
# $Id: 03_button.t,v 1.3 2006/05/16 18:57:26 robertemay Exp $
#
# Basic Button tsets:

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 19;

use Win32::GUI();

can_ok("Win32::GUI::Window", qw(AddButton));
can_ok("Win32::GUI::Button", qw(new Left Top Width Height Move Resize Text));

my $W = new Win32::GUI::Window(
    -name => "TestWindow",
    -pos  => [  0,   0],
    -size => [210, 200],
    -text => "TestWindow",
);
isa_ok($W, "Win32::GUI::Window", "\$W");

my $B = $W->AddButton(
    -name => "TestButton",
    -pos  => [  0,   0],
    -text => "TestButton",
);
isa_ok($B,               "Win32::GUI::Button", "\$B");
isa_ok($W->{TestButton}, "Win32::GUI::Button", "\$W->{TestButton}");
isa_ok($W->TestButton,   "Win32::GUI::Button", "\$W->TestButton");
is($B, $W->TestButton, "Parent references Button");

is($B->Left, 0, "button LEFT correct");
is($B->Top, 0, "button TOP correct");
is($B->Text, "TestButton", "button TEXT correct");

$W->TestButton->Left(100);
is($W->TestButton->Left(), 100, "change button LEFT");

$W->TestButton->Top(100);
is($W->TestButton->Top, 100, "change button TOP");

$W->TestButton->Width(100);
is($W->TestButton->Width, 100, "change button WIDTH");

$W->TestButton->Height(100);
is($W->TestButton->Height, 100, "change button HEIGHT");

$W->TestButton->Resize(10, 10);
is($W->TestButton->Width, 10, "resize button WIDTH");
is($W->TestButton->Height, 10, "resize button HEIGHT");

$W->TestButton->Move(0, 0);
is($W->TestButton->Left, 0, "move button LEFT");
is($W->TestButton->Top, 0, "move button TOP");

$W->TestButton->Text("Press me");
is($W->TestButton->Text, "Press me", "change button TEXT");
