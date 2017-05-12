#!perl
use strict;
use warnings;
use Test::More;
use Test::Exception tests => 1;
use Tripletail '/dev/null';
use Tripletail::CSV;

dies_ok {
    local $SIG{__DIE__} = 'DEFAULT';
    delete $INC{"Text/CSV_XS.pm"};
    local(@INC);
    Tripletail::CSV->_new;
};
