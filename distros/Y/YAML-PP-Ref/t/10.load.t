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

my $ypp = YAML::PP::Ref->new;

my $data = $ypp->load_string($yaml);
is_deeply $data, $expected, "Load string";

$data = $ypp->load_file($file);
is_deeply $data, $expected, "Load file";

open my $fh, '<:encoding(UTF-8)', $file or die $!;
$data = $ypp->load_file($fh);
close $fh;

is_deeply $data, $expected, "Load file handle";

done_testing;
