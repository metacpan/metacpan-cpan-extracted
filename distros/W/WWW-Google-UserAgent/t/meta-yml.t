#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use WWW::Google::UserAgent;
use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing MYMETA.yml" if $@;

my $meta    = meta_spec_ok('MYMETA.yml');
my $version = $WWW::Google::UserAgent::VERSION;

is($meta->{version},$version, 'MYMETA.yml distribution version matches');

if($meta->{provides}) {
    for my $mod (keys %{$meta->{provides}}) {
        is($meta->{provides}{$mod}{version}, $version, "MYMETA.yml entry [$mod] version matches");
    }
}

done_testing();
