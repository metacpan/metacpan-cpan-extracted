#!/usr/bin/env perl

# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

# We traffic exclusively in UTF-8-encoded characters, so this makes sense.
use utf8;

use Test2::V0;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Explain;

use Unicode::ICU ();
use Unicode::ICU::MessageFormat ();
use Unicode::ICU::Locale ();

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $can_take_named = Unicode::ICU::MessageFormat::CAN_TAKE_NAMED_ARGUMENTS;

my $icu_version = Unicode::ICU::ICU_MAJOR_VERSION . '.' . Unicode::ICU::ICU_MINOR_VERSION;

# CentOS 7’s provided ICU catches unused; CloudLinux 6’s does not.
my $icu_catches_unused_args = $icu_version > '50.2';

my $pattern = "You “have” {0, plural, one {# single} other {# plural}}.";

my $mfmt = Unicode::ICU::MessageFormat->new();

is(
    $mfmt->get_locale(),
    Unicode::ICU::Locale::DEFAULT_LOCALE,
    'get_locale()',
);

is( $mfmt->format("no args"), "no args", 'no arguments' );
is( $mfmt->format("no args", undef), "no args", 'no arguments (undef args)' );

my $got = $mfmt->format($pattern, [0]);
like($got, qr<plural>, '0 is other');

$got = $mfmt->format($pattern, [1]);
like($got, qr<single>, '1 is singular');

$got = $mfmt->format($pattern, [2]);
like($got, qr<plural>, '2 is other');

SKIP: {
    skip 'Needs named argument support' if !$can_take_named;

    my $got = $mfmt->format($pattern, { 0 => 2 });
    like($got, qr<plural>, '2 is other (args are hashref)');

#----------------------------------------------------------------------

    my $pattern = "You “have” {count, plural, one {# single} other {# plural}}.";

    $got = $mfmt->format($pattern, {count => 0});
    like($got, qr<plural>, '0 is other (named)');

    $pattern = "{num, number, integer} is an integer.";
    $got = $mfmt->format($pattern, {num => 86400.345});
    like($got, qr<8.?6.?4.?00 >, 'decimal part chopped off');

    $pattern = "Hello, {name}. The year is {time, date, ::y}.";
    $got = $mfmt->format($pattern, {name => 'Hal', time => 86400});
    like($got, qr<Hal.*1970>, 'named parameter substitution');
}

#----------------------------------------------------------------------

is(
    $mfmt->format("\xe9 {0}", ["\xe9"]),
    "\xe9 \xe9",
    'downgraded non-ASCII character in pattern and argument',
);

#----------------------------------------------------------------------

SKIP: {
    skip 'Needs named argument support' if !$can_take_named;

    my $err = dies { $mfmt->format("{num, adgcasdgda}", {num => 86400.345}) };
    is(
        $err,
        object {
            prop blessed => 'Unicode::ICU::X::ICU';
        },
        'format() throws as expected if given invalid string',
    );

    is(
        Unicode::ICU::get_error_name( $err->get('error') ),
        'U_ILLEGAL_ARGUMENT_ERROR',
        'format() error number',
    );

    $err = dies { $mfmt->format("\x{1fede} {num, } ahaha", {num => 86400.345}) };
    is(
        $err,
        object {
            prop blessed => 'Unicode::ICU::X::ICU';
            call [ get => 'extra' ] => match( qr<3> );
        },
        'error offset gives true character offset',
    );

    $err = dies { $mfmt->format("{haha}") };
    like($err, qr<argument>, 'named args but no args given');

    $err = dies { $mfmt->format("{haha}", undef) };
    like($err, qr<argument>, 'named args but undef args given');

    $err = dies { $mfmt->format("{haha}", []) };
    is(
        $err,
        check_set(
            match( qr<hash> ),
            match( qr<ARRAY> ),
        ),
        'named args but non-hashref given',
    );
}

my $err = dies { $mfmt->format("{0}", 123123) };
is(
    $err,
    check_set(
        match( qr<array> ),
        match( qr<123123> ),
    ),
    'positional args, but plain scalar given',
);

SKIP: {
    skip sprintf("This ICU (%s) may not catch unused args.", Unicode::ICU::ICU_VERSION) if !$icu_catches_unused_args;

    $err = dies { $mfmt->format("{1}", [123]) };
    is(
        $err,
        check_set(
            match( qr<0> ),
            match( qr<index> ),
            match( qr<argument> ),
        ),
        '1-indexed args rather than 0-indexed',
    );
}

$err = dies { $mfmt->format("{0}", [123, 234]) };
is(
    $err,
    check_set(
        match( qr<1> ),
        match( qr<2> ),
        match( qr<arguments> ),
    ),
    'args count mismatch',
);

$err = dies { $mfmt->format("{0} {1} {2}", [1, 2, undef]) };
is(
    $err,
    check_set(
        match( qr<undef> ),
        match( qr<2> ),
    ),
    'undef in args list',
);

$err = dies { $mfmt->format("{0} {1} {2}", [0, 0, "abc\x00123"]) };
is(
    $err,
    check_set(
        match( qr<NUL> ),
        match( qr<2> ),
    ),
    'NUL byte in arg',
);

SKIP: {
    skip sprintf("This ICU (%s) may not catch unused args.", Unicode::ICU::ICU_VERSION) if !$icu_catches_unused_args;

    $err = dies { $mfmt->format("{0} {2}", [0, 0, "abc123"]) };
    is(
        $err,
        check_set(
            match( qr<1> ),
            match( qr<argument> ),
        ),
        '“hole” in positional args list',
    );
}

SKIP: {
    skip 'Needs named argument support' if !$can_take_named;

    is(
        $mfmt->format("{0} {2}", { 0 => 1, 2 => 3 }),
        "1 3",
        '“hole” in positional args but named args given',
    );
}

$err = dies { $mfmt->format("{0}") };
is(
    $err,
    check_set(
        match(qr<1>),
        match(qr<argument>),
    ),
    'arg needed but none given',
);

$err = dies { $mfmt->format("{0} {1} {2}") };
is(
    $err,
    check_set(
        match(qr<3>),
        match(qr<argument>),
    ),
    'args needed but none given',
);

$err = dies { $mfmt->format("{0} {1} {2}", undef) };
is(
    $err,
    check_set(
        match(qr<3>),
        match(qr<argument>),
    ),
    'args needed but undef given',
);

SKIP: {
    skip 'Needs named argument support' if !$can_take_named;

    $err = dies { $mfmt->format("{foo} {bar}", { foo => 1 } ) };
    is(
        $err,
        check_set(
            match(qr<1>),
            match(qr<2>),
        ),
        'named args: counts mismatch',
    );

    $err = dies { $mfmt->format("{foo} {bar}", { foo => 1, baz => 2 } ) };
    is(
        $err,
        check_set(
            match(qr<foo>),
            match(qr<bar>),
            match(qr<baz>),
        ),
        'named args: keys mismatch',
    );

    is(
        $mfmt->format("{a} {b} {a}", {a => "\xe9", b => "\xea"}),
        "\xe9 \xea \xe9",
        'named args: repeat',
    );
}

$err = dies { $mfmt->format("") };
ok($err, "format(): empty string");

done_testing();
