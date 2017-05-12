#!/usr/bin/perl

use strict;
use warnings;

use WWW::Alexa::API;

use Data::Dumper;

my ($domain_url) = @ARGV;

my $ip_address  = $ENV{'REMOTE_ADDR'};

my $alexa = WWW::Alexa::API->new(ip_address=>$ip_address);
my $alexa_response = $alexa->get($domain_url);
my $alexa_rank = 'UNRANKED';
$alexa_rank = $alexa_response->{SD}[1]->{POPULARITY}->{-TEXT} if $alexa_response->{SD}[1];

my $dmoz_bool = 0;
$dmoz_bool = 1 if (defined $alexa_response->{DMOZ});