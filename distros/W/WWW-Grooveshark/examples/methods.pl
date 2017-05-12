#!/usr/bin/perl

use warnings;
use strict;

use WWW::Grooveshark;

# specify an API key to try this example or pass in on the command line
my $api_key = shift || 'deadbeef';

my $gs = WWW::Grooveshark->new;

my $r;
$r = $gs->session_start(apiKey => $api_key) or do {
	printf STDERR "ERROR: " . $r->fault_line;
	exit(1);
};

my @methods = $gs->service_getMethods->methods;
for(sort {$a->{method} cmp $b->{method}} @methods) {
	my $method_name = $_->{method};
	my @parameters = @{$_->{parameters}};
	printf("%s(%s)\n", $method_name, join(", ", @parameters));
}
