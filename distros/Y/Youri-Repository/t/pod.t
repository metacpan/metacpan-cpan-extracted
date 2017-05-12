#!/usr/bin/perl
# $Id$

use Test::More;
eval {
    require Test::Pod;
    import Test::Pod;
};
plan(skip_all => 'Test::Pod not installed; skipping') if $@;
plan(skip_all => 'Minimal Test::Pod version 1.14 required; skipping')
    unless $Test::Pod::VERSION >= 1.14;
all_pod_files_ok();
