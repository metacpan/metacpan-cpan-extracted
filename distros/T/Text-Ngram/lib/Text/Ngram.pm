package Text::Ngram;

use 5.008008;
use strict;
use warnings;

use Unicode::CaseFold;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( ngram_counts add_to_counts) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.15';

=head1 NAME

Text::Ngram - Ngram analysis of text

=head1 SYNOPSIS

  use Text::Ngram qw(ngram_counts add_to_counts);
  my $text   = "abcdefghijklmnop";
  my $hash_r = ngram_counts($text, 3); # Window size = 3
  # $hash_r => { abc => 1, bcd => 1, ... }

  add_to_counts($more_text, 3, $hash_r);

=head1 DESCRIPTION

n-Gram analysis is a field in textual analysis which uses sliding window
character sequences in order to aid topic analysis, language
determination and so on. The n-gram spectrum of a document can be used
to compare and filter documents in multiple languages, prepare word
prediction networks, and perform spelling correction.

The neat thing about n-grams, though, is that they're really easy to
determine. For n=3, for instance, we compute the n-gram counts like so:

    the cat sat on the mat
    ---                     $counts{"the"}++;
     ---                    $counts{"he "}++;
      ---                   $counts{"e c"}++;
       ...

This module provides an efficient XS-based implementation of n-gram
spectrum analysis.

There are two functions which can be imported:

=cut

require XSLoader;
XSLoader::load('Text::Ngram', $VERSION);

sub _clean_buffer {
    my %config = %{+shift};
    my $buffer = shift;
    $buffer = fc $buffer if $config{lowercase};
    $buffer =~ s/\s+/ /g;
    unless ($config{punctuation}) {
        if ($config{flankbreaks}) {
            $buffer =~ s/[^[:alpha:] ]+/ \xff /g;
        }
        else {
            $buffer =~ s/[^[:alpha:] ]+/\xff/g;
        }
    }
    $buffer =~ y/ / /s;
    return $buffer;
}

=head2 ngram_counts

This first function returns a hash reference with the n-gram histogram
of the text for the given window size. The default window size is 5.

    $href = ngram_counts(\%config, $text, $window_size);

As of version 0.14, the %config may instead be passed in as named arguments:

    $href = ngram_counts($text, $window_size, %config);

The only necessary parameter is $text.

The possible value for %config are:

=head3 flankbreaks

If set to 1 (default), breaks are flanked by spaces; if set to 0,
they're not. Breaks are punctuation and other non-alphabetic
characters, which, unless you use C<< punctuation => 0 >> in your
configuration, do not make it into the returned hash.

Here's an example, supposing you're using the default value
for punctuation (1):

  my $text = "Hello, world";
  my $hash = ngram_counts($text, 5);

That produces the following ngrams:

  {
    'Hello' => 1,
    'ello ' => 1,
    ' worl' => 1,
    'world' => 1,
  }

On the other hand, this:

  my $text = "Hello, world";
  my $hash = ngram_counts({flankbreaks => 0}, $text, 5);

Produces the following ngrams:

  {
    'Hello' => 1,
    ' worl' => 1,
    'world' => 1,
  }

=head3 lowercase

If set to 0, casing is preserved. If set to 1, all letters are
lowercased before counting ngrams. Default is 1.

    # Get all ngrams of size 4 preserving case
    $href_p = ngram_counts( {lowercase => 0}, $text, 4 );

=head3 punctuation

If set to 0 (default), punctuation is removed before calculating the
ngrams.  Set to 1 to preserve it.

    # Get all ngrams of size 2 preserving punctuation
    $href_p = ngram_counts( {punctuation => 1}, $text, 2 );

=head3 spaces

If set to 0 (default is 1), no ngrams containing spaces will be returned.

   # Get all ngrams of size 3 that do not contain spaces
   $href = ngram_counts( {spaces => 0}, $text, 3);

If you're going to request both types of ngrams, than the best way to
avoid calculating the same thing twice is probably this:

    $href_with_spaces = ngram_counts($text[, $window]);
    $href_no_spaces = $href_with_spaces;
    for (keys %$href_no_spaces) { delete $href->{$_} if / / }

=cut

sub ngram_counts {
    my %config = (
                  spaces => 1,
                  punctuation => 0,
                  lowercase => 1,
                  flankbreaks => 1
                 );
    if (ref($_[0]) eq 'HASH') {
        %config = (%config, %{+shift});
    }
    elsif (@_ > 2) {
        %config = (%config, splice @_, (@_ & 1) ? 1 : 2);
    }
    my ($buffer, $width) = @_;
    $width ||= 5;
    return {} if $width < 1;
    my $href = _process_buffer(_clean_buffer(\%config, $buffer), $width);
    unless ($config{punctuation}) {
        for (keys %$href) { delete $href->{$_} if /\xff/ }
    }
    unless ($config{spaces}) {
        for (keys %$href) { delete $href->{$_} if / / }
    }
    return $href;
}

=head2 add_to_counts

This incrementally adds to the supplied hash; if C<$window> is zero or
undefined, then the window size is computed from the hash keys.

    add_to_counts($more_text, $window, $href)

=cut

sub add_to_counts {
    my %config = (punctuation => 0, lowercase => 1);
    my ($buffer, $width, $href) = @_;
    if (!defined $width  or !$width) {
        my ($key, undef) = each %$href; # Just gimme a random key
        $width = length $key || 5;
    }
    _process_buffer_incrementally(_clean_buffer(\%config, $buffer), $width, $href);
    for (keys %$href) { delete $href->{$_} if /\xff/ }
}

1;
__END__

=head1 TO DO

=over 6

=item * Look further into the tests. Sort them and add more.

=back

=head1 SEE ALSO

Cavnar, W. B. (1993). N-gram-based text filtering for TREC-2. In D.
Harman (Ed.), I<Proceedings of TREC-2: Text Retrieval Conference 2>.
Washington, DC: National Bureau of Standards.

Shannon, C. E. (1951). Predication and entropy of printed English.
I<The Bell System Technical Journal, 30>. 50-64.

Ullmann, J. R. (1977). Binary n-gram technique for automatic correction
of substitution, deletion, insert and reversal errors in words.
I<Computer Journal, 20>. 141-147.

=head1 AUTHOR

Maintained by Alberto Simoes, C<ambs@cpan.org>.

Previously maintained by Jose Castro, C<cog@cpan.org>.
Originally created by Simon Cozens, C<simon@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Alberto Simoes

Copyright 2004 by Jose Castro

Copyright 2003 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
