
# newcopy.t

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}

use Data::Dumper::Sorted;

if ($0 =~ m|/E|) { # see if I am an extension test
  $package = 'Tie::Hash::MultiKey::ExtensionPrototype';
} else {
  $package = 'Tie::Hash::MultiKey';
}

eval "require $package";

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

my $dd = new Data::Dumper::Sorted;

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

# test 2	check accessor
my($x,$thx) = new $package;

my $base = q|6	= bless([{
	},
{
	},
{
	},
0,0,undef,], '|. $package .q|');
|;
my $got = $dd->DumperA($thx);
print "got: $got\nexp: $base\nnot "
	unless $got eq $base;
&ok;

# test 3	add stuff
$x->{['a','b']} = 'ab';
$x->{['c','d','e']} = 'cde';

my $expx = q|23	= bless([{
		'a'	=> 0,
		'b'	=> 0,
		'c'	=> 1,
		'd'	=> 1,
		'e'	=> 1,
	},
{
		'0'	=> 'ab',
		'1'	=> 'cde',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
		},
		'1'	=> {
			'c'	=> 2,
			'd'	=> 3,
			'e'	=> 4,
		},
	},
2,5,['c','d','e',],
], '|. $package .q|');
|;
$got = $dd->DumperA($thx);
print "got: $got\nexp: $expx\nnot "
	unless $got eq $expx;
&ok;

# test 4	second tied hash
my($y,$thy) = new $package;

$got = $dd->DumperA($thy);
print "got: $got\nexp: $base\nnot "
	unless $got eq $base;
&ok;

# test 5	clone
my($z,$thz) = $thx->clone;
$expz = q|20	= bless([{
		'a'	=> 0,
		'b'	=> 0,
		'c'	=> 1,
		'd'	=> 1,
		'e'	=> 1,
	},
{
		'0'	=> 'ab',
		'1'	=> 'cde',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
		},
		'1'	=> {
			'c'	=> 2,
			'd'	=> 3,
			'e'	=> 4,
		},
	},
2,5,undef,], '|. $package .q|');
|;
$got = $dd->DumperA($thz);
print "got: $got\nexp: $expz\nnot "
	unless $got eq $expz;
&ok;

# test 6	modify secondary
$y->{qw(the quick brown fox jumped over the lazy)} = 'dog';
$y->{qw(give a mouse)} = 'a cookie';

my $expy = q|30	= bless([{
		'a'	=> 1,
		'brown'	=> 0,
		'fox'	=> 0,
		'give'	=> 1,
		'jumped'	=> 0,
		'lazy'	=> 0,
		'mouse'	=> 1,
		'over'	=> 0,
		'quick'	=> 0,
		'the'	=> 0,
	},
{
		'0'	=> 'dog',
		'1'	=> 'a cookie',
	},
{
		'0'	=> {
			'brown'	=> 2,
			'fox'	=> 3,
			'jumped'	=> 4,
			'lazy'	=> 7,
			'over'	=> 5,
			'quick'	=> 1,
			'the'	=> 6,
		},
		'1'	=> {
			'a'	=> 9,
			'give'	=> 8,
			'mouse'	=> 10,
		},
	},
2,11,'giveamouse',], '|. $package .q|');
|;
$got = $dd->DumperA($thy);
print "got: $got\nexp: $expy\nnot "
	unless $got eq $expy;
&ok;

# test 7	copy x to y
$thx->copy($thy);
$got = $dd->DumperA($thy);
print "got: $got\nexp: $expz\nnot "
	unless $got eq $expz;
&ok;

