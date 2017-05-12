#!perl

use strict;
use warnings;

use Test::More tests => 3;
BEGIN{use_ok('Unix::Groups')};

BEGIN{Unix::Groups->import(':all')};

ok NGROUPS_MAX, 'NGROUPS_MAX';

my @g=split /\s+/, "$(";
shift @g;

my @gids=getgroups;
is 0+@gids, 0+@g, 'getgroup';
