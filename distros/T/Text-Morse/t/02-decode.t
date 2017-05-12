use Test::Simple tests => 1;

use Text::Morse;

my $morse = new Text::Morse;
my $text = $morse->Decode("... --- ...");

ok($text eq 'SOS');