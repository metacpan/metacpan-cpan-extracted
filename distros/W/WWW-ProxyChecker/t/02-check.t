#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use WWW::FreeProxyListsCom;
use WWW::ProxyChecker;
use Test::More;

my $p = WWW::FreeProxyListsCom->new(timeout => 10);
my $checker = WWW::ProxyChecker->new(debug => 1);

$p->get_list(type => 'https');

my $prox_list;

eval { $prox_list = $p->filter(latency => qr/\d{2}$/); };

if ($@){
    plan skip_all => "timeout occurred, skipping";
}

is (ref $prox_list, 'ARRAY', "proxy list ok");

@$prox_list = @$prox_list[0..15];

my @data;

{
    my $warning;
    $SIG{__WARN__} = sub { $warning = shift; };

    for (@$prox_list) {
        push @data, join '', 'http://', join ':', @$_{qw(ip port)};
    }

    for (@{ $checker->check(\@data) }){
        warn "$_ is alive\n";
    }

    like ($warning, qr/alive|Failed/, "check with debug ok");
}
done_testing();
