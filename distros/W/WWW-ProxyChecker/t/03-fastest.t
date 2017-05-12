#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use WWW::FreeProxyListsCom;
use WWW::ProxyChecker;
use Test::More;

my $p = WWW::FreeProxyListsCom->new(timeout => 10);
my $checker = WWW::ProxyChecker->new;

$p->get_list(type => 'us');

my $prox_list;

eval { $prox_list = $p->filter(is_https => 'false'); };

if ($@){
    plan skip_all => "timeout occurred, skipping";
}

@$prox_list = @$prox_list[0..15];

my @data;

for (@$prox_list){
    next if ! $_->{ip};
    push @data, join '', 'http://', join ':', @$_{qw(ip port)};
}

$checker->check(\@data);

my $fastest = $checker->fastest;

if (! @$fastest){
    plan skip_all => "nothing returned, skipping";
}

for (@$fastest){
    like ($_, qr/.*:\d+/, "$_ appears sane");
}

done_testing();

__END__
my @list;

$SIG{__WARN__} = sub {
    my $w = shift;
    if ($w =~ /.*::\s+\d+\.\d{2}/){
        push @list, $w;
    }
};

if (! @list){
    plan skip_all => "nothing caught, skipping";
}

my @times;

for (@list){
    my ($p, $t) = split /\s+::\s+/;

    like ($p, qr/.*:\d+/, "$p appears sane");
    like ($t, qr/\d+\.\d{2}/, "$t appears sane");

    push @times, $t;
}

if (! @times){
    plan skip_all => "nothing caught, skipping";
}

my @check;

for (@times){
    @check = sort { $a <=> $b } @times;
}

if (! @check){
    plan skip_all => "nothing caught, skipping";
}

my $i = 0;
for (@check){
    is ($times[$i], $check[$i], "time is in order");
}
done_testing();
