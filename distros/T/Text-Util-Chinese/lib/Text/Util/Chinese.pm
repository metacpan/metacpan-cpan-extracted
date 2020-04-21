package Text::Util::Chinese;
use strict;
use warnings;
use utf8;

use Exporter 5.57 'import';
use Unicode::UCD qw(charscript);

our $VERSION = '0.07';
our @EXPORT_OK = qw(sentence_iterator phrase_iterator presuf_iterator word_iterator extract_presuf extract_words tokenize_by_script);

use List::Util qw(uniq pairmap);

sub exhaust {
    my ($iter, $cb) = @_;
    my @list;
    while(defined(my $x = $iter->())) {
        push @list, $x;
        $cb->($x) if defined($cb);
    }
    return @list;
}

sub grep_iterator {
    my ($iter, $cb) = @_;
    return sub {
        local $_;
        do {
            $_ = $iter->();
            return undef unless defined($_);
        } while (! $cb->());
        return $_;
    }
}

sub phrase_iterator {
    my ($input_iter, $opts) = @_;
    my @phrases;
    return sub {
        while(! @phrases && defined(my $text = $input_iter->())) {
            @phrases = grep {
                (! /\A\s+\z/) && (! /\p{General_Category=Punctuation}/) && /\p{Han}/
            } split / ( \r?\n | \p{General_Category: Other_Punctuation} )+ /x, $text;
        }
        return shift @phrases;
    }
}

sub sentence_iterator {
    my ($input_iter, $opts) = @_;
    my @sentences;
    return sub {
        while(! @sentences && defined(my $text = $input_iter->())) {
            @sentences = grep { !/\A\s+\z/ } ($text =~
                          m/(
                               (?:
                                   [^\p{General_Category: Open_Punctuation}\p{General_Category: Close_Punctuation}]+?
                               | .*? \p{General_Category: Open_Punctuation} .*? \p{General_Category: Close_Punctuation} .*?
                               )
                               (?: \z | [\n\?\!。？！]+ )
                           )/gx);
        }
        return shift @sentences;
    }
}

sub presuf_iterator {
    my ($input_iter, $opts) = @_;

    my %stats;
    my $threshold = $opts->{threshold} || 9; # an arbitrary choice.
    my $lengths   = $opts->{lengths} || [2,3];

    my $phrase_iter = grep_iterator(
        phrase_iterator( $input_iter ),
        sub { /\A\p{Han}+\z/ }
    );

    my (%extracted, @extracted);
    return sub {
        if (@extracted) {
            return shift @extracted;
        }

        while (!@extracted && defined(my $phrase = $phrase_iter->())) {
            for my $len ( @$lengths ) {
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

                        push @extracted, $x;
                    }
                }
            }
        }

        if (@extracted) {
            return shift @extracted;
        }

        return undef;
    };
}

sub extract_presuf {
    my ($input_iter, $opts) = @_;
    return [ exhaust(presuf_iterator($input_iter, $opts)) ];
}

sub word_iterator {
    my ($input_iter) = @_;

    my $threshold = 5;
    my (%lcontext, %rcontext, %word, @words);

    my $phrase_iter = grep_iterator(
        phrase_iterator( $input_iter ),
        sub { /\A\p{Han}+\z/ }
    );

    return sub {
        if (@words) {
            return shift @words;
        }

        while (!@words && defined( my $txt = $phrase_iter->() )) {
            my @c = split("", $txt);

            for my $i (0..$#c) {
                if ($i > 0) {
                    $lcontext{$c[$i]}{$c[$i-1]}++;
                    for my $n (2,3) {
                        if ($i >= $n) {
                            my $tok = join('', @c[ ($i-$n+1) .. $i] );
                            unless ($word{$tok}) {
                                if (length($tok) > 1) {
                                    $lcontext{ $tok }{$c[$i - $n]}++;
                                }

                                if ($threshold <= (keys %{$lcontext{$tok}}) && $threshold <= (keys %{$rcontext{$tok}})) {
                                    $word{$tok} = 1;
                                    push @words, $tok;
                                }
                            }
                        }
                    }
                }
                if ($i < $#c) {
                    $rcontext{$c[$i]}{$c[$i+1]}++;
                    for my $n (2,3) {
                        if ($i + $n <= $#c) {
                            my $tok = join('', @c[$i .. ($i+$n-1)]);
                            unless ($word{$tok}) {
                                if (length($tok) > 1) {
                                    $rcontext{ $tok }{ $c[$i+$n] }++;
                                }

                                if ($threshold <= (keys %{$lcontext{$tok}}) && $threshold <= (keys %{$rcontext{$tok}})) {
                                    $word{$tok} = 1;
                                    push @words, $tok;
                                }
                            }
                        }
                    }
                }
            }
        }
        return shift @words;
    }
}

