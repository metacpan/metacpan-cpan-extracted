# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
use strict;
BEGIN { plan tests => 6 };
use Tie::LazyList;

$Test::Harness::verbose = 1;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $class       = 'Tie::LazyList'; # class all arrays are tied to
my $rand_nums   = 128;   # how many random numbers will it include
my $upper_bound = 128;   # the maximal number in the test range : 0 .. max
my $times       = 20;    # how many times every test executed

my $anim_sleep  = 0;
my @anim_chars  = qw ( - \ | / );
my $anim_chars  = @anim_chars;

print "Test 1 .. ";
ok( test1()); # testing APROG
print "Test 2 .. ";
ok( test2()); # testing GPROG, POW
print "Test 3 .. ";
ok( test3()); # testing APROG_SUM
print "Test 4 .. ";
ok( test4()); # testing GPROG_SUM
print "Test 5 .. ";
ok( test5()); # testing FIBON
print "Test 6 .. ";
ok( test6()); # testing FACT

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Generates array of numbers ( random, ordered or reversed ) according to the mode
# Returns ref to array
sub numbers ($){
	local $_;
	my ( $mode ) = @_;

	$mode = $mode % 3;
	if ( $mode == 0 ){
		# random numbers
		my @numbers = ();
		push @numbers, int rand ( $upper_bound + 1 ) for ( 1 .. $rand_nums );
		return \@numbers;
	} elsif ( $mode == 1 ){
		# ordered numbers
		return [ 0 .. $upper_bound ];
	} elsif ( $mode == 2 ){
		# numbers in reversed order
		return [ reverse ( 0 .. $upper_bound )];
	}
}


sub animate ($) {
	local $_;
	my ( $number ) = @_;
	print $anim_chars[ $number % $anim_chars ],"\b";
	select ( undef, undef, undef, $anim_sleep );
}

# returns TRUE if the value passed is a numeric value, FALSE otherwise
sub is_number($) {
	my $number = shift;
	( ~$number & $number ) eq '0';
}


# Gets an index and array references, returns TRUE if all arrays are equal
# at this index, FALSE otherwise
sub equal($@) {
	local $_;
	my ( $n, @refs ) = @_;
	my $value     = $refs[0][$n];
	my $is_number = is_number( $value );

	for my $ref ( @refs ){
		if ( $is_number ){
			$ref->[ $n ] == $value or return 0;
		} else {
			$ref->[ $n ] eq $value or return 0;
		}
	}

	return 1;
}


# Gets a number and references to arrays.
# Generates an array of indexes to check ( using the number passed ) and
# checks that all arrays ( referenced by references passed ) are equal at every index
sub all_equal($@){
	local $_;
	my ( $num, @refs ) = @_;

	for my $n ( @{ numbers( $num ) } ){
		equal ( $n, @refs ) or return 0;
	}

	return 1;
}


# testing APROG
sub test1 {
	local $_;

	# Arithmetic progression : 1, 2, 3 ... n, n+1 ..
	my @APROG = ();
	# A(n) = 1 + n
	$APROG[ $_ ] = 1 + $_ for ( 0 .. $upper_bound );

	for ( 1 .. $times ){
		animate( $_ );

		my ( @arr, @arr2, @arr3, @arr4 );
		# A(n) = A(n-1) + 1
		tie @arr,  $class, 1, sub { my( $arr_ref, $n ) = @_; $arr_ref->[ $n - 1 ] + 1 };
		tie @arr2, $class, [ 1, 2 ], 'APROG';
		tie @arr3, $class, \@arr;
		tie @arr4, $class, \@arr2;

		all_equal ( $_, \@APROG, \@arr, \@arr2, \@arr3, \@arr4 ) or return 0;
	}

	return 1;
}


# testing GPROG, POW
sub test2 {
	local $_;

	# Geometric progression : 1, 2, 4, 8 .. n, n*2 ..
	my @POW2;
	# P(n) = 2^n
	$POW2[ $_ ] = 2 ** $_ for ( 0 .. $upper_bound );

	for ( 1 .. $times ){
		animate( $_ );

		my ( @arr, @arr2, @arr3, @arr4, @arr5, @arr6 );
		# P(n) = P(n-1) * 2
		tie @arr,  $class, 1, sub { my( $arr_ref, $n ) = @_; $arr_ref->[ $n - 1 ] * 2 };
		tie @arr2, $class, [ 1, 2 ], 'GPROG';
		tie @arr3, $class, 2, 'POW';
		tie @arr4, $class, \@arr;
		tie @arr5, $class, \@arr2;
		tie @arr6, $class, \@arr3;

		all_equal ( $_, \@POW2, \@arr, \@arr2, \@arr3, \@arr4, \@arr5, \@arr6 ) or return 0;
	}

	return 1;
}

