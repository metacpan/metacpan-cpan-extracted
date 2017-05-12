#!/usr/bin/env perl
use warnings; use strict;
use Types::Core qw(blessed typ);
# vim=:SetNumberAndWidth


## Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl <name_of_test>.t'

#########################

#verbs: ok, is, isnt, like, unlike, cmp_ok, is_deeply, can_ok
#       isa_ok, pass, fail, BAIL_OUT
# require_ok(<module|file>)
# use_ok(<module>) -- use in BEGIN{} to get @imports active @run time
#
#


{	package HASH;
	use warnings; use strict;
	
	sub new {
		my $p=shift; my $c=$p||ref $p;
		bless $p=[], $c unless ref $p;
	}
1}


{ package Array;
	use warnings; use strict;

	sub new {
		my $p=shift; my $c=$p||ref $p;
		bless $p={}, $c unless ref $p;
	}
1}

{ package ARRAY;
	use warnings; use strict;

	sub new {
		my $p=shift; my $c=$p||ref $p;
		bless $p={}, $c unless ref $p;
	}
1}


package main;
use warnings; use strict;
use Test::More;
use Types::Core qw(blessed typ);

our ($name, $classname, $typename);

my $DepFailed="This test is dependent on the previous test working.";	

sub  run_test_with($$$) {
	($name, $classname, $typename) = @_;

	my $ref=$classname->new();

	our $PrevOK = ok(defined(blessed $ref), "blessed $name is defined");

		SKIP: {
			skip $DepFailed, 1 unless $PrevOK;

			ok($ref eq blessed $ref, "$name is blessed");
		};

	ok( $typename eq typ $ref, sprintf("%s should have type %s, not %s",$name, $typename, typ $ref));

}


##########
run_test_with("ARRAYedHASH", ARRAY, HASH);

##########

run_test_with("ArrayedHASH", "Array", HASH);

##########

run_test_with("HASHedARRAY", HASH, ARRAY);

done_testing();
