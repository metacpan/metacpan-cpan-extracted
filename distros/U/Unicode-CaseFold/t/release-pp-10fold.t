#!perl

use Test::More;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        plan skip_all => 'these tests are for testing by the release';
    }

    $ENV{PERL_UNICODE_CASEFOLD_PP} = 1;
}

use strict;
use warnings;
use utf8;

use Test::More tests => 1 + 9 + 62 + 4 + 5 + 18;
use Unicode::CaseFold;

# This one comes from the ICU project's test suite, more especifically
# http://icu.sourcearchive.com/documentation/4.4~rc1-1/strcase_8cpp-source.html

my $s = "A\N{U+00df}\N{U+00b5}\N{U+fb03}\N{U+1040C}\N{U+0130}\N{U+0131}";
#\N{LATIN CAPITAL LETTER A}\N{LATIN SMALL LETTER SHARP S}\N{MICRO SIGN}\N{LATIN SMALL LIGATURE FFI}\N{DESERET CAPITAL LETTER AY}\N{LATIN CAPITAL LETTER I WITH DOT ABOVE}\N{LATIN SMALL LETTER DOTLESS I}

my $f = "ass\N{U+03bc}ffi\N{U+10434}i\N{U+0307}\N{U+0131}";
#\N{LATIN SMALL LETTER A}\N{LATIN SMALL LETTER S}\N{LATIN SMALL LETTER S}\N{GREEK SMALL LETTER MU}\N{LATIN SMALL LETTER F}\N{LATIN SMALL LETTER F}\N{LATIN SMALL LETTER I}\N{DESERET SMALL LETTER AY}\N{LATIN SMALL LETTER I}\N{COMBINING DOT ABOVE}\N{LATIN SMALL LETTER DOTLESS I}

is(fc($s), $f, "ICU's casefold test passes");

# The next batch come from http://www.devdaily.com/java/jwarehouse/lucene/contrib/icu/src/test/org/apache/lucene/analysis/icu/TestICUFoldingFilter.java.shtml
# Except the article got most casings wrong. Or maybe Lucene does.

is( fc("This is a test"), "this is a test" );
is( fc("Ruß"), "russ"    );
is( fc("ΜΆΪΟΣ"), "μάϊοσ" );
is( fc("Μάϊος"), "μάϊοσ" );
is( fc("𐐖"), "𐐾"       );
is( fc("r\xe9sum\xe9"), "r\xe9sum\xe9" );
is( fc("re\x{0301}sume\x{0301}"), "re\x{301}sume\x{301}" );
is( fc("ELİF"), "eli\x{307}f" );
is( fc("eli\x{307}f"), "eli\x{307}f");


# Table stolen from tchrist's mail in
# http://bugs.python.org/file23051/casing-tests.py
# and http://98.245.80.27/tcpc/OSCON2011/case-test.python3
# For reference, it's a longer version of what he posted here:
# http://stackoverflow.com/questions/6991038/case-insensitive-storage-and-unicode-compatibility

#Couple of repeats because I'm lazy, not tchrist's fault.

sub table_test {
  for (@_) {
    my ($simple_lc, $simple_tc, $simple_uc, $simple_fc) = @{$_}[1, 2, 3, 7];
    my ($orig, $lower, $titlecase, $upper, $fc_turkic, $fc_full) = @{$_}[0,4,5,6,8,9];

    if ($Unicode::CaseFold::SIMPLE_FOLDING) {
      is( fc($orig), $simple_fc, "fc() with simple casefolding works" );
    } else {
      is( fc($orig), $fc_full, 'fc works' );
    }
  }
}

