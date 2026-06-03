use Test::More tests => 3;

use YAML::Safe;

my $p = {my_key => "When foo or foobar is used, everyone understands that these are just examples, and they dont really exist."};
my $e = <<'YAML';
---
my_key: When foo or foobar is used, everyone understands that these are just examples,
  and they dont really exist.
YAML
is Dump($p), $e, "Long plain scalars wrap at wrapwidth 80";

my $loaded = Load($e);
is_deeply $loaded, $p, "Long wrapped plain scalars roundtrip";

my $no_wrap = YAML::Safe->new;
$no_wrap->wrapwidth(YAML::Safe::NO_WRAP);
my $unwrapped = $no_wrap->Dump($p);
my $expected_unwrapped = <<'YAML';
---
my_key: When foo or foobar is used, everyone understands that these are just examples, and they dont really exist.
YAML
is $unwrapped, $expected_unwrapped, "Plain scalars don't wrap with high wrapwidth";
