use Test::More tests => 5;
BEGIN { use_ok('Text::EditTranscript',qw(EditTranscript)) };

my $string = "foo";
my $string2 = "fo0";

my $res = EditTranscript($string,$string2);

ok($res eq "--S","Testing substitution");

$string2 = "fo";

$res = EditTranscript($string,$string2);

ok($res eq "-D-","Testing deletion");

$string2 = "fooo";

$res = EditTranscript($string,$string2);

ok($res eq "-I--","Testing insertion");

$string = "In a hole in the ground there lived a hobbit. Not a nasty, dirty, wet hole, filled with the ends of worms and an oozy smell, nor yet a dry, bare, sandy hole with nothing in it to sit down on or to eat: it was a hobbit-hole, and that means comfort.";

$string2 = "in a hole in the ground there lived a hobbit. Not a nasty, dirty, wet hole, filled with the ends of worms and an oozy smell, nor yet a dry, bare, sandy hole with nothing in it to sit down on or to eat: it was a hobbit-hole, and that means comfort.";

$res = EditTranscript($string,$string2);

ok($res =~ /^S/,"Testing long string");
