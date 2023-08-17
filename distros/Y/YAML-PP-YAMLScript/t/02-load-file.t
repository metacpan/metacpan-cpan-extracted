use Test::More;

use YAML::PP::YAMLScript;
use YAML::PP;

my $test = -d 't' ? 't' : 'test';

my $ypp = YAML::PP::YAMLScript->new;

my $data = $ypp->load_file("$test/config1.yaml");

my $dump = $ypp->dump_string($data);

is $dump, <<'...', "Loading a YAMLScript YAML file works";
---
entries:
- color: blue
  fast: ''
  size: 43
- color: pink
  cool:
  - 1
  - 2
  - 3
  fast: 1
  size: 42
- color: blue
  fast: ''
  size: 42
- color: blue
  fast: 1
  other: stuff
  size: 42
...

done_testing;
