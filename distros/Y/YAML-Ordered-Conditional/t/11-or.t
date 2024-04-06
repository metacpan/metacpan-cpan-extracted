use Test::More;

use YAML::Ordered::Conditional;

my $struct = q|
if:
  key: test
  m: test
  or:
    key: test
    m: other
    or:
      key: test
      m: thing
  then:
    abc: 123
|;

my $compiled = YAML::Ordered::Conditional->new->compile($struct, { test => "thing" }, 1);

my $expected = {
	"abc" => 123
};

is_deeply($compiled, $expected);

done_testing;
