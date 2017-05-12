use strict;
use warnings;

use Test::More;

# -------------

BEGIN{ use_ok('Tree::DAG_Node'); }

my($count)    = 1; # Counting the use_ok above.
my($s)        = q|a => 'b=>b', c => "d=>d", 'e' => "f", 'g=>g' => "h", "i" => "j", 'k, k' => "l, l"|;
my($finished) = 0;
my($reg_exp)  =
qr/
	([\"'])([^"']*?)\1\s*=>\s*(["'])([^"']*?)\3,?\s*
	|
	(["'])([^"']*?)\5\s*=>\s*(.*?),?\s*
	|
	(.*?)\s*=>\s*(["'])([^"']*?)\9,?\s*
	|
	(.*?)\s*=>\s*(.*?),?\s*
/sx;

my(@got);

while (! $finished)
{
	if ($s =~ /$reg_exp/gc)
	{
		push @got, defined($2) ? ($2, $4) : defined($6) ? ($6, $7) : defined($8) ? ($8, $10) : ($11, $12);
	}
	else
	{
		$finished = 1;
	}
}

my(@expected) = ('a', 'b=>b', 'c', 'd=>d', 'e', 'f', 'g=>g', 'h', 'i', 'j', 'k, k', 'l, l');

for my $i (0 .. $#got)
{
	ok($got[$i] eq $expected[$i], "Matched $got[$i]"); $count++;
}

done_testing($count);
