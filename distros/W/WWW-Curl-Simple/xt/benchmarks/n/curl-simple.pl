#!/usr/bin/perl

use WWW::Curl::Simple;

my $n = shift || 10;

while ($n) {

    my $curl = WWW::Curl::Simple->new();

    my $res = $curl->get('http://localhost/');
 
    $n--;
}
