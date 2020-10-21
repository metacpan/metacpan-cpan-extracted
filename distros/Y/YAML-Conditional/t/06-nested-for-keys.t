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
    extend: 1
    if:
      key: test
      m: test
      then:
        abc: 123
    key: testing
    keys: nested
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
		nested => {
			a => { 
				def => 456,
				extend => 1
			},
			b => { 
				abc => 123, 
				extend => 1
			},
			c => { 
				def => 456, 
				extend => 1
			},
			d => { 
				ghi => 789,
				extend => 1
			}
		},
		def => 123
	}
};

is_deeply($compiled, $expected);

done_testing;
