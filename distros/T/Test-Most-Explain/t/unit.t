use strict;
use warnings;
use Test::Most;
use Test::Warnings;	 # ensure no unexpected warnings
use Test::Strict;	   # optional: enforce strictness in module
use Test::Vars;		 # optional: detect unused vars

use lib 'lib';
use Test::Most::Explain qw(explain);

#------------------------------------------------------------
# Public API: explain()
#------------------------------------------------------------
subtest 'explain() basic behaviour' => sub {

	my $got = explain( 1, 1 );
	ok( defined $got, 'explain() returns a string' );
	like( $got, qr/1/, 'output mentions the value' );
	unlike( $got, qr/diff/i, 'no diff when values are equal' );
};

#------------------------------------------------------------
# Scalar differences
#------------------------------------------------------------
subtest 'scalar diff' => sub {

	my $out = explain( 1, 2 );
	like( $out, qr/Expected.*2/s, 'shows expected value' );
	like( $out, qr/Got.*1/s,	  'shows got value' );
};

#------------------------------------------------------------
# Array differences
#------------------------------------------------------------
subtest 'array diff' => sub {

	my $out = explain( [1,2,3], [1,9,3] );

	like( $out, qr/Array diff/i, 'labels array diff' );
	like( $out, qr/2.*vs.*9/s,   'shows differing element' );

	like(explain([], [1]), qr/Array diff/, 'empty vs non-empty array');
};

#------------------------------------------------------------
# Hash differences
#------------------------------------------------------------
subtest 'hash diff' => sub {

	my $out = explain( { a => 1, b => 2 }, { a => 1, b => 9 } );

	like( $out, qr/Hash diff/i, 'labels hash diff' );
	like( $out, qr/b.*2.*9/s,   'shows differing key/value' );
	like(explain({}, {a=>1}), qr/Hash diff/, 'empty vs non-empty hash');
};

#------------------------------------------------------------
# Blessed references
#------------------------------------------------------------
{
	package Local::Thing;
	sub new { bless { x => shift }, shift }
}

subtest 'blessed refs' => sub {
	my $got = Local::Thing->new(1);
	my $exp = Local::Thing->new(2);

	my $out = explain( $got, $exp );

	like( $out, qr/bless/i, 'mentions blessed structure' );
	like( $out, qr/x.*1.*2/s, 'shows differing internal value' );

	my $a = bless {}, 'A';
	my $b = bless {}, 'B';
	like(explain($a, $b), qr/Blessed reference diff/, 'different classes');
};

#------------------------------------------------------------
# Deep structures: arrays of hashes, hashes of arrays
#------------------------------------------------------------
subtest 'nested structures' => sub {

	my $got = { a => [1,2], b => { x => 1 } };
	my $exp = { a => [1,9], b => { x => 2 } };

	my $out = explain( $got, $exp );

	like( $out, qr/Array diff/i, 'detects nested array diff' );
	like( $out, qr/Hash diff/i,  'detects nested hash diff' );
};

#------------------------------------------------------------
# No unexpected warnings
#------------------------------------------------------------
done_testing;
