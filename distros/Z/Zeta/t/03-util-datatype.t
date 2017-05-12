#!perl

use Test::More;

BEGIN {
	use strict;
	use warnings;
	no  strict 'refs';
    use_ok( 'Zeta::Util', ':DATATYPE' ) || BAIL_OUT('Failed to use Zeta::Util with :DATATYPE');
}

# declare variables
my $result;
my @result;
my %result;

my %tests = (
	42 => { 
		value   => 42,
		numeric => 1,
		float   => 0,
		int     => 1,
		string  => 1
	},
	'0.01' => {
		value   => 0.01,
		numeric => 1,
		float   => 1,
		int     => 0,
		string  => 1
	},
	'2.00' => {
		value   => 2.00,
		numeric => 1,
		float   => 1,
		int     => 0,
		string  => 1
	},
	'2.01' => {
		value   => 2.01,
		numeric => 1,
		float   => 1,
		int     => 0,
		string  => 1
	},
	0 => {
		value   => 0,
		numeric => 1,
		float   => 0,
		int     => 1,
		string  => 1
	},
	0e0 => {
		value   => 0e0,
		numeric => 1,
		float   => 0,
		int     => 1,
		string  => 1
	},
	'0e0' => {
		value   => '0e0',
		numeric => 0,
		float   => 0,
		int     => 0,
		string  => 1
	},
	'0.00' => {
		value   => 0.00,
		numeric => 1,
		float   => 1,
		int     => 0,
		string  => 1
	},
	'.0' => {
		value   => .0,
		numeric => 1,
		float   => 1,
		int     => 0,
		string  => 1
	},
	'0.' => {
		value   => 0.,
		numeric => 1,
		float   => 0,
		int     => 1,
		string  => 1
	},
	'6.' => {
		value   => 6.,
		numeric => 1,
		float   => 0,
		int     => 1,
		string  => 1
	},
	'1_014.25' => {
		value   => '1_014.25',
		numeric => 0,
		float   => 0,
		int     => 0,
		string  => 1
	},
	'1_016' => {
		value   => '1_016',
		numeric => 0,
		float   => 0,
		int     => 0,
		string  => 1
	},
	1_024.25 => {
		value   => 1_024.25,
		numeric => 1,
		float   => 1,
		int     => 0,
		string  => 1
	},
	1_026 => {
		value   => 1_026,
		numeric => 1,
		float   => 0,
		int     => 1,
		string  => 1
	},
	test1 => {
		numeric => 0,
		float   => 0,
		int     => 0,
		string  => 1
	},
	'test2' => {
		value   => 'test2',
		numeric => 0,
		float   => 0,
		int     => 0,
		string  => 1
	},
);

foreach my $val (sort keys %tests) {
	foreach my $test (sort keys %{$tests{$val}}) {
		next if ($test eq 'value');
		my $tv   = $val;
		my $call = 'is_' . $test;
		my $dt   = '%s';
		$result  = &{$call}($tv);
		$result  = ! $result if ( not $tests{$val}->{$test} );
		ok(
		   $result,
		   sprintf($dt . " %s %s %s value (testing: %s)",
				   $val,
				   ($tests{$val}->{$test} ? 'is' : 'is not'),
				   ($test =~ /^[aeiou]/   ? 'an'  : 'a'),
				   $test,
				   $call
		   )
		);
	}
}

# We're done here!
done_testing();