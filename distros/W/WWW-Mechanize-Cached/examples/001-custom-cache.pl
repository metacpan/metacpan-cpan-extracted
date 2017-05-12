#!/usr/bin/perl

use strict;
use warnings;

use WWW::Mechanize::Cached;
use CHI;

my $cache = CHI->new(
    driver   => 'File',
    root_dir => '/tmp/mech-example'
);

my $mech = WWW::Mechanize::Cached->new( cache => $cache );
$mech->get("http://www.google.com");

print $mech->content;

