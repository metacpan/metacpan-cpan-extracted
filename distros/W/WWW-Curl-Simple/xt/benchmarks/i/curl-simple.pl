#!/usr/bin/perl

use WWW::Curl::Simple;

my $curl = WWW::Curl::Simple->new();

my $res = $curl->get('http://www.google.com/');
