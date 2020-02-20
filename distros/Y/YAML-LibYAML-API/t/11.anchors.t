#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin '$Bin';

use Encode;
use YAML::LibYAML::API;
use YAML::LibYAML::API::XS;
use YAML::PP::Common qw/
    YAML_ANY_SCALAR_STYLE YAML_PLAIN_SCALAR_STYLE
    YAML_SINGLE_QUOTED_SCALAR_STYLE YAML_DOUBLE_QUOTED_SCALAR_STYLE
    YAML_LITERAL_SCALAR_STYLE YAML_FOLDED_SCALAR_STYLE
/;

my @events = (
    { name => 'stream_start_event' },
    { name => 'document_start_event' },
    { name => 'sequence_start_event' },

    { name => 'mapping_start_event', style => 'block', anchor => 1 },
    { name => 'scalar_event', value => 'a', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => 'b', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'mapping_end_event' },

    { name => 'alias_event', value => 1 },

    { name => 'sequence_start_event', style => 'block', anchor => 2 },
    { name => 'scalar_event', value => 'a', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => 'b', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'sequence_end_event' },

    { name => 'alias_event', value => 2 },

    { name => 'scalar_event', value => 'a', style => YAML_PLAIN_SCALAR_STYLE, anchor => 3 },

    { name => 'alias_event', value => 3 },

    { name => 'sequence_end_event' },
    { name => 'document_end_event', implicit => 1 },
    { name => 'stream_end_event' },
);

my $yaml = YAML::LibYAML::API::XS::emit_string_events(\@events, {});

my $exp = <<'EOM';
---
- &1
  a: b
- *1
- &2
  - a
  - b
- *2
- &3 a
- *3
EOM

is($yaml, $exp, 'Dumping numeric anchors works');

done_testing;
