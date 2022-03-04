# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Unicode::ICU::Locale;

use strict;
use warnings;

=head1 NAME

Unicode::ICU::Locale - Locale data via L<ICU|https://icu.unicode.org/>

=head1 SYNTAX

    my $default = Unicode::ICU::Locale::DEFAULT_LOCALE;

    # U.S. English in German:
    my $dispname = Unicode::ICU::Locale::get_display_name('en-US', 'de');

    my $all_locales_ar = Unicode::ICU::Locale::list_locales();

    if ( Unicode::ICU::Locale::is_rtl($default) ) {
        # .. the default locale is right-to-left
    }

=head1 DESCRIPTION

This module exposes parts of ICU’s locale interface.

=head1 CONSTANTS

=over

=item * C<DEFAULT_LOCALE> - e.g., C<en>

=item * C<LAYOUT_LTR>, C<LAYOUT_RTL>, C<LAYOUT_TTB>, and C<LAYOUT_BTT>
as from ICU’s F<uloc.h>.

=back

=head1 FUNCTIONS

=head2 $locales_ar = list_locales()

Returns a reference to an array of the current ICU library’s locales’
IDs (e.g., C<en>).

=head2 $display = get_display_name( [$LOCALE_ID [, $DISPLAY_LOCALE_ID]] )

Returns a given locale’s display name.

With 0 arguments this returns the default locale name, in the default
locale. With 1 argument it gives the given locale name, in the default
locale. With 2 arguments it gives the 1st locale name in the 2nd locale.

undef just means the default locale, so if you want to show the default
locale in a specific locale, do:

    Unicode::ICU::Locale::get_display_name(undef, 'de');

See the L</SYNOPSIS> above for more examples.

=head2 $yn = is_rtl( [$LOCALE_ID] )

A convenience function that wraps C<get_character_orientation()> with
logic to return truthy/falsy to indicate whether $LOCALE_ID (or,
in its absence, ICU’s default locale) is right-to-left.

=head2 $orient = get_character_orientation( [$LOCALE_ID] )

Returns the given locale’s character orientation as one of the
C<LAYOUT_*> constants described above. If $LOCALE_ID is undef or not
given, ICU’s default locale is used. English, for example, is
LAYOUT_LTR, while Arabic is LAYOUT_RTL.

This can theoretically accommodate non-LTR, non-RTL locales (e.g.,
traditional East Asian vertical scripts), but since most applications
don’t serve such locales you I<probably> don’t need this function
and can instead just call C<is_rtl()> above.

=head2 $orient = get_line_orientation( [$LOCALE_ID] )

Like C<get_character_orientation()> but returns the locale’s line
orientation. (NB: In the author’s ICU, all locales are LAYOUT_TTB.)

=head2 $locale_id = canonicalize( $LOCALE_ID )

Returns $LOCALE_ID in what ICU thinks is its canonical form.
(For example, C<en-US> becomes C<en_US>.)

(NB: $LOCALE_ID is required; if you want ICU’s default locale’s
canonical form, just get C<DEFAULT_LOCALE>, above.)

=cut

#----------------------------------------------------------------------

use Unicode::ICU ();

#----------------------------------------------------------------------

1;
