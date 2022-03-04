# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Unicode::ICU::ListFormatter;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Unicode::ICU::ListFormatter - List formatting via ICU

=head1 SYNOPSIS

    # “Hans und Franz”
    my $and_list = Unicode::ICU::ListFormatter::format_and(
        'de',   # German
        'Hans',
        'Franz',
    );

    # “Maedchen oder Weibchen”
    my $or_list = Unicode::ICU::ListFormatter::format_or(
        'de',
        'Maedchen',
        'Weibchen',
    );

=head1 DESCRIPTION

Use this to create properly localized lists. See examples above.

ICU supports more flexible list formatting than this module exposes;
more can be added as needed.

=head1 COMPATIBILITY

This requires ICU 63 or later.

=cut

#----------------------------------------------------------------------

use Unicode::ICU;

#----------------------------------------------------------------------

=head1 FUNCTIONS

=head2 $str = format_and( $LOCALE, @ELEMENTS )

Formats an “and” list per the given $LOCALE.

=head2 $str = format_or( $LOCALE, @ELEMENTS )

Like C<format_and()> but outputs an “or” list. Also requires
ICU 67 or later.

=cut

1;
