package Text::IQ;

use warnings;
use strict;
use Carp;
use Search::Tools::Tokenizer;
use Search::Tools::UTF8;
use Search::Tools::SpellCheck;
use Scalar::Util qw( openhandle );
use File::Basename;
use Data::Dump qw( dump );

our $VERSION = '0.004';

=head1 NAME

Text::IQ - naive intelligence about a body of text

=head1 SYNOPSIS

 use Text::IQ::EN;  # English text
 my $file = 'path/to/file';
 my $iq = Text::IQ::EN->new( $file );
 printf("Number of words: %d\n", $iq->num_words);
 printf("Avg word length: %d\n", $iq->word_length);
 printf("Number of sentences: %d\n", $iq->num_sentences);
 printf("Avg sentence length: %d\n", $iq->sentence_length);
 printf("Misspellings: %d\n", $iq->num_misspellings);
 printf("Grammar errors: %d\n", $iq->num_grammar_errors);
 
 # access internal Search::Tools::TokenList
 my $tokens = $iq->tokens;

=cut

=head1 METHODS

=head2 new( I<path/to/file> )

=head2 new( I<scalar_ref> )

Constructor method. Returns Text::IQ object. Single argument
is either the path to a file or a reference to a simple scalar
string.

=cut

sub new {
    my $class = shift;
    my $self  = bless {
        num_words             => 0,
        total_word_length     => 0,
        num_sentences         => 0,
        total_sentence_length => 0,
        tmp_sent_len          => 0,
        num_syllables         => 0,
        num_complex_words     => 0,
    }, $class;
    my $text = shift;
    if ( !defined $text ) {
        croak "text required";
    }
    if ( ref $text eq 'SCALAR' ) {
        $self->{_text} = to_utf8($$text);
    }
    else {
        $self->{_text} = to_utf8( Search::Tools->slurp($text) );
    }
    my $tokenizer = Search::Tools::Tokenizer->new();
    $self->{_tokens}
        = $tokenizer->tokenize( $self->{_text}, sub { $self->_examine(@_) },
        );
    $self->{avg_word_length}
        = $self->{total_word_length} / $self->{num_words};
    $self->{avg_sentence_length}
        = $self->{total_sentence_length} / $self->{num_sentences};
    return $self;
}

sub _examine {
    my $self  = shift;
    my $token = shift;
    $self->{num_words}++;
    $self->{total_word_length} += $token->u8len;
    my $syll = $self->get_num_syllables("$token");
    $self->{num_syllables} += $syll;
    if ( $syll > 2 and $token !~ m/\-/ ) {
        $self->{num_complex_words}++;
    }
    if ( $token->is_sentence_start ) {
        $self->{num_sentences}++;
        $self->{total_sentence_length} += $self->{tmp_sent_len};
        $self->{tmp_sent_len} = 0;
    }
    $self->{tmp_sent_len}++;
}

=head2 get_sentences

Wrapper around the L<Search::Tools::TokenList> as_sentences() method.
Passes through the same arguments as as_sentences().

=head2 num_words

Returns the number of words in the text.

=head2 num_sentences

Returns the number of sentences in the text.

=head2 avg_word_length

Returns the average number of characters in each word.

=head2 avg_sentence_length

Returns the average length of each sentence.

=head2 num_complex_words

Returns the number of words with more than 2 syllables.

=head2 num_syllables

Returns the total number of syllables in the text.

=cut

sub get_sentences       { shift->{_tokens}->as_sentences(@_) }
sub num_words           { shift->{num_words} }
sub num_sentences       { shift->{num_sentences} }
sub avg_word_length     { shift->{avg_word_length} }
sub avg_sentence_length { shift->{avg_sentence_length} }
sub num_complex_words   { shift->{num_complex_words} }
sub num_syllables       { shift->{num_syllables} }

# see http://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_test
# and http://www.plainlanguage.com/Resources/readability.html
# and Lingua::EN::Fathom

=head2 flesch

Returns the Flesch score per L<http://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_test>.

=cut

sub flesch {
    my $self = shift;
    return
          206.835
        - ( 1.015 * ( $self->{num_words} / $self->{num_sentences} ) )
        - ( 84.6 *  ( $self->{num_syllables} / $self->{num_words} ) );
}

=head2 fog

Returns the Fog score per L<http://www.plainlanguage.com/Resources/readability.html>.

=cut

sub fog {
    my $self = shift;
    return ( ( $self->{num_words} / $self->{num_sentences} )
        + ( ( $self->{num_complex_words} / $self->{num_words} ) * 100 ) )
        * 0.4;
}

=head2 kincaid

Returns the Kincaid score per L<http://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_test>.

=cut

sub kincaid {
    my $self = shift;
    return ( 11.8 * ( $self->{num_syllables} / $self->{num_words} ) )
        + ( 0.39 * ( $self->{num_words} / $self->{num_sentences} ) ) - 15.59;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-iq at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-IQ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::IQ

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-IQ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-IQ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-IQ>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-IQ/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2014 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
