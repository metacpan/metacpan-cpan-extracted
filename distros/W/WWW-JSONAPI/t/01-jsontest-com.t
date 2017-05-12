#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use WWW::JSONAPI;
use Data::Dumper;

plan tests => 2;

my $ip = WWW::JSONAPI->new ();
my $ip_hash = $ip->GET_json ('http://ip.jsontest.com');
is (ref($ip_hash), 'HASH');
ok (defined $ip_hash->{ip});
diag 'http://ip.jsontest.com says your IP is ' . $ip_hash->{ip};