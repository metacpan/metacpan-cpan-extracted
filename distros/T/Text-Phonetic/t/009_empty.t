# -*- perl -*-

# t/009_empty.t - empty string test 

use Test::Most tests=>(7*4)+1;
use Test::NoWarnings;
use utf8;

use Text::Phonetic;

require "t/global.pl";

my %algorithms = (
    Phonem          => '',
    DaitchMokotoff  => '',
    Koeln           => '',
    Phonix          => '',
    Metaphone       => 'Text::Metaphone',
    DoubleMetaphone => 'Text::DoubleMetaphone',
    Soundex         => 'Text::Soundex',
);

while (my ($algorithm,$predicate) = each %algorithms) {
    
    if (run_conditional($predicate,4)) {
        my $object = Text::Phonetic->load(
            algorithm   => $algorithm,
        );
        my $encoded1 = $object->encode('');
        my $encoded2 = $object->encode('       ');
        my $encoded3 = $object->encode(undef);
        is($encoded1,undef,'Empty string for '.$algorithm);
        is($encoded2,undef,'Whitespace for '.$algorithm);
        is($encoded3,undef,'Undef for '.$algorithm);
        is($object->compare('\t','   '),0,'Compare for '.$algorithm);
    }

}