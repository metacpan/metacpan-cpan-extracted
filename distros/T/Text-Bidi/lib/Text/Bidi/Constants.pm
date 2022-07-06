
use warnings;
use integer;
use strict 'vars';
package Text::Bidi::Constants;
# ABSTRACT: Constants for Text::Bidi
$Text::Bidi::Constants::VERSION = '2.18';

use Text::Bidi::private;
SYM: for my $sym ( keys %Text::Bidi::private:: ) {
    next unless $sym =~ /^FRIBIDI_/;


    for my $kind ( qw(Type Mask Par Flag Flags) ) {
        if ( $sym =~ /FRIBIDI_\U${kind}\E_([A-Z_]*)$/ ) {
            *{"Text::Bidi::${kind}::$1"} = *{"Text::Bidi::private::$sym"};
            next SYM;
        }
    }


    if ( $sym =~ /FRIBIDI_JOINING_TYPE_([A-Z])_VAL/ ) {
        *{"Text::Bidi::Joining::$1"} = *{"Text::Bidi::private::$sym"};
        next SYM;
    }


    if ( $sym =~ /FRIBIDI_CHAR_([A-Z_]*)$/ ) {
        no warnings 'once';
        ${"Text::Bidi::Char::$1"} = \chr(${"Text::Bidi::private::$sym"});
        next SYM;
    }
}

*{"Text::Bidi::Flag::ARABIC"} = *{"Text::Bidi::private::FRIBIDI_FLAGS_ARABIC"};


1;

__END__

=pod

=head1 NAME

Text::Bidi::Constants - Constants for Text::Bidi

=head1 VERSION

version 2.18

=head1 DESCRIPTION

This module provides various constants defined by the fribidi library. They 
can be used with some of the low-level functions in L<Text::Bidi>, such as 
L<Text::Bidi/get_bidi_types>, but are of little interest as far as standard 
usage is concerned.

Note that, though these are variables, they are read-only.

=over

=item *

Constants of the form B<FRIBIDI_TYPE_FOO> are available as 
C<$Text::Bidi::Type::FOO>. See fribidi_get_bidi_type(3) for possible constants.

=item *

Constants of the form B<FRIBIDI_MASK_FOO> are converted to 
C<$Text::Bidi::Mask::FOO>. See F<fribidi-bidi-types.h> for possible masks and 
how to use them.

=item *

Constants of the form B<FRIBIDI_PAR_FOO> are converted to 
C<$Text::Bidi::Par::FOO>. See fribidi_get_par_embedding_levels(3) for 
possible constants.

=item *

Constants of the form B<FRIBIDI_FLAG_FOO> or B<FRIBIDI_FLAGS_FOO> are 
converted to C<$Text::Bidi::Flag::FOO> or C<$Text::Bidi::Flag::FOO>. See 
fribidi_reorder_line(3) and fribidi_shape(3) for possible constants. As a 
special case, B<FRIBIDI_FLAGS_ARABIC> is also available as 
C<$Text::Bidi::Flag::ARABIC>

=item *

Constants of the form B<FRIBIDI_JOINING_TYPE_FOO> are converted to 
C<$Text::Bidi::Joining::FOO>. See fribidi_get_joining_type(3) for 
possible constants.

=item *

Constants of the form B<FRIBIDI_CHAR_FOO> are converted to the character they 
represent, and assigned to C<$Text::Bidi::Char::FOO>. See 
F<fribidi-unicode.h> for possible constants.

=back

=head1 SEE ALSO

L<Text::Bidi>

=head1 AUTHOR

Moshe Kamensky <kamensky@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Moshe Kamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