# test 8	modify 'y'
my $expm = q|32	= bless([{
		'a'	=> 0,
		'b'	=> 0,
		'bar'	=> 0,
		'c'	=> 1,
		'd'	=> 1,
		'dang'	=> 2,
		'ding'	=> 2,
		'dong'	=> 2,
		'e'	=> 1,
		'foo'	=> 0,
	},
{
		'0'	=> 'baz',
		'1'	=> 'cde',
		'2'	=> 'ddd',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'bar'	=> 7,
			'foo'	=> 6,
		},
		'1'	=> {
			'c'	=> 2,
			'd'	=> 3,
			'e'	=> 4,
		},
		'2'	=> {
			'dang'	=> 9,
			'ding'	=> 8,
			'dong'	=> 10,
		},
	},
3,11,'dingdangdong',], '|. $package .q|');
|;
$y->{qw(a foo bar)} = 'baz';
$y->{qw(ding dang dong)} = 'ddd';
$got = $dd->DumperA($thy);
print "got: $got\nexp: $expm\nnot "
	unless $got eq $expm;
&ok;

# test 9	verify 'z'
$got = $dd->DumperA($thz);
print "got: $got\nexp: $expz\nnot "
	unless $got eq $expz;
&ok;

# test 10	verify 'x'
$got = $dd->DumperA($thx);		# should be the same as Z
print "got: $got\nexp: $expz\nnot "
	unless $got eq $expz;
&ok;

# test 11	clear 'z';
%$z = ();
$got = $dd->DumperA($thz);
print "got: $got\nexp: $base\nnot "
	unless $got eq $base;
&ok;

# test 12	verify 'x'
$got = $dd->DumperA($thx);		# should still be the same as Z
print "got: $got\nexp: $expz\nnot "
	unless $got eq $expz;
&ok;

# test 13	verify 'y'
$got = $dd->DumperA($thy);
print "got: $got\nexp: $expm\nnot "
	unless $got eq $expm;
&ok;

# test 14	delete key from Y
$expm = q|22	= bless([{
		'c'	=> 1,
		'd'	=> 1,
		'dang'	=> 2,
		'ding'	=> 2,
		'dong'	=> 2,
		'e'	=> 1,
	},
{
		'1'	=> 'cde',
		'2'	=> 'ddd',
	},
{
		'1'	=> {
			'c'	=> 2,
			'd'	=> 3,
			'e'	=> 4,
		},
		'2'	=> {
			'dang'	=> 9,
			'ding'	=> 8,
			'dong'	=> 10,
		},
	},
3,11,undef,], '|. $package .q|');
|;
delete $y->{a};
$got = $dd->DumperA($thy);
print "got: $got\nexp: $expm\nnot "
	unless $got eq $expm;
&ok;

# test 15	reorder the keys
$expm = q|22	= bless([{
		'c'	=> 1,
		'd'	=> 1,
		'dang'	=> 2,
		'ding'	=> 2,
		'dong'	=> 2,
		'e'	=> 1,
	},
{
		'1'	=> 'cde',
		'2'	=> 'ddd',
	},
{
		'1'	=> {
			'c'	=> 0,
			'd'	=> 1,
			'e'	=> 2,
		},
		'2'	=> {
			'dang'	=> 4,
			'ding'	=> 3,
			'dong'	=> 5,
		},
	},
3,6,undef,], '|. $package .q|');
|;
Tie::Hash::MultiKey::_rordkeys($thy);
$got = $dd->DumperA($thy);
print "got: $got\nexp: $expm\nnot "
	unless $got eq $expm;
&ok;

# test 16	reorder the vals
$expm = q|22	= bless([{
		'c'	=> 0,
		'd'	=> 0,
		'dang'	=> 1,
		'ding'	=> 1,
		'dong'	=> 1,
		'e'	=> 0,
	},
{
		'0'	=> 'cde',
		'1'	=> 'ddd',
	},
{
		'0'	=> {
			'c'	=> 0,
			'd'	=> 1,
			'e'	=> 2,
		},
		'1'	=> {
			'dang'	=> 4,
			'ding'	=> 3,
			'dong'	=> 5,
		},
	},
2,6,undef,], '|. $package .q|');
|;
Tie::Hash::MultiKey::_rordvals($thy);
$got = $dd->DumperA($thy);
print "got: $got\nexp: $expm\nnot "
	unless $got eq $expm;
&ok;
