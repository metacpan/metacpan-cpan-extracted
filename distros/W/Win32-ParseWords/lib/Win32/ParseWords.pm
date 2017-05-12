package Win32::ParseWords;
$Win32::ParseWords::VERSION = '0.01';
use strict;
use warnings;

use Carp;

require Exporter;
our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ();
our @EXPORT      = qw(shellwords quotewords nested_quotewords parse_line);
our @EXPORT_OK   = qw(old_shellwords set_perl_squote);

my $PERL_SINGLE_QUOTE = 0;

sub set_perl_squote {
    $PERL_SINGLE_QUOTE = $_[0];
}

sub shellwords {
    my (@lines) = @_;
    my @allwords;

    foreach my $line (@lines) {
        $line =~ s/^\s+//;
        my @words = parse_line('\s+', 0, $line);
        pop @words if (@words and !defined $words[-1]);
        return() unless (@words || !length($line));
        push(@allwords, @words);
    }
    return(@allwords);
}

sub quotewords {
    my($delim, $keep, @lines) = @_;
    my($line, @words, @allwords);

    foreach $line (@lines) {
        @words = parse_line($delim, $keep, $line);
        return() unless (@words || !length($line));
        push(@allwords, @words);
    }
    return(@allwords);
}

sub nested_quotewords {
    my($delim, $keep, @lines) = @_;
    my($i, @allwords);

    for ($i = 0; $i < @lines; $i++) {
        @{$allwords[$i]} = parse_line($delim, $keep, $lines[$i]);
        return() unless (@{$allwords[$i]} || !length($lines[$i]));
    }
    return(@allwords);
}

