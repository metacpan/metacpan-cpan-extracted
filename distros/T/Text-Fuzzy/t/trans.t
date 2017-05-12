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
is ($thing2->distance ('あういかきおえくけこ'), 4, "correct distance without transpos");
$thing2->transpositions_ok (1);
is ($thing2->distance ('あういかきおえくけこ'), 2, "correct distance with transpos");

# From "Text-Levenshtein-Damerau-XS/t/02_xs_edistance.t"

is( xs_edistance('four','for'), 		1, 'test xs_edistance insertion');
is( xs_edistance('four','four'), 		0, 'test xs_edistance matching');
is( xs_edistance('four','fourth'), 	2, 'test xs_edistance deletion');
is( xs_edistance('four','fuor'), 		1, 'test xs_edistance transposition');
is( xs_edistance('four','fxxr'), 		2, 'test xs_edistance substitution');
is( xs_edistance('four','FOuR'), 		3, 'test xs_edistance case');
is( xs_edistance('four',''), 		4, 'test xs_edistance target empty');
is( xs_edistance('','four'), 		4, 'test xs_edistance source empty');
is( xs_edistance('',''), 			0, 'test xs_edistance source and target empty');
is( xs_edistance('111','11'), 		1, 'test xs_edistance numbers');
is( xs_edistance('xxx','xx',1),    	1, 'test xs_edistance <= max distance setting');

# Test some utf8

is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓞⓤⓡ'), 	0, 'test xs_edistance matching (utf8)');
is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓞⓡ'), 	1, 'test xs_edistance insertion (utf8)');
is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓞⓤⓡⓣⓗ'), 2, 'test xs_edistance deletion (utf8)');
is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓤⓞⓡ'), 	1, 'test xs_edistance transposition (utf8)');
is( xs_edistance('ⓕⓞⓤⓡ','ⓕⓧⓧⓡ'), 	2, 'test xs_edistance substitution (utf8)');

done_testing ();

sub xs_edistance
{
    my ($left, $right) = @_;
    my $tf = Text::Fuzzy->new (
	$left,
	trans => 1,
    );

    my $d = $tf->distance ($right);
    return $d;
}
