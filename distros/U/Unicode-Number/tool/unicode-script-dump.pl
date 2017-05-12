#!/usr/bin/env perl

use Unicode::UCD qw(charscript);
use v5.14;
use FindBin ();
use Path::Class;

# <http://www.unicode.org/iso15924/codelists.html>
# <http://www.unicode.org/iso15924/iso15924-codes.html>
# <http://www.unicode.org/Public/UNIDATA/PropertyValueAliases.txt>
open my $prop_alias, '<', file($FindBin::Bin, 'PropertyValueAliases.txt');

my %script_name_to_iso15924;

# this is because charscript() returns the script name as ucfirst(lc())
sub norm_script_name {
	return $_[0] =~ s/_(.)/_\U$1/gr;
}

while(defined( my $sc_line = <$prop_alias> )) {
	chomp $sc_line;
	if( $sc_line =~ /^sc/ ) {
		my @info = split /\s+;\s+/, $sc_line;
		my $iso15924_code = $info[1];
		my $full_name = norm_script_name($info[2]);
		die "duplicate script name!\n" if exists $script_name_to_iso15924{$full_name};
		$script_name_to_iso15924{$full_name} = $iso15924_code;
	}
}
#use DDP; p %script_name_to_iso15924; # DEBUG


while(<DATA>) {
	#if( /_END/ ) {
		my ($name, $num) = (split)[(1,-1)];
		my $codepoint = hex($num);
		my $script_name = norm_script_name(charscript($codepoint));
		my $iso15924_code = $script_name_to_iso15924{$script_name};
		say "$name => '$iso15924_code' # $script_name";
	#}
}

