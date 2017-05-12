#!/usr/bin/perl -w
use warnings;
use strict;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib', 'lib/';
    use_ok 'aliased' or die "Could not use aliased";
}
ok defined &alias, 'alias() should be imported into our namespace';

ok my $alias = alias("Really::Long::Name"),
  'aliasing to a scalar should succeed';
is $alias->thing(2), 4, '... and it should return the correct results';

{

    package Foo::Bar;
    ::alias( "Really::Long::Module::Conflicting::Name", "echo" );
    ::is_deeply [ echo("foo") ], ["foo"],
      '... and it should still allow importing';
}

done_testing;
