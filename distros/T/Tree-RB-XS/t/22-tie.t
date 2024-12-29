#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS;
use Time::HiRes 'time';
use Scalar::Util 'weaken';

my %example;
my $t= tie %example, 'Tree::RB::XS';
weaken( $t );

ok( !%example ) if $] > 5.025000;
is( ($example{x}= 1), 1, 'store 1' );
is( $t->get('x'), 1, 'stored' );
is( ($example{y}= 2), 2, 'store 2' );
is( $t->get('y'), 2, 'stored' );
ok( %example ) if $] > 5.025000;
is( $example{x}, 1, 'fetch' );
$_= 8 for values %example;
is( delete $example{x}, 8, 'delete' );
ok( exists $example{y}, 'exists' );

$example{x}= 9;
$example{c}= 3;

is( [ keys %example ], [ 'c', 'x', 'y' ], 'keys' );
is( [ values %example ], [ 3, 9, 8 ], 'values' );

$example{1}= 1;
$example{2}= undef;

tied(%example)->hseek('x');
is( [ each %example ], [ 'x', 9 ], '"x" after seek' );
is( [ each %example ], [ 'y', 8 ], '"y" after' );

tied(%example)->hseek('c', { -reverse => 1 });
is( [ each %example ], [ 'c', 3 ], '"c" after seek' );
is( [ each %example ], [ 2, undef ], '"2" after (reverse)' );
is( [ each %example ], [ 1, 1 ], '"1" after (reverse)' );
is( [ each %example ], [], '() after (reverse)' );
is( [ keys %example ], ['y','x','c',2,1], 'reversed keys' );
is( [ each %example ], ['y', 8 ], '"y" after reset (reverse)' );
tied(%example)->hseek({ -reverse => 0 });
is( [ each %example ], [1, 1 ], '"1" after reverse change' );

untie %example;
is( [ keys %example ], [], 'untied' );
is( $t, undef, 'tree freed' );

subtest foldcase => sub {
	my %hash;
	tie %hash, 'Tree::RB::XS', 'foldcase';
	$hash{'content-type'}= 'text/plain';
	$hash{'Content-Type'}= 'text/html';
	is( $hash{'content-type'}, 'text/html', 'lowercase lookup sees uppercase key value' );
	is( [ keys %hash ], [ 'Content-Type' ], 'official key is last-written case' );
};

# These are the tests from Tie::CPHash, to verify that Tree::RB::XS can behave identically
subtest tie_cphash_tests => sub {
	my (%h, $j, $test);
	tie(%h, 'Tree::RB::XS', compare_fn => 'foldcase');
	ok( 1, 'tied %h' );
	is( $h{Hello}, undef, "Hello not yet defined");
	ok( !exists $h{Hello}, "Hello does not exist");
	SKIP: {
		skip 'SCALAR added in Perl 5.8.3', 1 unless $] >= 5.008003;
		ok((not scalar %h), 'SCALAR empty');
	};
	$h{Hello}= 'World';
	$j= $h{HeLLo};
	is( $j, 'World', 'HeLLo - World' );
	is( [keys %h], ['Hello'], 'last key Hello' );
	ok( exists $h{Hello}, "Hello now exists" );
	$h{World}= 'HW';
	$h{HELLO}= $h{World};
	is( tied(%h)->key('hello'), 'HELLO', 'last key HELLO' );
	SKIP: {
		skip 'SCALAR added in Perl 5.8.3', 1 unless $] >= 5.008003;
		ok( scalar %h, 'SCALAR not empty' );
	};
	is( delete $h{Hello}, 'HW', "deleted Hello" );
	is( delete $h{Hello}, undef, "can't delete Hello twice" );
	SKIP: {
		skip 'SCALAR added in Perl 5.8.3', 1 unless $] >= 5.008003;
		ok( scalar %h, 'SCALAR still not empty' );
	};
	is( tied(%h)->key('hello'), undef, 'hello not in keys' );
	tied(%h)->put(qw(HeLlO world));
	is( $h{world}, 'HW', 'World still exists' );
	is( $h{hello}, 'world', 'hello was pushed' );
	is( tied(%h)->key('hello'), 'HeLlO', 'hello is HeLlO' );
	is( tied(%h)->key('world'), 'World', 'world is World' );
	%h= ();
	SKIP: {
		skip 'SCALAR added in Perl 5.8.3', 1 unless $] >= 5.008003;
		ok( !scalar %h, 'SCALAR now empty' );
	};
	{
		my %i;
		tie( %i, 'Tree::RB::XS', compare_fn => 'foldcase', kv => [Hello => 'World'] );
		is( $i{hello}, 'World', 'initialized from list' );
		is( tied(%i)->key('hello'), 'Hello', 'list remembers case' );
	}
	{
		tie( my %i, 'Tree::RB::XS', compare_fn => 'foldcase', kv => [qw(Hello World  hello world)] );
		is( $i{Hello}, 'world', '1 line initialized from list' );
		is( tied(%i)->key('Hello'), 'hello', '1 line remembers case' );
	}
};

done_testing;
