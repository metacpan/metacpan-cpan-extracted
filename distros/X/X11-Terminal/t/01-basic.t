use strict;
use warnings;

use Test::More tests => 9;

#==============================================================================#

my @modules = (
  "X11::Terminal",
  "X11::Terminal::XTerm",
  "X11::Terminal::GnomeTerminal"
);

for my $module ( @modules ) {
  require_ok($module);
  my $term = $module->new();
  ok($term,"Created $module object");
  ok($term->isa("X11::Terminal"), "$module is an X11::Terminal");
}

#==============================================================================#
