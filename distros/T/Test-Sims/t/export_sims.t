#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

{

    package Phone;
    use Test::Sims;

    make_rand phone => [qw(555-555-5555 212-123-4567)];

    sub sim_phone {
        return rand_phone();
    }

    sub sim_thing {
        return 42;
    }

    export_sims();
}

{

    package Foo;

    Phone->import;

    ::can_ok( Foo => "sim_phone", "sim_thing" );
}

{

    package Bar;

    Phone->import(":sims");

    ::can_ok( Bar => "sim_phone", "sim_thing" );
}

{

    package Baz;

    Phone->import("sim_thing");

    ::can_ok( Baz => "sim_thing" );
}

done_testing();
