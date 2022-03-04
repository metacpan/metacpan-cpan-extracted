# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Unicode::ICU::MessagePatternPart;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Unicode::ICU::MessagePatternPart

=head1 SYNOPSIS

    my $parse = Unicode::ICU::MessagePattern->new('My name is {name}.');

    my $part = $parse->get_part(0);

=head1 DESCRIPTION

This class implements functionality for
L<MessagePattern parts|https://unicode-org.github.io/icu-docs/apidoc/dev/icu4c/classicu_1_1MessagePattern_1_1Part.html>.

It is not directly instantiated.

=head1 COMPATIBILITY

This requires ICU 4.8 or later.

=head1 SEE ALSO

L<Unicode::ICU::MessagePattern>

=cut

#----------------------------------------------------------------------

use Unicode::ICU;

our %PART_TYPE;
our %ARG_TYPE;

#----------------------------------------------------------------------

=head1 CONSTANTS

=head2 %PART_TYPE

Name-value map corresponding to ICU’s
L<UMessagePatternPartType|https://unicode-org.github.io/icu-docs/apidoc/dev/icu4c/messagepattern_8h.html#a020e83c308fc5d1b2b4a7029cc3d9b42>
enum.

=head2 %ARG_TYPE

Name-value map corresponding to ICU’s
L<UMessagePatternArgType|https://unicode-org.github.io/icu-docs/apidoc/dev/icu4c/messagepattern_8h.html#a2929f87500a04fd66021e3fda6c1f103>
enum.

=head1 METHODS

The following match their C++ counterparts:

=over

=item * C<type()> (cf. L<Unicode::ICU>’s C<%UMSGPAT_PART_TYPE>)

=item * C<arg_type()> (cf. L<Unicode::ICU>’s C<%UMSGPAT_ARG_TYPE>)

=item * C<value()>

=back

The following are like their C++ counterparts but return actual
character indices, not C<UChar *> indices:

=over

=item * C<index()>

=item * C<length()>

=item * C<limit()>

=back

Getting actual character indices matters if your pattern contains emoji,
CJK, or other code points outside Unicode’s Basic Multilingual Plane,
i.e., 0 - 0xFFFF.

=cut

1;
