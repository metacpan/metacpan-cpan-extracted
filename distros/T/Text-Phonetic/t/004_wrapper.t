# -*- perl -*-

# t/004_wrapper.t - check wrapped modules

use utf8;
use Test::Most tests=>33+1;
use Test::NoWarnings;

use_ok('Text::Phonetic');

require "t/global.pl";

if (run_conditional('Text::Soundex','19')) {
    my $soundex = Text::Phonetic->load(
        algorithm   => 'Soundex',
    );
    
    isa_ok($soundex,'Text::Phonetic::Soundex');
    test_encode($soundex,"Euler","E460");
    test_encode($soundex,"Gauss","G200");
    test_encode($soundex,"Hilbert","H416");
    test_encode($soundex,"Knuth","K530");
    test_encode($soundex,"Lloydi","L300");
    test_encode($soundex,"Lukasiewicz","L222");
    test_encode($soundex,"Ashcraft","A226");
    
    is($soundex->compare('Alexander','Alieksandr'),50,'Compare soundex');
    is($soundex->compare('Alexander','Barbara'),0,'Compare soundex');
    is($soundex->compare('Alexander','Alexander'),100,'Compare soundex');
    is($soundex->compare('Alexander','Alexandér'),99,'Compare soundex');
    
    # Multi tests
    my @rlist = $soundex->encode('Alexander','Alieksandr','Euler');
    my $rlist = $soundex->encode('Alexander','Alieksandr','Euler');
    is(scalar(@rlist),3,'Soundex list');
    is(scalar(@$rlist),3,'Soundex list');
    is($rlist[2],'E460','Soundex list');
    is($rlist->[2],'E460','Soundex list');
    
    my $soundexnara = Text::Phonetic->load(
        algorithm   => 'Soundex',
        nara        => 1,
    );
    isa_ok($soundexnara,'Text::Phonetic::Soundex');
    test_encode($soundexnara,"Ashcraft","A261");
    
    my $soundexnocode = Text::Phonetic->load(
        algorithm   => 'Soundex',
        nocode      => 'Z0000',
    );
    test_encode($soundexnocode,"_","Z0000");
}

if (run_conditional('Text::Metaphone','8')) {
    my $metaphone = Text::Phonetic->load(
        algorithm   => 'Metaphone'
    );
    isa_ok($metaphone,'Text::Phonetic::Metaphone');
    test_encode($metaphone,"recrudescence","RKRTSNS");
    test_encode($metaphone,"moist","MST");
    test_encode($metaphone,"Gutenberg","KTNBRK");
    
    my $metaphone_length = Text::Phonetic->load(
        algorithm   => 'Metaphone',
        max_length  => 4
    );
    isa_ok($metaphone_length,'Text::Phonetic::Metaphone');
    test_encode($metaphone_length,"recrudescence","RKRT");
    test_encode($metaphone_length,"Gutenberg","KTNB");

    is($metaphone->compare('Gutenberg','Gutnbaerg'),50,'Compare Metaphone');
}

if (run_conditional('Text::DoubleMetaphone','5')) {
    my $doublemetaphone = Text::Phonetic->load(
        algorithm   => 'DoubleMetaphone'
    );
    isa_ok($doublemetaphone,'Text::Phonetic::DoubleMetaphone');
    is($doublemetaphone->compare('Alexander','Alieksandr'),50,'Compare DoubleMetaphone');
    is($doublemetaphone->compare('Alexander','Barbara'),0,'Compare DoubleMetaphone');
    is($doublemetaphone->compare('Alexander','Alexander'),100,'Compare DoubleMetaphone');
    is($doublemetaphone->compare('Alexander','Alexandér'),99,'Compare DoubleMetaphone');
}


