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
use Unicode::ICU::ListFormatter ();

if (!Unicode::ICU::ListFormatter->can('format_and')) {
    plan skip_all => sprintf('This ICU version (%s) can’t format lists.', Unicode::ICU::ICU_VERSION);
}

my $long_ascii = 'a' x 256;

my $got = Unicode::ICU::ListFormatter::format_and('de',
    123, 234, "épée",
    $long_ascii
);

is(
    $got,
    match( qr<123.+234.+épée.+$long_ascii> ),
    'expected string - format_and()',
);

like($got, qr<und>, '... and it has the expected conjunction');

#----------------------------------------------------------------------

my $bad_unicode = do {
    no warnings 'utf8';
    "hey\x{d83f}now";
};

my $err = dies {
    Unicode::ICU::ListFormatter::format_and('de', 123, $bad_unicode, 234);
};

like($err, qr<U_INVALID_CHAR_FOUND>, 'format_and() rejects invalid Unicode');

#----------------------------------------------------------------------

SKIP: {
    skip 'format_or() is undefined; your ICU must be old.' if !Unicode::ICU::ListFormatter->can('format_or');
    $got = Unicode::ICU::ListFormatter::format_or('de', 123, 234, "épée");

    is(
        $got,
        check_set(
            match( qr<123> ),
            match( qr<234> ),
            match( qr<épée> ),
        ),
        'expected string - format_or()',
    );

    like($got, qr<oder>, '... and it has the expected conjunction');
}

done_testing;
