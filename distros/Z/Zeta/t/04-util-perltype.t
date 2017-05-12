#!perl

use Test::More;

BEGIN {
	use strict;
	use warnings;
	no  strict 'refs';
    use_ok( 'Zeta::Util', ':PERLTYPE' ) || BAIL_OUT('Failed to use Zeta::Util with :PERLTYPE');
}

# declare variables
my $result;
my @result;
my %result;

my %tests = (
	1 => { 
		value   => 1,
		float   => 0,
		int     => 1,
		string  => 0,
	},
	'0.02' => {
		value   => 0.02,
		float   => 1,
		int     => 0,
		string  => 0,
	},
	'3.00' => {
		value   => 3.00,
		float   => 1,
		int     => 0,
		string  => 0,
		skip    => 1,
	},
	'4.00' => {
		value   => '4.00',
		float   => 1,
		int     => 0,
		string  => 0,
		skip    => 1,
	},
	5 => {
		value  => 5,
		float  => 0,
		int    => 1,
		string => 0,
	},
	'test' => {
		value   => 'test',
		float   => 0,
		int     => 0,
		string  => 1
	},
);

foreach my $val (sort keys %tests) {
	foreach my $test (sort keys %{$tests{$val}}) {
		next if (($test eq 'value') or ($test eq 'skip'));
		my $tv   = undef;
		if (($val !~ /[^0-9.]/) and ($val =~ /\./)) {
			$tv = $val + 0.0;
		} elsif (($val !~ /[^0-9.]/) and ($val !~ /\./)) {
			$tv = $val + 0;
		} else {
			$tv = $val;
		}
		my $call = 'is_type_' . $test;
		my $dt   = '%s';
		$result  = &{$call}($tv);
		$result  = ! $result if ( not $tests{$val}->{$test} );
		SKIP: {
			skip "Floats with all 0s for decimals can be unpredictable", 1 if ($tests{$val}->{'skip'});
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
}

# We're done here!
done_testing();
