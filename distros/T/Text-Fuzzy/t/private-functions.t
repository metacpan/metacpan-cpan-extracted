use warnings;
use strict;
use Test::More;
use Text::Fuzzy;
use utf8;

my @stuff = qw/
one
two
three
four
five
six
seven
/;

my $tf = Text::Fuzzy->new ('bibbity bobbity boo');
$tf->set_max_distance (1);
$tf->nearest (\@stuff);

# All of the strings have a length much less than $tf, so we expect
# them all to be rejected at the stage of length comparisons.

cmp_ok ($tf->length_rejections, '==', scalar @stuff);
cmp_ok ($tf->ualphabet_rejections, '==', 0);
cmp_ok ($tf->alphabet_rejections, '==', 0);

# Test that the non-Unicode alphabetization is catching some matches.

my $tfsim = Text::Fuzzy->new ('WXYZ');
$tfsim->set_max_distance (1);
my @nearest = $tfsim->nearest (\@stuff);
cmp_ok ($tfsim->alphabet_rejections, '>', 0);

my $tf2 = Text::Fuzzy->new ('あいうえ');

$tf2->set_max_distance (1);
$tf2->nearest (\@stuff);

# All of the strings are three, four, or five letters long, so we do
# not expect to have any rejected for being the wrong length.

cmp_ok ($tf2->length_rejections, '==', 0);

# None of the strings has any characters in common with the string in
# $tf2, so we expect all of them to be rejected by the Unicode
# alphabet test.

cmp_ok ($tf2->ualphabet_rejections, '==', scalar @stuff, "alphabet rejections");

is ($tf2->unicode_length (), 4);

is ($tf2->get_trans (), 0);

done_testing ();


