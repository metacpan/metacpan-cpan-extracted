#! /usr/bin/perl -Tw

use strict;
use warnings;
use Test::Builder::Tester tests => 3;
use Test::More;

diag "\$Test::More::VERSION = $Test::More::VERSION";

BEGIN { use_ok( 'Test::Exception' ) };

sub works {return shift};
sub dies { die 'oops' };
my $die_line = __LINE__ - 1;

my $filename = sub { return (caller)[1] }->();

lives_and {is works(42), 42} 'lives_and, no_exception & success';

test_out('not ok 1 - lives_and, no_exception & failure');
test_fail(+3);
test_err("#          got: '42'");
test_err("#     expected: '24'");
lives_and {is works(42), 24}	'lives_and, no_exception & failure';
	 
test_out('not ok 2 - lives_and, exception');
test_fail(+2);
test_err("# died: oops at $filename line $die_line.");
lives_and {is dies(42), 42}		'lives_and, exception';

test_out('ok 3 - the test passed' );
lives_and { ok(1, 'the test passed') };

test_test('lives_and works');
