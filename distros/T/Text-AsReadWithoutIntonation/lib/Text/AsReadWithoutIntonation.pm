package Text::AsReadWithoutIntonation;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::AsReadWithoutIntonation ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'test' => [ qw(
	inSpanish
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'test'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.9';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Text::AsReadWithoutIntonation - Perl extension for converting sentences to  text resembling the way it would be read without intonation.

=head1 SYNOPSIS

  use Text::AsReadWithoutIntonation;
  $readWord = Text::AsReadWithoutIntonation:inSpanish($text);

=head1 DESCRIPTION

Perl extension for converting sentences to  text resembling the way it would be read without intonation (no questions, no pauses or any other prosodic clues).

=head2 EXPORT

None by default.



=head1 SEE ALSO


=head1 AUTHOR

Alberto Montero, E<lt>amonero@gsi.dit.upm.esE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Alberto Montero

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

use Lingua::ES::Numeros qw(parse_num);
use Text::IdMor;
use Text::Roman;
use Symbol::Name;
use String::Multibyte;

=item inSpanish

Convert the given sentence to text resembling the way it would be read without intonation (no questions, no pauses or any other prosodic clues). 

Non interpretable symbols are supressed.

Numbers are read in spanish. If ª or º is supplied, appropiated gender is used.

Roman numbers lower than or equal to 10 are read as ordinals, and cardinals otherwise.

Supported currencies are euros and dollars.

Mathematical symbols are equal, plus and percentage

'@' is correctly read

=cut
sub inSpanish($) {
    my $text = shift;

    my @words = split /\s+/, $text;

    my $readText = "";

    foreach my $word (@words) {
        $readText .= " "._wordInSpanish($word);
    }
    $readText =~ s/^\s+//;
    $readText =~ s/\s+$//;

    return $readText;
}

=item wordInSpanish

Read the supplied single word in spanish, with the same conventions as inSpanish.

=cut
sub _wordInSpanish($) {
    my $word = shift;
    chop($word) if (($word =~ /\.$/ && !Text::IdMor::isAcronym($word)) 
                 || ($word =~ /\,$/)
                 || ($word =~ /:$/));
    my $readWord = "";

    if (Text::IdMor::isAcronym($word)) {
        $word =~ s/\.//g;
        $readWord .= _readSymbolBySymbolInSpanish($word);
    } elsif (Text::IdMor::isRomanNumber($word)) {
        my $numReader = new Lingua::ES::Numeros(FORMATO => "");
        my $intVersion = roman2int($word);
        if ($intVersion <= 10) {
            $readWord .= " ".$numReader->ordinal($intVersion);
        } else {
            $readWord .= " ".$numReader->real($intVersion);
        }
    } elsif (Text::IdMor::isWord($word)) {
#         $word =~ tr/A-ZÁ-ÚUÑ/a-zá-úüñ/;
        $word =~ tr/A-Z/a-z/;
        $word =~ s/Á/á/g;
        $word =~ s/É/é/g;
        $word =~ s/Í/í/g;
        $word =~ s/Ó/ó/g;
        $word =~ s/Ú/ú/g;
        $word =~ s/Ü/ü/g;
        $word =~ s/Ñ/ñ/g;
        $readWord = $word;
#         my $utf8 = new String::Multibyte('UTF8');
#         $readWord = $utf8->strtr($word, 
#                                  ["A-Z", "Á-Ú", "Ü", "Ñ"],
#                                  ["a-z", "á-ú", "ü", "ñ"]);
        
    } elsif (Text::IdMor::isInteger($word)) {
        my $numReader = new Lingua::ES::Numeros(FORMATO => "", UNMIL => 0);
        $word = _convertNumbersFromSpanishToEnglishForm($word);
        eval {
            $readWord .= " ".$numReader->cardinal($word);
        };
    } elsif (Text::IdMor::isSpanishRealNumber($word)) {
        my ($ent, $frac) = split /\,/, $word;
        $readWord .= " "._wordInSpanish($ent)." con";
        $frac =~ /^(0*)([^0]*)$/;
        my $fracZeros = $1; my $fracDigits = $2;
        $readWord .= " ".Symbol::Name::inSpanish('0') foreach (split //, $fracZeros);
        $readWord .= " "._wordInSpanish($fracDigits);
    } elsif (Text::IdMor::isRomanNumber($word)) {
        my $numReader = new Lingua::ES::Numeros(FORMATO => "");
        my $intVersion = roman2int($word);
        eval {
        if ($intVersion <= 10) {
            $readWord .= " ".$numReader->ordinal($intVersion);
        } else {
            $readWord .= " ".$numReader->real($intVersion);
        }
        };
    } elsif (Text::IdMor::isOrdinalNumber($word)) {
        my $lastChar = chop($word);  # A bit tricky, but it does the job if not utf8
        my $c2 = chop($word);
        if ($c2 =~ /[0-9]/) {
            $word .= $c2;
            $lastChar = $c2.$c1;
        } else {
            $lastChar = $c2.$lastChar;
        }
        my $gender = $lastChar =~ /º/?'o':'a';
        my $numReader = new Lingua::ES::Numeros(FORMATO => "", UNMIL => 0, SEXO => $gender);
        $word = _convertNumbersFromSpanishToEnglishForm($word);
        eval {
        $readWord .= " ".$numReader->ordinal($word);
        };
#     } elsif (Text::IdMor::isURL($word)) {
#         my @items = split( /\/+/, $word);
#         $readWord .= " "._readSymbolBySymbolInSpanish(shift @items); # read protocol
#         $readWord .= " ".Symbol::Name::inSpanish(':');
#         $readWord .= " ".Symbol::Name::inSpanish('/');
#         $readWord .= " ".Symbol::Name::inSpanish('/');
#         while (@items) {
#             my $item = shift @items;
#             my @byDot = split(/\./, $item);
#             while (@byDot) {
#                 my $deeperItem = shift;
#                 if ($deeperItem eq "www" ||
#                     $deeperItem eq "html" ||
#                     $deeperItem eq "htm"  ||
#                     $deeperItem eq "sgml" ||
#                     $deeperItem eq "asp"  ||
#                     $deeperItem eq "jsp") { # consider as an achronym)
#                     $readWord .= " "._readSymbolBySymbolInSpanish($deeperItem);
#                 } else {
#                     $readWord .= " "._wordInSpanish($deeperItem);
#                 }
#                 $readWord .= " ".Symbol::Name::inSpanish('.') if (@byDot);
#             }
#             $readWord .= " ".Symbol::Name::inSpanish('/') if (@items);
#         }
#     } elsif (Text::IdMor::isEMail($word)) {
#         
    } elsif ($word =~ /[¡!¡?"]/) {
        $word =~ s/[¡!¡?"]//g;
        $readWord .= _wordInSpanish($word);
    } elsif ($word =~ /^([^$€%\@\+=\(\)]*)(\$|€|%|\@|\+|=|\(|\))(.*)$/) { #(\$|€|%|\@|\+|=|\(|\))
        my $beforeSymbol = $1; my $symbol = $2; my $afterSymbol = $3;
        $readWord .= " "._wordInSpanish($beforeSymbol) if $beforeSymbol;
        $readWord .= " ".Symbol::Name::inSpanish($symbol);
        $readWord .= " "._wordInSpanish($afterSymbol) if $afterSymbol;
    } else {
        my $supportedSymbols = Symbol::Name::supportedSpanishSymbols();
        my $supportedSymbolsEnum = join('', @$supportedSymbols);
        my @symbols = split //, $word;
        my $nOriginalSymbols = @symbols;
        shift @symbols unless (grep /[$supportedSymbolsEnum]/, $symbols[0]);
        pop @symbols if (@symbols && !grep /[$supportedSymbolsEnum]/, $symbols[-1]);
        if (@symbols == $nOriginalSymbols) {
            $readWord = _readSymbolBySymbolInSpanish($word);
        } else {
            $readWord = _wordInSpanish(join('', @symbols));
        }
    }

    $readWord =~ s/^\s+//;
    $readWord =~ s/\s+$//;

    return $readWord;
}

=item _readSymbolBySymbolInSpanish

Read the supplied single word in spanish, symbol by symbol

=cut
sub _readSymbolBySymbolInSpanish($) {
    my $arg = shift;
    my @symbols = split //, $arg;
    my $readWord = "";
    foreach (@symbols) {
        $readWord .= " ".Symbol::Name::inSpanish($_) ;
    }

    $readWord =~ s/  +/ /g;
    return $readWord;
}

sub _convertNumbersFromSpanishToEnglishForm($) {
    my $num = shift;
    $num =~ s/\./a/g;
    $num =~ s/,/./;
    $num =~ s/a/,/g;
    return $num;
}