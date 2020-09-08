#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use YAML::LibYAML::API;
use YAML::LibYAML::API::XS;

my $yaml = <<'EOM';
---
- [aaaaaaaaaaaaaaaaa, bbbbbbbbbbbbbbbbbb]
EOM
my $out = <<'EOM';
---
- [aaaaaaaaaaaaaaaaa,
  bbbbbbbbbbbbbbbbbb]
EOM

my $ev = [];
YAML::LibYAML::API::parse_string_events($yaml, $ev);

my $emit = YAML::LibYAML::API::emit_string_events($ev);
is($emit, $yaml, "Emit default width");

my $options = {
    width => 20,
};
$emit = YAML::LibYAML::API::emit_string_events($ev, $options);
is($emit, $out, "Emit width=20");

done_testing;
