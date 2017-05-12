#-*-perl-*-

package Uplug::PreProcess::SentDetect;

# sentence boundary detection based on the Moses/Europarl sentence splitter
# (adjusted from Lingua::Sentence to Uplug)

=head1 NAME

Uplug::PreProcess::SentDetect - Moses/Europarl sentence boundary detector

=head1 SYNOPSIS

 use Uplug::PreProcess::SentDetect;
 my $splitter = Uplug::PreProcess::SentDetect->new (lang => 'en');
 my $text = 'This is a paragraph. It contains several sentences. "But why," you ask?';
 print $splitter->split($text);

=head1 DESCRIPTION

This module is basically a copy of L<Lingua::Sentence> by Achim Ruopp adapted to Uplug which is based on tools developed for Moses and the Europarl corpus. All credits go to the original authors. This version includes some additional non-breaking prefix files.

This module allows splitting of text paragraphs into sentences.
It is based on scripts developed by Philipp Koehn and Josh Schroeder
for processing the Europarl corpus (L<http://www.statmt.org/europarl/>).

The module uses punctuation and capitalization clues to split paragraphs
into an newline-separated string with one sentence per line.
For example:

 This is a paragraph. It contains several sentences. "But why," you ask?

goes to:

 This is a paragraph.
 It contains several sentences.
 "But why," you ask?

Languages currently supported by the module are:

=over

=item ca (Catalan)

=item da (Danish)

=item de (German)

=item el (Greek)

=item en (English)

=item es (Spanish)

=item fr (French)

=item is (Icelandic)

=item it (Italian)

=item nl (Dutch)

-item pl (Polish)

=item pt (Portuguese)

=item ro (Romanian)

=item ru (Russian)

=item sk (Slovak)

=item sl (Slovene)

=item sv (Swedish)

=back


=head2 Nonbreaking-Prefixes Files

Nonbreaking prefixes are loosely defined as any word ending in a period
that does NOT indicate an end of sentence marker.
A basic example is Mr. and Ms. in English.

The sentence splitter module uses the nonbreaking prefix files included in this distribution.

To add a file for other languages, follow the naming convention nonbreaking_prefix.??
and use the two-letter language code you intend to use when creating a Lingua::Sentence object.

The sentence splitter module will first look for a file for the language it is processing,
and fall back to English if a file for that language is not found. 

For the splitter, normally a period followed by an uppercase word results in a sentence split.
If the word preceeding the period is a nonbreaking prefix, this line break is not inserted.

A special case of prefixes, NUMERIC_ONLY, is included for special cases where the prefix should be handled ONLY when before numbers.
For example, "Article No. 24 states this." the No. is a nonbreaking prefix.
However, in "No. It is not true." No functions as a word.

See the example prefix files included in the distribution for more examples.

=cut

use strict;

use Uplug::Config;

# defaults: language = English

our $DEFAULT_LANG = 'en';

our $NONBREAKING_PREFIX_DIR     = &shared_lang() . '/nonbreaking_prefixes';
our $DEFAULT_NONBREAKING_PREFIX = $NONBREAKING_PREFIX_DIR . '/nonbreaking_prefix.en';


=head1 CONSTRUCTOR

The constructor can be called in two ways:

 Uplug::PreProcess::SentDetect->new (lang => $lang_id)

Instantiate an object to split sentences in language C<$lang_id>.
If the language is not supported, a splitter object for English will be instantiated.

=cut

sub new {
    my $class = shift;

    my $self = {};
    %{$self} = @_;

    $self->{lang} = $DEFAULT_LANG unless ( defined $self->{lang} );
    bless $self, $class;
    $self->init( $self->{lang} );
    return $self;
}


# Preloaded methods go here.

sub init {
    my $self = shift;

    my $langid = shift;
    my $prefixfile = shift;

    # Try loading nonbreaking prefix file specified in constructor
    my $dir = $NONBREAKING_PREFIX_DIR;
    if ( defined($prefixfile) ) {
        if ( !( -e $prefixfile ) ) {
            $prefixfile = "$dir/nonbreaking_prefix.$langid";
        }
    }
    else {
        $prefixfile = "$NONBREAKING_PREFIX_DIR/nonbreaking_prefix.$langid";
    }

    my %NONBREAKING_PREFIX;

    #default back to English if we don't have a language-specific prefix file
    if ( !( -e $prefixfile ) ) {
        $prefixfile = $DEFAULT_NONBREAKING_PREFIX;
        unless ( -e $prefixfile ) {
            die "ERROR: No abbreviations files found in $dir";
        }
    }
    if ( -e "$prefixfile" ) {
        open( PREFIX, "<:encoding(utf8)", "$prefixfile" );
        while (<PREFIX>) {
            my $item = $_;
            chomp($item);
            if ( ($item) && ( substr( $item, 0, 1 ) ne "#" ) ) {
                if ( $item =~ /(.*)[\s]+(\#NUMERIC_ONLY\#)/ ) {
                    $NONBREAKING_PREFIX{$1} = 2;
                }
                else {
                    $NONBREAKING_PREFIX{$item} = 1;
                }
            }
        }
        close(PREFIX);
    }

    $self->{LangID}      = $langid;
    $self->{Nonbreaking} = \%NONBREAKING_PREFIX;
    return $self;
}


sub split {
    my $self = shift;
    if ( !ref $self ) {
        return "Unnamed $self";
    }
    my $text = shift;
    if ( !$text ) {
        return ();
    }
    my $splittext = _preprocess( $self, $text );
    chomp $splittext;
    return split( /\n/, $splittext );
}


sub _preprocess {
    my ( $self, $text ) = @_;

    # clean up spaces at head and tail of each line as well as any double-spacing
    $text =~ s/ +/ /g;
    $text =~ s/\n /\n/g;
    $text =~ s/ \n/\n/g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    ##### add sentence breaks as needed #####

    #non-period end of sentence markers (?!) followed by sentence starters.
    $text =~ s/([?!]) +([\'\"\(\[\¿\¡\p{IsPi}\x{201E}]*[\p{IsUpper}])/$1\n$2/g;

    #multi-dots followed by sentence starters
    $text =~ s/(\.[\.]+) +([\'\"\(\[\¿\¡\p{IsPi}\x{201E}]*[\p{IsUpper}])/$1\n$2/g;

    # add breaks for sentences that end with some sort of punctuation
    # inside a quote or parenthetical and are followed by a possible
    # sentence starter punctuation and upper case
    $text =~ s/([?!\.][\ ]*[\'\"\)\]\p{IsPf}]+) +([\'\"\(\[\¿\¡\p{IsPi}\x{201E}]*[\ ]*[\p{IsUpper}])/$1\n$2/g;

    # add breaks for sentences that end with some sort of punctuation are
    # followed by a sentence starter punctuation and upper case
    $text =~ s/([?!\.]) +([\'\"\(\[\¿\¡\p{IsPi}\x{201E}]+[\ ]*[\p{IsUpper}])/$1\n$2/g;

    # special punctuation cases are covered. Check all remaining periods.
    my $word;
    my $i;
    my @words = split( / /, $text );
    $text = "";
    for ( $i = 0; $i < ( scalar(@words) - 1 ); $i++ ) {
        if ( $words[$i]
            =~ /([\p{IsAlnum}\.\-]*)([\'\"\)\]\%\p{IsPf}]*)(\.+)$/ )
        {
            #check if $1 is a known honorific and $2 is empty, never break
            my $prefix         = $1;
            my $starting_punct = $2;
            if (   $prefix
                && $self->{Nonbreaking}{$prefix}
                && $self->{Nonbreaking}{$prefix} == 1
                && !$starting_punct )
            {
                #not breaking;
            }
            elsif ( $words[$i] =~ /(\.)[\p{IsUpper}\-]+(\.+)$/ ) {
                #not breaking - upper case acronym
            }
            elsif ( $words[ $i + 1 ] =~ /^([ ]*[\'\"\(\[\¿\¡\p{IsPi}\x{201E}]*[ ]*[\p{IsUpper}0-9])/ ) {
                # the next word has a bunch of initial quotes,
                # maybe a space, then either upper case or a number
                $words[$i] = $words[$i] . "\n"
                    unless ( $prefix
                    && $self->{Nonbreaking}{$prefix}
                    && $self->{Nonbreaking}{$prefix} == 2
                    && !$starting_punct
                    && ( $words[ $i + 1 ] =~ /^[0-9]+/ ) );
                # we always add a return for these unless we have
                # a numeric non-breaker and a number start
            }

        }
        $text = $text . $words[$i] . " ";
    }

    # we stopped one token from the end to allow for easy look-ahead. Append it now.
    $text = $text . $words[$i];

    # clean up spaces at head and tail of each line as well as any double-spacing
    $text =~ s/ +/ /g;
    $text =~ s/\n /\n/g;
    $text =~ s/ \n/\n/g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    #add trailing break
    $text .= "\n" unless $text =~ /\n$/;

    return $text;
}


1;

=head2 CREDITS

Thanks for the following individuals for supplying nonbreaking prefix files:
Bas Rozema (Dutch), HilE<aacute>rio Leal Fontes (Portuguese), JesE<uacute>s GimE<eacute>nez (Catalan & Spanish)

=head1 SUPPORT

Bugs should always be submitted via the project hosting bug tracker

L<http://code.google.com/p/corpus-tools/issues/list>

For other issues, contact the maintainer.

=head1 SEE ALSO

L<Text::Sentence>,
L<Lingua::EN::Sentence>,
L<Lingua::DE::Sentence>,
L<Lingua::HE::Sentence>

=head1 AUTHOR

Lingua::Sentence: Achim Ruopp, E<lt>achimru@gmail.comE<gt>

Adapted to Uplug: Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Digital Silk Road

Portions Copyright (C) 2005 by Philip Koehn and Josh Schroeder (used with permission)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

