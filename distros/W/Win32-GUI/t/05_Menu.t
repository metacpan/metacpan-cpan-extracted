#!perl -wT
# Win32::GUI test suite.
# $Id: 05_Menu.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# test coverage of Menus

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 4;

use Win32::GUI();

my $ctrl = "Menu";
my $name = "Test$ctrl";
my $class = "Win32::GUI::$ctrl";
my @menulist =
    (
     "&File" => "File",
     "> &Open..." => {-name => 'MenuOpen'},
     "> &Save"    => {-name => 'MenuSave'},
     "> -" 	  => 0,
     "> &Quit"    => {-name => 'MenuQuit'},
    );

my $C = Win32::GUI::MakeMenu(@menulist);
isa_ok($C, $class, "new $class");

my $W = new Win32::GUI::Window(
    -name => "TestWindow",
    -pos  => [  0,   0],
    -size => [100, 100],
    -text => "TestWindow",
    -menu => $C,
);
isa_ok($W, "Win32::GUI::Window", "\$W");

$C->{MenuSave}->Enabled(0);
is($C->{MenuSave}->Enabled(), 0, "Enabled(0)");

$C->{MenuOpen}->Checked(1);
is($C->{MenuOpen}->Checked(), 1, "Checked(1)");

# What is this testing?
#Win32::GUI::Timer->new($W, "Timer1", 500);
#sub Timer1_Timer { $W->PostQuitMessage(); }
#$W->Show();
#Win32::GUI::Dialog();
