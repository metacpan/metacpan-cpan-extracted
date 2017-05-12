#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

my @modules = grep { $_ ne 'MMM::Config' } all_modules();

my %testpod = (
    'MMM::Sync::Rsync' => { coverage_class => 'Pod::Coverage::CountParents' },
    'MMM::Sync::Ftp' => { coverage_class => 'Pod::Coverage::CountParents' },
    'MMM::Sync::Dummy' => { coverage_class => 'Pod::Coverage::CountParents' },
    'MMM::Report' => { coverage_class => 'Pod::Coverage::CountParents' },
    'MMM::Report::Html' => { coverage_class => 'Pod::Coverage::CountParents' },
    'MMM::Report::Console' => { coverage_class => 'Pod::Coverage::CountParents' },
    'MMM::Report::Mail' => { coverage_class => 'Pod::Coverage::CountParents' },
    'MMM::Daemon' => { coverage_class => 'Pod::Coverage::CountParents' },
    'MMM::Batch' => { coverage_class => 'Pod::Coverage::CountParents' },
    'MMM::Queue' => { coverage_class => 'Pod::Coverage::CountParents' },
);

plan tests => scalar(@modules);

foreach (@modules) {
    pod_coverage_ok($_, $testpod{$_});
}

