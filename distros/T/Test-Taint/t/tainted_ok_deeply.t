#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Taint tests => 8;

taint_checking_ok('Taint checking is on');

my %vars = (
    HASH   => { key => 'value' },
    ARRAY  => [ 1..2 ],
    GLOB   => \*DATA,
    SCALAR => \q{u can't taint this},
    REF    => \{ another_key => 1 },
);

while(my($key, $value) = each %vars) {
  is(
    ref $value,
    $key,
    'Make sure the datatype is correct',
  );
}

untainted_ok_deeply( \%vars, 'Everything should be untainted' );

taint_deeply( \%vars );

tainted_ok_deeply( \%vars, 'Everything should be tainted' );

__DATA__
i am glob
