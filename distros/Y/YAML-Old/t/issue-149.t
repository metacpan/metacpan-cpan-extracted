use Test::More;
use YAML::Old;

YAML::Old::Load("a: b");
YAML::Old::Load("a:\n  b: c");
YAML::Old::Load("a: b\nc: d");

pass "YAML w/o final newlines loads";

done_testing;
