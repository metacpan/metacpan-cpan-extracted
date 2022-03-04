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

use Test2::V0;
use Test2::Plugin::NoWarnings;

binmode *STDOUT, ':encoding(utf-8)';

use Unicode::ICU::IDN;

if (!Unicode::ICU::IDN->can('new')) {
    plan skip_all => sprintf('This ICU version (%s) lacks the IDN interface we need.', Unicode::ICU::ICU_VERSION);
}

my $idn = Unicode::ICU::IDN->new();

is(
    $idn->name2ascii("épée.com"),
    'xn--pe-9iab.com',
    'épée.com to ASCII',
);

do {
    use utf8;

    is(
        $idn->name2unicode('xn--kxawhkp.gr'),
        'νίκος.gr',
        'νίκος.gr from ASCII',
    );
};

my $err = dies {
    use utf8;
    no warnings 'utf8';
    diag $idn->name2ascii("hey\x{d83f}now.épée.com");
};

is(
    $err,
    object {
        prop blessed => 'Unicode::ICU::X::BadIDN';

        call get_message => match( qr<DISALLOWED> );

        call [ get => 'error' ] => $Unicode::ICU::IDN::ERROR{'DISALLOWED'};
    },
    'name2ascii() rejects invalid Unicode',
);

for my $const ( qw(
    UIDNA_DEFAULT
    UIDNA_ALLOW_UNASSIGNED
    UIDNA_USE_STD3_RULES
    UIDNA_CHECK_BIDI
    UIDNA_CHECK_CONTEXTJ
    UIDNA_NONTRANSITIONAL_TO_ASCII
    UIDNA_NONTRANSITIONAL_TO_UNICODE
    UIDNA_CHECK_CONTEXTO
) ) {
    can_ok( 'Unicode::ICU::IDN', $const );
}

done_testing;

1;
