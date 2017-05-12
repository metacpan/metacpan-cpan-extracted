use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

# use if available
eval { require Test::FailWarnings; Test::FailWarnings->import };

use lib 't/lib';
use TestThrower;

use failures qw/vogon vogon::jeltz human::arthur/;

subtest 'throw unnested failure' => sub {
    my $err;
    eval { failure::vogon->throw };
    ok( $err = $@, 'caught thrown error' );
    isa_ok( $err, $_ ) for qw/failure failure::vogon/;
};

subtest 'throw nested failure' => sub {
    my $err;
    eval { failure::vogon::jeltz->throw };
    ok( $err = $@, 'caught thrown error' );
    isa_ok( $err, $_ ) for qw/failure failure::vogon failure::vogon::jeltz/;

    eval { failure::human::arthur->throw };
    ok( $err = $@, 'caught thrown error' );
    isa_ok( $err, $_ ) for qw/failure failure::human failure::human::arthur/;
};

subtest 'stringification' => sub {
    my $err;
    eval { failure::vogon::jeltz->throw };
    ok( $err = $@, 'caught thrown error (no message)' );
    is( "$err", "Caught failure::vogon::jeltz\n", "stringification (no message)" );

    eval { failure::vogon::jeltz->throw("bypass over budget") };
    ok( $err = $@, 'caught thrown error (string message)' );
    is(
        "$err",
        "Caught failure::vogon::jeltz: bypass over budget\n",
        "stringification (string message)"
    );

    eval { failure::vogon::jeltz->throw( { msg => "bypass over budget" } ) };
    ok( $err = $@, 'caught thrown error (message in hashref)' );
    is(
        "$err",
        "Caught failure::vogon::jeltz: bypass over budget\n",
        "stringification (message in hashref)"
    );
};

subtest 'trace' => sub {
    my $err;
    eval { failure::vogon::jeltz->throw( { trace => 'STACK TRACE' } ) };
    ok( $err = $@, 'caught thrown error (with trace)' );
    is( $err->message, "Caught failure::vogon::jeltz", "message method has no trace" );
    is(
        "$err",
        "Caught failure::vogon::jeltz\n\nSTACK TRACE\n",
        "stringification has stack trace"
    );

    eval { failure::vogon::jeltz->throw( { trace => failure->line_trace } ) };
    ok( $err = $@, 'caught thrown error (with line trace)' );
    like(
        "$err",
        qr/Caught failure::vogon::jeltz\n\nFailure caught at t\/basic\.t line \d+\.?\n/,
        "stringification with line trace"
    );

    eval { deep_throw( 'failure::vogon::jeltz', "Ouch!", 'croak_trace' ) };
    ok( $err = $@, 'caught thrown error (with croak trace)' );
    like(
        "$err",
        qr/Caught failure::vogon::jeltz: Ouch!\n\nFailure caught at t\/basic\.t line \d+\.?\n/,
        "stringification with croak trace"
    );

    eval { deep_throw( 'failure::vogon::jeltz', "Ouch!", 'confess_trace' ) };
    ok( $err = $@, 'caught thrown error (with confess trace)' );
    like(
        "$err",
        qr/Caught failure::vogon::jeltz: Ouch!\n\nFailure caught at t\/lib\/TestThrower\.pm line \d+\.?\n\s+Baz::baz/,
        "stringification with croak trace"
    );
};

subtest 'payload' => sub {
    my $err;
    my $payload = { foo => 'bar' };
    eval {
        failure::vogon::jeltz->throw( { msg => "bypass over budget", payload => $payload } );
    };
    ok( $err = $@, 'caught thrown error' );
    is_deeply( $err->payload, $payload, "payload is correct" );
};

done_testing;
#
# This file is part of failures
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
