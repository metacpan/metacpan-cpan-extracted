#!/usr/bin/env perl
use strict;
use warnings;

use lib qw(../lib  lib);
use Data::Dumper;
use WWW::FreeProxyListsCom;

my $prox = WWW::FreeProxyListsCom->new( debug => 1 );

my $ref = $prox->get_list( type => 'elite' );

#print "Got a list of " . @$ref . " proxies\nFiltering...\n";

$ref = $prox->filter( port => qr/(80){1,2}/ );

#print "Filtered list contains: " . @$ref . " proxies\n"
#        . join "\n", map( "$_->{ip}:$_->{port}", @$ref), '';

print join "\n", map { "$_->{ip}:$_->{port}" } @$ref;


