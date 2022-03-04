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

use Unicode::ICU::Locale;

my $default = Unicode::ICU::Locale::DEFAULT_LOCALE;

like( $default, qr<[a-z]>, 'DEFAULT_LOCALE' );

do {
    use utf8;

    is(
        Unicode::ICU::Locale::get_display_name('en', 'en'),
        'English',
        'English, in English',
    );

    is(
        Unicode::ICU::Locale::get_display_name('en', 'fr'),
        'anglais',
        'English, in French',
    );

    is(
        Unicode::ICU::Locale::get_display_name('fr', 'de'),
        'Französisch',
        'French, in German',
    );

    is(
        Unicode::ICU::Locale::get_display_name('ru', 'ru'),
        'русский',
        'Russian, in Russian',
    );

    #----------------------------------------------------------------------

    is(
        Unicode::ICU::Locale::get_display_name(),
        Unicode::ICU::Locale::get_display_name($default, $default),
        'Default locale, in default (no args)',
    );

    is(
        Unicode::ICU::Locale::get_display_name(undef, undef),
        Unicode::ICU::Locale::get_display_name($default, $default),
        'Default locale, in default (2 x undef)',
    );

    is(
        Unicode::ICU::Locale::get_display_name('fr'),
        Unicode::ICU::Locale::get_display_name('fr', $default),
        'French, in default',
    );

    is(
        Unicode::ICU::Locale::get_display_name($default, 'fr'),
        Unicode::ICU::Locale::get_display_name(undef, 'fr'),
        'Default locale, in French',
    );
};

my @orientation = (
    [ en => 'LTR', 'TTB' ],
    [ ar => 'RTL', 'TTB', ],

    # My own ICU lacks any non-LTR, non-RTL locales.
    # But it’s nice to know ICU can handle them anyway. :)
);

for my $loc_id ( @{ Unicode::ICU::Locale::list_locales() } ) {
    my $orient = Unicode::ICU::Locale::get_line_orientation($loc_id);
    my $orient2 = Unicode::ICU::Locale::get_character_orientation($loc_id);
    diag "weird: $loc_id" if $orient != Unicode::ICU::Locale::LAYOUT_TTB;
}

for my $loc_orient_ar (@orientation) {
    my ($loc_id, $char_orient, $line_orient) = @$loc_orient_ar;

    my $disp_name = Unicode::ICU::Locale::get_display_name($loc_id);
    $disp_name .= " ($loc_id)";

    is(
        Unicode::ICU::Locale::get_character_orientation($loc_id),
        Unicode::ICU::Locale->can("LAYOUT_$char_orient")->(),
        "$disp_name has $char_orient characters",
    );

    is(
        Unicode::ICU::Locale::get_line_orientation($loc_id),
        Unicode::ICU::Locale->can("LAYOUT_$line_orient")->(),
        "$disp_name has $line_orient lines",
    );

    is(
        (Unicode::ICU::Locale::get_character_orientation($loc_id) == Unicode::ICU::Locale::LAYOUT_RTL),
        !!Unicode::ICU::Locale::is_rtl($loc_id),
        "$disp_name: is_rtl()",
    );
}

is(
    (Unicode::ICU::Locale::get_character_orientation() == Unicode::ICU::Locale::LAYOUT_RTL),
    !!Unicode::ICU::Locale::is_rtl(),
    "default locale: is_rtl()",
);

is(
    Unicode::ICU::Locale::list_locales(),
    bag {
        item 'en';
        item 'ar';
        etc();
    },
    'list_locales()',
);

is(
    Unicode::ICU::Locale::canonicalize("en-US"),
    "en_US",
    'canonicalize “en-US”',
);

is(
    dies { Unicode::ICU::Locale::canonicalize() },
    match( qr<locale>i ),
    'canonicalize() needs an argument',
);

is(
    dies { Unicode::ICU::Locale::canonicalize(undef) },
    match( qr<locale>i ),
    'canonicalize() needs a defined argument',
);

done_testing;