my @test_table = (
# ORIG LC_SIMPLE TC_SIMPLE UC_SIMPLE LC_FULL TC_FULL UC_FULL FC_SIMPLE FC_TURKIC FC_FULL
  [ 'þǽr rihtes', 'þǽr rihtes', 'Þǽr Rihtes', 'ÞǼR RIHTES', 'þǽr rihtes', 'Þǽr Rihtes', 'ÞǼR RIHTES', 'þǽr rihtes', 'þǽr rihtes', 'þǽr rihtes',  ],
  [ 'duȝeðlice', 'duȝeðlice', 'Duȝeðlice', 'DUȜEÐLICE', 'duȝeðlice', 'Duȝeðlice', 'DUȜEÐLICE', 'duȝeðlice', 'duȝeðlice', 'duȝeðlice',  ],
  [ 'Ævar Arnfjörð Bjarmason', 'ævar arnfjörð bjarmason', 'Ævar Arnfjörð Bjarmason', 'ÆVAR ARNFJÖRÐ BJARMASON', 'ævar arnfjörð bjarmason', 'Ævar Arnfjörð Bjarmason', 'ÆVAR ARNFJÖRÐ BJARMASON', 'ævar arnfjörð bjarmason', 'ævar arnfjörð bjarmason', 'ævar arnfjörð bjarmason',  ],
  [ 'Кириллица', 'кириллица', 'Кириллица', 'КИРИЛЛИЦА', 'кириллица', 'Кириллица', 'КИРИЛЛИЦА', 'кириллица', 'кириллица', 'кириллица',  ],
  [ 'ĳ', 'ĳ', 'Ĳ', 'Ĳ', 'ĳ', 'Ĳ', 'Ĳ', 'ĳ', 'ĳ', 'ĳ',  ],
  [ 'Van Dĳke', 'van dĳke', 'Van Dĳke', 'VAN DĲKE', 'van dĳke', 'Van Dĳke', 'VAN DĲKE', 'van dĳke', 'van dĳke', 'van dĳke',  ],
  [ 'VAN DĲKE', 'van dĳke', 'Van Dĳke', 'VAN DĲKE', 'van dĳke', 'Van Dĳke', 'VAN DĲKE', 'van dĳke', 'van dĳke', 'van dĳke',  ],
  [ 'ǳur', 'ǳur', 'ǲur', 'ǱUR', 'ǳur', 'ǲur', 'ǱUR', 'ǳur', 'ǳur', 'ǳur',  ],
  [ 'ǲur', 'ǳur', 'ǲur', 'ǱUR', 'ǳur', 'ǲur', 'ǱUR', 'ǳur', 'ǳur', 'ǳur',  ],
  [ 'ǱUR', 'ǳur', 'ǲur', 'ǱUR', 'ǳur', 'ǲur', 'ǱUR', 'ǳur', 'ǳur', 'ǳur',  ],
  [ 'ǳur mountain', 'ǳur mountain', 'ǲur Mountain', 'ǱUR MOUNTAIN', 'ǳur mountain', 'ǲur Mountain', 'ǱUR MOUNTAIN', 'ǳur mountain', 'ǳur mountain', 'ǳur mountain',  ],
  [ 'ǲur Mountain', 'ǳur mountain', 'ǲur Mountain', 'ǱUR MOUNTAIN', 'ǳur mountain', 'ǲur Mountain', 'ǱUR MOUNTAIN', 'ǳur mountain', 'ǳur mountain', 'ǳur mountain',  ],
  [ 'ǱUR MOUNTAIN', 'ǳur mountain', 'ǲur Mountain', 'ǱUR MOUNTAIN', 'ǳur mountain', 'ǲur Mountain', 'ǱUR MOUNTAIN', 'ǳur mountain', 'ǳur mountaın', 'ǳur mountain',  ],
  [ 'poſt', 'poſt', 'Poſt', 'POST', 'poſt', 'Poſt', 'POST', 'post', 'post', 'post',  ],
  [ 'ᾲ', 'ᾲ', 'Ὰͅ', 'ᾺΙ', 'ᾲ', 'Ὰͅ', 'ᾺΙ', 'ὰι', 'ὰι', 'ὰι',  ],
  [ 'Ὰι', 'ὰι', 'Ὰι', 'ᾺΙ', 'ὰι', 'Ὰι', 'ᾺΙ', 'ὰι', 'ὰι', 'ὰι',  ],
  [ 'ᾺΙ', 'ὰι', 'Ὰι', 'ᾺΙ', 'ὰι', 'Ὰι', 'ᾺΙ', 'ὰι', 'ὰι', 'ὰι',  ],
  [ 'Ὰͅ', 'ᾲ', 'Ὰͅ', 'ᾺΙ', 'ᾲ', 'Ὰͅ', 'ᾺΙ', 'ὰι', 'ὰι', 'ὰι',  ],
  [ 'ᾺΙ', 'ὰι', 'Ὰι', 'ᾺΙ', 'ὰι', 'Ὰι', 'ᾺΙ', 'ὰι', 'ὰι', 'ὰι',  ],
  [ 'ᾲ στο διάολο', 'ᾲ στο διάολο', 'Ὰͅ Στο Διάολο', 'ᾺΙ ΣΤΟ ΔΙΆΟΛΟ', 'ᾲ στο διάολο', 'Ὰͅ Στο Διάολο', 'ᾺΙ ΣΤΟ ΔΙΆΟΛΟ', 'ὰι στο διάολο', 'ὰι στο διάολο', 'ὰι στο διάολο',  ],
  [ '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐇𐐝𐐀𐐡𐐇𐐓', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐇𐐝𐐀𐐡𐐇𐐓', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻',  ],
  [ '𐐔𐐯𐑅𐐨𐑉𐐯𐐻', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐇𐐝𐐀𐐡𐐇𐐓', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐇𐐝𐐀𐐡𐐇𐐓', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻',  ],
  [ '𐐔𐐇𐐝𐐀𐐡𐐇𐐓', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐇𐐝𐐀𐐡𐐇𐐓', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐯𐑅𐐨𐑉𐐯𐐻', '𐐔𐐇𐐝𐐀𐐡𐐇𐐓', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻', '𐐼𐐯𐑅𐐨𐑉𐐯𐐻',  ],
  [ 'henry ⅷ', 'henry ⅷ', 'Henry Ⅷ', 'HENRY Ⅷ', 'henry ⅷ', 'Henry Ⅷ', 'HENRY Ⅷ', 'henry ⅷ', 'henry ⅷ', 'henry ⅷ',  ],
  [ 'Henry Ⅷ', 'henry ⅷ', 'Henry Ⅷ', 'HENRY Ⅷ', 'henry ⅷ', 'Henry Ⅷ', 'HENRY Ⅷ', 'henry ⅷ', 'henry ⅷ', 'henry ⅷ',  ],
  [ 'HENRY Ⅷ', 'henry ⅷ', 'Henry Ⅷ', 'HENRY Ⅷ', 'henry ⅷ', 'Henry Ⅷ', 'HENRY Ⅷ', 'henry ⅷ', 'henry ⅷ', 'henry ⅷ',  ],
  [ 'i work at ⓚ', 'i work at ⓚ', 'I Work At Ⓚ', 'I WORK AT Ⓚ', 'i work at ⓚ', 'I Work At Ⓚ', 'I WORK AT Ⓚ', 'i work at ⓚ', 'i work at ⓚ', 'i work at ⓚ',  ],
  [ 'I Work At Ⓚ', 'i work at ⓚ', 'I Work At Ⓚ', 'I WORK AT Ⓚ', 'i work at ⓚ', 'I Work At Ⓚ', 'I WORK AT Ⓚ', 'i work at ⓚ', 'ı work at ⓚ', 'i work at ⓚ',  ],
  [ 'I WORK AT Ⓚ', 'i work at ⓚ', 'I Work At Ⓚ', 'I WORK AT Ⓚ', 'i work at ⓚ', 'I Work At Ⓚ', 'I WORK AT Ⓚ', 'i work at ⓚ', 'ı work at ⓚ', 'i work at ⓚ',  ],
  [ 'istambul', 'istambul', 'Istambul', 'ISTAMBUL', 'istambul', 'Istambul', 'ISTAMBUL', 'istambul', 'istambul', 'istambul',  ],
  [ 'i̇stanbul', 'i̇stanbul', 'İstanbul', 'İSTANBUL', 'i̇stanbul', 'İstanbul', 'İSTANBUL', 'i̇stanbul', 'i̇stanbul', 'i̇stanbul',  ],
  [ 'İstanbul', 'i̇stanbul', 'İstanbul', 'İSTANBUL', 'i̇stanbul', 'İstanbul', 'İSTANBUL', 'i̇stanbul', 'ı̇stanbul', 'i̇stanbul',  ],
  [ 'στιγμας', 'στιγμας', 'Στιγμας', 'ΣΤΙΓΜΑΣ', 'στιγμας', 'Στιγμας', 'ΣΤΙΓΜΑΣ', 'στιγμασ', 'στιγμασ', 'στιγμασ',  ],
  [ 'στιγμασ', 'στιγμασ', 'Στιγμασ', 'ΣΤΙΓΜΑΣ', 'στιγμασ', 'Στιγμασ', 'ΣΤΙΓΜΑΣ', 'στιγμασ', 'στιγμασ', 'στιγμασ',  ],
  [ 'ΣΤΙΓΜΑΣ', 'στιγμασ', 'Στιγμασ', 'ΣΤΙΓΜΑΣ', 'στιγμασ', 'Στιγμασ', 'ΣΤΙΓΜΑΣ', 'στιγμασ', 'στιγμασ', 'στιγμασ',  ],
  [ 'ʀᴀʀᴇ', 'ʀᴀʀᴇ', 'Ʀᴀʀᴇ', 'ƦᴀƦᴇ', 'ʀᴀʀᴇ', 'Ʀᴀʀᴇ', 'ƦᴀƦᴇ', 'ʀᴀʀᴇ', 'ʀᴀʀᴇ', 'ʀᴀʀᴇ',  ],
  [ 'Ʀᴀʀᴇ', 'ʀᴀʀᴇ', 'Ʀᴀʀᴇ', 'ƦᴀƦᴇ', 'ʀᴀʀᴇ', 'Ʀᴀʀᴇ', 'ƦᴀƦᴇ', 'ʀᴀʀᴇ', 'ʀᴀʀᴇ', 'ʀᴀʀᴇ',  ],
  [ 'ƦᴀƦᴇ', 'ʀᴀʀᴇ', 'Ʀᴀʀᴇ', 'ƦᴀƦᴇ', 'ʀᴀʀᴇ', 'Ʀᴀʀᴇ', 'ƦᴀƦᴇ', 'ʀᴀʀᴇ', 'ʀᴀʀᴇ', 'ʀᴀʀᴇ',  ],
  [ "þǽr rihtes", "þǽr rihtes", "Þǽr Rihtes", "ÞǼR RIHTES", "þǽr rihtes", "Þǽr Rihtes", "ÞǼR RIHTES", "þǽr rihtes", "þǽr rihtes", "þǽr rihtes",  ],
  [ "duȝeðlice", "duȝeðlice", "Duȝeðlice", "DUȜEÐLICE", "duȝeðlice", "Duȝeðlice", "DUȜEÐLICE", "duȝeðlice", "duȝeðlice", "duȝeðlice",  ],
  [ "Van Dĳke", "van dĳke", "Van Dĳke", "VAN DĲKE", "van dĳke", "Van Dĳke", "VAN DĲKE", "van dĳke", "van dĳke", "van dĳke",  ],
  [ "ǳ", "ǳ", "ǲ", "Ǳ", "ǳ", "ǲ", "Ǳ", "ǳ", "ǳ", "ǳ",  ],
  [ "ǳur mountain", "ǳur mountain", "ǲur Mountain", "ǱUR MOUNTAIN", "ǳur mountain", "ǲur Mountain", "ǱUR MOUNTAIN", "ǳur mountain", "ǳur mountain", "ǳur mountain",  ],
  [ "ͅ", "ͅ", "Ι", "Ι", "ͅ", "Ι", "Ι", "ι", "ι", "ι",  ],
  [ "ᾲ", "ᾲ", "Ὰͅ", "ᾺΙ", "ᾲ", "Ὰͅ", "ᾺΙ", "ὰι", "ὰι", "ὰι",  ],
  [ "Ὰι", "ὰι", "Ὰι", "ᾺΙ", "ὰι", "Ὰι", "ᾺΙ", "ὰι", "ὰι", "ὰι",  ],
  [ "ᾺΙ", "ὰι", "Ὰι", "ᾺΙ", "ὰι", "Ὰι", "ᾺΙ", "ὰι", "ὰι", "ὰι",  ],
  [ "Ὰͅ", "ᾲ", "Ὰͅ", "ᾺΙ", "ᾲ", "Ὰͅ", "ᾺΙ", "ὰι", "ὰι", "ὰι",  ],
  [ "ᾺΙ", "ὰι", "Ὰι", "ᾺΙ", "ὰι", "Ὰι", "ᾺΙ", "ὰι", "ὰι", "ὰι",  ],
  [ "ᾲ στο διάολο", "ᾲ στο διάολο", "Ὰͅ Στο Διάολο", "ᾺΙ ΣΤΟ ΔΙΆΟΛΟ", "ᾲ στο διάολο", "Ὰͅ Στο Διάολο", "ᾺΙ ΣΤΟ ΔΙΆΟΛΟ", "ὰι στο διάολο", "ὰι στο διάολο", "ὰι στο διάολο",  ],
  [ "ⅷ", "ⅷ", "Ⅷ", "Ⅷ", "ⅷ", "Ⅷ", "Ⅷ", "ⅷ", "ⅷ", "ⅷ",  ],
  [ "henry ⅷ", "henry ⅷ", "Henry Ⅷ", "HENRY Ⅷ", "henry ⅷ", "Henry Ⅷ", "HENRY Ⅷ", "henry ⅷ", "henry ⅷ", "henry ⅷ",  ],
  [ "ⓚ", "ⓚ", "Ⓚ", "Ⓚ", "ⓚ", "Ⓚ", "Ⓚ", "ⓚ", "ⓚ", "ⓚ",  ],
  [ "i work at ⓚ", "i work at ⓚ", "I Work At Ⓚ", "I WORK AT Ⓚ", "i work at ⓚ", "I Work At Ⓚ", "I WORK AT Ⓚ", "i work at ⓚ", "i work at ⓚ", "i work at ⓚ",  ],
  [ "istambul", "istambul", "Istambul", "ISTAMBUL", "istambul", "Istambul", "ISTAMBUL", "istambul", "istambul", "istambul",  ],
  [ "i̇stanbul", "i̇stanbul", "İstanbul", "İSTANBUL", "i̇stanbul", "İstanbul", "İSTANBUL", "i̇stanbul", "i̇stanbul", "i̇stanbul",  ],
  [ "İstanbul", "i̇stanbul", "İstanbul", "İSTANBUL", "i̇stanbul", "İstanbul", "İSTANBUL", "i̇stanbul", "ı̇stanbul", "i̇stanbul",  ],
  [ "στιγμας", "στιγμας", "Στιγμας", "ΣΤΙΓΜΑΣ", "στιγμας", "Στιγμας", "ΣΤΙΓΜΑΣ", "στιγμασ", "στιγμασ", "στιγμασ",  ],
  [ "στιγμασ", "στιγμασ", "Στιγμασ", "ΣΤΙΓΜΑΣ", "στιγμασ", "Στιγμασ", "ΣΤΙΓΜΑΣ", "στιγμασ", "στιγμασ", "στιγμασ",  ],
  [ "ΣΤΙΓΜΑΣ", "στιγμασ", "Στιγμασ", "ΣΤΙΓΜΑΣ", "στιγμασ", "Στιγμασ", "ΣΤΙΓΜΑΣ", "στιγμασ", "στιγμασ", "στιγμασ",  ],
  [ "ʀᴀʀᴇ", "ʀᴀʀᴇ", "Ʀᴀʀᴇ", "ƦᴀƦᴇ", "ʀᴀʀᴇ", "Ʀᴀʀᴇ", "ƦᴀƦᴇ", "ʀᴀʀᴇ", "ʀᴀʀᴇ", "ʀᴀʀᴇ",  ],
  [ "𐐼𐐯𐑅𐐨𐑉𐐯𐐻", "𐐼𐐯𐑅𐐨𐑉𐐯𐐻", "𐐔𐐯𐑅𐐨𐑉𐐯𐐻", "𐐔𐐇𐐝𐐀𐐡𐐇𐐓", "𐐼𐐯𐑅𐐨𐑉𐐯𐐻", "𐐔𐐯𐑅𐐨𐑉𐐯𐐻", "𐐔𐐇𐐝𐐀𐐡𐐇𐐓", "𐐼𐐯𐑅𐐨𐑉𐐯𐐻", "𐐼𐐯𐑅𐐨𐑉𐐯𐐻", "𐐼𐐯𐑅𐐨𐑉𐐯𐐻",  ],
);

table_test(@test_table);

SKIP: {
  skip "Unicode version <5.1", 4 unless $^V ge v5.10.1;
  
  my @test_table = (
    [ 'TSCHÜẞ', 'tschüß', 'Tschüß', 'TSCHÜẞ', 'tschüß', 'Tschüß', 'TSCHÜẞ', 'tschüß', 'tschüss', 'tschüss',  ],
    [ 'WEIẞ', 'weiß', 'Weiß', 'WEIẞ', 'weiß', 'Weiß', 'WEIẞ', 'weiß', 'weıss', 'weiss',  ],
    [ 'ẞIEW', 'ßiew', 'ẞiew', 'ẞIEW', 'ßiew', 'ẞiew', 'ẞIEW', 'ßiew', 'ssıew', 'ssiew',  ],
    [ "RUẞLAND", "rußland", "Rußland", "RUẞLAND", "rußland", "Rußland", "RUẞLAND", "rußland", "russland", "russland",  ],
  );

  table_test(@test_table);
}

SKIP: {
  skip "Unicode version <6.0", 5 unless $^V ge v5.14.0;
  my @test_table = (
    [ 'Ԧԧ', 'ԧԧ', 'Ԧԧ', 'ԦԦ', 'ԧԧ', 'Ԧԧ', 'ԦԦ', 'ԧԧ', 'ԧԧ', 'ԧԧ',  ],
    [ 'ԧԧ', 'ԧԧ', 'Ԧԧ', 'ԦԦ', 'ԧԧ', 'Ԧԧ', 'ԦԦ', 'ԧԧ', 'ԧԧ', 'ԧԧ',  ],
    [ 'Ԧԧ', 'ԧԧ', 'Ԧԧ', 'ԦԦ', 'ԧԧ', 'Ԧԧ', 'ԦԦ', 'ԧԧ', 'ԧԧ', 'ԧԧ',  ],
    [ 'ԦԦ', 'ԧԧ', 'Ԧԧ', 'ԦԦ', 'ԧԧ', 'Ԧԧ', 'ԦԦ', 'ԧԧ', 'ԧԧ', 'ԧԧ',  ],
    [ "Ԧԧ", "ԧԧ", "Ԧԧ", "ԦԦ", "ԧԧ", "Ԧԧ", "ԦԦ", "ԧԧ", "ԧԧ", "ԧԧ",  ],
  );

  table_test(@test_table);
}

SKIP: {
  skip "Full folding not available", 18 if $Unicode::CaseFold::SIMPLE_FOLDING;

  my @test_table = (
    [ 'eﬃcient', 'eﬃcient', 'Eﬃcient', 'EﬃCIENT', 'eﬃcient', 'Eﬃcient', 'EFFICIENT', 'eﬃcient', 'efficient', 'efficient',  ],
    [ 'ﬂour', 'ﬂour', 'ﬂour', 'ﬂOUR', 'ﬂour', 'Flour', 'FLOUR', 'ﬂour', 'flour', 'flour',  ],
    [ 'ﬂour and water', 'ﬂour and water', 'ﬂour And Water', 'ﬂOUR AND WATER', 'ﬂour and water', 'Flour And Water', 'FLOUR AND WATER', 'ﬂour and water', 'flour and water', 'flour and water',  ],
    [ 'poﬅ', 'poﬅ', 'Poﬅ', 'POﬅ', 'poﬅ', 'Poﬅ', 'POST', 'poﬅ', 'post', 'post',  ],
    [ 'ﬅop', 'ﬅop', 'ﬅop', 'ﬅOP', 'ﬅop', 'Stop', 'STOP', 'ﬅop', 'stop', 'stop',  ],
    [ 'tschüß', 'tschüß', 'Tschüß', 'TSCHÜß', 'tschüß', 'Tschüß', 'TSCHÜSS', 'tschüß', 'tschüss', 'tschüss',  ],
    [ 'weiß', 'weiß', 'Weiß', 'WEIß', 'weiß', 'Weiß', 'WEISS', 'weiß', 'weiss', 'weiss',  ],
    [ 'ᾲ', 'ᾲ', 'ᾲ', 'ᾲ', 'ᾲ', 'Ὰͅ', 'ᾺΙ', 'ᾲ', 'ὰι', 'ὰι',  ],
    [ 'ᾲ στο διάολο', 'ᾲ στο διάολο', 'ᾲ Στο Διάολο', 'ᾲ ΣΤΟ ΔΙΆΟΛΟ', 'ᾲ στο διάολο', 'Ὰͅ Στο Διάολο', 'ᾺΙ ΣΤΟ ΔΙΆΟΛΟ', 'ᾲ στο διάολο', 'ὰι στο διάολο', 'ὰι στο διάολο',  ],
    [ 'İSTANBUL', 'istanbul', 'İstanbul', 'İSTANBUL', 'i̇stanbul', 'İstanbul', 'İSTANBUL', 'İstanbul', 'istanbul', 'i̇stanbul',  ],
    [ "ﬁ", "ﬁ", "ﬁ", "ﬁ", "ﬁ", "Fi", "FI", "ﬁ", "fi", "fi",  ],
    [ "ﬁlesystem", "ﬁlesystem", "ﬁlesystem", "ﬁLESYSTEM", "ﬁlesystem", "Filesystem", "FILESYSTEM", "ﬁlesystem", "filesystem", "filesystem",  ],
    [ "ﬓﬔﬕﬖﬗ", "ﬓﬔﬕﬖﬗ", "ﬓﬔﬕﬖﬗ", "ﬓﬔﬕﬖﬗ", "ﬓﬔﬕﬖﬗ", "Մնﬔﬕﬖﬗ", "ՄՆՄԵՄԻՎՆՄԽ", "ﬓﬔﬕﬖﬗ", "մնմեմիվնմխ", "մնմեմիվնմխ",  ],
    [ "ŉ groot", "ŉ groot", "ŉ Groot", "ŉ GROOT", "ŉ groot", "ʼN Groot", "ʼN GROOT", "ŉ groot", "ʼn groot", "ʼn groot",  ],
    [ "ﬀ", "ﬀ", "ﬀ", "ﬀ", "ﬀ", "Ff", "FF", "ﬀ", "ff", "ff",  ],
    [ "ǰ", "ǰ", "ǰ", "ǰ", "ǰ", "J̌", "J̌", "ǰ", "ǰ", "ǰ",  ],
    [ "550 nm or Å", "550 nm or å", "550 Nm Or Å", "550 NM OR Å", "550 nm or å", "550 Nm Or Å", "550 NM OR Å", "550 nm or å", "550 nm or å", "550 nm or å",  ],
    [ "ẚ", "ẚ", "ẚ", "ẚ", "ẚ", "Aʾ", "Aʾ", "ẚ", "aʾ", "aʾ",  ],
  );
  table_test(@test_table);
}


