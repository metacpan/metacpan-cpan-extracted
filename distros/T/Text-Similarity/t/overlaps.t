# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl overlaps.t'
#
# Last modified by : $Id: overlaps.t,v 1.1.1.1 2013/06/26 02:38:12 tpederse Exp $
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 16;

BEGIN {use_ok Text::OverlapFinder};

$finder = Text::OverlapFinder->new;
ok ($finder);

$string1 = 'the cat in the hat';
$string2 = 'these cats in these hats';
$string3 = 'the cat over there under the door in the hat';

# --------------------------------------------------------
# exact matching between two identical files

($overlaps, $wc1, $wc2) = $finder -> getOverlaps ($string1, $string1);

# just one overlap in this case

foreach $overlap (keys %$overlaps) {
	is ($overlap, 'the cat in the hat', "identical match string");
	is ($overlaps -> {$overlap}, 1, "identical match number");
    }

is ($wc1, 5, "identical match length 1");
is ($wc2, 5, "identical match length 2");

# --------------------------------------------------------
# just one word match here

($overlaps, $wc1, $wc2) = $finder -> getOverlaps ($string1, $string2);

# just one word overlap in this case

foreach $overlap (keys %$overlaps) {
	is ($overlap, 'in', "string1 string2 one word match");
	is ($overlaps -> {$overlap}, 1, "frequency of string1 string2 match");
    }

is ($wc1, 5, "length 1");
is ($wc2, 5, "length 2");

# --------------------------------------------------------
# two phrasal matches separated by intermediate words

($overlaps, $wc1, $wc2) = $finder -> getOverlaps ($string1, $string3);

# order in which these results stored in hashes can't be predicted, sort!

@overlap = (sort keys %$overlaps);

is ($overlap[0], 'in the hat', "string1 string3 multi word match");
is ($overlaps -> {$overlap[0]}, 1, "frequency of string1 string3 match");
is ($overlap[1], 'the cat', "string1 string3 multi word match");
is ($overlaps -> {$overlap[1]}, 1, "frequency of string1 string3 match");

is ($wc1, 5, "length 1");
is ($wc2, 10, "length 3");
