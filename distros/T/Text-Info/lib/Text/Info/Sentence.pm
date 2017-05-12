package Text::Info::Sentence;
use Moose;
use namespace::autoclean;

extends 'Text::Info::BASE';

=encoding utf-8

=head1 NAME

Text::Info::Sentence - An object-oriented representation of a sentence.

=head1 DESCRIPTION

You should never instantiate objects of this class directly, but instead
use L<Text::Info> to create a general text object and retrieve the
L<Text::Info::Sentence> objects from that with its C<sentences()> method.

=head1 METHODS

=over

=item words()

Returns an array reference containing the sentence's words. This method is
derived from L<Text::Info::BASE>.

=item word_count()

Returns the number of words in the sentence. This is a helper method and is
derived from L<Text::Info::BASE>.

=item avg_word_length()

Returns the average length of the words in the sentence. This is a helper
method and is derived from L<Text::Info::BASE>.

=item ngrams( $size )

Returns an array reference containing the sentence's ngrams of size C<$size>.
Default size is 2 (i.e. bigrams). This method is derived from
L<Text::Info::BASE>.

=item unigrams()

Returns an array reference containing the sentence's unigrams, i.e. the same
as C<ngrams(1)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item bigrams()

Returns an array reference containing the sentence's bigrams, i.e. the same
as C<ngrams(2)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item trigrams()

Returns an array reference containing the sentence's trigrams, i.e. the same
as C<ngrams(3)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item quadgrams()

Returns an array reference containing the sentence's quadgrams, i.e. the same
as C<ngrams(4)>. This is a helper method and is derived from L<Text::Info::BASE>.

=cut

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
