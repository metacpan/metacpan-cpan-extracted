use Test2::V0;
use Text::EditDistance::DamerauLevenshtein qw(dl_distance);

is dl_distance('four', 'four'), 0, "four -> four";
is dl_distance('four', 'for'), 1, "four -> for";
is dl_distance('four', 'fourth'), 2, "four -> fourth";
is dl_distance('four', 'fuor'), 1, "four -> fuor";
is dl_distance('four', 'fxxr'), 2, "four -> fxxr";
is dl_distance('four', 'FOuR'), 3, "four -> FOuR";
is dl_distance('four', ''), 4, "four -> ";
is dl_distance('', 'four'), 4, " -> four";
is dl_distance('', ''), 0, " -> ";
is dl_distance(11, 1), 1, "11 -> 1";
is dl_distance('xxx', 'x'), 2, "xxx -> x";
is dl_distance('xxx', 'xx'), 1, "xxx -> xx";
is dl_distance('xxx', 'xxxx'), 1, "xxx -> xxxx";
is dl_distance('xxxx', 'xxx'), 1, "xxxx -> xxx";
is dl_distance('a', "\N{U+0100}"), 1, "a -> U+0100";
is dl_distance("\N{U+0100}", "\N{U+0101}"), 1, "U+0100 -> U+0101";
is dl_distance("\N{U+1F63C}", "\N{U+0100}"), 1, "U+1F63C -> U+0100";
is dl_distance('ⓕⓞⓤⓡ', 'ⓕⓞⓤⓡ'), 0, "ⓕⓞⓤⓡ -> ⓕⓞⓤⓡ";
is dl_distance('ⓕⓞⓤⓡ', 'ⓕⓞⓡ'), 1, "ⓕⓞⓤⓡ -> ⓕⓞⓡ";
is dl_distance('ⓕⓞⓤⓡ', 'ⓕⓞⓤⓡⓣⓗ'), 2, "ⓕⓞⓤⓡ -> ⓕⓞⓤⓡⓣⓗ";
is dl_distance('ⓕⓞⓤⓡ', 'ⓕⓤⓞⓡ'), 1, "ⓕⓞⓤⓡ -> ⓕⓤⓞⓡ";
is dl_distance('ⓕⓞⓤⓡ', 'ⓕⓧⓧⓡ'), 2, "ⓕⓞⓤⓡ -> ⓕⓧⓧⓡ";

done_testing;
