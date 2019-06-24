#!perl -w

use strict;
use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 1) : (skip_all => 'require Test::LeakTrace');
use Test::LeakTrace;

use YAML::Safe;

leaks_cmp_ok{
    my $yaml = Load(<<'...');
--- 42
--- 0.333
--- '02134'
...
    Dump($yaml);
} '<', 1;
