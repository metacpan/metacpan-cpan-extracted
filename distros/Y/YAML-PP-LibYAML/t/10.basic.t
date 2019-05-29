#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use FindBin '$Bin';
use YAML::PP;
use YAML::PP::LibYAML;
use YAML::PP::LibYAML::Parser;

my $events = [];
my $yaml = <<'EOM';
foo: &X bar
k: !!int "23"
FOO: *X
flow: { "a":23 }
EOM


my $yp = YAML::PP::LibYAML->new;

my $data = $yp->load_string($yaml);
my $expected = {
    foo => 'bar',
    k => 23,
    FOO => 'bar',
    flow => { a => 23 },
};
is_deeply($data, $expected, "load_string data like expected");

$yaml = <<'EOM';
foo: "bar"
 x: y
EOM
eval {
    $data = $yp->load_string($yaml);
};
my $error = $@;
cmp_ok($error, '=~', qr{did not find expected key}, "Invalid YAML - expected error message");

my $file = "$Bin/data/simple.yaml";
$data = $yp->load_file($file);
$expected = { a => "b" };
is_deeply($data, $expected, "load_file data like expected");

open my $fh, '<', $file or die $!;
$data = $yp->load_file($fh);
close $fh;
is_deeply($data, $expected, "load_file(filehandle) data like expected");


$data = { a => 'b' };
$yaml = <<'EOM';
---
a: b
EOM
my $dump = $yp->dump_string($data);
cmp_ok($dump, 'eq', $yaml, "dump_string");

$yp->dump_file("$Bin/data/simple.yaml.out", $data);
open $fh, '<', "$Bin/data/simple.yaml.out" or die $!;
$dump = do { local $/; <$fh> };
close $fh;
cmp_ok($dump, 'eq', $yaml, "dump_file");

open $fh, '>', "$Bin/data/simple.yaml.out" or die $!;
$yp->dump_file($fh, $data);
close $fh;

open $fh, '<', "$Bin/data/simple.yaml.out" or die $!;
$dump = do { local $/; <$fh> };
close $fh;
cmp_ok($dump, 'eq', $yaml, "dump_file(filehandle)");

subtest options => sub {
    my $yp = YAML::PP::LibYAML->new(
        indent => 4,
        header => 0,
        footer => 1,
    );
    $data = { x => 1, y => { z => 2 } };
    $dump = $yp->dump_string($data);
    my $exp = <<'EOM';
x: 1
y:
    z: 2
...
EOM
    cmp_ok($dump, 'eq', $exp, "dump with options");
};

done_testing;

END {
    unlink "$Bin/data/simple.yaml.out";
}
