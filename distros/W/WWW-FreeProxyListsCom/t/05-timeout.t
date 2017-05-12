#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Test::More;
use WWW::FreeProxyListsCom;

{
    eval {
        my $p = WWW::FreeProxyListsCom->new(timeout => '0.0000001');
        my $elite = $p->get_list();
    };
    if ($@){
        like ($@, qr/Error GETing/, "timeout ok");
    }
}
{
    my $ca;

    eval {
        my $p = WWW::FreeProxyListsCom->new(timeout => 10);
        $ca = $p->get_list(type => 'ca');
    };
    if ($@){
        like ($@, qr/Error GETing/, "timeout broken, but we've skipped");
    }
    else {
        is (ref $ca->[1], 'HASH', "timeout ok, we got success");
    }
}

done_testing();
