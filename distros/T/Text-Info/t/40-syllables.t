use Test::More;
use utf8;

use Text::Info;

my $text = Text::Info->new( text => 'supercalifragilisticexpialidocious', language => 'en' );

is( $text->syllable_count, 14, 'Number of syllables matches!' );

$text = Text::Info->new( text => 'supércàlifragilisticexpialidocious', language => 'en' );

is( $text->syllable_count, 14, 'Number of syllables matches!' );

$text = Text::Info->new( text => 'Tyrannosaurus', language => 'no' );

is( $text->syllable_count, 5, 'Number of syllables matches!' );

done_testing;
