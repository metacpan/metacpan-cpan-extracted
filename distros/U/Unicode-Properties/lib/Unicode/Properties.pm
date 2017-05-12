package Unicode::Properties;

use warnings;
use strict;
use Unicode::UCD;

require 5.008008;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK= qw/uniprops matchchars/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.07';

my %propnames = qw/
Armenian 4.1.0
Balinese 5.0.0
Bengali 4.1.0
Bopomofo 4.1.0
Braille 4.1.0
Buginese 4.1.0
Buhid 4.1.0
CanadianAboriginal 4.1.0
Cherokee 4.1.0
Coptic 4.1.0
Cuneiform 5.0.0
Cypriot 4.1.0
Cyrillic 4.1.0
Deseret 4.1.0
Devanagari 4.1.0
Ethiopic 4.1.0
Georgian 4.1.0
Glagolitic 4.1.0
Gothic 4.1.0
Greek 4.1.0
Gujarati 4.1.0
Gurmukhi 4.1.0
Han 4.1.0
Hangul 4.1.0
Hanunoo 4.1.0
Hebrew 4.1.0
Hiragana 4.1.0
Inherited 4.1.0
Kannada 4.1.0
Katakana 4.1.0
Kharoshthi 4.1.0
Khmer 4.1.0
Lao 4.1.0
Latin 4.1.0
Limbu 4.1.0
LinearB 4.1.0
Malayalam 4.1.0
Mongolian 4.1.0
Myanmar 4.1.0
NewTaiLue 4.1.0
Nko 5.0.0
Ogham 4.1.0
OldItalic 4.1.0
OldPersian 4.1.0
Oriya 4.1.0
Osmanya 4.1.0
PhagsPa 5.0.0
Phoenician 5.0.0
Runic 4.1.0
Shavian 4.1.0
Sinhala 4.1.0
SylotiNagri 4.1.0
Syriac 4.1.0
Tagalog 4.1.0
Tagbanwa 4.1.0
TaiLe 4.1.0
Tamil 4.1.0
Telugu 4.1.0
Thaana 4.1.0
Thai 4.1.0
Tibetan 4.1.0
Tifinagh 4.1.0
Ugaritic 4.1.0
Yi 4.1.0
InAegeanNumbers 4.1.0
InAlphabeticPresentationForms 4.1.0
InAncientGreekMusicalNotation 4.1.0
InAncientGreekNumbers 4.1.0
InArabic 4.1.0
InArabicPresentationFormsA 4.1.0
InArabicPresentationFormsB 4.1.0
InArabicSupplement 4.1.0
InArmenian 4.1.0
InArrows 4.1.0
InBalinese 5.0.0
InBasicLatin 4.1.0
InBengali 4.1.0
InBlockElements 4.1.0
InBopomofo 4.1.0
InBopomofoExtended 4.1.0
InBoxDrawing 4.1.0
InBraillePatterns 4.1.0
InBuginese 4.1.0
InBuhid 4.1.0
InByzantineMusicalSymbols 4.1.0
InCJKCompatibility 4.1.0
InCJKCompatibilityForms 4.1.0
InCJKCompatibilityIdeographs 4.1.0
InCJKCompatibilityIdeographsSupplement 4.1.0
InCJKRadicalsSupplement 4.1.0
InCJKStrokes 4.1.0
InCJKSymbolsAndPunctuation 4.1.0
InCJKUnifiedIdeographs 4.1.0
InCJKUnifiedIdeographsExtensionA 4.1.0
InCJKUnifiedIdeographsExtensionB 4.1.0
InCherokee 4.1.0
InCombiningDiacriticalMarks 4.1.0
InCombiningDiacriticalMarksSupplement 4.1.0
InCombiningDiacriticalMarksforSymbols 4.1.0
InCombiningHalfMarks 4.1.0
InControlPictures 4.1.0
InCoptic 4.1.0
InCountingRodNumerals 5.0.0
InCuneiform 5.0.0
InCuneiformNumbersAndPunctuation 5.0.0
InCurrencySymbols 4.1.0
InCypriotSyllabary 4.1.0
InCyrillic 4.1.0
InCyrillicSupplement 4.1.0
InDeseret 4.1.0
InDevanagari 4.1.0
InDingbats 4.1.0
InEnclosedAlphanumerics 4.1.0
InEnclosedCJKLettersAndMonths 4.1.0
InEthiopic 4.1.0
InEthiopicExtended 4.1.0
InEthiopicSupplement 4.1.0
InGeneralPunctuation 4.1.0
InGeometricShapes 4.1.0
InGeorgian 4.1.0
InGeorgianSupplement 4.1.0
InGlagolitic 4.1.0
InGothic 4.1.0
InGreekExtended 4.1.0
InGreekAndCoptic 4.1.0
InGujarati 4.1.0
InGurmukhi 4.1.0
InHalfwidthAndFullwidthForms 4.1.0
InHangulCompatibilityJamo 4.1.0
InHangulJamo 4.1.0
InHangulSyllables 4.1.0
InHanunoo 4.1.0
InHebrew 4.1.0
InHighPrivateUseSurrogates 4.1.0
InHighSurrogates 4.1.0
InHiragana 4.1.0
InIPAExtensions 4.1.0
InIdeographicDescriptionCharacters 4.1.0
InKanbun 4.1.0
InKangxiRadicals 4.1.0
InKannada 4.1.0
InKatakana 4.1.0
InKatakanaPhoneticExtensions 4.1.0
InKharoshthi 4.1.0
InKhmer 4.1.0
InKhmerSymbols 4.1.0
InLao 4.1.0
InLatin1Supplement 4.1.0
InLatinExtendedA 4.1.0
InLatinExtendedAdditional 4.1.0
InLatinExtendedB 4.1.0
InLatinExtendedC 5.0.0
InLatinExtendedD 5.0.0
InLetterlikeSymbols 4.1.0
InLimbu 4.1.0
InLinearBIdeograms 4.1.0
InLinearBSyllabary 4.1.0
InLowSurrogates 4.1.0
InMalayalam 4.1.0
InMathematicalAlphanumericSymbols 4.1.0
InMathematicalOperators 4.1.0
InMiscellaneousMathematicalSymbolsA 4.1.0
InMiscellaneousMathematicalSymbolsB 4.1.0
InMiscellaneousSymbols 4.1.0
InMiscellaneousSymbolsAndArrows 4.1.0
InMiscellaneousTechnical 4.1.0
InModifierToneLetters 4.1.0
InMongolian 4.1.0
InMusicalSymbols 4.1.0
InMyanmar 4.1.0
InNKo 5.0.0
InNewTaiLue 4.1.0
InNumberForms 4.1.0
InOgham 4.1.0
InOldItalic 4.1.0
InOldPersian 4.1.0
InOpticalCharacterRecognition 4.1.0
InOriya 4.1.0
InOsmanya 4.1.0
InPhagspa 5.0.0
InPhoenician 5.0.0
InPhoneticExtensions 4.1.0
InPhoneticExtensionsSupplement 4.1.0
InPrivateUseArea 4.1.0
InRunic 4.1.0
InShavian 4.1.0
InSinhala 4.1.0
InSmallFormVariants 4.1.0
InSpacingModifierLetters 4.1.0
InSpecials 4.1.0
InSuperscriptsAndSubscripts 4.1.0
InSupplementalArrowsA 4.1.0
InSupplementalArrowsB 4.1.0
InSupplementalMathematicalOperators 4.1.0
InSupplementalPunctuation 4.1.0
InSupplementaryPrivateUseAreaA 4.1.0
InSupplementaryPrivateUseAreaB 4.1.0
InSylotiNagri 4.1.0
InSyriac 4.1.0
InTagalog 4.1.0
InTagbanwa 4.1.0
InTags 4.1.0
InTaiLe 4.1.0
InTaiXuanJingSymbols 4.1.0
InTamil 4.1.0
InTelugu 4.1.0
InThaana 4.1.0
InThai 4.1.0
InTibetan 4.1.0
InTifinagh 4.1.0
InUgaritic 4.1.0
InUnifiedCanadianAboriginalSyllabics 4.1.0
InVariationSelectors 4.1.0
InVariationSelectorsSupplement 4.1.0
InVerticalForms 4.1.0
InYiRadicals 4.1.0
InYiSyllables 4.1.0
InYijingHexagramSymbols 4.1.0
Alphabetic 4.1.0
Lowercase 4.1.0
Uppercase 4.1.0
Math 4.1.0
IDStart 4.1.0
IDContinue 4.1.0
DefaultIgnorableCodePoint 5.0.0
Any 4.1.0
Assigned 4.1.0
Unassigned 4.1.0
ASCII 4.1.0
Common 4.1.0
/;

