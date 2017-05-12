#
# MultiKeyInsertOrderHash.pm - save multiple keys in insertion order
#
# 2008 - Marc-Sebastian Lucksch
# perl@maluku.de
#
# Partly based on Tie::InsertOrderHash from
# B. K. Oxley (binkley) binkley@bigfoot.comE
#

=head1 NAME 

Tie::MultiKeyInsertOrderHash

=head2 DESCRIPTION

Store multiple keys in a hash in insertion order

=head1 SYNOPSIS

	tie my %hash => 'Tie::MultiKeyInsertOrderHash';
	$hash{Say}="Hello World";
	$hash{Do}="wave";
	$hash{Say}="Good-Bye";
	$hash{Do}="leave";

	while (my ($key, $value) = each (%hash)) {
		print "Action: $key Option: $value\n";
	}
	print "I said: '", join ("' and '",@{$hash{Say}}),"'\n";
	print "I did: '", join ("' and '",@{$hash{Do}}),"'\n";

	print "The first thing I said was $hash{Say}->[0]\n";
	print "The last thing I said was $hash{Say}->[-1]\n";


Or:

	tie my %hash => 'Tie::MultiKeyInsertOrderHash',A,1,B,2,A,3,B,4; #Initial values.

=head1 Notes

To complete overwrite a value use:

	delete $hash{Value}
	$hash{Value}="newvalue";

$hash{Value} will return an array of all values of that key; This won't work as you expect:

	foreach my $key (keys %hash) {
		print $key; #This will work and print the key in the right order, but the key will be printed multiple times.
		print $hash{$key}; #This will print "ARRAY(......)";
		print $hash{$key}->[0]; # This will print the first value multiple times.
		print join(@{$hash{$key}}); #This will print all values of that key multiple times.
	}

Better use:
	while (my ($key, $value) = each (%hash)) {
		print $key;
		print $value; #This will print every value only once and in the right order.
	}

OR maybe:

	my %seen;
	foreach my $key (grep !$seen{$_}++,keys %hash) {
		print $key;
		print join(@{$hash{$key}}); #This will print the keys in the right order, but the values grouped by keys.
	}

=cut

package Tie::MultiKeyInsertOrderHash;

require 5.006_001;
use strict;
use warnings;

our $VERSION = 0.1;

use base qw(Tie::Hash);

use Data::Dumper;

use Carp qw/cluck/;

sub TIEHASH {
	my $class = shift;
	bless [
		[@_[grep { $_ % 2 == 0 } (0..$#_)]],
		{@_},
		0,
		{},
		undef
	],$class;
}

sub STORE { 
	push @{$_[0]->[0]}, $_[1];
	$_[0]->[2] = -1;
	push @{$_[0]->[1]->{$_[1]}},$_[2];
}

sub FETCH {
	#cluck();
	if ($_[0]->[4] and $_[0]->[4]->[0] eq $_[1]) {
		my $r=$_[0]->[4]->[1];
		$_[0]->[4]=undef;
		return $r;
	}
	return $_[0]->[1]->{$_[1]};
}

sub FIRSTKEY {
	#print STDERR Data::Dumper->Dump([@_]);
	$_[0]->[3]={};
	$_[0]->[2] = 0;
	return $_[0]->[4]=undef unless exists $_[0]->[0]->[$_[0]->[2]];
	my $key = $_[0]->[0]->[0];
	$_[0]->[3]->{$key}=1 unless $_[0]->[3]->{$key};
	$_[0]->[4]=[$key, $_[0]->[1]->{$key}->[0]];
	return $key
}


sub NEXTKEY  {
	my $i = $_[0]->[2];
	return $_[0]->[4]=undef unless exists $_[0]->[0]->[$i];
	if ($_[0]->[0]->[$i] eq $_[1]) {
		$i = ++$_[0]->[2] ;
		return $_[0]->[4]=undef unless exists $_[0]->[0]->[$i];
	}
	my $key = ${$_[0]->[0]}[$i];
	$_[0]->[3]->{$key}=0 unless $_[0]->[3]->{$key};
	$_[0]->[3]->{$key}++;
	#print STDERR "\nKey=$_[0]->[3]->{$key}\n$_[0]->[1]->{$key}->[$_[0]->[3]->{$key}-1]\n\n";
	$_[0]->[4]=[$key, $_[0]->[1]->{$key}->[$_[0]->[3]->{$key}-1]];
	return $key;
}

sub EXISTS   {
	return exists $_[0]->[1]->{$_[1]}
}

sub DELETE   {
	@{$_[0]->[0]} = grep { $_ ne $_[1] } @{$_[0]->[0]};
	delete $_[0]->[1]->{$_[1]};
}

sub CLEAR {
	$_[0]->[0] = [];
	$_[0]->[1] = {};
	$_[0]->[2] = 0;
	$_[0]->[3] = {};
}

sub SCALAR {
	return scalar $_[0]->[0];
}

=head1 BUGS

values() and scalar each() won't work do what you expect at all, because they call values(%hash) calls $hash{key} for each key, so it will return and array of arrayrefs
scalar each() works, but there is no way to find out in which context each was called, so it will screw up the next $hash{key} request.

Better only use ONLY this for iterating over this hash

	while (my ($key, $value) = each (%hash)) {
		#do something with $key and $value
	}

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@maluku.de

=cut

#It seems to me that wantarray is never set in FIRSTKEY or NEXTKEY even if each is called in list context. It will always trigger FETCH.
1;