sub parse_line {
    my($delimiter, $keep, $line) = @_;
    my($word, @pieces);

    no warnings 'uninitialized'; # we will be testing undef strings

    while (length($line)) {
        # This pattern is optimised to be stack conservative on older perls.
        # Do not refactor without being careful and testing it on very long strings.
        # See Perl bug #42980 for an example of a stack busting input.
        $line =~ s/^
                    (?: 
                        # double quoted string
                        (")                             # $quote
                        ((?>[^\^"]*(?:\^.[^\^"]*)*))"   # $quoted
      | # --OR--
                        # singe quoted string
                        (')                             # $quote
                        ((?>[^\^']*(?:\^.[^\^']*)*))'   # $quoted
                    |   # --OR--
                        # unquoted string
          (                               # $unquoted 
                            (?:\^.|[^\^"'])*?           
                        )  
                        # followed by
          (                               # $delim
                            \Z(?!\n)                    # EOL
                        |   # --OR--
                            (?-x:$delimiter)            # delimiter
                        |   # --OR--                    
                            (?!^)(?=["'])               # a quote
                        )  
      )//xs or return;  # extended layout                  
        my ($quote, $quoted, $unquoted, $delim) = (($1 ? ($1,$2) : ($3,$4)), $5, $6);

        return() unless( defined($quote) || length($unquoted) || length($delim));

        if ($keep) {
            $quoted = "$quote$quoted$quote";
        }
        else {
            $unquoted =~ s/\^(.)/$1/sg;
            if (defined $quote) {
                $quoted =~ s/\^(.)/$1/sg if ($quote eq '"');
                $quoted =~ s/\^([\^'])/$1/g if ( $PERL_SINGLE_QUOTE && $quote eq "'");
            }
        }
        $word .= substr($line, 0, 0); # leave results tainted
        $word .= defined $quote ? $quoted : $unquoted;
 
        if (length($delim)) {
            push(@pieces, $word);
            push(@pieces, $delim) if ($keep eq 'delimiters');
            undef $word;
        }
        if (!length($line)) {
            push(@pieces, $word);
        }
    }
    return(@pieces);
}

sub old_shellwords {
    # Usage:
    # use ParseWords;
    # @words = old_shellwords($line);
    # or
    # @words = old_shellwords(@lines);
    # or
    # @words = old_shellwords(); # defaults to $_ (and clobbers it)

    no warnings 'uninitialized'; # we will be testing undef strings
    local *_ = \join('', @_) if @_;
    my (@words, $snippet);

    s/\A\s+//;
    while ($_ ne '') {
        my $field = substr($_, 0, 0); # leave results tainted
        for (;;) {
            if (s/\A"(([^"\^]|\^.)*)"//s) {
                ($snippet = $1) =~ s#\^(.)#$1#sg;
            }
            elsif (/\A"/) {
                Carp::carp("Unmatched double quote: $_");
                return();
            }
            elsif (s/\A'(([^'\^]|\^.)*)'//s) {
                ($snippet = $1) =~ s#\^(.)#$1#sg;
            }
            elsif (/\A'/) {
                Carp::carp("Unmatched single quote: $_");
                return();
            }
            elsif (s/\A\^(.?)//s) {
                $snippet = $1;
            }
            elsif (s/\A([^\s\^'"]+)//) {
                $snippet = $1;
            }
            else {
                s/\A\s+//;
                last;
            }
            $field .= $snippet;
        }
        push(@words, $field);
    }
    return @words;
}

1;

__END__

=head1 NAME

Win32::ParseWords - Parse a Win32 commandline

=head1 DESCRIPTION

This module has been copied almost verbatim from Text::ParseWords.
Only the quote character \ has been replaced by ^

=head1 SYNOPSIS

  use Text::ParseWords;
  @lists = nested_quotewords($delim, $keep, @lines);
  @words = quotewords($delim, $keep, @lines);
  @words = shellwords(@lines);
  @words = parse_line($delim, $keep, $line);
  @words = old_shellwords(@lines); # DEPRECATED!

=head1 DESCRIPTION

The &nested_quotewords() and &quotewords() functions accept a delimiter 
(which can be a regular expression)
and a list of lines and then breaks those lines up into a list of
words ignoring delimiters that appear inside quotes.  &quotewords()
returns all of the tokens in a single long list, while &nested_quotewords()
returns a list of token lists corresponding to the elements of @lines.
&parse_line() does tokenizing on a single string.  The &*quotewords()
functions simply call &parse_line(), so if you're only splitting
one line you can call &parse_line() directly and save a function
call.

The $keep argument is a boolean flag.  If true, then the tokens are
split on the specified delimiter, but all other characters (including
quotes and backslashes) are kept in the tokens.  If $keep is false then the
&*quotewords() functions remove all quotes and backslashes that are
not themselves backslash-escaped or inside of single quotes (i.e.,
&quotewords() tries to interpret these characters just like the Bourne
shell).  NB: these semantics are significantly different from the
original version of this module shipped with Perl 5.000 through 5.004.
As an additional feature, $keep may be the keyword "delimiters" which
causes the functions to preserve the delimiters in each string as
tokens in the token lists, in addition to preserving quote and
backslash characters.

&shellwords() is written as a special case of &quotewords(), and it
does token parsing with whitespace as a delimiter-- similar to most
Unix shells.

=head1 EXAMPLES

The sample program:

  use Text::ParseWords;
  @words = quotewords('\s+', 0, q{this   is "a test" of^ quotewords ^"for you});
  $i = 0;
  foreach (@words) {
      print "$i: <$_>\n";
      $i++;
  }

produces:

  0: <this>           -- a simple word
  1: <is>             -- multiple spaces are skipped because of our $delim
  2: <a test>         -- use of quotes to include a space in a word
  3: <of quotewords>  -- use of a ^ to include a space in a word
  4: <"for>           -- use of a ^ to remove the special meaning of a double-quote
  5: <you>            -- another simple word (note the lack of effect of ^")

Replacing C<quotewords('\s+', 0, q{this   is...})>
with C<shellwords(q{this   is...})>
is a simpler way to accomplish the same thing.

=head1 SEE ALSO

L<Text::CSV> - for parsing CSV files

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

This module has been copied almost verbatim from the
original module Text::ParseWords.
Only the quote character \ has been replaced by ^

Maintainer of the original module: Alexandr Ciornii <alexchornyATgmail.com>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Klaus Eichner

This module has been copied almost verbatim from Text::ParseWords.
Only the quote character \ has been replaced by ^

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut
