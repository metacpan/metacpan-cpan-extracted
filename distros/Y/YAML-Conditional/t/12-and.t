use Test::More;

use YAML::Conditional;

my $struct = q|
if:
  and:
    and:
      key: tester
      m: thing
    key: testing
    m: other
  key: test
  m: test
  then:
    abc: 123
|;

my $compiled = YAML::Conditional->new->compile($struct, { test => "test", testing => "other", tester => "thing" }, 1);

my $expected = {
	"abc" => 123
};

is_deeply($compiled, $expected);

done_testing;
