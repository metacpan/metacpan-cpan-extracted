use Test::More;

BEGIN {
	use strict;
	use warnings;
	no  strict 'refs';
    use_ok( 'Zeta::Util', ':STRING' ) || BAIL_OUT('Failed to use Zeta::Util with :STRING');
}

my %tests = (
	1 => {
		value    => undef,
		is_empty => 1,
		is_blank => 1,
		no_undef => '',
	},
	2 => {
		value    => '',
		is_empty => 1,
		is_blank => 1,
		no_undef => '',
	},
	3 => {
		value    => ' ',
		is_empty => 0,
		is_blank => 1,
		no_undef => ' ',
	},
	4 => {
		value    => "\t",
		is_empty => 0,
		is_blank => 1,
		no_undef => "\t",
	},
	5 => {
		value    => " \t\t ",
		is_empty => 0,
		is_blank => 1,
		no_undef => " \t\t ",
	},
	6 => {
		value    => 'abc',
		is_empty => 0,
		is_blank => 0,
		no_undef => 'abc',
	},
);

foreach my $seq (sort keys %tests) {
	foreach my $test (sort keys %{$tests{$seq}}) {
		next if ($test eq 'value');
		my $result = &{$test}($tests{$seq}->{'value'});
		if ($test eq 'no_undef') {
			is($result, $tests{$seq}->{$test}, 'no_undef()');
		} else {
			$result = ! $result if ( not $tests{$seq}->{$test} );
			ok($result, "${test}()");
		}
	}
}

# We're done here!
done_testing();

