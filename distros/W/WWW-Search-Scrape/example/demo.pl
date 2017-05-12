#/usr/bin/perl 
use strict;
use warnings;

use WWW::Search::Scrape qw/:all/;
my $result = search({engine => 'google', keyword =>'keywords', results => 10});
print "Google returns " . $result->{num} . " results\n";
print $_, "\n" foreach (@{$result->{results}});
