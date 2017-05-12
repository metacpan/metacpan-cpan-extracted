#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.07";
plan skip_all => "Test::Pod::Coverage 1.07 required for testing POD coverage" if $@;
eval "use Pod::Coverage::Moose";
plan skip_all => "Pod::Coverage::Moose is required for testing POD coverage" if $@;

my @modules = all_modules('lib/VCI/Abstract');
push(@modules, 'VCI', 'VCI::Util');

plan tests => scalar(@modules) - 1;

my %mod_private = (
    # These are actually internal functions, I see no reason to doc them yet.
    'VCI' => [qr/_class$/, 'CLASS_BASE'],
    # "Project" really comes from Committable, and so doesn't need docs.
    'VCI::Abstract::Commit' => [qr/^project$/],
);

foreach my $module (@modules) {
    next if $module eq 'VCI::Abstract::ProjectItem';
    my @also_private = (qr/^has_/, qr/^clear_/, qr/^BUILD$/);
    push(@also_private, @{ $mod_private{$module} }) if $mod_private{$module};
    pod_coverage_ok($module, { coverage_class => 'Pod::Coverage::Moose',
                               also_private =>  \@also_private });
}
