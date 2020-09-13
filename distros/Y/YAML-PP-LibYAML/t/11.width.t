#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use YAML::PP::LibYAML;
use YAML::PP::Common qw/ PRESERVE_FLOW_STYLE /;

my $yp = YAML::PP::LibYAML->new(
    preserve => PRESERVE_FLOW_STYLE,
);

my $yaml = <<'EOM';
---
- [aaaaaaaaaaaaaaaaa, bbbbbbbbbbbbbbbbbb]
EOM
my $out = <<'EOM';
---
- [aaaaaaaaaaaaaaaaa,
  bbbbbbbbbbbbbbbbbb]
EOM

my $data = $yp->load_string($yaml);
my $dump = $yp->dump_string($data);

is($dump, $yaml, "Dump with default width");

$yp = YAML::PP::LibYAML->new(
    preserve => PRESERVE_FLOW_STYLE,
    width => 20,
);

$dump = $yp->dump_string($data);
is($dump, $out, "Dump with width=20");

done_testing;
