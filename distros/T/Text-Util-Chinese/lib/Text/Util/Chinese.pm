package Text::Util::Chinese;
use strict;
use warnings;

use Exporter 5.57 'import';

our $VERSION = '0.02';
our @EXPORT_OK = qw(extract_presuf extract_words);

use List::Util qw(uniq);

sub extract_presuf {
    my ($input_iter, $output_cb, $opts) = @_;

    my %stats;
    my %extracted;
    my $threshold = $opts->{threshold} || 9; # an arbitrary choice.
    my $text;

    while (defined($text = $input_iter->())) {
        for my $phrase (split /\p{General_Category: Other_Punctuation}+/, $text) {
            next unless length($phrase) >= 2 && $phrase =~ /\A\p{Han}+\z/x;

            for my $len (2..5) {
                my $re = '\p{Han}{' . $len . '}';
                next unless length($phrase) >= $len * 2 && $phrase =~ /\A($re) .* ($re)\z/x;
                my ($prefix, $suffix) = ($1, $2);
                $stats{prefix}{$prefix}++ unless $extracted{$prefix};
                $stats{suffix}{$suffix}++ unless $extracted{$suffix};

                for my $x ($prefix, $suffix) {
                    if (! $extracted{$x}
                        && $stats{prefix}{$x}
                        && $stats{suffix}{$x}
                        && $stats{prefix}{$x} > $threshold
                        && $stats{suffix}{$x} > $threshold
                    ) {
                        $extracted{$x} = 1;
                        delete $stats{prefix}{$x};
                        delete $stats{suffix}{$x};

                        $output_cb->($x, \%extracted);
                    }
                }
            }
        }
    }

    return \%extracted;
}

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
                            my $tok = join('', @c[ ($i-$n+1) .. $i] );
                            if (length($tok) > 1) {
                                $lcontext{ $tok }{$c[$i - $n]}++;
                            }
                        }
                    }
                }
                if ($i < $#c) {
                    $rcontext{$c[$i]}{$c[$i+1]}++;
                    for my $n (2,3) {
                        if ($i + $n <= $#c) {
                            my $tok = join('', @c[$i .. ($i+$n-1)]);
                            if (length($tok) > 1) {
                                $rcontext{ $tok }{ $c[$i+$n] }++;
                            }
                        }
                    }
                }
            }
        }
    }

    my @tokens = uniq((keys %lcontext), (keys %rcontext));
    my @words;
    my $threshold = 5;
    for my $x (@tokens) {
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

This extracts words from Chinese text. A word in Chinese text is a token
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

=item extract_presuf( $input_iter, $output_cb, $opts ) #=> HashRef

This subroutine extract meaningful tokens that are prefix or suffix of
input. Comparing to C<extract_word>, it yields extracted tokens frequently
by calling C<$output_cb>.

It is used like this:

    my $extracted = extract_presuf(
        \&next_input,
        sub {
            my ($token, $extracted) = @_;

            ...
        },
        { threshold => 9 }
    );

The C<$output_cb> callback is passed two arguments. The first one is the new
C<$token> that appears more then C<$threshold> times as a prefix and as a
suffix. The second arguments is a HashRef with keys being the set of all
extracted tokens. The very same HashRef is also going to be the return value
of this subroutine.

The 3rd argument is a HashRef with parameters to the internal algorithm. So
far C<threshold> is the only one with default value being 9.

=back

=head1 AUTHORS

Kang-min Liu <gugod@gugod.org>

=head1 LICENCE

Unlicense L<https://unlicense.org/>
