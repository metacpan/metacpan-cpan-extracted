#!/usr/bin/perl -w

use strict;

use WWW::Compete;

use constant COMPETE_API_KEY => 'INSERT_KEY_HERE'; 

my $c = WWW::Compete->new({api_key => COMPETE_API_KEY});

$c->fetch("cpan.org");

print "Domain:  ", $c->get_domain(), "\n";
print "YYYY:    ", $c->get_measurement_yr(), "\n";
print "MM:      ", $c->get_measurement_mon(), "\n";
print "Trust:   ", $c->get_trust(), "\n";
print "UV:      ", $c->get_visitors(), "\n";
print "Rank:    ", $c->get_rank(), "\n";
print "Link:    ", $c->get_summary_link(), "\n";
print "UA:      ", $c->ua, "\n";
print "API Ver: ", $c->api_ver(), "\n";
print "API Key: ", $c->api_key(), "\n";

