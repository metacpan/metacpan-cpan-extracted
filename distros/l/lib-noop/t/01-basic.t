#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

require lib::noop;

{
    lib::noop->import( qw(Data::Dumper) );
    require Data::Dumper;
    dies_ok { Data::Dumper::Dumper([]) };
}

{
    lib::noop->unimport;
    delete $INC{"Data/Dumper.pm"};
    require Data::Dumper;
    lives_ok { Data::Dumper::Dumper([]) };
}

done_testing;
