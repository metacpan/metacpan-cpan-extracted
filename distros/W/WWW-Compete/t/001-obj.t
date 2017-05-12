#!/usr/bin/perl -w
#
use strict;

use Test::More tests => 6;

use WWW::Compete;

my $c = WWW::Compete->new( api_key => 'abc123',
                           debug => 1 );
ok( defined $c, 'new() returned something' );
ok( $c->isa('WWW::Compete'), "and it's the right class" );
ok( $c->{_ua}->isa('LWP::UserAgent'), 'got an LWP::UserAgent in my pocket' );

is( $c->api_key(), 'abc123', '  create with api_key' );

is( $c->api_ver(), 3,        '  default api_ver()' );
$c->api_ver(42);
is( $c->api_ver(), 42,       '  set/get api_ver()' );


