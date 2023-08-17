use strict;
use warnings;
use Test::More;
use Test::Requires qw( Type::Library );

use lib qw( ./t/externals/Type-Library/lib );

use Sample qw( hello world Foo Bar );

ok hello;
isa_ok Foo, 'Type::Tiny';
isa_ok Bar, 'Type::Tiny';

done_testing;
