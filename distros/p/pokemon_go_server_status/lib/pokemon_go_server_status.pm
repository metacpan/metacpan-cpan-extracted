package pokemon_go_server_status;

use warnings;
use strict;

our $VERSION = 1.00;

use WWW::Mechanize::Timed;

use Exporter 'import';
our @EXPORT = qw( get_server_status );

sub get_server_status {
    my $ua = WWW::Mechanize::Timed->new();
    my $result;
    eval {
	$ua->get('https://pgorelease.nianticlabs.com/plfe/');
	if ($ua->client_elapsed_time < 3) {
	    $result = 'Go! catch them all!';
	} else {
	    $result = 'Servers are down, go back to work';
	}
	1;
    } or do {
	$result = 'Go! Cacth them all!';
    };
    $result
}

1;
