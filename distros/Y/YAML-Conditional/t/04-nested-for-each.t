use Test::More;

use YAML::Conditional;

my $struct = q|
thing:
  def: 123
  for:
    each: abc
    else:
      then:
        ghi: 789
    elsif:
      key: test
      m: other
      then:
        def: 456
    if:
      key: test
      m: test
      then:
        abc: 123
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
	thing => {
		abc => [
			{ def => 456 },
			{ abc => 123 },
			{ def => 456 },
			{ ghi => 789 },
		],
		def => 123
	}
};

is_deeply($compiled, $expected);

done_testing;
