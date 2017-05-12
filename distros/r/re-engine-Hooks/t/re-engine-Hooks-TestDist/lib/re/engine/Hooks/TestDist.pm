package re::engine::Hooks::TestDist;

use 5.010_001;

use strict;
use warnings;

our ($VERSION, @ISA);

use re::engine::Hooks;

BEGIN {
 $VERSION = '0.05';
 require DynaLoader;
 push @ISA, 'DynaLoader';
 __PACKAGE__->bootstrap($VERSION);
}

sub import {
 my ($class, $key, $var) = @_;

 set_variable($key, $var) if defined $var;
 re::engine::Hooks::enable(__PACKAGE__ . "::$key");
}

sub unimport {
 my ($class, $key) = @_;

 re::engine::Hooks::disable(__PACKAGE__ . "::$key");
}

1;
