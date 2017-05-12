#!/usr/bin/perl
# $Id$

use Test::More;
eval {
    require Test::Pod::Coverage;
    import Test::Pod::Coverage;
};
plan(skip_all => 'Test::Pod::Coverage not installed; skipping') if $@;
plan(skip_all => 'Minimal Test::Pod::Coverage version 1.04 required; skipping')
    unless $Test::Pod::Coverage::VERSION >= 1.04;
all_pod_coverage_ok(
    { coverage_class => 'Pod::Coverage::CountParents' }
);
