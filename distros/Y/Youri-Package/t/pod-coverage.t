#!/usr/bin/perl
# $Id$

use strict;
use warnings;
use Test::More;
use UNIVERSAL::require;

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    unless $ENV{TEST_AUTHOR};

eval "use Test::Pod::Coverage 1.04";
plan(skip_all => 'Test::Pod::Coverage >= 1.04 required, skipping') if $@;

my @modules = all_modules('lib');

if (!RPM4->require()) {
    @modules = grep { ! /RPM::RPM4$/ } @modules;
}

if (!RPM->require()) {
    @modules = grep { ! /RPM::RPM$/ } @modules;
}

plan tests => scalar @modules;

foreach my $module (@modules) {
    pod_coverage_ok(
        $module,
        {
            coverage_class => 'Pod::Coverage::CountParents',
        }
    );
}