sub extract_words {
    return [ exhaust(word_iterator(@_)) ];
}

sub tokenize_by_script {
    my ($str) = @_;
    my @tokens;
    my @chars = grep { defined($_) } split "", $str;
    return () unless @chars;

    my $t = shift(@chars);
    my $s = charscript(ord($t));
    while(my $char = shift @chars) {
        my $_s = charscript(ord($char));
        if ($_s eq $s) {
            $t .= $char;
        }
        else {
            push @tokens, $t;
            $s = $_s;
            $t = $char;
        }
    }
    push @tokens, $t;
    return grep { ! /\A\s*\z/u } @tokens;
}

1;

__END__

=encoding utf8

=head1 NAME

Text::Util::Chinese - A collection of subroutines for processing Chinese Text

=head1 DESCRIPTIONS

The subroutines provided by this module are for processing Chinese text.
Conventionally, all input strings are assumed to be wide-characters.  No
`decode_utf8` or `utf8::decode` were done in this module. Users of this module
should deal with input-decoding first before passing values to these
subroutines.

Given the fact that corpus files are usually large, it may be a good idea to
avoid slurping the entire input stream. Conventionally, subroutines in this
modules accept "input iterator" as its way to receive a small piece of corpus
at a time. The "input iterator" is a CodeRef that returns a string every time
it is called, or undef if there are nothing more to be processed. Here's a
trivial example to open a file as an input iterator:

    sub open_as_iterator {
        my ($path) = @_
        open my $fh, '<', $path;
        return sub {
            my $line = <$fh>;
            return undef unless defined($line);
            return decode_utf8($line);
        }
    }

    my $input_iter = open_as_iterator("/data/corpus.txt");

This C<$input_iter> can be then passed as arguments to different subroutines.

Although in the rest of this document, `Iter` is used as a Type
notation for iterators. It is the same as a CODE reference.

=head1 EXPORTED SUBROUTINES

=over 4

=item word_iterator( $input_iter ) #=> Iter

This extracts words from Chinese text. A word in Chinese text is a token
with N charaters. These N characters is often used together in the input and
therefore should be a meaningful unit.

The input parameter is a iterator -- a subroutine that must return a string of
Chinese text each time it is invoked. Or, when the input is exhausted, it must
return undef. For example:

    open my $fh, '<', 'book.txt';
    my $word_iter = word_iterator(
        sub {
            my $x = <$fh>;
            return decode_utf8 $x;
        });

The type of return value is Iter (CODE ref).

=item extract_words( $input_iter ) #=> ArrayRef[Str]

This does the same thing as C<word_iterator>, but retruns the exhausted list instead of iterator.

For example:

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

=item presuf_iterator( $input_iter, $opts) #=> Iter

This subroutine extract meaningful tokens that are prefix or suffix of
input.

The 2nd argument C<$opts> is a HashRef with parameters C<threshold>
and C<lengths>. C<threshold> should be an Int, C<lengths> should be an
ArrayRef[Int] and that constraints the lengths of prefixes and
suffixes to be extracted.

The default value for C<threshold> is 9, while the default value for C<lengths> is C<[2,3]>

=item extract_presuf( $input_iter, $opts ) #=> ArrayRef[Str]

Similar to C<presuf_iterator>, but returns a ArrayRef[Str] instead.

=item sentence_iterator( $input_iter ) #=> Iter

This subroutine split input into sentences. It takes an text iterator,
and returns another one.

=item phrase_iterator( $input_iter ) #=> Iter

This subroutine split input into smallelr phrases. It takes an text iterator,
and returns another one.

=item tokenize_by_script( $text ) #=> Array[ Str ]

This subroutine split text into tokens, where each token is the same writing script.

=back

=head1 AUTHORS

Kang-min Liu <gugod@gugod.org>

=head1 LICENCE

Unlicense L<https://unlicense.org/>
