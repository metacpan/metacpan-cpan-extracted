package Text::Info::Readability;
use Moose;
use namespace::autoclean;

extends 'Text::Info::BASE';

=encoding utf-8

=head1 NAME

Text::Info::Readability - Information about a text's readability.

=head1 DESCRIPTION

See Wikipedia's article about L<readability tests|https://en.wikipedia.org/wiki/Readability_test> for more information.

You should never instantiate objects of the class directly, but instead
use L<Text::Info> to access this class' methods.

=head1 METHODS

=over

=item can_be_calculated()

Returns true if the text's readability can be calculated, false otherwise.

=cut

has 'can_be_calculated' => ( isa => 'Bool', is => 'ro', lazy_build => 1 );

sub _build_can_be_calculated {
    my $self = shift;

    return undef if ( $self->text           eq '' );
    return undef if ( $self->sentence_count == 0  );
    return undef if ( $self->word_count     == 0  );

    return 1;
}

=item fres()

Returns the text's "Flesch reading ease score" (FRES), a text readability score.
See L<Flesch–Kincaid readability tests|https://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_tests> on Wikipedia for more information.

Returns undef is it's impossible to calculate the score, for example if the
there is no text, no sentences that could be detected etc.

=cut

has 'fres' => ( isa => 'Maybe[Num]', is => 'ro', lazy_build => 1 );

sub _build_fres {
    my $self = shift;

    return undef unless ( $self->can_be_calculated );

    my $words_per_sentence = $self->word_count / $self->sentence_count;
    my $syllables_per_word = $self->syllable_count / $self->word_count;

    my $score = 206.835 - ( ($words_per_sentence * 1.015) + ($syllables_per_word * 84.6) );

    return sprintf( '%.2f', $score );
}

=item fkrgl()

Returns the text's "Flesch–Kincaid reading grade level", a text readability score.
See L<Flesch–Kincaid readability tests|https://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_tests> on Wikipedia for more information.

Returns undef is it's impossible to calculate the score, for example if the
there is no text, no sentences that could be detected etc.

=cut

has 'fkrgl' => ( isa => 'Maybe[Num]', is => 'ro', lazy_build => 1 );

sub _build_fkrgl {
    my $self = shift;

    return undef unless ( $self->can_be_calculated );

    my $words_per_sentence = $self->word_count / $self->sentence_count;
    my $syllables_per_word = $self->syllable_count / $self->word_count;

    my $score = ( ($words_per_sentence * 0.39) + ($syllables_per_word * 11.8) ) - 15.59;

    return sprintf( '%.2f', $score );
}

__PACKAGE__->meta->make_immutable;

1;

=back

=head1 SEE ALSO

=over 4

=item * L<Text::Info>

=back

=head1 AUTHOR

Tore Aursand, C<< <toreau at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.