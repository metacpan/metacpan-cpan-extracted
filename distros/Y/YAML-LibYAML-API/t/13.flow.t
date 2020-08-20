#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin '$Bin';

use YAML::LibYAML::API;
use YAML::LibYAML::API::XS;

my $yaml = <<'EOM';
---
- []
- [a, b]
- [a, [b], c]
---
- {}
- {a: b}
- {a: b, c: d}
---
- {a: [b], c: {d: f}}
EOM

my @yaml = split qr{^---\n}m, $yaml;

for my $i (0 .. $#yaml) {
    my $input = $yaml[ $i ];
    next unless length $input;

    my $ev = [];
    YAML::LibYAML::API::parse_string_events($input, $ev);

    my $emit = YAML::LibYAML::API::emit_string_events($ev);
    is($emit, $input, "[$i] emit equals input");
}

done_testing;
