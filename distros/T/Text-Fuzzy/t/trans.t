use warnings;
use strict;
use Test::More;
use Text::Fuzzy;
use utf8;
my $thing = Text::Fuzzy->new ('abc');
eval {
    $thing->transpositions_ok (1);
    $thing->transpositions_ok (0);
};
ok (! $@, "No errors turning transpositions on and off");

$thing->transpositions_ok (0);
is ($thing->distance ('bac'), 2, "correct distance without transpos");

$thing->transpositions_ok (1);
is ($thing->distance ('bac'), 1, "correct distance with transpos");

# Test using Unicode characters. The following string is set up to
# have an edit distance of 2 using transposition edit distance, but 4
# using the Levenshtein edit distance.

my $thing2 = Text::Fuzzy->new (
    'あいうかきえおくけこ',
);

$thing2->transpositions_ok (0);
is ($thing2->distance ('あういかきおえくけこ'), 4,
    "correct distance without transpos");
$thing2->transpositions_ok (1);
is ($thing2->distance ('あういかきおえくけこ'), 2,
    "correct distance with transpos");

# From "Text-Levenshtein-Damerau-XS/t/02_xs_edistance.t"

is( d ('four','for'), 1, 'insertion');
is( d ('four','four'), 0, 'matching');
is( d ('four','fourth'), 2, 'deletion');
is( d ('four','fuor'), 1, 'transposition');
is( d ('four','oufr'), 2, 'test adjacent transpositions');
is( d ('four','fxxr'), 2, 'substitution');
is( d ('four','FOuR'), 3, 'case');
is( d ('four',''), 4, 'target empty');
is( d ('','four'), 4, 'source empty');
is( d ('',''), 0, 'source and target empty');
is( d ('111','11'), 1, 'numbers');
is( d ('xxx','xx',1), 1, '<= max distance setting');

is (d ('a cat', 'an abct'), 3, "Test from document");

# Test some utf8

is( d ('ⓕⓞⓤⓡ','ⓕⓞⓤⓡ'), 0, 'matching (utf8)');
is( d ('ⓕⓞⓤⓡ','ⓕⓞⓡ'), 1, 'insertion (utf8)');
is( d ('ⓕⓞⓤⓡ','ⓕⓞⓤⓡⓣⓗ'), 2, 'deletion (utf8)');
is( d ('ⓕⓞⓤⓡ','ⓕⓤⓞⓡ'), 1, 'transposition (utf8)');
is( d ('ⓕⓞⓤⓡ','ⓞⓤⓕⓡ'), 2, 'test adjacent transpositions');
is( d ('ⓕⓞⓤⓡ','ⓕⓧⓧⓡ'), 2, 'substitution (utf8)');

# Test with a maximum distance.

my $tf = Text::Fuzzy->new (
    'abcdefghijklm',
    trans => 1,
    max => 2,
);
my $d = $tf->distance ('mlkjihgfedcba');
is ($d, 3);

$tf = undef;

# Test doing multiple tests, to make sure the construction of the
# internal dictionary is not going wrong.

my $tfrepa = Text::Fuzzy->new ('central', trans => 1);
is ($tfrepa->distance ('centre'), 2);
is ($tfrepa->distance ('sinter'), 5);
is ($tfrepa->distance ('central'), 0);

$tfrepa = undef;

my $tfrepi = Text::Fuzzy->new ('かきくけこ', trans => 1);
is ($tfrepi->distance ('かきふらい'), 3);
is ($tfrepi->distance ('きかくこけ'), 2);
is ($tfrepi->distance ('かきくけこ'), 0);

$tfrepi = undef;

my $alleygater = Text::Fuzzy->new ('alleygater', trans => 1, max => 2);
my $alleydistance = $alleygater->distance ('overgreatly');
ok ($alleydistance == 3);
note ($d);
done_testing ();
exit;

sub d
{
    my ($left, $right) = @_;
    my $tf = Text::Fuzzy->new (
	$left,
	trans => 1,
    );

    my $d = $tf->distance ($right);
    return $d;
}
