
use Test::More 0.88;
use YAML::Hobo;

my $got = YAML::Hobo::Dump(
    {   false => 1,
        null  => 2,
        true  => 3
    }
);
my $expected = <<YAML;
---
"false": 1
"null": 2
"true": 3
YAML

is( $got, $expected, "Special strings get quoted" );

done_testing;
