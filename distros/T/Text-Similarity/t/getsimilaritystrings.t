# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/getsimilaritystrings.t'
# Note that because of the file paths used this must be run from the
# directory in which /t resides
#
# Last modified by : '$Id: getsimilaritystrings.t,v 1.1.1.1 2013/06/26 02:38:12 tpederse Exp $'
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 22;

BEGIN {use_ok Text::Similarity}
BEGIN {use_ok Text::Similarity::Overlaps}

# these results should be normalized

my %opt_hash = ('normalize' => 1);

my $overlapmod = Text::Similarity::Overlaps->new (\%opt_hash);
ok ($overlapmod);

# test cases

$string1 = 'this is our          test case today';
$string2 = '   this is our     test case                      today           ';
$string3 = ' winston churchill winston churchill ';
$string4 = ' winston churchill';
$string5 = ' WINSTON CHURCHILL';
$string6 = ' our test case today is winston churchill';
$string7 = ' ';

# exact matching between two identical strings

$score = $overlapmod->getSimilarityStrings ($string1, $string1);
is ($score, 1, "self similarity of string1, normalized");

# differ only by spaces

$score = $overlapmod->getSimilarityStrings ($string1, $string2);
is ($score, 1, "similarity of string1 and string2, normalized");

# differ by half the number of words

$score = $overlapmod->getSimilarityStrings ($string3, $string4);

# answer is around .666

cmp_ok($score, '<', .7);
cmp_ok($score, '>', .6);

# differ due to case, but that is ignored

$score = $overlapmod->getSimilarityStrings ($string4, $string5);
is ($score, 1, "similarity of string5 and string6, normalized");

# partial match

$score = $overlapmod->getSimilarityStrings ($string1, $string6);
cmp_ok($score, '<', .8);
cmp_ok($score, '>', .7);

# test on empty string

$score = $overlapmod->getSimilarityStrings ($string7, $string7);
is ($score, 0, "empty string7, normalized");

# test on empty string with non-empty

$score = $overlapmod->getSimilarityStrings ($string7, $string1);
is ($score, 0, "empty string7 with string1, normalized");

# test on undefined strings

$score = $overlapmod->getSimilarityStrings ($string99, $string99);
is ($score, undef, "undefined string99, normalized");

# -----------------------------------------------------------------

# these results should NOT be normalized

%opt_hash = ('normalize' => 0);

$overlapmod = Text::Similarity::Overlaps->new (\%opt_hash);
ok ($overlapmod);

# exact matching between two identical strings

$score = $overlapmod->getSimilarityStrings ($string1, $string1);
is ($score, 6, "self similarity of string1, unnormalized");

# differ only by spaces

$score = $overlapmod->getSimilarityStrings ($string1, $string2);
is ($score, 6, "similarity of string1 and string2, unnormalized");

# differ by half the number of words

$score = $overlapmod->getSimilarityStrings ($string3, $string4);
is ($score, 2, "similarity of string1 and string2, unnormalized");

# differ due to case, but that is ignored

$score = $overlapmod->getSimilarityStrings ($string4, $string5);
is ($score, 2, "similarity of string5 and string6, unnormalized");

# partial match

$score = $overlapmod->getSimilarityStrings ($string1, $string6);
is ($score, 5, "similarity of string1 and string6, unnormalized");

# test on empty string

$score = $overlapmod->getSimilarityStrings ($string7, $string7);
is ($score, 0, "empty string7, unnormalized");

# test on empty string with non-empty

$score = $overlapmod->getSimilarityStrings ($string7, $string1);
is ($score, 0, "empty string7 with string1, unnormalized");

# test on undefined strings

$score = $overlapmod->getSimilarityStrings ($string99, $string99);
is ($score, undef, "undefined string99, unnormalized");

