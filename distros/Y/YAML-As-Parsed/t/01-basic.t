use Test::More;

use YAML::As::Parsed;

my $string = q|---
one: two
three: four
Foo: Bar
empty: ~
|;

# Open the config
my $yaml = YAML::As::Parsed->read_string( $string );

my @ordered = map { %{ $_ } } @{ $yaml };

is($ordered[0], 'one');
is($ordered[1], 'two');
is($ordered[-2], 'empty');
is($ordered[-1], undef);


$string = q|---
- one: two
  three: four
  Foo: Bar
  empty: ~
- one: two
  three: four
  Foo: Bar
  empty: ~
|;
$yaml = YAML::As::Parsed->read_string( $string );

my @array = map { %{ $_ } } @{ $yaml->[0] };

is($array[0], 'one');
is($array[1], 'two');
is($array[-2], 'empty');
is($array[-1], undef);

$string = q|---
- one: two
  three: four
  Foo: Bar
  empty: ~
  nested: 
    - one: two
      three: four
      Foo: Bar
      empty: ~
      nested:
        - one: two
          three: four
          Foo: Bar
          empty: ~
- one: two
  three: four
  Foo: Bar
  empty: ~
  hash: 
    one: okay
    two:
      three: 1
|;

$yaml = YAML::As::Parsed->read_string( $string );

ok($yaml);

my @array2 = map { %{ $_ } } @{ $yaml->[0] };

is_deeply($array2[-1], {
    'one' => 'okay',
    'two' => {
       'three' => '1'
     }
});



done_testing();
