use strict;
use warnings;
use Test::More;
use Test::Requires qw( Exporter );

use lib qw( ./t/externals/Exporter/lib );

use Sample qw( hello world Foo );

ok hello;
isa_ok Foo, 'Type::Tiny';

done_testing;
