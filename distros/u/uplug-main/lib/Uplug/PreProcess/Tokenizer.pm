#-*-perl-*-

package Uplug::PreProcess::Tokenizer;

=head1 NAME

Uplug::PreProcess::Tokenizer

=head1 SYNOPSIS

 my $tokenizer = new Uplug::PreProcess::Tokenizer( lang => 'en' );
 my @tokens = tokenizer->tokenize( 'Mr. Smith says: "What is a text anyway?"' );
 my $text = detokenize( '" Big improvement ! " says Mr. Smith .');

=head1 IMPLEMENTS

=head2 C<tokenize>

Tokenize a given text. Returns a list of tokens.

=head2 C<detokenize>

De-tokenize a space-separated text or a list of tokens. Returns plain text.

=head2 C<load_prefixes>

Load language specific abbreviations and other non-breaking prefixes.

=head1 DESCRIPTION

This module heavily relies on the implementation of the tokenizer and detokenizer used in the Moses toolkit for SMT. All credits go to the original authors (Josh Schroeder and Philipp Koehn).

=cut

use strict;


use Uplug::Config;

# defaults: language = English

our $DEFAULT_LANG = 'en';

our %NONBREAKING_PREFIX;
our $NONBREAKING_PREFIX_DIR     = &shared_lang() . '/nonbreaking_prefixes';
our $DEFAULT_NONBREAKING_PREFIX = $NONBREAKING_PREFIX_DIR . '/nonbreaking_prefix.en';


sub new {
    my $class = shift;
    my %self  = @_;

    if ( $self{lang} ) {
        load_prefixes( $self{lang}, \%NONBREAKING_PREFIX );
    }

    return bless \%self, $class;
}


