use strict;
use warnings;

use Test::More tests => 24;

#==============================================================================#
use X11::Terminal::GnomeTerminal;

my $t1 = X11::Terminal::GnomeTerminal->new();

ok($t1, "Created GnomeTerminal object");
ok($t1->can("launch"), "Object has launch method");
ok($t1->terminalName() eq "gnome-terminal", "good program name");

my $t2 = X11::Terminal::GnomeTerminal->new();
ok($t1->launch(1) eq $t2->launch(1), "Created two similar objects");

# test the string attributes
for my $option ( qw(profile geometry host) ) {
  my $t3 = X11::Terminal::GnomeTerminal->new($option => "DUMMY");
  ok($t1->launch(1) ne $t3->launch(1), "Option $option makes a difference");

  my $t4 = X11::Terminal::GnomeTerminal->new();
  my $accessor = $t4->can($option);
  ok($accessor, "Accessor function $option exists");
  ok($accessor->($t4,"DUMMY"), "Accessor $option make a difference");
  ok($t3->launch(1) eq $t4->launch(1), "Accessor $option equivalent to constructor");
}

# test the connection attributes
for my $option ( qw(xforward agentforward) ) {
  my $t3 = X11::Terminal::GnomeTerminal->new($option => 1, host => "DUMMY");
  my $t4 = X11::Terminal::GnomeTerminal->new(host => "DUMMY");
  ok($t3->launch(1) ne $t4->launch(1), "Option $option makes a difference");

  my $accessor = $t4->can($option);
  ok($accessor, "Accessor function $option exists");
  ok($accessor->($t4,1), "Accessor $option make a difference");
  ok($t3->launch(1) eq $t4->launch(1), "Option $option makes a difference");
}

#==============================================================================#
