# Copyright 2018 Francesco Nidito. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Text::Shingle;

use strict;
use Carp;
use Unicode::Normalize;
use Text::NGrammer;

use vars qw($VERSION);
$VERSION = '0.03';

sub new {
  my $class = shift;
  my %config = ( w => 2,       # shingles length
                 norm => 1,    # by default, enable the normalization
                 lang => 'en', # used by the sentencer
               );

  my %param = @_;

  for my $opt (keys %param) {
    croak "option $opt unsupported by version $VERSION of Text::Shingle" unless exists $config{$opt};
    croak "window size cannot be negative or zero" if $opt eq 'w' && $_{w} < 1;
    $config{$opt} = $param{$opt};
  }
  $config{version} = $VERSION;
  return bless \%config, $class;
}

sub _shingles_from_ngrams {
  my $self   = shift;
  my @ngrams = @_;

  my %shingles = ();
  for my $ngram (@ngrams) {
    my $shingle = join(' ', sort {$a cmp $b}
                            map  { ($self->{norm}) ? NFKC($_) : $_ }
                            @{$ngram}
                      );
    $shingles{$shingle} = 1 if (!exists $shingles{$shingle});
  }
  return keys %shingles;
}

sub shingle_array {
  my $self = shift;
  my $n    = scalar(@_);

  return () if $n < $self->{w};

  my $ngrammer = Text::NGrammer->new(lang => $self->{lang});
  return $self->_shingles_from_ngrams($ngrammer->ngrams_array($self->{w}, @_));
}

sub shingle_sentence {
  my $self     = shift;
  my $sentence = shift;

  my $ngrammer = Text::NGrammer->new(lang => $self->{lang});
  return $self->_shingles_from_ngrams($ngrammer->ngrams_sentence($self->{w}, $sentence));
}

sub shingle_text {
  my $self = shift;
  my $text = shift;

  my $ngrammer = Text::NGrammer->new(lang => $self->{lang});
  return $self->_shingles_from_ngrams($ngrammer->ngrams_text($self->{w}, $text));
}

1;

__END__

=head1 NAME

Text::Shingle - Pure Perl implementation of shingles for pieces of text

=head1 SYNOPSIS

 use Text::Shingle;
 my $s = Text::Shingle->new;
 
 my @shingles = $s->shingle_text("a rose is a rose");
 # prints [ (a is) (is rose) (a rose) ]
 print '[ (',join(') (',@shingles),') ]',"\n";

=head1 DESCRIPTION

The module provides a way to extract shingles from a piece of text.  Shingles can then be used for other operations such as clustering, deduplication, etc.

Given a document, the w-shingles represent a set of sorted groups of I<w> adjacent words in the text.  The parameter I<w> is also called the I<width> of the shingle.  For instance, the sentence "a rose is a rose", contains the following shingles of width 2, or 2-shingles: [ (a is), (is rose) and (a rose).  While the shingle "a rose" would be present twice in the text twice, in the set of the shingles that is found only once.

Since the w-shingles are very close relatives of the n-grams, this module is built on top of L<Text::NGrammer> and then it can break the text into sentences before the shingling in such a way that they do not cross the boundaries of the sentences.  Moreover, the module provides a way to normalize the shingles in order to collapse on the same shingle token that look the same but that are represented by different code points, e.g., composite accents vs. accented letters.  The normalization, enabled by default, is done through the module L<Unicode::Normalize> and it uses the NFKC normalization (details in L<http://www.unicode.org/reports/tr15/>).

The shingles in output are represented by strings in which the tokens have been joined through the use of the space character U+0020, the common space character available also in the ASCII set.  This choice has been made for two reasons: the first one is the fact that usually the shingles are then used as tokens in computing distances and this makes life a lot easies, and second that breaking them again in the various components is just doable invoking C<split>.

=head1 METHODS

=over 4

=item new(%)

Creates a new C<Text::Shingle> object and returns it.  The accepted parameters are I<w>, the width of the shingles (default is 2); I<lang> the language to be passed to the tokenizer for the division in sentences, if no language is specified, English is assumed, and the supported languages, are the ones supported by L<Lingua::Sentence>; I<norm> to specify if the NFKC normalization has to be applied to the tokens of not (default is 1).

 my $s = Text::Shingle->new ( lang => 'de', # German
                              w    => 3,    # width is 3
                              norm => 1,    # please normalize the tokens
                            );
 
 my $t = Text::Shingle->new ( ); # defaults to English, width 2 and enables normalization

=item shingle_text($text)

Extracts all the shingles of width C<w>, from the constructor, from the C<$text>.  C<$text> is broken into sentences by the module L<Lingua::Sentence> in such a way that the shingles do not cross the sentence boundaries.

=item shingle_sentence($sentence)

Extracts all the shingles of width C<w>, from the constructor, from the C<$sentence>.   C<$sentence> is I<not> broken into sub-sentences but only into tokens representing single words.

=item shingle_array(@array)

Extracts all the shingles of width C<w>, from the constructor, from the C<@array>.  Exactly as in the case of C<shingle_sentence>, the module L<Lingua::Sentence> is not used.

=back

=head1 HISTORY

=over 4

=item 0.01

Initial version of the module

=item 0.02

Fixed dependencies

=item 0.03

Fixed dependencies in Makefile.PL

=back

=head1 AUTHOR

Francesco Nidito

=head1 COPYRIGHT

Copyright 2018 Francesco Nidito. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Unicode::Normalize>, L<Lingua::Sentence>, L<Text::NGrammer>

=cut
