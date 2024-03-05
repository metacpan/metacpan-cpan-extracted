#!/usr/bin/env perl

use 5.006;
use strict; use warnings;
use WWW::Google::CustomSearch;
use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing MYMETA.yml" if $@;

my $meta    = meta_spec_ok('MYMETA.yml', undef, @_);
my $version = $WWW::Google::CustomSearch::VERSION;

is($meta->{version},$version, 'MYMETA.yml distribution version matches');

if($meta->{provides}) {
    for my $mod (keys %{$meta->{provides}}) {
        is($meta->{provides}{$mod}{version}, $version, "MYMETA.yml entry [$mod] version matches");
    }
}

done_testing();
