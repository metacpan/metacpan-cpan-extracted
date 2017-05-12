use strict;
use warnings;
use Test::Requires {
  'Moose' => '()',
  'Moo' => '1.004000 ()',
};

use Test::More;
plan skip_all => 'this combination of Moo/Sub::Util is unstable'
    if Moo->VERSION >= 2 and not eval { Moo->VERSION('2.000002') }
        and $INC{"Sub/Util.pm"} and not defined &Sub::Util::set_subname;

use FindBin qw($Bin);

do "$Bin/moo.t";
die $@ if $@;
