#!perl -wT
# Win32::GUI test suite.
# $Id: 04_cov.t,v 1.3 2006/05/16 18:57:26 robertemay Exp $
#
# test coverage of most AddCtrl, new Ctrl and DESTROY methods

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More qw(no_plan);

use Win32::GUI();

my @ControlsAdd =
  qw/Animation
     Button Checkbox Combobox ComboboxEx
     DateTime Graphic
     Groupbox Header Label
     ListView Listbox
     Menu MonthCal 
     ProgressBar RadioButton Rebar
     RichEdit Slider Splitter StatusBar
     TabStrip Textfield Toolbar
     Trackbar TreeView UpDown/;

# TODO: Win32::GUI::MDIFrame->Add...
# MDIClient, ...

# Need special tests:
my @ControlsNewSpecial =
  qw(AcceleratorTable ImageList Region Icon
     MenuButton MenuItem
     Brush Cursor DC DialogBox Font
     Header Label Menu MDIChild
     MDIClient MDIFrame
     MonthCal NotifyIcon Pen
     Timer Window);

my $W = new Win32::GUI::Window(
    -name => "TestWindow",
    -pos  => [  0,   0],
    -size => [800, 600],
    -text => "TestWindow",
);
isa_ok($W, "Win32::GUI::Window");

for my $ctrl (@ControlsAdd) {
  #no strict 'refs';
  my $method = "Add$ctrl";
  my $name = "Test$ctrl";
  my $C = $W->$method(-name => $name);
  isa_ok($C,          "Win32::GUI::$ctrl", "\$W->$method") unless $ctrl =~ /Menu/;
  isa_ok($W->{$name}, "Win32::GUI::$ctrl", "\$W->{$name}") unless $ctrl =~ /Menu/;
  is($C, $W->{$name}, "Parent references $ctrl")           unless $ctrl =~ /Menu/;
  $C->DESTROY();
  ok(!defined $W->{$name}, "$name->DESTROY()") unless $ctrl =~ /NotifyIcon/;
}
exit(0);
# The same ctrls: requiring $W (PARENT) as first arg:
for my $ctrl (@ControlsAdd) {
  #no strict 'refs';
  next if $ctrl =~ /Menu/;
  my $class = "Win32::GUI::$ctrl";
  my $name = "Test$ctrl";
  my $C = new $class($W, -name => $name);
  isa_ok($C,          $class, "new $class(\$W)");
  isa_ok($W->{$name}, $class, "\$W->{$name}");
  is($C, $W->{$name}, "Parent references $ctrl");
  $C->DESTROY();
  ok(!defined $W->{$name}, "$name->DESTROY()") unless $ctrl =~ /NotifyIcon/;
}
