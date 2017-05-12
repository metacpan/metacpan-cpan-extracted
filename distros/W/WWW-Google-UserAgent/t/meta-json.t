#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use WWW::Google::UserAgent;
use Test::More;

eval "use Test::CPAN::Meta::JSON";
plan skip_all => "Test::CPAN::Meta::JSON required for testing MYMETA.json" if $@;

my $meta    = meta_spec_ok('MYMETA.json');
my $version = $WWW::Google::UserAgent::VERSION;

is($meta->{version},$version, 'MYMETA.json distribution version matches');

if($meta->{provides}) {
    for my $mod (keys %{$meta->{provides}}) {
        is($meta->{provides}{$mod}{version}, $version, "MYMETA.json entry [$mod] version matches");
    }
}

done_testing();
