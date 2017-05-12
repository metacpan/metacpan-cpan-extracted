package Text::Extract::MaketextCallPhrases;

use strict;
use warnings;

$Text::Extract::MaketextCallPhrases::VERSION = '0.94';

use Text::Balanced      ();
use String::Unquotemeta ();

# So we don't have to maintain an identical regex
use Module::Want 0.6 ();
my $ns_regexp = Module::Want::get_ns_regexp();

my $NO_EXTRACT_KEY = '## no extract maketext';

sub import {
    no strict 'refs';    ## no critic
    *{ caller() . '::get_phrases_in_text' } = \&get_phrases_in_text;
    *{ caller() . '::get_phrases_in_file' } = \&get_phrases_in_file;
}

my $default_regexp_conf_item = [
    qr/(?:(?:^|\:|\s|=|\(|\.|\b)translatable|(?:make|lex)text(?:_[a-zA-Z0-9_]+_context)?)\s*\(?/,
    sub { return substr( $_[0], -1, 1 ) eq '(' ? qr/\s*\)/ : qr/\s*\;/ },
];

sub get_phrases_in_text {

    # 3rd arg is used internally to get the line number in the 'debug_ignored_matches' results when called via get_phrases_in_file(). Don't rely on this as it may change.
    my ( $text, $conf_hr, $linenum ) = @_;    # 3rd arg is used internally to get the line number in the 'debug_ignored_matches' results when called via get_phrases_in_file(). Don't rely on this as it may change.

    $conf_hr ||= {};

    if ( $conf_hr->{'encode_unicode_slash_x'} ) {
        Module::Want::have_mod('Encode') || die $@;
    }

    if ( $conf_hr->{'cpanel_mode'} && $conf_hr->{'cpanel_mode'} != 0 ) {
        $conf_hr->{'cpanel_mode'} = '0E0';
        push @{ $conf_hr->{'regexp_conf'} }, [ qr/\<cptext[^\\]/, qr/\s*\>/ ], [ qr/(?:^|[^<])cptext\s*\(/, qr/\s*\)/ ], [ qr/Cpanel::Exception(?:::$ns_regexp)?->new\(/, qr/\s*\)/ ], [ qr/Cpanel::Exception(?:::$ns_regexp)?::create\(/, qr/\s*\)/, { 'optional' => 1, 'arg_position' => 2 } ], [ qr/Cpanel::Exception(?:::$ns_regexp)?\-\>create\(/, qr/\s*\)/, { 'optional' => 1 } ],
          [ qr/Cpanel::LocaleString->new\(\s*/, qr/\s*\)/ ];
    }

    my @results;
    my %offset_seen;

    # I like this alignment better than what tidy does, seems clearer to me even if a bit overkill perhaps
    #tidyoff
    for my $regexp (
        $conf_hr->{'regexp_conf'} ? (
                                        $conf_hr->{'no_default_regex'} ? @{ $conf_hr->{'regexp_conf'} }
                                                                       : ( $default_regexp_conf_item, @{ $conf_hr->{'regexp_conf'} } )
                                    )
                                  : ($default_regexp_conf_item)
    ) {
    #tidyon
        my $text_working_copy = $text;
        my $original_len      = length($text_working_copy);

        my $rx_conf_hr = defined $regexp->[2] && ref( $regexp->[2] ) eq 'HASH' ? $regexp->[2] : { 'optional' => 0, 'arg_position' => 0 };
        $rx_conf_hr->{arg_position} = exists $rx_conf_hr->{arg_position} ? int( abs( $rx_conf_hr->{arg_position} ) ) : 0;    # if caller passes a non-numeric value this should warn, that is a feature!

        my $token_rx = qr/$regexp->[0]/;
        my ( $did_match, $matched, $no_extract_index );
        while (1) {
            last if !defined $text_working_copy;

            $did_match = $text_working_copy =~ $token_rx;

            if ($did_match) {
                $no_extract_index = index(
                    substr( $text_working_copy, 0, $+[0] ),
                    $NO_EXTRACT_KEY,
                );
                $matched = substr( $text_working_copy, $-[0], $+[0] - $-[0] );
            }
            else {
                $no_extract_index = index( $text_working_copy, $NO_EXTRACT_KEY );
                last if -1 == $no_extract_index;
            }

            # we have a (possibly multiline) chunk w/ notation-not-preceded-by-token that we should ignore
            if ( -1 != $no_extract_index && ( !$did_match || ( $no_extract_index < $-[0] ) ) ) {
                $text_working_copy =~ s/.* \Q$NO_EXTRACT_KEY\E [^\n]*//x;
                next;
            }

            my $pre;

            # TODO: incorporate the \s* into results: 'post_token_ws' => $1 || '' ?
            ( $pre, $text_working_copy ) = split( m/(?:$regexp->[0]|$NO_EXTRACT_KEY)\s*/, $text_working_copy, 2 );    # the \s* takes into account trailing WS that Text::Balanced ignores which then can throw off the offset

            # we have a token line that we should ignore
            next if $text_working_copy =~ s/^[^\n]* \Q$NO_EXTRACT_KEY\E [^\n]*//x;

            my $offset = $original_len - length($text_working_copy);

            my $phrase;
            my $result_hr = { 'is_error' => 0, 'is_warning' => 0, 'offset' => $offset, 'regexp' => $regexp, 'matched' => $matched };

            if ( $conf_hr->{'ignore_perlish_comments'} ) {

                # ignore matches in a comment
                if ( $pre =~ m/\#/ && $pre !~ m/[\n\r]$/ ) {
                    my @lines = split( /[\n\r]+/, $pre );

                    if ( $lines[-1] =~ m/\#/ ) {
                        $result_hr->{'type'} = 'comment';
                        $result_hr->{'line'} = $linenum if defined $linenum;
                        push @{ $conf_hr->{'debug_ignored_matches'} }, $result_hr;
                        next;
                    }
                }
            }

            # ignore functions named *$1
            if ( $text_working_copy =~ m/^\s*\{/ && $matched !~ m/\(\s*$/ ) {
                $result_hr->{'type'} = 'function';
                $result_hr->{'line'} = $linenum if defined $linenum;
                push @{ $conf_hr->{'debug_ignored_matches'} }, $result_hr;
                next;
            }

            # ignore assignments to things named *maketext
            if ( $text_working_copy =~ m/^\s*=/ ) {
                $result_hr->{'type'} = 'assignment';
                $result_hr->{'line'} = $linenum if defined $linenum;
                push @{ $conf_hr->{'debug_ignored_matches'} }, $result_hr;
                next;
            }

            if ( $conf_hr->{'ignore_perlish_statement'} ) {

                # ignore a statement named *maketext (e.g. goto &XYZ::maketext;)
                if ( $text_working_copy =~ m/^\s*;/ ) {
                    $result_hr->{'type'} = 'statement';
                    $result_hr->{'line'} = $linenum if defined $linenum;
                    push @{ $conf_hr->{'debug_ignored_matches'} }, $result_hr;
                    next;
                }
            }

            # phrase is argument N (instead of first)
            if ( $rx_conf_hr->{'arg_position'} > 0 ) {

                # hack away the args before the one at $arg_position
                for my $at_index ( 1 .. $rx_conf_hr->{'arg_position'} ) {
                    $text_working_copy =~ s{^\s*\,\s*}{};
                    if ( $at_index >= $rx_conf_hr->{'arg_position'} ) {
                        $result_hr->{'offset'} = $original_len - length($text_working_copy);
                        last;
                    }

                    ( $phrase, $text_working_copy ) = Text::Balanced::extract_variable($text_working_copy);

                    if ( !defined $phrase ) {
                        ( $phrase, $text_working_copy ) = Text::Balanced::extract_quotelike($text_working_copy);
                    }
                }
            }

            ( $phrase, $text_working_copy ) = Text::Balanced::extract_variable($text_working_copy);
            my $optional_perlish =
                $text_working_copy =~ m/^\s*\[/ ? "ARRAY"
              : $text_working_copy =~ m/^\s*\{/ ? "HASH"
              :                                   0;

            if ( !$phrase ) {

                # undef $@;
                my ( $type, $inside, $opener, $closer );
                ( $phrase, $text_working_copy, undef, $type, $opener, $inside, $closer ) = Text::Balanced::extract_quotelike($text_working_copy);
                $text_working_copy = '' if !defined $text_working_copy;

                $result_hr->{'quotetype'} = 'single' if ( defined $opener && $opener eq "'" ) || ( defined $type && ( $type eq 'q' || $type eq 'qw' ) );
                $result_hr->{'quotetype'} = 'double' if ( defined $opener && $opener eq '"' ) || ( defined $type && $type eq 'qq' );
                if ( $result_hr->{'quotetype'} ) {
                    $result_hr->{'quote_before'} = $type . $opener;
                    $result_hr->{'quote_after'}  = $closer;
                }

                if ( defined $type && $type eq '<<' ) {
                    $result_hr->{'quote_before'} = $type . $opener;
                    $result_hr->{'quote_after'}  = $closer;

                    $result_hr->{'heredoc'} = $opener;
                    if ( substr( $opener, 0, 1 ) eq "'" ) {
                        $result_hr->{'quotetype'} = 'single';
                    }
                    else {
                        $result_hr->{'quotetype'} = 'double';
                    }
                }

                if ( defined $inside && ( exists $result_hr->{'quotetype'} ) && $inside eq '' ) {
                    $result_hr->{'is_error'} = 1;
                    $result_hr->{'type'}     = 'empty';
                    $phrase                  = $inside;
                }
                elsif ( defined $inside && $inside ) {
                    $phrase = $inside;

                    if ( $type eq 'qw' ) {
                        if ( $phrase =~ m/\A(\s+)/ ) {
                            $result_hr->{'quote_before'} .= $1;
                            $phrase =~ s/\A(\s+)//;
                        }
                        if ( $phrase =~ m/(\s+)\z/ ) {
                            $result_hr->{'quote_after'} = $1 . $result_hr->{'quote_after'};
                            $phrase =~ s/(\s+)\z//;
                        }

                        if ( $phrase =~ m/(\s+)/ ) {
                            $result_hr->{'quote_after'} = $1;
                        }

                        # otherwise leave quote_after asis for cases like this: qw(foo)

                        ($phrase) = split( /\s+/, $phrase, 2 );
                    }
                    elsif ( $type eq 'qx' || $opener eq '`' ) {
                        $result_hr->{'is_warning'} = 1;
                        $result_hr->{'type'}       = 'command';
                    }
                    elsif ( $type eq 'm' || $type eq 'qr' || $type eq 's' || $type eq 'tr' || $opener eq '/' ) {
                        $result_hr->{'is_warning'} = 1;
                        $result_hr->{'type'}       = 'pattern';
                    }
                }
                elsif ( defined $opener && defined $inside && defined $closer && defined $phrase && $phrase eq "$opener$inside$closer" ) {
                    $result_hr->{'is_error'} = 1;
                    $result_hr->{'type'}     = 'empty';
                    $phrase                  = $inside;
                }
                else {
                    my $is_no_arg = 0;
                    if ( defined $regexp->[1] ) {
                        if ( ref( $regexp->[1] ) eq 'CODE' ) {
                            my $rgx = $regexp->[1]->($matched);
                            if ( $text_working_copy =~ m/^$rgx/ ) {
                                $is_no_arg = 1;
                            }
                        }
                        elsif ( ref( $regexp->[1] ) eq 'Regexp' ) {
                            my $rgx = qr/^$regexp->[1]/;
                            if ( $text_working_copy =~ $rgx ) {
                                $is_no_arg = 1;
                            }
                        }
                    }

                    if ($is_no_arg) {
                        if ( $rx_conf_hr->{'optional'} ) {
                            next;
                        }
                        else {
                            $result_hr->{'is_error'} = 1;
                            $result_hr->{'type'}     = 'no_arg';
                        }
                    }
                    elsif ( $text_working_copy =~ m/^\s*(((?:\&|\\\*)?)$ns_regexp(?:\-\>$ns_regexp)?((?:\s*\()?))/o ) {
                        $phrase = $1;
                        my $perlish = $2 || $3 ? 1 : 0;

                        $text_working_copy =~ s/\s*(?:\&|\\\*)?$ns_regexp(?:\-\>$ns_regexp)?(?:\s*\()?\s*//o;

                        $result_hr->{'is_warning'} = 1;
                        $result_hr->{'type'} = $perlish ? 'perlish' : 'bareword';
                    }
                }
            }
            else {
                $result_hr->{'is_warning'} = 1;
                $result_hr->{'type'}       = 'perlish';
            }

            if ( !defined $phrase ) {
                my $is_no_arg = 0;
                if ( defined $regexp->[1] ) {
                    if ( ref( $regexp->[1] ) eq 'CODE' ) {
                        my $rgx = $regexp->[1]->($matched);
                        if ( $text_working_copy =~ m/^$rgx/ ) {
                            $is_no_arg = 1;
                        }
                    }
                    elsif ( ref( $regexp->[1] ) eq 'Regexp' ) {
                        my $rgx = qr/^$regexp->[1]/;
                        if ( $text_working_copy =~ $rgx ) {
                            $is_no_arg = 1;
                        }
                    }
                }

                if ($is_no_arg) {
                    if ( $rx_conf_hr->{'optional'} ) {
                        next;
                    }
                    else {
                        $result_hr->{'is_error'} = 1;
                        $result_hr->{'type'}     = 'no_arg';
                    }
                }
                else {
                    if ($optional_perlish) {
                        if ( $rx_conf_hr->{'optional'} ) {
                            next;
                        }
                        else {
                            $result_hr->{'is_warning'} = 1;
                            $result_hr->{'type'}       = 'perlish';
                            $phrase                    = $optional_perlish;
                        }
                    }
                    else {
                        $result_hr->{'is_warning'} = 1;
                        $result_hr->{'type'}       = 'multiline';
                    }
                }
            }
            else {
                $result_hr->{'original_text'} = $phrase;

                # make sure its wasn't a tricky variable in quotes like maketext("$foo->{zip}")
                # '$foo->{zip}' '   $foo->{zip} ' " $foo->{zip} " to but that seems like a good idea to flag as wonky and in need of human follow up
                my ( $var, $for, $aft ) = Text::Balanced::extract_variable($phrase);
                if ( $var && defined $for && defined $aft && $for =~ m/\A\s*\z/ && $aft =~ m/\A\s*\z/ ) {
                    $result_hr->{'is_warning'} = 1;
                    $result_hr->{'type'}       = 'perlish';
                }
                else {
                    if ( exists $result_hr->{'quotetype'} ) {
                        if ( $result_hr->{'quotetype'} eq 'single' ) {

                            # escape \n\t etc to preserver them during unquotemeta()
                            $phrase =~ s{(\\(?:n|t|f|r|a|b))}{\\$1}g;
                        }
                        elsif ( $result_hr->{'quotetype'} eq 'double' ) {

                            # interpolate \n\t etc
                            $phrase =~ s{(\\(?:n|t|f|r|a|b))}{eval qq{"$1"}}eg;
                        }
                    }

                    if ( $conf_hr->{'encode_unicode_slash_x'} ) {

                        # Turn Unicode string \x{} into bytes strings
                        $phrase =~ s{(\\x\{[0-9a-fA-F]+\})}{Encode::encode_utf8( eval qq{"$1"} )}eg;
                    }
                    else {

                        # Preserve Unicode string \x{} for unquotemeta()
                        $phrase =~ s{(\\)(x\{[0-9a-fA-F]+\})}{$1$1$2}g;
                    }

                    # Turn graphemes into characters to avoid quotemeta() problems
                    $phrase =~ s{((:?\\x[0-9a-fA-F]{2})+)}{eval qq{"$1"}}eg;
                    $phrase = String::Unquotemeta::unquotemeta($phrase) unless exists $result_hr->{'type'} && $result_hr->{'type'} eq 'perlish';
                }
            }

            $result_hr->{'phrase'} = $phrase;

            push @results, $result_hr if ++$offset_seen{ $result_hr->{'offset'} } == 1;
        }
    }

    return [ sort { $a->{'offset'} <=> $b->{'offset'} } @results ];
}

sub get_phrases_in_file {
    my ( $file, $regex_conf ) = @_;

    open my $fh, '<', $file or return;

    my @results;
    my $prepend       = '';
    my $linenum       = 0;
    my $in_multi_line = 0;
    my $line;    # buffer

    while ( $line = readline($fh) ) {
        $linenum++;

        my $initial_result_count = @results;
        push @results, map { $_->{'file'} = $file; $_->{'line'} = $in_multi_line ? $in_multi_line : $linenum; $_ } @{ get_phrases_in_text( $prepend . $line, $regex_conf, $linenum ) };
        my $updated_result_count = @results;

        if ( $in_multi_line && $updated_result_count == $initial_result_count ) {
            $prepend = $prepend . $line;
            next;
        }
        elsif ( $in_multi_line && $updated_result_count > $initial_result_count && $results[-1]->{'type'} ) {
            $prepend = $prepend . $line;
            pop @results;
            next;
        }
        elsif ( !$in_multi_line && @results && defined $results[-1]->{'type'} && $results[-1]->{'type'} eq 'multiline' ) {
            $in_multi_line = $linenum;
            my $trailing_partial = pop @results;

            require bytes;
            my $offset = $trailing_partial->{'offset'} > bytes::length( $prepend . $line ) ? bytes::length( $prepend . $line ) : $trailing_partial->{'offset'};
            $prepend = $trailing_partial->{'matched'} . substr( "$prepend$line", $offset );
            next;
        }
        else {
            $in_multi_line = 0;
            $prepend       = '';
        }
    }

    close $fh;

    return \@results;
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::Extract::MaketextCallPhrases - Extract phrases from maketext–call–looking text

=head1 VERSION

This document describes Text::Extract::MaketextCallPhrases version 0.94

=head1 SYNOPSIS

    use Text::Extract::MaketextCallPhrases;
    my $results_ar = get_phrases_in_text($text);

    use Text::Extract::MaketextCallPhrases;
    my $results_ar = get_phrases_in_file($file);

=head1 DESCRIPTION

Well designed systems use consistent calls for localization. If you're really smart you've also used Locale::Maketext!!

You will probably have a collection of data that contains things like this:

    $locale->maketext( ... ); (perl)

    [% locale.maketext( ..., arg1 ) %] (TT)

    !!* locale%greetings+programs | ... , arg1 | *!! (some bizarre thing you've invented)

This module looks for the first argument to things that look like maketext() calls (See L</SEE ALSO>) so that you can process as needed (lint check, add to lexicon management system, etc).

By default it looks for calls to maketext(), maketext_*_context(), lextext(), and translatable() (ala L<Locale::Maketext::Utils::MarkPhrase>). If you use a shortcut (e.g. _()) or an unperlish format, it can do that too (You might also want to look at L</SEE ALSO> for an alternative this module).

=head1 EXPORTS

get_phrases_in_text() and get_phrases_in_file() are exported by default unless you bring it in with require() or no-import use()

    require Text::Extract::MaketextCallPhrases;

    use Text::Extract::MaketextCallPhrases ();

=head1 INTERFACE

These functions return an array ref containing a "result hash" (described below) for each phrase found, in the order they appear in the original text.

=head2 get_phrases_in_text()

The first argument is the text you want to parse for phrases.

The second optional argument is a hashref of options. It’s keys can be as follows:

=over 4

=item 'regexp_conf'

This should be an array reference. Each item in it should be an array reference with at least the following 2 items:

=over 4

=item First

A regex object (i.e. qr()) that matches the beginning of the thing you are looking for.

The regex should simply match and remain simple as it gets used by the parser where and as needed. Do not anchor or capture in it!

   qr/\<cptext/

=item Second

A regex object (i.e. qr()) that matches the end of the thing you are looking for.

It can also be a coderef that gets passed the string matched by item 1 and returns the appropriate regex object (i.e. qr()) that matches the end of the thing you are looking for.

The regex should simply match and remain simple as it gets used by the parser where and as needed. Do not anchor or capture in it! If it is possible that there is space before the closing "whatever" you should include that too.

   qr/\s*\>/

=item Third (Optional)

A hashref to configure this particular token’s behavior.

Keys are:

=over 4

=item 'optional'

Default is false. When set to true, tokens not followed by a string are not included in the results (e.g. no_arg).

    blah("I am howdy", [ …], {…}); # 'I am howdy'
    blah([…],{…}); # usually included in the results w/ a type of 'perlish' but under optional => 1 it will not be included in the results

=item 'arg_position'

Default is not to use it but conceptually it is '1' as in “first”.

After the token match, the next thing (per L<Text::Balanced>) is typically the phrase. If that is not the case w/ a given token you can use arg_position to specify what position it takes in a list of arguments after the token as found by L<Text::Balanced>.

For example:

    mythingy('Merp', 'I am the phrase we want to parse.', 'foo')

The list is 3 things: 'Merp', 'I am the phrase we want to parse.', and 'foo', positioned at 1, 2 , and 3 respectively.

In that case you want to specify arg_position => 2 in order to find 'I am the phrase we want to parse.' instead of 'Merp'.

=back

=back

Example:

    'regexp_conf' => [
        [ qr/greetings\+programs \|/, qr/\s*\|/ ],
        [ qr/\_\(?/, sub { return substr( $_[0], -1, 1 ) eq '(' ? qr/\s*\)/ : qr/\s*\;/ } ],
    ],

    'regexp_conf' => [
        [ qr/greetings\+programs \|/, qr/\s*\|/ ],
        [ qr/\_\(?/, sub { return substr( $_[0], -1, 1 ) eq '(' ? qr/\s*\)/ : qr/\s*\;/ } ],
        { 'optional' => 1 }
    ],

=item 'no_default_regex'

If you are using 'regexp_conf' then setting this to true will avoid using the default maketext() lookup. (i.e. only use 'regexp_conf')

=item 'cpanel_mode'

Boolean. Default false, when true it enables cPanel specific checks (e.g. cptext call syntax).

=item 'encode_unicode_slash_x'

Boolean (default is false) that when true will turn Unicode string notation \x{....} into a non-grapheme byte string. This will cause L<Encode>  to be loaded if needed.

Otherwise \x{....} are left in the phrase as-is.

=item 'debug_ignored_matches'

This is an array that gets aggregate debug info on matches that did not look like something that should have a phrase associated with it.

Some examples of things that might match but would not :

    sub i_heart_maketext { 1 }

    *i_heart_maketext = "foo";

    goto &xyz::maketext;

    print $locale->Maketext("Hello World"); # maketext() is cool

=item 'ignore_perlish_statement'

Boolean (default is false) that when true will cause matches that look like a statement to be put in 'debug_ignored_matches' instead of a result with a 'type' of 'no_arg'.

=item 'ignore_perlish_comment'

Boolean (default is false) that when true will cause matches that look like a perl comment to be put in 'debug_ignored_matches' instead of a result.

Since this is parsing arbitrary text and thus there is no real context, interpreting what is a comment or not becomes very complex and context sensitive.

If you do not want to grab phrases from commented out data and this check does not work with this text's commenting scheme then you could instead strip comments out of the text before parsing.

=back

=head2 get_phrases_in_file()

Same as get_phrases_in_text() except it takes a path whose contents you want to process instead of text you want to process.

If it can't be opened  returns false:

    my $results = get_phrases_in_file($file) || die "Could not read '$file': $!";

=head2 The "result hash"

This hash contains the following keys that describe the phrase that was parsed.

=over 4

=item 'phrase'

The phrase in question.

=item 'offset'

The offset in the text where the phrase started.

=item 'line'

Available via get_phrases_in_file() only, not get_phrases_in_text().

The line number the offset applies to. If a phrase spans more than one line it should be the line it starts on - but you're too smart to let the phrase dictate output format right ;p?

=item 'file'

Available via get_phrases_in_file() only, not get_phrases_in_text().

The file the result is from. Useful when aggregating results from multiple files.

=item 'original_text'

This is 'phrase' before any final normalizations happens.

You should be able to match the result's exact instance of the phrase if you find qr/\Q$rh->{'original_text'}\E/ right around $rh->{'file'} -> $rh->{'line'} -> $rh->{'offset'}.

=item 'matched'

Chunk that matched the "maketext call" regex.

=item 'regexp'

The array reference used to match this call/phrase. It is the same thing as each array ref passed in the regexp_conf list.

=item 'quotetype'

If the match was in double quote context it will be 'double'. Specials like \t and \n are interpolated.

If the match was in single quote context it will be 'single'. Specials like \t and \n remain literal.

Otherwise it won't exist.

=item 'quote_before' and 'quote_after'

If 'quotetype' is set these will be set also, it will be the quote-string before and after the phrase. For example, w/ 'foo' they'd both be '. For q{foo} they'd be q{ and } respectively.

If 'heredoc' is set then keep the following caveat in mind: Due to how L<Text::Balanced> has to handle here docs 'quote_before' will not contain anything after '<<TOKEN'. i.e. it is not exactly the string that was before it in the source code.

=item 'heredoc'

If the match was a here-doc, it will contain the opening token/the left delimiter, including any quotes.

=item 'is_warning'

The phrase we found wasn't a string, which is odd.

=item 'is_error'

The phrase we found looks like a mistake was made.

=item 'type'

If the phrase is a warning or error this is a keyword that highlights why the parser wants you to look at it further.

The value can be:

=over 4

=item undef/non-existent

Was a normal string, all is well.

=item 'command'

The phrase was a backtick or qx() expression.

=item 'pattern'

The phrase was a regex or transliteration expression.

=item 'empty'

The phrase was a hardcoded empty value.

=item 'bareword'

The phrase was a bare word expression.

=item 'perlish'

The phrase was perl-like expression (e.g. a variable)

=item 'no_arg'

The call had no arguments

=item 'multiline'

The call’s argument did not contain a full entity. Probably due to a multiline phrase that is cut off at the end of the text being parsed.

This should only happen in the last item and means that some data need prepended to the next chunk you will be parsing in effort to get a complete, parsable, argument.

    my $string_1 = "maketext('I am the very model of ";
    my $string_2 = "of a modern major general.')";

    my $results = get_phrases_in_text($string_1);

    if ( $results->[-1]->{'type'} eq 'multiline' ) {
        my $trailing_partial = pop @{$results};
        $string_2 = $trailing_partial->{'matched'} . substr( $string_1, $trailing_partial->{'offset'} ) . $string_2;
    }
    push @{$results}, @{ get_phrases_in_text($string_2) };

=back

=back

=head2 “## no extract maketext” notation

If you have a token in the text being parsed that is not actually a maketext call (or is a maketext call that you want to ignore for some reason) you can mark it as such (i.e. so that it is not included in the results) by putting the string “## no extract maketext” after said token on the same line.

    print $lh->maketext('I am a localized string!');
    print $lh->maketext('I am not to be parsed for various undisclosed business reasons.'); ## no extract maketext
    print $lh->maketext( ## no extract maketext
        'I am not to be parsed for various undisclosed business reasons.'
    …
    # parse API format string:
    if ($str =~ m/maketext\(/) { ## no extract maketext
    …
    # mock maketext for testing:
    sub maketext { ## no extract maketext

Even if you are not parsing perl code you can use it (i.e. the #s are part of the notation and happen to work as comments in perl).

    $('#msg').text( LOCALE.maketext('I am a localized string!') );
    $('#msg').text( LOCALE.maketext('I am not to be parsed for various undisclosed business reasons.'); // ## no extract maketext
    $('#msg').text( LOCALE.maketext( // ## no extract maketext
        'I am not to be parsed for various undisclosed business reasons.'
    …
    // parse API format string:
    if (str.match(/maketext\(/)) { // ## no extract maketext
    …
    // mock maketext for testing:
    function maketext(…) { // ## no extract maketext

Any token-looking things after the notation on that line are also ignored.

    maketext('I am ignored.') ## no extract maketext: could also be maketext('I am also ignored')

=head1 DIAGNOSTICS

This module throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Text::Extract::MaketextCallPhrases requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Text::Balanced>

L<String::Unquotemeta>

L<Module::Want>

=head1 INCOMPATIBILITIES

None reported.

=head1 CAVEATS

If the first thing following the "call" is a comment, the phrase will not be found.

This is because these are maketext-looking calls, not necessarily perl code. Thus interpreting what is a comment or not becomes very complex and context sensitive.

See L</SEE ALSO> if you really need to support that convention (said convention seems rather silly but hey, its your code).

The result hash's values for that call are unknown (probably 'multiline' type and undef phrase). If that holds true then detecting one in the middle of your results stack is a sign of that condition.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-extract-maketextcallphrases@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<Locale::Maketext::Extract> it is a driver based OO parser that has a more complex and extensible interface that may serve your needs better.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

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
