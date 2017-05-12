use strict;
use warnings;
use Test::Proto::Where qw(test_subject where otherwise);
use Test::Proto qw(p pArray pHash);
use Test::More tests=>6;

test_subject( scalar('a'),
	where ( 
		'a', 
		sub{
			pass ('got "a"');
		},
	),
);

test_subject scalar('b'),
	where 'b', sub{
		pass ('got "b"');
	};


test_subject scalar('c'),
	where
		'b', 
		sub{
			fail ('this is the test for c');
		},
	otherwise sub { pass ('got "c"') }
;

test_subject 'd',
	where 'd', sub{
			pass ('got "d"');
		},
	otherwise sub { fail ('This is the test for d') }
;

ok( (
	test_subject 'e',
		where 'd', sub{ 0 },
		where 'e', sub{ 1 },
		otherwise sub { 0 }
), 'test for e');


ok( (
	test_subject {foo=>'bar'},
		where [], sub{ 0 },
		where pHash, sub{ 1 },
		otherwise sub { 0 }
), 'test for hashref');

