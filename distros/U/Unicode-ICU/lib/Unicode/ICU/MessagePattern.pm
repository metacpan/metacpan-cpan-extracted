# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Unicode::ICU::MessagePattern;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Unicode::ICU::MessagePattern - ICU’s L<MessagePattern|https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/classicu_1_1MessagePattern.html> class

=head1 SYNOPSIS

    my $parse = Unicode::ICU::MessagePattern->new('My name is {name}.');

    for my $index ( 0 .. ($parse->count_parts() - 1) ) {
        my $part = $parse->get_part($index);

        # ..
    }

=head1 DESCRIPTION

This module exposes useful parts of ICU’s MessagePattern API. It
facilitates parsing localizable pattern strings.

=head1 COMPATIBILITY

This requires ICU 4.8 or later.

=head1 SEE ALSO

L<Unicode::ICU::MessagePatternPart>

=cut

#----------------------------------------------------------------------

use Unicode::ICU;

#----------------------------------------------------------------------

=head1 METHODS

=head2 $obj = I<CLASS>->new( $PATTERN );

Parses $PATTERN and returns an instance of this class.

=head2 $count = I<OBJ>->count_parts()

Returns the number of parts in the parse.

=head2 $part = I<OBJ>->get_part( $INDEX )

Returns a L<Unicode::ICU::MessagePatternPart> instance that represents
the part. ($INDEX is 0-based.)

=cut

1;
