#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use YYZ;

can_ok __PACKAGE__, "YYZ";

is( YYZ("foo"), "foo" );
is_deeply( YYZ({ something => "something" }), { something => "something" } );

done_testing;
