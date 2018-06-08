# Copyright 2018 Francesco Nidito. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Text::NGrammer;

use strict;
use Carp;
use Lingua::Sentence;

use vars qw($VERSION);
$VERSION = '0.03';

sub new {
  my $class = shift;
  my %config = (lang => 'en', # used by the sentencer
               );

  my %param = @_;

  for my $opt (keys %param) {
    croak "option $opt unsupported by version $VERSION of Text::NGrammer" unless exists $config{$opt};
    $config{$opt} = $param{$opt};
  }
  $config{version} = $VERSION;
  return bless \%config, $class;
}

##
# Skip-grams

sub skipgrams_array {
  my $self   = shift;
  my $n      = shift;
  my $k      = shift;
  my $length = scalar(@_);

  croak "the n-gram length cannot be lesser than 1" if $n < 1;
  croak "the tokens to be skipped cannot be lesser than 0" if $k < 0;

  my @ngrams = ();
  my $step = $k + 1;
  for (my $i = 0; $i <= ($length - ($n+($k*($n-1)))); $i += 1) {
    my @tokens = ();
    push @tokens, $_[$i];
    while (@tokens < $n) {
      push @tokens, $_[$i + ($k+1)];
    }
    push @ngrams, \@tokens;
  }

  return @ngrams;
}

sub skipgrams_sentence {
  my $self     = shift;
  my $n        = shift;
  my $k        = shift;
  my $sentence = shift;

  croak "the n-gram length cannot be lesser than 1" if $n < 1;
  croak "the tokens to be skipped cannot be lesser than 0" if $k < 0;

  # splits a string -- assumed to be a sentence -- according to spaces, control chars, etc.
  my @tokens = grep /\S+/, split(/(?:\p{C}|\p{M}|\p{P}|\p{S}|\p{Z})+/, $sentence);
  return () if @tokens < $n;
  return $self->skipgrams_array($n, $k, @tokens);
}

sub skipgrams_text {
  my $self = shift;
  my $n    = shift;
  my $k    = shift;
  my $text = shift;

  croak "the n-gram length cannot be lesser than 1" if $n < 1;
  croak "the tokens to be skipped cannot be lesser than 0" if $k < 0;

  my @ngrams = ();

  my $splitter = Lingua::Sentence->new($self->{lang});
  for my $sentence ($splitter->split_array($text)) {
    push @ngrams, $self->skipgrams_sentence($n, $k, $sentence);
  }

  return @ngrams;
}

##
# N-Grams

sub ngrams_array {
  my $self   = shift;
  my $n      = shift;

  return $self->skipgrams_array($n, 0, @_);
}

sub ngrams_sentence {
  my $self     = shift;
  my $n        = shift;
  my $sentence = shift;

  return $self->skipgrams_sentencey($n, 0, $sentence);
}

sub ngrams_text {
  my $self = shift;
  my $n    = shift;
  my $text = shift;

  return $self->skipgrams_text($n, 0, $text);
}


1;

__END__

=head1 NAME

Text::NGrammer - Pure Perl extraction of n-grams and skip-grams

=head1 SYNOPSIS

 use Text::NGrammer;
 my $s = Text::NGrammer->new;
 
 # prints [ (a,rose) (rose,is) (is,a) (a,flower) ]
 my @ngrams = $n->ngrams_text(2, "a rose is a flower");
 print "[ ";
 for my $ngram (@ngrams) {
   print "(",$ngram->[0],",",$ngram->[1],") ";
 }
 print "]\n";
 
 # prints [ (a,is) (rose,a) (is,flower) ]
 my @skipgrams = $n->skipgrams_text(2, 1, "a rose is a flower");
 print "[ ";
 for my $skipgram (@skipgrams) {
   print "(",$skipgram->[0],",",$skipgram->[1],") ";
 }
 print "]\n";

=head1 DESCRIPTION

The module provides a way to extract both n-grams and skip-grams from a text, a sentence or fro man array of tokens.

