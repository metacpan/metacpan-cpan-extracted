use strict;
use warnings;
use Test::More;
use List::Util qw/max/;
use Type::Guess;
use Mojo::Loader qw/data_section/;
use Encode qw/decode encode/;
use Text::VisualPrintf qw/vprintf vsprintf/;
use Text::VisualWidth::PP qw/vwidth/;
use Text::CharWidth qw/mbswidth/;
use utf8;


$\ = "\n"; $, = "\t";

my $unicode_strings = [
		       "normal",
		       "übung",
		       "schön",
		       "fähig",
		       "niño",
		       "crème brûlée",
		       "smörgåsbord",
		       "добрый день",
		       "😊",
		       "🌍",
		       "你好",
		       "こんにちは",
		       "안녕하세요",
		       "ज़िंदगी"
		      ];

my $ok = [
	  "normal       |",
	  "übung        |",
	  "schön        |",
	  "fähig        |",
	  "niño         |",
	  "crème brûlée |",
	  "smörgåsbord  |",
	  "добрый день  |",
	  "😊           |",
	  "🌍           |",
	  "你好         |",
	  "こんにちは   |",
	  "안녕하세요   |",
	  "ज़िंदगी        |"
	 ];


my $t = Type::Guess->with_roles("+Unicode")->new(@{$unicode_strings});

ok($t->length == 12, "length");

my $i = 0;
for ($unicode_strings->@*) {
    is(($t->($_) . " |"), (encode "UTF-8", $ok->[$i]), $t->($_));
    $i++;
}
done_testing()

__DATA__
@@ strings
normal
übung
schön
fähig
niño
crème brûlée
smörgåsbord
добрый день
😊
🌍
你好
こんにちは
안녕하세요
#مرحبا
#שָׁלוֹם
ज़िंदगी
