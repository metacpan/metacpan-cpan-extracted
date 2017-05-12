#!perl -w

use strict;
use Test::More tests => 4;

use Test::LeakTrace;
use autouse 'Data::Dumper' => 'Dumper';

my @info = leaked_info{
	my %a = (foo => 42);
	my %b = (bar => 3.14);

	$b{a} = \%a;
	$a{b} = \%b;

	pass 'in leaktrace block';
};

cmp_ok(scalar(@info), '>', 1)
	or diag(Dumper(\@info));

my($si) = grep {
		my $ref = $_->[0];
		ref($ref) eq 'REF' and ref(${$ref}) eq 'HASH' and exists ${$ref}->{a}
	} @info;


like __FILE__, qr/\Q$si->[1]\E/, 'state info'
	or diag(Dumper \@info);

@info = leaked_info{
#line 1 here_is_extreamely_long_file_name_that_tests_the_file_name_limitation_in_stateinfo_in_LeakTrace_xs
	my %a = (foo => 42);
	my %b = (bar => 3.14);

	$b{a} = \%a;
	$a{b} = \%b;
};


($si) = grep {
		my $ref = $_->[0];
		ref($ref) eq 'REF' and ref(${$ref}) eq 'HASH' and exists ${$ref}->{a}
	} @info;

is 'here_is_extreamely_long_file_name_that_tests_the_file_name_limitation_in_stateinfo_in_LeakTrace_xs', $si->[1];
