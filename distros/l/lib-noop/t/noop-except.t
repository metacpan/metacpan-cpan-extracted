#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

require lib::noop::except;

{
    lib::noop::except->import('Data::Dumper');
    require Data::Dumper;
    lives_ok { Data::Dumper::Dumper([]) };
    require Foo::Bar42; # no-op'ed
}

{
    lib::noop::except->unimport;
    delete $INC{"Foo/Bar42.pm"};
    dies_ok { require Foo::Bar42 };
}

done_testing;