sub tokenize {
    my $self = shift;

    my ($text) = @_;
    chomp($text);
    $text = " $text ";

    # seperate out all "other" special characters
    $text =~ s/([^\p{IsAlnum}\s\.\'\`\,\-])/ $1 /g; #`

    #multi-dots stay together
    $text =~ s/\.([\.]+)/ DOTMULTI$1/g;
    while ( $text =~ /DOTMULTI\./ ) {
        $text =~ s/DOTMULTI\.([^\.])/DOTDOTMULTI $1/g;
        $text =~ s/DOTMULTI\./DOTDOTMULTI/g;
    }

    # seperate out "," except if within numbers (5,300)
    $text =~ s/([^\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;

    # separate , pre and post number
    $text =~ s/([\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;
    $text =~ s/([^\p{IsN}])[,]([\p{IsN}])/$1 , $2/g;

    # turn `into '
    $text =~ s/\`/\'/g; #`

    #turn '' into "
    $text =~ s/\'\'/ \" /g;

    if ( $$self{lang} eq "en" ) {
        #split contractions right
        $text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([^\p{IsAlpha}\p{IsN}])[']([\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1 '$2/g;

        #special case for "1990's"
        $text =~ s/([\p{IsN}])[']([s])/$1 '$2/g;
    }
    elsif ( ( $$self{lang} eq "fr" ) or ( $$self{lang} eq "it" ) ) {
        #split contractions left
        $text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([^\p{IsAlpha}])[']([\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1' $2/g;
    }
    else {
        $text =~ s/\'/ \' /g;
    }

    #word token method
    my @words = split( /\s/, $text );
    $text = "";
    for ( my $i = 0; $i < ( scalar(@words) ); $i++ ) {
        my $word = $words[$i];
        if ( $word =~ /^(\S+)\.$/ ) {
            my $pre = $1;
            if (( $pre =~ /\./ && $pre =~ /\p{IsAlpha}/ )
                || (   $NONBREAKING_PREFIX{$pre}
                    && $NONBREAKING_PREFIX{$pre} == 1 )
                || ( $i < scalar(@words) - 1
                    && ( $words[ $i + 1 ] =~ /^[\p{IsLower}]/ ) ) )
            {
                #no change
            }
            elsif (
                (      $NONBREAKING_PREFIX{$pre}
                    && $NONBREAKING_PREFIX{$pre} == 2
                )
                && ( $i < scalar(@words) - 1
                    && ( $words[ $i + 1 ] =~ /^[0-9]+/ ) ) )
            {
                #no change
            }
            else {
                $word = $pre . " .";
            }
        }
        $text .= $word . " ";
    }

    # clean up extraneous spaces
    $text =~ s/ +/ /g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    #restore multi-dots
    while ( $text =~ /DOTDOTMULTI/ ) {
        $text =~ s/DOTDOTMULTI/DOTMULTI./g;
    }
    $text =~ s/DOTMULTI/./g;

    #ensure final line break
    $text .= "\n" unless $text =~ /\n$/;
    return split( /\s+/, $text );
}


sub load_prefixes {
    my ( $language, $PREFIX_REF ) = @_;

    my $prefixfile
        = $NONBREAKING_PREFIX_DIR . '/nonbreaking_prefix.' . $language;

    #default back to English if we don't have a language-specific prefix file
    if ( !( -e $prefixfile ) ) {
        $prefixfile = $DEFAULT_NONBREAKING_PREFIX;
        unless ( -e $prefixfile ) {
            return 0;
        }
    }

    if ( -e "$prefixfile" ) {
        open( PREFIX, "<:encoding(utf8)", "$prefixfile" );
        while (<PREFIX>) {
            my $item = $_;
            chomp($item);
            if ( ($item) && ( substr( $item, 0, 1 ) ne "#" ) ) {
                if ( $item =~ /(.*)[\s]+(\#NUMERIC_ONLY\#)/ ) {
                    $PREFIX_REF->{$1} = 2;
                }
                else {
                    $PREFIX_REF->{$item} = 1;
                }
            }
        }
        close(PREFIX);
    }
}


# this is the Moses detokenizer
# written by Josh Schroeder, based on code by Philipp Koehn

sub detokenize {
    my $self  = shift;
    my $token = shift;

    my $text = ref($token) eq 'ARRAY' ? join( ' ', @$token ) : $token;
    my $language = $self->{lang} || 'en';

    #    chomp($text);
    $text =~ s/\n/ /gs;
    $text =~ s/\s\s+/ /gs;
    $text = " $text ";

    my $word;
    my $i;
    my @words = split( / /, $text );
    $text = "";
    my %quoteCount = ( "\'" => 0, "\"" => 0 );
    my $prependSpace = " ";
    for ( $i = 0; $i < ( scalar(@words) ); $i++ ) {
        if ( $words[$i] =~ /^[\p{IsSc}\(\[\{\¿\¡]+$/ ) {
            # perform right shift on currency and other random punctuation items
            $text         = $text . $prependSpace . $words[$i];
            $prependSpace = "";
        }
        elsif ( $words[$i] =~ /^[\,\.\?\!\:\;\\\%\}\]\)]+$/ ) {
            # perform left shift on punctuation items
            $text         = $text . $words[$i];
            $prependSpace = " ";
        }
        elsif (( $language eq "en" )
            && ( $i > 0 )
            && ( $words[$i] =~ /^[\'][\p{IsAlpha}]/ )
            && ( $words[ $i - 1 ] =~ /[\p{IsAlnum}]$/ ) )
        {
            # left-shift the contraction for English
            $text         = $text . $words[$i];
            $prependSpace = " ";
        }
        elsif (( $language eq "fr" )
            && ( $i < ( scalar(@words) - 2 ) )
            && ( $words[$i] =~ /[\p{IsAlpha}][\']$/ )
            && ( $words[ $i + 1 ] =~ /^[\p{IsAlpha}]/ ) )
        {
            # right-shift the contraction for French
            $text         = $text . $prependSpace . $words[$i];
            $prependSpace = "";
        }
        elsif ( $words[$i] =~ /^[\'\"]+$/ ) {
            # combine punctuation smartly
            if ( ( $quoteCount{ $words[$i] } % 2 ) eq 0 ) {
                if (   ( $language eq "en" )
                    && ( $words[$i] eq "'" )
                    && ( $i > 0 )
                    && ( $words[ $i - 1 ] =~ /[s]$/ ) )
                {
                   # single quote for posesssives ending in s... "The Jones' house"
                   # left shift
                    $text         = $text . $words[$i];
                    $prependSpace = " ";
                }
                else {
                    # right shift
                    $text         = $text . $prependSpace . $words[$i];
                    $prependSpace = "";
                    $quoteCount{ $words[$i] } = $quoteCount{ $words[$i] } + 1;
                }
            }
            else {
                # left shift
                $text                     = $text . $words[$i];
                $prependSpace             = " ";
                $quoteCount{ $words[$i] } = $quoteCount{ $words[$i] } + 1;
            }
        }
        else {
            $text         = $text . $prependSpace . $words[$i];
            $prependSpace = " ";
        }
    }

    # clean up spaces at head and tail of each line as well as any double-spacing
    $text =~ s/ +/ /g;
    $text =~ s/\n /\n/g;
    $text =~ s/ \n/\n/g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    # add trailing break
    #$text .= "\n" unless $text =~ /\n$/;

    return $text;
}


1;

