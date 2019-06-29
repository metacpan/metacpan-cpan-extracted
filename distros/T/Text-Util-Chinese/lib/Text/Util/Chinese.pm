package Text::Util::Chinese;
use strict;
use warnings;
use utf8;

use Exporter 5.57 'import';
use Unicode::UCD qw(charscript);

our $VERSION = '0.06';
our @EXPORT_OK = qw(sentence_iterator phrase_iterator extract_presuf extract_words tokenize_by_script);

use List::Util qw(uniq pairmap);

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

sub extract_presuf {
    my ($input_iter, $output_cb, $opts) = @_;

    my %stats;
    my %extracted;
    my $threshold = $opts->{threshold} || 9; # an arbitrary choice.
    my $lengths   = $opts->{lengths} || [2,3];
    my $text;

    my $phrase_iter = grep_iterator(
        phrase_iterator( $input_iter ),
        sub { /\A\p{Han}+\z/ }
    );
    while (my $phrase = $phrase_iter->()) {
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

                    $output_cb->($x, \%extracted);
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

=head1 EXPORTED SUBROUTINES

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
        +{
            threshold => 9,
            lengths => [ 2,3 ],
        }
    );

The C<$output_cb> callback is passed two arguments. The first one is the new
C<$token> that appears more then C<$threshold> times as a prefix and as a
suffix. The second arguments is a HashRef with keys being the set of all
extracted tokens. The very same HashRef is also going to be the return value
of this subroutine.

The 3rd argument is a HashRef with parameters to the internal algorithm.
C<threshold> should be an Int, C<lengths> should be an ArrayRef[Int] and
that constraints the lengths of prefixes and suffixes to be extracted.

The default value for C<threshold> is 9, while the default value for C<lengths> is C<[2,3]>

=item sentences_iterator( $input_iter ) #=> CodeRef

This subroutine split input into sentences. It takes an text iterator,
and returns another one.

=item phrase_iterator( $input_iter ) #=> CodeRef

This subroutine split input into smallelr phrases. It takes an text iterator,
and returns another one.

=item tokenize_by_script( $text ) #=> Array[ Str ]

This subroutine split text into tokens, where each token is the same writing script.

=back

=head1 AUTHORS

Kang-min Liu <gugod@gugod.org>

=head1 LICENCE

Unlicense L<https://unlicense.org/>