# testing APROG_SUM
sub test3 {

	# Sum of 1, 2, 3 .. n, n+1 progression
	my @APROG_SUM = ();
	# S(n-1) = ( n + n^2 ) / 2
	$APROG_SUM[ $_ - 1 ] = ( $_ + ( $_ * $_ )) / 2
		for ( 1 .. $upper_bound + 1 );

	for ( 1 .. $times ){
		animate( $_ );

		my ( @arr, @arr2, @arr3, @arr4 );
		# S(n) = S(n-1) + (n+1) // n - zero based
		tie @arr,  $class, 1, sub { my( $array_ref, $n ) = @_; $array_ref->[ $n - 1 ] + ( $n + 1 ) };
		tie @arr2, $class, [ 1, 2 ], 'APROG_SUM';
		tie @arr3, $class, \@arr;
		tie @arr4, $class, \@arr2;

		all_equal ( $_, \@APROG_SUM, \@arr, \@arr2, \@arr3, \@arr4 ) or return 0;
	}

	return 1;
}


# testing GPROG_SUM
sub test4 {
	local $_;

	# Sum of 1, 2, 4, 8 .. n, n*2 .. progression
	my @POW2_SUM;
	# S(n) = (2^(n+1)) - 1
	$POW2_SUM[ $_ ] = ( 2 ** ( $_ + 1 )) - 1 for ( 0 .. $upper_bound );

	for ( 1 .. $times ){
		animate( $_ );

		my ( @arr, @arr2, @arr3, @arr4 );
		# S(n) = S(n-1) + 2^n
		tie @arr,  $class, 1, sub { my( $array_ref, $n ) = @_; $array_ref->[ $n - 1 ] + ( 2 ** $n ) };
		tie @arr2, $class, [ 1, 2 ], 'GPROG_SUM';
		tie @arr3, $class, \@arr;
		tie @arr4, $class, \@arr2;

		all_equal ( $_, \@POW2_SUM, \@arr, \@arr2, \@arr3, \@arr4 ) or return 0;
	}

	return 1;
}

# testing FIBON
sub test5 {
	local $_;

	# Fibonacci numbers - 0, 1, 1, 2 ..
	my @FIBON = ( 0, 1 );
	# F(n) = F(n-1) + F(n-2)
	$FIBON[ $_ ] = $FIBON[ $_ - 1 ] + $FIBON[ $_ - 2 ]
		for ( 2 .. $upper_bound );

	for ( 1 .. $times ){
		animate( $_ );

		my ( @arr, @arr2, @arr3, @arr4 );
		tie @arr,  $class, [ 0, 1 ], sub { my ( $array_ref, $n ) = @_; $array_ref->[ $n - 1 ] + $array_ref->[ $n - 2 ] };
		tie @arr2, $class, [ 0, 1 ], 'FIBON';
		tie @arr3, $class, \@arr;
		tie @arr4, $class, \@arr2;

		all_equal ( $_, \@FIBON, \@arr, \@arr2, \@arr3, \@arr4 ) or return 0;
	}

	return 1;
}

# testing FACT
sub test6 {
	local $_;

	# Factorials : 1, 2, 6, 24, 120 ..
	my @FACT = ( 1 );
	# Fact(n) = Fact(n-1) * n
	$FACT[ $_ ] = $FACT[ $_ - 1 ] * $_ for ( 1 .. $upper_bound );

	for ( 1 .. $times ){
		animate( $_ );

		my ( @arr, @arr2, @arr3, @arr4 );
		tie @arr,  $class, 1, sub { my ( $array_ref, $n ) = @_; $array_ref->[ $n - 1 ] * $n };
		tie @arr2, $class, [ 1 ], 'FACT';
		tie @arr3, $class, \@arr;
		tie @arr4, $class, \@arr2;

		all_equal ( $_, \@FACT, \@arr, \@arr2, \@arr3, \@arr4 ) or return 0;
	}

	return 1;
}
