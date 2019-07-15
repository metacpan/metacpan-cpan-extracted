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

my $yaml = <<'EOM';


foo: &ALIAS bar
'alias': *ALIAS
tag: !!int 23
list:
- "doublequoted"
- >
  folded
- |-
  literal
...
%YAML 1.1
---
a: b
EOM

open my $fh, '<',"$Bin/data/simple.yaml" or die $!;
my $file_yaml = do { local $/; <$fh> };
close $fh;


my @exp_events;
subtest parse_string_events => sub {
    my $ev = [];
    YAML::LibYAML::API::parse_string_events($yaml, $ev);

    my @ts = map { YAML::PP::Common::event_to_test_suite($_) } @$ev;
    @exp_events = (
        '+STR',
        '+DOC',
        '+MAP',
        '=VAL :foo',
        '=VAL &ALIAS :bar',
        "=VAL 'alias",
        '=ALI *ALIAS',
        '=VAL :tag',
        '=VAL <tag:yaml.org,2002:int> :23',
        '=VAL :list',
        '+SEQ',
        '=VAL "doublequoted',
        '=VAL >folded\n',
        '=VAL |literal',
        '-SEQ',
        '-MAP',
        '-DOC ...',
        '+DOC ---',
        '+MAP',
        '=VAL :a',
        '=VAL :b',
        '-MAP',
        '-DOC',
        '-STR',
    );
    is_deeply(\@ts, \@exp_events, "parse_events - Test Suite Events match");

    @exp_events = (
        { name => 'stream_start_event',
            start => { line => 0, column => 0 },
            end   => { line => 0, column => 0 },
        },
        { name => 'document_start_event', implicit => 1,
            start => { line => 2, column => 0 },
            end   => { line => 2, column => 0 },
        },
        { name => 'mapping_start_event',
            start => { line => 2, column => 0 },
            end   => { line => 2, column => 0 },
            style => 'block',
        },
        { name => 'scalar_event', style => YAML_PLAIN_SCALAR_STYLE, value => 'foo',
            start => { line => 2, column => 0 },
            end   => { line => 2, column => 3 },
        },
        { name => 'scalar_event', style => YAML_PLAIN_SCALAR_STYLE, value => 'bar', anchor => 'ALIAS',
            start => { line => 2, column => 5 },
            end   => { line => 2, column => 15 },
        },
        { name => 'scalar_event', style => YAML_SINGLE_QUOTED_SCALAR_STYLE, value => 'alias',
            start => { line => 3, column => 0 },
            end   => { line => 3, column => 7 },
        },
        { name => 'alias_event', value => 'ALIAS',
            start => { line => 3, column => 9 },
            end   => { line => 3, column => 15 },
        },
        { name => 'scalar_event', style => YAML_PLAIN_SCALAR_STYLE, value => 'tag',
            start => { line => 4, column => 0 },
            end   => { line => 4, column => 3 },
        },
        { name => 'scalar_event', style => YAML_PLAIN_SCALAR_STYLE, value => '23', tag => 'tag:yaml.org,2002:int',
            start => { line => 4, column => 5 },
            end   => { line => 4, column => 13 },
        },
        { name => 'scalar_event', style => YAML_PLAIN_SCALAR_STYLE, value => 'list',
            start => { line => 5, column => 0 },
            end   => { line => 5, column => 4 },
        },
        { name => 'sequence_start_event',
            start => { line => 6, column => 0 },
            end   => { line => 6, column => 1 },
            style => 'block',
        },
        { name => 'scalar_event', style => YAML_DOUBLE_QUOTED_SCALAR_STYLE, value => 'doublequoted',
            start => { line => 6, column => 2 },
            end   => { line => 6, column => 16 },
        },
        { name => 'scalar_event', style => YAML_FOLDED_SCALAR_STYLE, value => "folded\n",
            start => { line => 7, column => 2 },
            end   => { line => 9, column => 0 },
        },
        { name => 'scalar_event', style => YAML_LITERAL_SCALAR_STYLE, value => "literal",
            start => { line => 9, column => 2 },
            end   => { line => 11, column => 0 },
        },
        { name => 'sequence_end_event',
            start => { line => 11, column => 0 },
            end   => { line => 11, column => 0 },
        },
        { name => 'mapping_end_event',
            start => { line => 11, column => 0 },
            end   => { line => 11, column => 0 },
        },
        { name => 'document_end_event',
            start => { line => 11, column => 0 },
            end   => { line => 11, column => 3 },
        },
        { name => 'document_start_event',
            start => { line => 12, column => 0 },
            end   => { line => 13, column => 3 },
            version_directive => { major => 1, minor => 1 },
        },
        { name => 'mapping_start_event',
            start => { line => 14, column => 0 },
            end   => { line => 14, column => 0 },
            style => 'block',
        },
        { name => 'scalar_event', style => YAML_PLAIN_SCALAR_STYLE, value => "a",
            start => { line => 14, column => 0 },
            end   => { line => 14, column => 1 },
        },
        { name => 'scalar_event', style => YAML_PLAIN_SCALAR_STYLE, value => "b",
            start => { line => 14, column => 3 },
            end   => { line => 14, column => 4 },
        },
        { name => 'mapping_end_event',
            start => { line => 15, column => 0 },
            end   => { line => 15, column => 0 },
        },
        { name => 'document_end_event', implicit => 1,
            start => { line => 15, column => 0 },
            end   => { line => 15, column => 0 },
        },
        { name => 'stream_end_event',
            start => { line => 15, column => 0 },
            end   => { line => 15, column => 0 },
        },
    );
    is_deeply($ev, \@exp_events, "parse_events - Events match");
};

