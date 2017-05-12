#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Validate::Tiny ':all';

eval { validate( {}, {} ) };
ok $@, "Fields must be defined";

eval { validate( {}, { fields => {} } ) };
ok $@, "Fields must be an array";

eval { validate( {}, { fields => [qw/a/], filters => [ 1, 2, 3 ] } ) };
ok $@, "Fields must have even number of elements";

{
    my $res = validate( { a => 1, b => 2 }, { fields => [] } );
    is_deeply $res, { success => 1, data => { a => 1, b => 2 }, error => {} },
      "Empty fields takes all";
}

eval { validate( {}, { fields => [qw/a/], checks => [ 1, 2, 3 ] } ) };
ok $@, "Checks must have even number of elements";

eval { validate( {}, { fields => [qw/a/], filters => { a => 1 } } ) };
ok $@, "Filters must be an arrayref";

eval { validate( {}, { fields => [qw/a/], checks => { a => 1 } } ) };
ok $@, "Checks must be an arrayref";

eval { validate( {}, { fields => [qw/a/], checks => [ a => 1 ] } ) };
ok $@, "Each check must be code or arrayref";

eval { validate( { a => 2 }, { fields => [qw/a/], filters => [ a => 1 ] } ) };
ok $@, "Each filter must be code or arrayref";

eval { validate( {}, { fields => ['a'], something => [ 1, 2, 3 ] } ) };
ok $@, "Checks for misspelled keys";

eval { my $result = Validate::Tiny->check(1,2) };
ok $@, "Wrong params to constructor";

eval { my $result = Validate::Tiny->check({}) };
ok $@, "Wrong params to constructor 2";


