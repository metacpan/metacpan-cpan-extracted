#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use utf8;
use YAML::PP::Ref;

my $yaml = <<'EOM';
---
[complex key]: valüe
EOM
my $file = "$Bin/data/file.yaml";
my $expected = {
    "['complex key']" => 'valüe',
};

subtest 'load string' => sub {
    my $ypp = YAML::PP::Ref->new;

    my $data = $ypp->load_string($yaml);
    is_deeply $data, $expected, "Load string";
};

subtest preserve => sub {
    my $ypp = YAML::PP::Ref->new( preserve => 1 );
    $yaml = <<'EOM';
---
 key1: &x value1
 key2: *x
 flowseq: [ 23 ]
 flowmap: { "x": 'y' }
 lit: |
   eral
...
EOM
    my $data = $ypp->load_string($yaml);
    my $dump = $ypp->dump_string($data);
    my $exp_dump = <<'EOM';
---
key1: &x value1
key2: *x
flowseq: [23]
flowmap: {"x": 'y'}
lit: |
  eral
EOM
    is $dump, $exp_dump;
};

subtest 'load file' => sub {
    my $ypp = YAML::PP::Ref->new;
    $expected = {
        "['complex key']" => 'valüe',
    };
    my $data = $ypp->load_file($file);
    is_deeply $data, $expected, "Load file";
};

subtest 'load filehandle' => sub {
    my $ypp = YAML::PP::Ref->new;
    open my $fh, '<:encoding(UTF-8)', $file or die $!;
    my $data = $ypp->load_file($fh);
    close $fh;

    is_deeply $data, $expected, "Load file handle";
};

done_testing;
