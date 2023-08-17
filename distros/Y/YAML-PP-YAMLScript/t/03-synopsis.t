use Test::More;

use YAML::PP::YAMLScript;
use YAML::PP;

my $test = -d 't' ? 't' : 'test';

my $ypp = YAML::PP::YAMLScript->new;
my $data = $ypp->load_file("$test/data.yaml");
my $dump = $ypp->dump_string($data);

is $dump, <<'...', "Synopsis file works";
---
foo:
- 1
- 2
- 3
...


done_testing;
