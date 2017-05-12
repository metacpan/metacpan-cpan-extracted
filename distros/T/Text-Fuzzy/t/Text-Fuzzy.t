use warnings;
use strict;
use Test::More;
BEGIN { use_ok('Text::Fuzzy') };
use Text::Fuzzy;

my $tf = Text::Fuzzy->new ('buggles');
ok ($tf);
ok (ref $tf eq 'Text::Fuzzy');
my $d = $tf->distance ('biggles');
is ($d, 1, "Distance between biggles and buggles is 1");
is ($tf->get_max_distance (), undef, "Expected maximum distance");
my $word1 = 'bongos';
is ($tf->distance ($word1), 4, "Distance between buggles and $word1 is 4");
my $tf2 = Text::Fuzzy->new ('chuggles', max => 5);
ok ($tf2);
ok (ref $tf2 eq 'Text::Fuzzy');

my $tf3 = Text::Fuzzy->new ('knox');

my @words = qw/
quick
brown
fox
lazy
dog
/;
my $nearest = $tf3->nearest (\@words);
is ($nearest, 2);
my $distance = $tf3->last_distance ();
is ($distance, 2);

use utf8;
my $tf4 = Text::Fuzzy->new ('サインはV');
is ($tf4->unicode_length (), 5, "Unicode length test");
my $dist = $tf4->distance ('パインはB');
is ($dist, 2);
no utf8;
my $dist2 = $tf4->distance ('Sign Wa V');
is ($dist2, 8, "Unicode and non-Unicode distance test");
use utf8;
my @uwords = qw/
あいうえお
サイんはＶ
サイエンスはV
/;
my $nearest4 = $tf4->nearest (\@uwords);
is ($nearest4, 2);
is ($tf4->last_distance (), 2);

$tf->set_max_distance ();
my $md = $tf->get_max_distance ();
is ($md, undef, "max distance is undefined");

my $short_word = 'boo';
my @long_words = ('bibbity');
my $tfboo = Text::Fuzzy->new ($short_word);
is ($tfboo->nearest (\@long_words), 0,
    "Do not truncate maximum distance to word's length");

done_testing ();

# Local variables:
# mode: perl
# End:
