# This tests returning array values, as well as checking that things
# are returned as expected when the maximum distance = minimum
# distance = only distance, and that the last value is returned in
# scalar context.

use warnings;
use strict;
use Test::More;
use Text::Fuzzy;

# A list of words, all of which is 

my @words = qw/
nice
rice
mice
lice
/;

my $tf = Text::Fuzzy->new ('dice');
my $nearest = $tf->nearest (\@words);

print "$nearest\n";

ok ($nearest == 3, "Scalar context gives last value");
$tf->set_max_distance (1);
$nearest = $tf->nearest (\@words);
cmp_ok ($nearest, '>=', 0, "Find word when maximum distance = distance");
my $md = $tf->get_max_distance ();
is ($md, 1, "max distance is one");

my @nearest = $tf->nearest (\@words);

is (scalar @nearest, 4, "Got four matches for dice in lice, rice, etc.");

# Check we can pick out the three near words in the following list.

my @funky_words = qw/
nice
funky
rice
gibbon
lice
graham
garden
/;

@nearest = $tf->nearest (\@funky_words);
is_deeply (\@nearest, [0, 2, 4], "Picked out nearest words only");

# Check that a complete mismatch returns an empty list.

use utf8;
my $tf2 = Text::Fuzzy->new ('あいうえお');
$tf2->set_max_distance (1);

@nearest = $tf2->nearest (\@funky_words);

cmp_ok (scalar @nearest, '==', 0, "Empty list returned for non-matching");

my $md2 = $tf2->get_max_distance ();
is ($md2, 1, "max distance is one");

$tf2->set_max_distance (3);
$tf2->nearest (\@funky_words);
is ($tf2->get_max_distance (), 3, "Test value of max distance");

done_testing ();
