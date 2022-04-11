#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';

use YAML::LibYAML::API;
use YAML::LibYAML::API::XS;
use YAML::PP::Common qw/
    YAML_PLAIN_SCALAR_STYLE YAML_BLOCK_SEQUENCE_STYLE
/;

my $yaml = <<'EOM';
---
- a
...
%TAG !foo! !bar-
---
- b
EOM

my @exp_events = (
    { name => 'stream_start_event' },

    {
        name => 'document_start_event',
    },
    { name => 'sequence_start_event', style => YAML_BLOCK_SEQUENCE_STYLE },
    { name => 'scalar_event', value => 'a', style => YAML_PLAIN_SCALAR_STYLE },
    { name => 'sequence_end_event' },
    { name => 'document_end_event' },

    {
        name => 'document_start_event',
        tag_directives => [
            { handle => '!foo!', prefix => '!bar-' }
        ],
    },
    { name => 'sequence_start_event', style => YAML_BLOCK_SEQUENCE_STYLE },
    { name => 'scalar_event', value => 'b', style => YAML_PLAIN_SCALAR_STYLE },
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
};

done_testing;
