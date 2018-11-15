package Text::Util::Chinese;
use strict;
use warnings;

use Exporter 5.57 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(extract_words);

use List::Util qw(uniq);

sub extract_words {
    my ($input_iter) = @_;

    my (%lcontext, %rcontext);

    while( my $txt = $input_iter->() ) {
        my @phrase = split /\P{Letter}/, $txt;
        for (@phrase) {
            next unless /\A\p{Han}+\z/;

            my @c = split("", $_);

            for my $i (0..$#c) {
                if ($i > 0) {
                    $lcontext{$c[$i]}{$c[$i-1]}++;
                    for my $n (2,3) {
                        if ($i >= $n) {
                            $lcontext{ join('', @c[ ($i-$n+1) .. $i] ) }{$c[$i - $n]}++;
                        }
                    }
                }
                if ($i < $#c) {
                    $rcontext{$c[$i]}{$c[$i+1]}++;
                    for my $n (2,3) {
                        if ($i + $n <= $#c) {
                            $rcontext{ join('', @c[$i .. ($i+$n-1)]) }{ $c[$i+$n] }++;
                        }
                    }
                }
            }
        }
    }

    my @words;
    my $threshold = 5;
    for my $x (uniq((keys %lcontext), (keys %rcontext))) {
        next unless length($x) > 1;
        next unless ($threshold <= (keys %{$lcontext{$x}}) && $threshold <= (keys %{$rcontext{$x}}));
        push @words, $x;
    }

    return \@words;
}

1;

__END__

=encoding utf8

=head1 NAME

Text::Util::Chinese - A collection of subroutines for processing Chinese Text

=head1 Exportable Subroutines

=over 4

=item extract_words( $input_iter ) #=> ArrayRef[Str]

This extracts words from Chinese text. A word in Chinese text is a token token
with N charaters. These N characters is often used together in the input and
therefore should be a meaningful unit.

The input parameter is a iterator -- a subroutine that must return a string of
Chinese text each time it is invoked. Or, when the input is exhausted, it must
return undef. For example:

    open my $fh, '<', 'book.txt';
    my $words = extract_words(
        sub {
            my $x = <$fh>;
            return decode_utf8 $x;
        });

The type of return value is ArrayRef[Str].

It is likely that this subroutine returns an empty ArrayRef with no contents.
It is only useful when the volume of input is a leats a few thousands of
characters. The more, the better.

=back

=head1 AUTHORS

Kang-min Liu <gugod@gugod.org>

=head1 LICENCE

Unlicense L<https://unlicense.org/>
