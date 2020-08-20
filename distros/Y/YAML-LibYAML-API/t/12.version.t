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
    YAML_FLOW_MAPPING_STYLE YAML_BLOCK_MAPPING_STYLE
    YAML_FLOW_SEQUENCE_STYLE YAML_BLOCK_SEQUENCE_STYLE
/;

my $yaml = <<'EOM';
z: 1
a: 2
y: YES
b: 0b10
x:
    y: z
...
%YAML 1.2
--- &yes
- YES
- 0b10
- *yes
EOM

my $exp = <<'EOM';
z: 1
a: 2
y: YES
b: 0b10
x:
    y: z
...
%YAML 1.2
--- &yes
- YES
- 0b10
- *yes
EOM

my @exp_events = (
    { name => 'stream_start_event' },
    { name => 'document_start_event', implicit => 1 },
    { name => 'mapping_start_event', style => YAML_BLOCK_MAPPING_STYLE, },

    { name => 'scalar_event', value => 'z', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => '1', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => 'a', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => '2', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => 'y', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => 'YES', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => 'b', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => '0b10', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => 'x', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'mapping_start_event', style => YAML_BLOCK_MAPPING_STYLE, },
    { name => 'scalar_event', value => 'y', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => 'z', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'mapping_end_event' },
    { name => 'mapping_end_event' },

    { name => 'document_end_event' },

    {
        name => 'document_start_event',
        version_directive => { major => 1, minor => 2 },
    },

    { name => 'sequence_start_event', style => YAML_BLOCK_SEQUENCE_STYLE, anchor => 'yes' },
    { name => 'scalar_event', value => 'YES', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'scalar_event', value => '0b10', style => YAML_PLAIN_SCALAR_STYLE },

    { name => 'alias_event', value => 'yes' },
    { name => 'sequence_end_event' },

    { name => 'document_end_event', implicit => 1 },
    { name => 'stream_end_event' },
);

subtest parse_string_events => sub {
    my $ev = [];
    YAML::LibYAML::API::parse_string_events($yaml, $ev);

    my @ts = map { YAML::PP::Common::event_to_test_suite($_) } @$ev;
    delete $_->{end}, delete $_->{start} for @$ev;
    is_deeply($ev, \@exp_events, "parse_events - Test Suite Events match") or
        do { diag $_ for @ts };

    my $options = { indent => 4 };
    my $emit = YAML::LibYAML::API::emit_string_events($ev, $options);
    cmp_ok($emit, 'eq', $exp, 'Emitted doc like expected');
};

done_testing;

