#!/usr/bin/perl -w

use Test::More;

use strict;

$| = 1;

eval "use Test::Pod 0.95";
eval "use File::Spec" unless $@;
eval "use File::Find" unless $@;

if ($@) {
    plan 'skip_all', 'File::Spec, File::Find, and Test::Pod 0.95 required for testing POD';
} else {
    Test::Pod->import;
    my @files;
    my $blib = File::Spec->catfile(qw(blib lib));
    my $warning_thwarter = $File::Find::name;
    find( sub { push @files, $File::Find::name if /\.p(l|m|od)$/ }, $blib);
    plan 'tests', scalar @files;
    pod_file_ok($_) foreach (@files);
}

