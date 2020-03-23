use strict;
use warnings;

use Test::More;
use Test::Warnings ':all';

my $module = 'Does::Not::Exist::'.substr(rand, 2);
eval "use $module";
plan skip_all => 'Need '.$module.' to continue!' if $@;

fail('we should not ever get here');

