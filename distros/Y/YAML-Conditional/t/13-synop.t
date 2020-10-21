use Test::More;

use YAML::Conditional;

my $c = YAML::Conditional->new();

my $struct = q|
for:
  country: '{country}'
  each: countries
  else:
    then:
      rank: ~
  elsif:
    key: country
    m: Indonesia
    then:
      rank: 2
  if:
    key: country
    m: Thailand
    then:
      rank: 1
  key: countries
|;

my $compiled = $c->compile($struct, {
	countries => [
		{ country => "Thailand" },
		{ country => "Indonesia" },
		{ country => "Hawaii" },
		{ country => "Canada" },
	]
}, 1);

my $expected = {
	'countries' => [
		{
			'rank' => 1,
			'country' => 'Thailand'
		},
		{
			'rank' => 2,
			'country' => 'Indonesia'
		},
		{
			'country' => 'Hawaii',
			'rank' => undef
		},
		{
			'rank' => undef,
			'country' => 'Canada'
		}
	]
};

is_deeply($compiled, $expected);

done_testing;
