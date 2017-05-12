#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Test::More;
use WWW::FreeProxyListsCom;

my $p = WWW::FreeProxyListsCom->new(timeout => 10);

eval {
    my $ca = $p->get_list(type => 'ca');

    my $all = $p->filter;
    is (@$ca, @$all, "no filter results in entire list");

    my $canada = $p->filter(country => 'Canada');
    is (@$canada, @$all, "country filter results in proper count");

    my $ip = $ca->[0]->{ip};
    my $ip_check = @{ $p->filter(ip => $ip) };
    is ($ip_check, 1, "IP filter count is ok");

    my $port_count;
    for my $prox (@$ca) {
        $port_count++ if $prox->{port} eq '3128';
    }
    is (@{ $p->filter(port => '3128') }, $port_count, "string port filter ok");

    $port_count = 0;
    for my $prox (@$ca) {
        $port_count++ if $prox->{port} == 3128;
    }
    is (@{ $p->filter(port => 3128) }, $port_count, "numeric port filter ok");

    my $latency = $p->filter(latency => qr/^\d{3}$/);
    ok (scalar @$latency < scalar @$ca, "latency filter has less entries than all");

#    my $last_test = $p->filter(last_test => qr/(am|pm)/);
#    ok (scalar @$last_test < scalar @$ca, "last_test filter works");

    my $http = $p->filter(is_https => 'false');
    my $https = $p->filter(is_https => 'true');
    ok (scalar @$http < scalar @$ca, "is_http filter works for false");
    ok (scalar @$https < scalar @$ca, "is_http filter works for true");
};

if ($@){
    plan skip_all => "test failure due to timeout";
}

done_testing();
