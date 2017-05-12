use Test::More tests => 6;

use returning {
	Affirmative   => !0,
	Negitive      => !1,
	ReturnNumber  => sub { 0+$_[0] },
	Ctx           => sub () { wantarray ? 'list' : 'scalar' },
	CallerLineNo  => sub () { (caller(0))[2] },
};

sub test1
{
	Affirmative;
	Negitive;
}

sub test2
{
	ReturnNumber("2bad");
	die "failed!";
}

sub test3
{
	Ctx;
	die "failed!";
}

sub test4
{
	CallerLineNo;
	die "failed!";
}

sub outer
{
	my $num = inner();
	return "got($num)";
}

sub inner
{
	ReturnNumber(1);
	return 2;
}

ok(
	test1(),
);

cmp_ok(
	test2(),
	'eq',
	'2'
);

is(
	[test3()]->[0],
	'list',
);

is(
	scalar test3(),
	'scalar',
);

#line 1000
is(test4(), 1000);

is(
	outer(),
	"got(1)",
);