__DATA__
#define AEGEAN_BEGIN 0x10107
#define AEGEAN_END   0x10133
#define ARABIC_BEGIN 0x0660
#define ARABIC_END 0x066C
#define ARABIC_ALPHABETIC_BEGIN 0x0627
#define ARABIC_ALPHABETIC_END 0x064A
#define PERSO_ARABIC_BEGIN 0x06F0
#define PERSO_ARABIC_END 0x06F9
#define ARMENIAN_ALPHABETIC_UPPER_BEGIN 0x0531
#define ARMENIAN_ALPHABETIC_UPPER_END 0x554
#define BALINESE_BEGIN 0x1B50
#define BALINESE_END   0x1B59
#define BENGALI_BEGIN 0x09E6
#define BENGALI_END 0x09EF
#define BURMESE_BEGIN 0x1040
#define BURMESE_END 0x1049
#define CHINESE_COUNTING_ROD_BEGIN	0x1D360
#define CHINESE_COUNTING_ROD_END	0x1D371
#define CHINESE_A_BEGIN 0x4E00
#define CHINESE_A_END 0x9FBB
#define CHINESE_B_BEGIN 0x20000
#define CHINESE_B_END 0x2A6D6
#define CYRILLIC_ALPHABETIC_UPPER_BEGIN 0x0400
#define CYRILLIC_ALPHABETIC_UPPER_END 0x04FF
#define DEVANAGARI_BEGIN 0x0966
#define DEVANAGARI_END 0x096F
#define COMMON_BRAILLE_BEGIN 0x2801
#define COMMON_BRAILLE_END   0x281B
#define ETHIOPIC_BEGIN 0x1369
#define ETHIOPIC_END 0x137C
#define EWELLIC_BEGIN 0xE6C0
#define EWELLIC_DECIMAL_END 0xE6C9
#define EWELLIC_END 0xE6CF
#define GLAGOLITIC_ALPHABETIC_BEGIN 0x2C00
#define GLAGOLITIC_ALPHABETIC_END 0x2C1E
#define GREEK_ALPHABETIC_LOWER_BEGIN 0x03B1
#define GREEK_ALPHABETIC_LOWER_END 0x03C9
#define GREEK_ALPHABETIC_UPPER_BEGIN 0x0391
#define GREEK_ALPHABETIC_UPPER_END 0x03A9
#define GREEK_ALPHABETIC_LOWER_DIGAMMA 0x03DD
#define GREEK_ALPHABETIC_UPPER_DIGAMMA 0x03DC
#define GREEK_ALPHABETIC_LOWER_KOPPA 0x03DF
#define GREEK_ALPHABETIC_UPPER_KOPPA 0x03DE
#define GREEK_ALPHABETIC_LOWER_SAN 0x03FB
#define GREEK_ALPHABETIC_UPPER_SAN 0x03FA
#define GREEK_ALPHABETIC_LOWER_STIGMA 0x03DB
#define GREEK_ALPHABETIC_UPPER_STIGMA 0x03DA
#define GREEK_ALPHABETIC_RIGHT_KERAIA 0x0374
#define GREEK_ALPHABETIC_LEFT_KERAIA 0x0375
#define GUJARATI_BEGIN 0x0AE6
#define GUJARATI_END 0x0AEF
#define GURMUKHI_BEGIN 0x0A66
#define GURMUKHI_END 0x0A6F
#define HEBREW_BEGIN 0x0590
#define HEBREW_END   0x05FF
#define KAYAH_LI_BEGIN 0xA900
#define KAYAH_LI_END   0xA909
#define KANNADA_BEGIN 0x0CE6
#define KANNADA_END 0x0CEF
#define KHAROSHTHI_BEGIN 0x10A40
#define KHAROSHTHI_END 0x10A47
#define KHMER_BEGIN 0x17E0
#define KHMER_END   0x17E9
#define KLINGON_BEGIN 0xF8F0
#define KLINGON_END 0xF8F9
#define LAO_BEGIN 0x0ED0
#define LAO_END 0x0ED9
#define LEPCHA_BEGIN 0x1C40
#define LEPCHA_END 0x1C49
#define LIMBU_BEGIN 0x1946
#define LIMBU_END 0x194F
#define MALAYALAM_BEGIN 0x0D00
#define MALAYALAM_END   0x0D7F
#define MONGOLIAN_BEGIN 0x1810
#define MONGOLIAN_END   0x1819
#define MXEDRULI_BEGIN	0x10D0
#define MXEDRULI_END	0x10F5
#define NEW_TAI_LUE_BEGIN 0x19D0
#define NEW_TAI_LUE_END   0x19D9
#define NKO_BEGIN 0x07C0
#define NKO_END 0x07C9
#define OL_CHIKI_BEGIN 0x1C50
#define OL_CHIKI_END 0x1C59
#define OLD_ITALIC_BEGIN 0x10320
#define OLD_ITALIC_END   0x10323
#define OLD_PERSIAN_BEGIN 0x103D1
#define OLD_PERSIAN_END 0x103D5
#define ORIYA_BEGIN 0x0B66
#define ORIYA_END 0x0B6F
#define OSMANYA_BEGIN 0x104A0
#define OSMANYA_END 0x104A9
#define PHOENICIAN_BEGIN 0x10916
#define PHOENICIAN_END 0x10919
#define SAURASHTRA_BEGIN 0xA8D0
#define SAURASHTRA_END 0xA8D9
#define SHAN_BEGIN 0x1090
#define SHAN_END 0x1099
#define SINHALA_BEGIN 0x0DE7
#define SINHALA_END   0x0DFA
#define SUNDANESE_BEGIN 0x1BB0
#define SUNDANESE_END 0x1BB9
#define SUZHOU_BEGIN 0x3021
#define SUZHOU_END 0x3029
#define TAMIL_BEGIN 0x0BE6
#define TAMIL_END 0x0BF2
#define TELUGU_BEGIN 0x0C66
#define TELUGU_END 0x0C6F
#define TENGWAR_BEGIN 0xE030
#define TENGWAR_END 0xE06E
#define THAI_BEGIN 0x0E50
#define THAI_END 0x0E59
#define TIBETAN_BEGIN 0x0F20
#define TIBETAN_END 0x0F29
#define VAI_BEGIN 0xA620
#define VAI_END 0xA629
#define VERDURIAN_BEGIN 0xE260
#define VERDURIAN_END 0xE26B
#define XUCURI_LOWER_BEGIN 0x2D00
#define XUCURI_LOWER_END   0x2D25
#define XUCURI_UPPER_BEGIN 0x10A0
#define XUCURI_UPPER_END   0x10C5
