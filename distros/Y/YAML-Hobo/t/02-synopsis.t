
use Test::More;
use YAML::Hobo;

my $got = YAML::Hobo::Dump(
    {   release => { dist => 'YAML::Tiny', version => '1.70' },
        author  => 'ETHER'
    }
);
my $expected = <<YAML;
---
author: "ETHER"
release:
  dist: "YAML::Tiny"
  version: "1.70"
YAML

is( $got, $expected, "Synopsis code works" );

done_testing;
