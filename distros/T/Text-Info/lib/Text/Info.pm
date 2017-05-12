package Text::Info;
use Moose;
use namespace::autoclean;

extends 'Text::Info::BASE';

use Text::Info::Sentence;
use Text::Info::Readability;

=encoding utf-8

=head1 NAME

Text::Info - Retrieve information about, and do analysis on, text.

=head1 VERSION

Version 0.01.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Text::Info;

    my $text = Text::Info->new( "Some text..." );

    say "The text is written in language '" . $text->language . "', and";
    say "has a readability score (FRES) of " . $text->readability->fres;

=head1 DESCRIPTION

L<Text::Info> is an extensible and easy to use solution for retrieving useful
information about texts based on the L<Germanic languages|https://en.wikipedia.org/wiki/Germanic_languages>.

For the time being it has a limited feature set, but the plan is to use this
as a basis for NLP-solutions.

The solution is under heavy development, and the API will definitely change.
Please respect these facts if you intend to use it.

Contributions and suggestions are welcome!

=head1 WARNING!

This solution is - and will be - heavily based on language-specific features.
This means that if you use this solution on languages that doesn't have the
required "support modules", you're on your own. For the time being this only
affects the L<Text::Info::Readability> functionality, but will in the future
also include stemming- and stop word-functionality (and probably many other
things).

What you can do to help on this, is to create the missing supported modules,
for example create a Lingua::__::Syllable module specific for your language.

=head1 METHODS

=over

=item new()

Returns a new L<Text::Info> object. Can take C<text> as a single argument,
optionally C<tld> (top level domain, for better language detection), and/or
optionally C<language> if you want to specify the text's language yourself.

    my $text = Text::Info->new( 'Dette er en norsk tekst.' );

    # ...or...

    my $text = Text::Info->new(
        text => 'Dette er en norsk tekst.',
        tld  => 'no',
    );

    # ...or...

    my $text = Text::Info->new(
        text     => 'Dette er en norsk tekst.'
        language => 'no',
    );

It really doesn't make sense to set both C<tld> and C<language>, as the
former is a helper for detecting the correct language of the text, while
the latter overrides whatever that detection algorithm returns.

=item readability()

Returns an instance of the text's L<Text::Info::Readability> class, which in turn
can be used to retrieve L<readability information|https://en.wikipedia.org/wiki/Readability_test> about the text in question.

=cut

has 'readability' => ( isa => 'Text::Info::Readability', is => 'ro', lazy_build => 1 );

sub _build_readability {
    my $self = shift;

    return Text::Info::Readability->new(
        text     => $self->text,
        tld      => $self->tld,
        language => $self->language,
    );
}

=item sentences()

Returns an array reference of the text's sentences as C<Text::Info::Sentence>
objects. This method is derived from L<Text::Info::BASE>.

Keep in mind that this method tries to remove any separators, so the sentences
returned should NOT contain those. For example "This is a sentence!" will be
returned as "This is a sentence".

=item sentence_count()

Returns the number of sentences in the text. This method is derived from
L<Text::Info::BASE>.

=item avg_sentence_length()

Returns the average length of the sentences in the text. This method is derived
from L<Text::Info::BASE>.

=item words()

Returns an array reference containing the text's words. This method is derived
from L<Text::Info::BASE>.

=item word_count()

Returns the number of words in the text. This is a helper method and is derived
from L<Text::Info::BASE>.

=item avg_word_length()

Returns the average length of the words in the text. This is a helper method and
is derived from L<Text::Info::BASE>.

=item ngrams( $size )

Returns an array reference containing the text's ngrams of size C<$size>.
Default size is 2 (i.e. bigrams). This method overrides L<Text::Info::BASE>'s
C<ngrams()> method, as it takes into accounts building ngrams based on the
text's sentences, not the text's complete list of words.

=cut

override 'ngrams' => sub {
    my $self = shift;

    my @ngrams = ();

    foreach my $sentence ( @{$self->sentences} ) {
        foreach my $ngram ( @{$sentence->ngrams(@_)} ) {
            push( @ngrams, $ngram );
        }
    }

    return \@ngrams;
};

=item unigrams()

Returns an array reference containing the text's unigrams, i.e. the same
as C<ngrams(1)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item bigrams()

Returns an array reference containing the text's bigrams, i.e. the same
as C<ngrams(2)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item trigrams()

Returns an array reference containing the text's trigrams, i.e. the same
as C<ngrams(3)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item quadgrams()

Returns an array reference containing the text's quadgrams, i.e. the same
as C<ngrams(4)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item syllable_count()

Returns the number of syllables in the text. This method requires that
Lingua::__::Syllable is available for the language in question. This method
is derived from L<Text::Info::BASE>.

=cut

__PACKAGE__->meta->make_immutable;

1;

=back

=head1 SEE ALSO

=over 4

=item * L<Text::Info::Sentence>

=item * L<Text::Info::Readability>

=back

=head1 AUTHOR

Tore Aursand, C<< <toreau at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the web interface at L<https://rt.cpan.org/Dist/Display.html?Name=Text-Info>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Info

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Info>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Info>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Info/>

=item * GitHub

L<https://github.com/toreau/Text-Info>

=back

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
