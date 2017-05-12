package Text::Fingerprint;
# ABSTRACT: perform simple text clustering by key collision


use strict;
use utf8;
use warnings qw(all);

use base q(Exporter);

our %EXPORT_TAGS    = (all => [qw(fingerprint fingerprint_ngram)]);
our @EXPORT_OK      = (@{$EXPORT_TAGS{all}});
our @EXPORT         = qw();

use List::MoreUtils qw(uniq);
use Text::Unidecode;

our $VERSION = '0.006'; # VERSION


my $NON_WORD = qr{ [\W_]+ }x;

sub fingerprint ($) {
    my ($string) = @_;

    $string = lc unidecode $string;
    $string =~ s{^ $NON_WORD | $NON_WORD $}{}gosx;

    return join q( ) =>
        sort(
            uniq(
                split(
                    m{ $NON_WORD }ox,
                    $string
                )
            )
        );
}


sub fingerprint_ngram ($;$) {
    my ($string, $n) = (@_, 2);

    $string = lc unidecode $string;
    $string =~ s{ $NON_WORD }{}gosx;

    return join '' =>
        sort(
            uniq(
                $string =~ m{
                    (?=
                        (.{$n})
                    )
                }gx
            )
        );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Fingerprint - perform simple text clustering by key collision

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use common::sense;

    use Text::Fingerprint qw(:all);

    my $str = q(
        À noite, vovô Kowalsky vê o ímã cair no pé do pingüim
        queixoso e vovó põe açúcar no chá de tâmaras do jabuti feliz.
    );

    say fingerprint($str);
    # a acucar cair cha de do e feliz ima jabuti kowalsky
    # no noite o pe pinguim poe queixoso tamaras ve vovo

    say fingerprint_ngram($str);
    # abacadaialamanarasbucachcudedoeaedeieleoetevfeg
    # uhaifiminiritixizjakokylilsmamqngnoocoeoiojokop
    # osovowpepipoqurarnsdsksotatetiucueuiutvevowaxoyv

    say fingerprint_ngram($str, 1);
    # abcdefghijklmnopqrstuvwxyz

=head1 DESCRIPTION

Text clustering functions borrowed from the L<Google Refine|http://code.google.com/p/google-refine/>.
Can be useful for finding groups of different values that might be alternative representations of the same thing.
For example, the two strings "New York" and "new york" are very likely to refer to the same concept and just have capitalization differences.
Likewise, "Gödel" and "Godel" probably refer to the same person.

=head1 FUNCTIONS

=head2 fingerprint($string)

The process that generates the key from a C<$string> value is the following (note that the order of these operations is significant):

=over 4

=item *

normalize extended western characters to their ASCII representation (for example "gödel" → "godel")

=item *

change all characters to their lowercase representation

=item *

remove leading and trailing whitespace

=item *

split the string into punctuation, whitespace and control characters-separated tokens (using C</[\W_]/> regexp)

=item *

sort the tokens and remove duplicates

=item *

join the tokens back together

=back

=head2 fingerprint_ngram($string, $n)

The L<n-gram|http://en.wikipedia.org/wiki/N-gram> fingerprint method is similar to the C<fingerprint> method described above but instead of using whitespace separated tokens, it uses I<n-grams>, where the C<$n> (or the size in chars of the token) can be specified by the user (default: 2).
Algorithm steps:

=over 4

=item *

normalize extended western characters to their ASCII representation

=item *

change all characters to their lowercase representation

=item *

remove all punctuation, whitespace, and control characters (using C</[\W_]/> regexp)

=item *

obtain all the string n-grams

=item *

sort the n-grams and remove duplicates

=item *

join the sorted n-grams back together

=back

=head1 CAVEAT

Fingerprint functions I<are not exactly the same> as those found in Google Refine!
They were slightly changed to take advantage of the superb Perl handling of Unicode characters.

=head1 SEE ALSO

=over 4

=item *

L<Text::Unidecode>

=item *

L<Methods and theory behind the clustering functionality in Google Refine.|http://code.google.com/p/google-refine/wiki/ClusteringInDepth>

=back

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
