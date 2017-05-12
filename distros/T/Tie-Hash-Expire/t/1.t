
use Test::More tests => 28;

BEGIN {
	warn "\n\n###################################################################\n";
	warn "##### Tests take some time because of testing expirations.    #####\n";
	warn "##### Tests may hang for up to 10 seconds with nothing wrong. #####\n";
	warn "###################################################################\n\n";

	use_ok('Tie::Hash::Expire');
};

my %test;
tie %test, 'Tie::Hash::Expire', {'expire_seconds' => 3};

### Test assignment (STORE), fetch (FETCH) and expiration.

$test{'fred'} = 'barney';
sleep 1;
is($test{fred}, 'barney',	'value storage and retrieval');
sleep 3;
is($test{fred},	undef,		'basic expiration');

### Test slicing

@test{'fred','lone ranger'} = ('barney','tonto');
is($test{'fred'}, 'barney',		'hash slice');
is($test{'lone ranger'}, 'tonto',	'hash slice 2');


### Test DELETE

delete $test{'fred'};
is($test{fred},	undef,			'delete');
is($test{'lone ranger'}, 'tonto',	'delete 2');


### Test CLEAR

%test = ();
is($test{'lone ranger'}, undef,	'clear');
is(scalar keys(%test),	0,	'clear 2');


### Test EXISTS, defined, etc.

%test = (
	true	=>	'Hello',
	false	=>	0,
	undefined	=>	undef,
);

ok($test{true},			'exists 1');
ok(defined($test{false}),	'exists 2');
ok(exists($test{undefined}),	'exists 3');
ok(!defined($test{undefined}),	'exists 4');


### Test FIRSTKEY and NEXTKEY and expiration while iterating

%test = (
	'one'	=>	1,
	'two'	=>	2,
	'three'	=>	3,
);

ok(eq_set([keys %test],	[qw/one two three/]),	'keys 1'); 
ok(eq_set([values %test],	[1,2,3,]),	'keys 2'); 

sleep 2;

$test{three} = 'three';
$test{four} = 4;

ok(eq_set([keys %test],	[qw/one two three four/]),	'keys 3'); 
ok(eq_set([values %test],	[1,2,'three',4,]),	'keys 4'); 

sleep 2;

ok(eq_set([keys %test],	[qw/three four/]),	'keys 5'); 
ok(eq_set([values %test],	['three',4,]),	'keys 6'); 

my %zero_test;
tie %zero_test, 'Tie::Hash::Expire', {'expire_seconds' => 0};

$zero_test{foo} = 'bar';
ok(!exists($zero_test{foo}),	'zero');


my %undef_test;
tie %undef_test, 'Tie::Hash::Expire';

$undef_test{foo} = 'bar';
is($undef_test{foo}, 'bar',	'no expire 1');
sleep 2;
is($undef_test{foo}, 'bar',	'no expire 2');

# Test for NEXTKEY bug when expirations happen mid-iteration

my %exp;
tie %exp, 'Tie::Hash::Expire', { 'expire_seconds' => 5 };

$exp{'foo'} = 'bar';
sleep 2;
$exp{'biz'} = 'baz';
sleep 2;
$exp{'kate'} = 'jeffy';

my ($key, $value) = each %exp;
is($key,	'foo',	'NEXTKEY expire 1');
is($value,	'bar',	'NEXTKEY expire 2');

sleep 2;
($key, $value) = each %exp;
is($key,	'biz',	'NEXTKEY expire 1');
is($value,	'baz',	'NEXTKEY expire 2');

($key, $value) = each %exp;
is($key,	'kate',	'NEXTKEY expire 1');
is($value,	'jeffy',	'NEXTKEY expire 2');
