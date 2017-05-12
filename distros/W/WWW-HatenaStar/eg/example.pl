#!/usr/bin/perl

use strict;
use WWW::HatenaStar;
use YAML;
use Data::Dumper;

sub main {
    my $conf = YAML::LoadFile("config.yaml");
    my $star = WWW::HatenaStar->new({ config => $conf });

    my $uri = "http://blog.woremacx.com/2008/01/shut-the-fuck-up-and-just-be-chaos.html";
    $star->stars({ uri => $uri, count => 5 });
}

main;
