#!perl -w
use strict;
use utf8;
use Test::More;
use Test::Deep;
use Storable qw(dclone);

use WordLists::Sort qw( atomic_compare complex_compare sorted_collate schwartzian_collate);

ok( 
	('a' cmp 'b') == -1, 
	'Sanity: a sorts before b' 
);
ok( 
	atomic_compare('a', 'b') == -1, 
	'a sorts before b' 
);
ok( 
	atomic_compare('a', 'aa') == -1, 
	'a sorts before aa' 
);
ok( 
	atomic_compare(undef, undef) == 0, 
	'atomic_compare(undef, undef) == 0' 
);
ok( 
	atomic_compare(undef, 1) == -1, 
	'atomic_compare(undef, 1) == -1' 
);
ok( 
	atomic_compare('b', 'a') == 1, 
	'a sorts before b, even if a is first' 
);
ok(
	atomic_compare('a', 'a') == 0, 
	'a and a are identical' 
);
ok( 
	atomic_compare('a', '') == 1, 
	'Empty sorts before string' 
);
ok( 
	atomic_compare('', 'a') == -1, 
	'Empty sorts before string (reversed)' 
);
ok(
	atomic_compare('a', 'A', ) == 1, 
	'uppercase A-Z sorts before lowecase a-z' 
);
ok(
	atomic_compare('a', 'A', {n=> sub{lc $_[0];}}) == 0, 
	'uppercase A-Z sorts the same as lowecase a-z with a lowercase normalisation' 
);
ok(
	atomic_compare('a', 'b', {n=> [ sub{$_[0]=~s/a/A/i;}, sub{$_[0]=~s/b/A/i;} ] }) == 0, 
	'Different normalisation on $a and $b' 
);
ok( 
	atomic_compare('ab', 'abc', ) == -1, 
	'Empty still sorts before nonempty a few chars in'
);
ok(
	atomic_compare('a', 'Ab', {t=> [ { re => qr/a/i, c => sub {lc $_[0] cmp lc $_[1]} }, ] }) == -1, 
	'Empty still sorts before nonempty across a token boundary' 
);
ok(
	atomic_compare( 000, 0.0, {n=> sub{lc $_[0];}}) == 0, 
	'Numbers evaluate and compare ok' 
);
sub test_complex_compare
{
	complex_compare($_[0], $_[1], {functions => [{n=>sub{$_[0]=~s/[^[:alpha:]]//g; $_[0];},},{},],});
}
ok( 
	test_complex_compare('a','ab') == -1, 
	'complex_compare: a<ab'
);
ok( 
	test_complex_compare('a','+ab') == -1, 
	'complex_compare: a<+ab'
);
ok( 
	test_complex_compare('a','a+') == -1, 
	'complex_compare: a<a+'
);
ok(
	test_complex_compare('ab','a+b') == 1, 
	'complex_compare: ab<a+b'
);
ok(
	test_complex_compare('ab','ab') == 0, 
	'complex_compare: ab=ab'
);

# Collation tests...

my $cCmp = sub{ lc ($_[1]->{'hw'}) cmp lc ($_[0]->{'hw'}) };
my $cSchCmp = sub{ $_[1] cmp $_[0] };
my $cSchNorm = sub{ return lc ($_[0]->{'hw'}); };
my $cMerge = sub{ $_[0]->{'pos'} .= ', '. $_[1]->{'pos'} };

use Data::Dumper;
sub ok_collate
{
	my ($data, $expected, $why) = @_;
	$why ||='';
	cmp_deeply(WordLists::Sort::naive_collate(dclone ($data), $cCmp, $cMerge), $expected, $why.' (using naive_collate)');
	cmp_deeply(sorted_collate(dclone ($data), $cCmp, $cMerge), $expected, $why.' (using sorted_collate)');
	cmp_deeply(schwartzian_collate(dclone ($data), $cSchCmp, $cSchNorm, $cMerge), $expected, $why.' (using schwartzian_collate)');
}

ok_collate(
	[{hw=>'a', pos=>'det'}, {hw=>'A', pos=>'n'}]
	, 
	[{hw=>'a', pos=>'det, n'}],
	'collation test with collation'
);
ok_collate(
	[{hw=>'a', pos=>'det'}]
	, 
	[{hw=>'a', pos=>'det'}],
	'collation test with only one element'
);
ok_collate(
	[{hw=>'a', pos=>'det'}, {hw=>'B', pos=>'n'}]
	, 
	[{hw=>'a', pos=>'det'}, {hw=>'B', pos=>'n'}],
	'collation test with no collation'
);
ok_collate(
	[{hw=>'a', pos=>'det'}, {hw=>'A', pos=>'n'}, {hw=>'A', pos=>'excl'}]
	, 
	[{hw=>'a', pos=>'det, n, excl'}],
	'collation test with multiple collation'
);
# todo: write more tests, for things like 't' and 'c'.
# todo: test complex_compare.

done_testing();
#Résumé