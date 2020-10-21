use Test::More;

use YAML::Conditional;

my $struct = q|
for:
  abc: 123
  each: testing
  key: testing
  remap: '{test}'
nested:
  nested:
    other: '{testing}'
other: '{testing}'
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
	other => [ 
		{ test => "other" },
		{ test => "test" },
		{ test => "other" },
		{ test => "thing" },
	],
	nested => {
		nested => {
			other => [ 
				{ test => "other" },
				{ test => "test" },
				{ test => "other" },
				{ test => "thing" },
			]
		}
	},
	testing => [
		{ abc => 123, remap => "other" },
		{ abc => 123, remap => "test" },
		{ abc => 123, remap => "other" },
		{ abc => 123, remap => "thing" },
	]
};

is_deeply($compiled, $expected);

done_testing;