# Compare 4.1.0 with 5.0.0

our $unicode_version = Unicode::UCD::UnicodeVersion();
my @uv = split /\./, $unicode_version;

sub versionok
{
    my ($version) = @_;
#    print "$version, $unicode_version\n";
    my @v = split /\./, $version;
#    print "\@v = @v\n";
    for (0..2) {
	return undef if $v[$_] > $uv[$_];
	return 1 if $v[$_] < $uv[$_];
    }
    return 1; # equal
}

sub uniprops
{
    my ($inchar) = @_;
    return if !$inchar;
    if (length ($inchar) != 1) {
	$inchar = substr ($inchar, 0, 1);
    }
    my @matched;
    for my $block (sort keys %propnames) {
#	print "Version $propnames{$block} is ",  
#	    versionok ($propnames{$block}) ? "OK" : "Not OK", "\n";
	next unless versionok $propnames{$block};
	if ($inchar =~ /^\p{$block}$/) {
	    push @matched, $block;
	}
    }
    return wantarray ? @matched : \@matched;
}

sub matchchars
{
    my ($re) = @_;
    if ($propnames{$re}) {
	$re = "\\p{$re}";
    }
    my @matches = grep { chr ($_) =~ /$re/ } 
	(0x00 .. 0xD7FF, 0xE000 .. 0xFDCF, 0xFDF0.. 0xFFFD);
    return wantarray ? @matches : \@matches;
}

1;

