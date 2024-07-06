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

done_testing;
