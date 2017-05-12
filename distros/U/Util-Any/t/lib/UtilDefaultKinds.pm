package UtilDefaultKinds;

use strict;
use warnings;

use Util::Any -Base;
our $Utils = Clone::clone($Util::Any::Utils);

sub _default_kinds { '-list', '-string' }

1;

