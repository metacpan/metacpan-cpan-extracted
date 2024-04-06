use Test::More;

use YAML::Ordered::Conditional;

my $struct = q|
given:
  default:
    ghi: 789
  key: test
  when:
  - m: test
    then:
      abc: 123
  - m: other
    then:
      def: 456
overlord: 1
|;


my $compiled = YAML::Ordered::Conditional->new->compile($struct, { 
	test => "other", 
	again => "yay" 
}, 1);

my $hash = {
	overlord => 1,
	def => 456,
};

is_deeply($compiled, $hash);

$compiled = YAML::Ordered::Conditional->new->compile($struct, { 
	test => "again", 
	again => "yay" 
}, 1);

$hash = {
	overlord => 1,
	ghi => 789,
};
is_deeply($compiled, $hash);

done_testing;
