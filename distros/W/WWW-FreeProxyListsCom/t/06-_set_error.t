#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use WWW::FreeProxyListsCom;


my $p = WWW::FreeProxyListsCom->new(timeout => 10);

eval {
    $p->get_list(type => 'ca');
    $p->_set_error($p->{mech}, 'net');

};

if ($@){
    like ($@, qr/Error GETing/, "timeout skip");
}
else {
    like ($p->error, qr/Network error/, "network error ok");
}

eval {
    $p->get_list(type => 'ca');
    $p->_set_error("error");
};

if ($@){
    like ($@, qr/Error GETing/, "timeout skip");
}
else {
   is ($p->error, 'error', "string error ok");
}

done_testing();
