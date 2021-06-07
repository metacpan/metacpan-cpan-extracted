#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

require lib::noop::missing;

{
    lib::noop::missing->import;
    require Data::Dumper;
    lives_ok { Data::Dumper::Dumper([]) };
    require Foo::Bar42;
}

{
    lib::noop::missing->unimport;
    delete $INC{"Foo/Bar42.pm"};
    dies_ok { require Foo::Bar42 };
}

done_testing;
