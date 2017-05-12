package Text::Fold;

use strict;
use warnings;
use String::UnicodeUTF8;

$Text::Fold::VERSION = '0.5';

sub import {
    no strict 'refs';
    *{ caller() . '::fold_text' } = \&fold_text;
}

sub fold_text {
    my ( $orig_line, $width, $join ) = @_;

    my $conf;
    if ( defined $width && ref($width) eq 'HASH' ) {
        $conf  = $width;
        $width = undef;
    }
    $width = defined $width ? abs( int($width) ) || 78 : 78;

    if ( !defined $conf && defined $join && ref($join) eq 'HASH' ) {
        $conf = $join;
        $join = undef;
    }
    $conf ||= {};
    $join = $conf->{'join'} if exists $conf->{'join'};

    my $soft_hyphen_threshold = 0;
    if ( exists $conf->{'soft_hyphen_threshold'} ) {

        # Zero-but-true means default to ~20% of width
        # Since this should be a number this works, if it could be a string then this would not work
        if ( $conf->{'soft_hyphen_threshold'} && $conf->{'soft_hyphen_threshold'} == 0 ) {
            $soft_hyphen_threshold = int( $width / 5 );
        }
        else {
            $soft_hyphen_threshold = abs( int( $conf->{'soft_hyphen_threshold'} ) );
        }

        if ( $soft_hyphen_threshold < 3 || $soft_hyphen_threshold > $width ) {
            $soft_hyphen_threshold = $width;
        }
    }

    my $turn_back_into_byte_string = String::UnicodeUTF8::is_unicode($orig_line) ? 0 : 1;
    my $line = String::UnicodeUTF8::get_unicode($orig_line);

    # split(/\n/, "foo\nbar\nbaz\n") is (foo, bar, baz) not (foo, bar, baz, '')
    # split(/\n/, "foo\nbar\nbaz\n\n\n") is (foo, bar, baz) not (foo, bar, baz, '', '', '')
    # So we need to count the trailing newlines in order to add them back at the end.
    #
    # This trailing newline count is a corner case where `perldoc -q count` did not do the trick.
    # If you have a better/faster way I'm all ears!
    #
    # Removing them (i.e. s///) is safe since the split() will essentially be removing them anyway.
    my $trailing_newlines_count = 0;
    while ( $line =~ s/(?:\015\012|\012|\015)\z//g ) {
        $trailing_newlines_count++;
    }

    # It was entirely newlines
    if ( $line eq '' ) {
        return defined $join ? $join : "\n" x $trailing_newlines_count;
    }

    my @aggregate_tokens;
    my $part;    # buffer

  LINE:
    for $part ( split( /(?:\015\012|\012|\015)/, $line ) ) {
      PARSE_PART:
        {
            if ( $part eq '' ) {
                push @aggregate_tokens, $part;
                next LINE;
            }

            my @tokens = ( $part =~ m/.{1,$width}/g );

            # unpack(A) lops off trailing spaces on each chunk, if there's a better way I'm all ears!
            # my @tokens = unpack( "A$width" x ( CORE::length($part) / $width ) . ' A*', $part );

            my $n;    # buffer
            my $last_index = $#tokens;
            for $n ( 0 .. $last_index ) {
                if ( $n < $last_index ) {
                    if ( $tokens[$n] =~ m/[^ \t\f]\z/ && $tokens[ $n + 1 ] =~ m/\A[^ \t\f]/ ) {

                        if ($soft_hyphen_threshold) {
                            my ($end_chunk) = $tokens[$n] =~ m/([^ \t\f]+)\z/;
                            my ($beg_chunk) = $tokens[ $n + 1 ] =~ m/\A([^ \t\f]+)/;

                            if ( CORE::length("$end_chunk$beg_chunk") <= $soft_hyphen_threshold ) {
                                $tokens[$n] =~ s/[^ \t\f]+\z//;
                                $tokens[ $n + 1 ] =~ s/\A[^ \t\f]+//;
                                push @aggregate_tokens, @tokens[ 0 .. $n ];
                                $part = join( '', $end_chunk, $beg_chunk, @tokens[ $n + 1 .. $last_index ] );
                                goto PARSE_PART;
                            }
                            else {
                                goto SOFT_HYPHEN;
                            }
                        }
                        else {
                          SOFT_HYPHEN:
                            my $last_chr = CORE::substr( $tokens[$n], -2, 1 ) =~ m/[ \t\f]/ ? CORE::substr( $tokens[$n], -1, 1, " " ) : CORE::substr( $tokens[$n], -1, 1, "-" );

                            if ($n) {
                                push @aggregate_tokens, @tokens[ 0 .. $n - 1 ], $tokens[$n];
                            }
                            else {
                                push @aggregate_tokens, $tokens[$n];
                            }

                            $part = join( '', $last_chr, @tokens[ $n + 1 .. $last_index ] );
                            goto PARSE_PART;
                        }
                    }
                }
            }

            # unpack will return an empty token as last token if the 2nd to last token
            # was exactly $width long, so we need to pop the last element if it's empty
            if ( $tokens[-1] eq '' ) {
                pop @tokens;
            }

            push @aggregate_tokens, @tokens;
        }
    }

    if ($turn_back_into_byte_string) {
        for ( 0 .. $#aggregate_tokens ) {
            $aggregate_tokens[$_] = String::UnicodeUTF8::get_utf8( $aggregate_tokens[$_] );
        }
    }

    if ($trailing_newlines_count) {
        for ( 1 .. $trailing_newlines_count ) {
            push @aggregate_tokens, '';
        }
    }

    return join( defined $join ? $join : "\n", @aggregate_tokens );
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::Fold - Turn “unicode” and “byte” string text into lines of a given width, soft-hyphenating broken words

=head1 VERSION

This document describes Text::Fold version 0.5

=head1 SYNOPSIS

    use Text::Fold;

    my $78_char_wide_text = fold_text($long_lines);

    my $42_char_wide_text = fold_text($long_lines,42);

=head1 DESCRIPTION

This simple folding mechanism is intended to turn a long string of text (possibly containg multiple lines) into multiple lines not exceeding a certain width.

It should work consistently with Unicode strings and Byte strings.

See the rest of this document for further details.

=head2 What this is/does and what this is/does not

Before you worry that this module is superfluous and send me hate mail consider the context of this module, then decide: 

=head3 What it is meant for

=over 4 

=item * Handling Unicode strings (e.g. "Perl is the \x{32b7}\x{2122}") and byte strings (e.g. "Perl is the \xe3\x8a\xb7\xe2\x84\xa2" or "Perl is the ㊷™")

All 3 formats should be considered 14 characters longs. You should get back the same type of string you passed it.

=item * Folding long text (possibly containing multiple lines) into multiple lines not exceeding the given width in characters

=item * connecting words that span the width limit with a (loose) soft hyphen

=back

=head3 What it is not meant for

=over 4 

=item * Understanding locale specific items, whitespace beyond the very basic, or special character behavior

=item * folding in column or byte width context

=item * normalization or implied understanding of your context

e.g. a tab is a single character, if you mean it to stand for 4 spaces then normalize it first into 4 spaces

Your data should be encoded properly before folding it. If you really want the original encoding then re-encode the results.

=back

=head3 See Also

Here are some other modules that do similar things that you might like to use instead and the reasons I opted to do a different one.

=over 4 

=item L<Text::LineFold>

Lines longer than the 'ColumnsMax' are not chunked. In other words you will get text wider than what you want.

Too many options/functionality for what the goal of this module was.

Did not soft-hyphen broken words.

=item L<Text::Wrap>

Behavior set by global vars. (I know, I too used them back in the day when they were all the rage, I am working on rectifying that!)

Unintuitive interface.

Too many options/functionality for what the goal of this module was.

Did not soft-hyphen broken words.

=item L<Text::Format>

Too many options/functionality for what the goal of this module was.

Did not soft-hyphen broken words.

=item L<Text::WrapI18N>

Too many options/functionality for what the goal of this module was.

Did not soft-hyphen broken words.

=back

=head1 EXPORTS

It exports fold_text() unless you bring it in a non-import() way, i.e.:

    use Text::Fold; # we now have fold_text() in this package since its import() was called

    use Text::Fold (); # we do not have fold_text() in this package since its import() was not called, we have Text::Fold::fold_text()

    require Text::Fold; # we do not have fold_text() in this package since its import() was not called, we have Text::Fold::fold_text()

=head1 INTERFACE 

It has a single function: fold_text()

=head2 fold_text()

The first argument is the string to fold (either a Unicode string or a Byte string).

Additional arguments are described in the follow list:

=over 4

=item no hashref argument
 
The second argument (optional) is the width. It defaults to 78.

The third argument (optional) is the string to join the chunks back together again. It defaults to "\n".

    my $78_char_wide_text = fold_text( $string ); # 78 chars wide lines seperated by \n
    
    my $42_char_wide_text = fold_text( $string, 42, "\n\n\n" ); # 42 chars wide lines seperated by 3 newlines
    
    my $78_char_wide_text = fold_text( $string, undef, "\n\n\n" ); # 78 chars wide lines seperated by 3 newlines

=item hashref argument

The second or third argument, both optional, can instead be a hashref with behavior options. 

If a hashref is passed as the second argument the default width is used and any third argument is ignored.

If a hashref is passed as the third argument the second argument remains the same as when used under “no hashref argument” style calls.

The keys to the hashref are all optional and can be:

=over 4

=item join

The same value as the third argument when not using a hasref argument.

=item soft_hyphen_threshold

The value should be the maximim number of “non-whitespace” (See the blurb about whitespace under “What it is not meant for”) characters that a sequence can be before it is soft hyphenated.

passing "0E0" will do a default value of about 20% of the width (i.e. I say “about” because it is $width/5 passed through int())

Not passing this key (default) simply does not enable this behavior and results in a chunk of anysize (i.e. 2 or more) being soft hyphenated. 

=back

    # w/ sequence of 15 (i.e. int(78/5)) characters or less moved to the next line
    my $78_char_wide_text = fold_text( $string,{ 'soft_hyphen_threshold' => '0E0'} );
    
    # w/ sequence of 20 characters or less moved to the next line
    my $42_char_wide_text =fold_text( $string, 42, { 'soft_hyphen_threshold' => '20', 'join' => "\n\n\n"} );

=back

Regardless of the string type the intended character counts as 1 character. For example, the Unicode string "Perl is the \x{32b7}\x{2122}" and the Byte strings "Perl is the \xe3\x8a\xb7\xe2\x84\xa2" and "Perl is the ㊷™" are all considered 14 characters longs

It returns a string of multiple lines each of which do not exceed the width. 

Words that crossed the width boundary are (loosely) notated with a soft hyphen taking into account the 'soft_hyphen_threshold' setting if any.

The string is the same type you passed in (either a Unicode string or a Byte string).

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 DEPENDENCIES

L<Encode>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-fold@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

Would any one find array context useful?

Do you know of a better/faster/etc way to do what it does?

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
