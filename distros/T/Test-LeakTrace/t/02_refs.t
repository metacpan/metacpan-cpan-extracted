#!perl -w

use strict;
use Test::More tests => 3;

use Test::LeakTrace;

my $a;
my @refs = leaked_refs{
	$a = [];
};
is_deeply \@refs, [ [] ] or do{
	require Data::Dumper;
	diag(Data::Dumper->Dump([\@refs], ['*refs']));
};

@refs = leaked_refs{
	my %a = (foo => 42);
	my %b = (bar => 3.14);

	$b{a} = \%a;
	$a{b} = \%b;
};

cmp_ok(scalar(@refs), '>=', 2) or do{
	require Data::Dumper;
	diag(Data::Dumper->Dump([\@refs], ['*refs']));
};

cmp_ok scalar(grep{ ref($_) eq 'REF' && ref(${$_}) eq 'HASH' } @refs), '>=', 2;
