use strict;
use warnings;

use Test::More;

use Test::Moose::More;

{ package Pristine;     use Moose;                          }
{ package NotPristine;  use Moose; has foo => (is => 'rw'); }
{ package AlsoPristine; use Moose; extends 'NotPristine'    }

subtest 'sanity' => sub {

    is_pristine_ok 'Pristine';
    is_not_pristine_ok 'NotPristine';
    is_pristine_ok 'AlsoPristine';
};

done_testing;