subtest libyaml_version => sub {
    my $libyaml_version = YAML::LibYAML::API::XS::libyaml_version();
    diag "libyaml version = $libyaml_version";
    cmp_ok($libyaml_version, '=~', qr{^\d+\.\d+(?:\.\d+)$}, "libyaml_version ($libyaml_version)");
};

my @exp_file_events = (
    { name => 'stream_start_event',
        start => { line => 0, column => 0 },
        end   => { line => 0, column => 0 },
    },
    { name => 'document_start_event',
        start => { line => 0, column => 0 },
        end   => { line => 0, column => 3 },
    },
    { name => 'mapping_start_event', style => 'block',
        start => { line => 1, column => 0 },
        end   => { line => 1, column => 0 },
    },
    { name => 'scalar_event', value => 'a', style => YAML_PLAIN_SCALAR_STYLE,
        start => { line => 1, column => 0 },
        end   => { line => 1, column => 1 },
    },
    { name => 'scalar_event', value => 'b', style => YAML_PLAIN_SCALAR_STYLE,
        start => { line => 1, column => 3 },
        end   => { line => 1, column => 4 },
    },
    { name => 'mapping_end_event',
        start => { line => 2, column => 0 },
        end   => { line => 2, column => 0 },
    },
    { name => 'document_end_event', implicit => 1,
        start => { line => 2, column => 0 },
        end   => { line => 2, column => 0 },
    },
    { name => 'stream_end_event',
        start => { line => 2, column => 0 },
        end   => { line => 2, column => 0 },
    },
);

subtest parse_file_events => sub {
    my $ev = [];
    YAML::LibYAML::API::parse_file_events("$Bin/data/simple.yaml", $ev);

    is_deeply($ev, \@exp_file_events, "parse_file_events");

    open my $fh, "<", "$Bin/data/simple.yaml" or die $!;

    $ev = [];
    YAML::LibYAML::API::parse_filehandle_events($fh, $ev);
    close $fh;

    is_deeply($ev, \@exp_file_events, "parse_filehandle_events");

};

subtest emit_string_events => sub {

    my $ev = \@exp_events;
    my $dump = YAML::LibYAML::API::emit_string_events($ev);

    $yaml =~ s/^\s+//;
    cmp_ok($dump, 'eq', $yaml, "emit_string_events");

};

subtest emit_file_events => sub {
    my $ev = \@exp_file_events;
    YAML::LibYAML::API::emit_file_events("$Bin/data/simple.yaml.out", $ev);

    open my $fh, "<", "$Bin/data/simple.yaml.out" or die $!;
    my $dump_file_yaml = do { local $/; <$fh> };
    close $fh;
    cmp_ok($dump_file_yaml, 'eq', $file_yaml, "emit_file_events");


    open $fh, ">", "$Bin/data/simple.yaml.out" or die $!;
    YAML::LibYAML::API::emit_filehandle_events($fh, $ev);
    close $fh;

    open $fh, "<", "$Bin/data/simple.yaml.out" or die $!;
    $dump_file_yaml = do { local $/; <$fh> };
    close $fh;
    cmp_ok($dump_file_yaml, 'eq', $file_yaml, "emit_filehandle_events");
};

subtest unicode => sub {
    my $ev = [];
    $yaml = "[ö]";
    YAML::LibYAML::API::parse_string_events($yaml, $ev);
    my $value = encode_utf8 $ev->[3]->{value};
    cmp_ok($value, 'eq', "ö", "utf8 parse");

    $ev->[3]->{value} = decode_utf8 "ä";
    my $dump = YAML::LibYAML::API::emit_string_events($ev);
    cmp_ok($dump, '=~', qr{- "\\xE4"}i, "utf8 emit");

    $ev->[3]->{value} = "\303\274 \303\300";
    $dump = YAML::LibYAML::API::emit_string_events($ev);
    cmp_ok($dump, '=~', qr{- "\\xC3\\xBC \\xC3\\xC0"}i, "binary emit");
};

subtest indent => sub {
    my @events = (
        { name => 'stream_start_event' },
        { name => 'document_start_event' },
        { name => 'mapping_start_event', style => 'block' },
        { name => 'scalar_event', value => 'a', style => YAML_PLAIN_SCALAR_STYLE },
        { name => 'mapping_start_event', style => 'block' },
        { name => 'scalar_event', value => 'b', style => YAML_PLAIN_SCALAR_STYLE },
        { name => 'scalar_event', value => 'c', style => YAML_PLAIN_SCALAR_STYLE },
        { name => 'mapping_end_event' },
        { name => 'mapping_end_event' },
        { name => 'document_end_event', implicit => 1 },
        { name => 'stream_end_event' },
    );

    my $options = { indent => 4 };
    my $dump = YAML::LibYAML::API::emit_string_events(\@events, $options);
    my $exp_yaml = <<'EOM';
---
a:
    b: c
EOM
    cmp_ok($dump, 'eq', $exp_yaml, "Indent 4 emit ok");
};

done_testing;

END {
    unlink "$Bin/data/simple.yaml.out";
}
