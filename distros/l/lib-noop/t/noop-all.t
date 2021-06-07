#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

require lib::noop::all;

{
    lib::noop::all->import;
    require Data::Dumper;
    ok(!defined(&Data::Dumper::Dumper));
    require Foo::Bar42;
}

{
    lib::noop::all->unimport;
    delete $INC{"Data/Dumper.pm"};
    require Data::Dumper;
    lives_ok { Data::Dumper::Dumper([]) };
}

done_testing;