A n-gram is defines as an ordered sequence of tokens in a piece or text.  Some frequent n-grams such as 2-grams, are also called bigrams and they represent all the ordered pairs of words in a text.  For instance, the text "a rose is a flower" is composed by 4 bigrams: "a rose", "rose is", "is a", "a flower".

A skip-gram is defined as an ordered sequence of I<n> tokens from a text with a predetermined interval I<k>.  For instance, the skip-gram with n=2 and k=1 for a piece of text are all the sequences of tokens of length 2 with interval 1 between the tokens.  For instance, the text "a rose is a flower" is composed by 3 skip-grams with n=2 and k=1: "a is", "rose a", "is a", "is flower".  A skip-gram with k=0 is the same of a n-gram of the same size, e.g., a 2-skip-gram with k=0 is the same of a bigram.

A broader, and better, discussion on n-grams and skip-grams can be found at L<https://en.wikipedia.org/wiki/N-gram>.

Behind the scenes, the module uses the L<Lingua::Sentence> module to tokenize the text in such a way that the n-grams and skip-grams never go over the boundaries of the sentences.  The module provides also ways to extract the n-grams and skip-grams from sentences, i.e., without invoking L<Lingua::Sentence>, or from an array of tokens if the application wants to make use of a custom tokenization for the text.  The language to be used for the sentencer must be specified in the constructor; if not present, English is used by default.

All the methods return the n-grams and skip-grams as arrays or references to arrays of length I<n>, where I<n> is the specifies as a parameter of the method.  Sentences, or more in general, pieces of text are not divided in n-grams skip-grams if not long enough to perform the operation.  For instance, asking for all the n-grams of length 4 for the sentence "I am Francesco" returns an empty array of 4-grams because there are are only 3 tokens in the sentence.

 my $ngrammer = Text::NGrammer->new();
 
 my @ngrams = $ngrammer->ngrams_array(3, ("a", "b", "c", "d"));
 my $ngram = $ngrams[0]; # the first ngram
 print $ngram->[1]; # prints "b"
 
 my @empty = $ngrammer->ngrams_array(5, ("a", "b", "c", "d"));
 print "empty!" if (@empty == 0); # prints "empty!"

=head1 METHODS

=over 4

=item new(%)

Creates a new C<Text::NGrammer> object and returns it. The only parameter to accepted to the constructor is the language for the sentencer. For instance, to create a NGrammer for German the syntax is the following one

 my $german_ngrammer = Text::NGrammer->new(lang => 'de');

If no language is specified, English is assumed.  The supported languages, are the ones supported by L<Lingua::Sentence>.

=item skipgrams_text($n, $k, $text)

Extracts all the skip-grams of length C<$n> with interval C<$k> from the C<$text>.  C<$text> is broken into sentences by the module L<Lingua::Sentence> in such a way that the skip-grams do not cross the sentence bounduaries.

=item skipgrams_sentence($n, $k, $sentence)

Extracts all the skip-grams of length C<$n> with interval C<$k> from the I<$sentence>.  C<$sentence> is I<not> broken into sub-sentences but only into tokens representing single words.

=item skipgrams_array($n, $k, @array)

Extracts all the skip-grams of length C<$n> with interval C<$k> from the C<@array>.  Exactly as in the case of C<skipgrams_sentence>, the module L<Lingua::Sentence> is not used.

=item ngrams_text($n, $text)

Extracts all the n-grams of length C<$n> from the C<$text>.  C<$text> is broken into sentences by the module L<Lingua::Sentence> in such a way that the n-grams do not cross the sentence boundaries.  This is equivalent to C<skipgrams_text($n, 0, $text)>.

=item ngrams_sentence($n, $sentence)

Extracts all the n-grams of length C<$n> from the C<$sentence>.  C<$sentence> is I<not> broken into sub-sentences but only into tokens representing single words.  This is equivalent to C<skipgrams_sentence($n, 0, $sentence)>.

=item ngrams_array($n, @array)

Extracts all the n-grams of length C<$n> from the C<@array>.  Exactly as in the case of C<ngrams_sentence>, the module L<Lingua::Sentence> is not used.  This is equivalent to C<skipgrams_array($n, 0, $array)>.

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

L<Lingua::Sentence>

=cut
