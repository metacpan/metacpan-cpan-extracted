use Test::More;

use YAML::Conditional;

my $struct = q|
thing:
  def: 123
  for:
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
    keys: 1
|;

my $compiled = YAML::Conditional->new->compile($struct, {
	testing => { 
		a => { test => "other" },
		b => { test => "test" },
		c => { test => "other" },
		d => { test => "thing" },
	}
}, 1);

my $expected = {
	thing => {
		a => { def => 456 },
		b => { abc => 123 },
		c => { def => 456 },
		d => { ghi => 789 },
		def => 123
	}
};

is_deeply($compiled, $expected);

done_testing;
