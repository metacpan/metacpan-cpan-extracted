use Test::More;

use YAML::Conditional;

my $struct = q|
for:
  abc: 123
  each: testing
  key: testing
|;

my $compiled = YAML::Conditional->new->compile($struct, {
	testing => [ 
		{ test => "other" },
		{ test => "test" },
		{ test => "other" },
		{ test => "thing" },
	]
}, 1);

my $expected = {
	testing => [
		{ abc => 123 },
		{ abc => 123 },
		{ abc => 123 },
		{ abc => 123 },
	]
};

is_deeply($compiled, $expected);

done_testing;
