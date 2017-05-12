package DBIx::dbMan::Extension::SuggestionCacheStore;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000096-000001"; }

sub preference { return 0; }

sub known_actions { return [ qw/CACHE/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;

	if ($action{action} eq 'CACHE' and $action{oper} eq 'complete' and $action{what} eq 'list') {
		$action{action} = 'NONE';

		my $local_mempool = $obj->{-dbi}->mempool();
		my $cache_type = $action{cache_type} || 'generic';

		if ( $local_mempool and $local_mempool->get('suggestion_cache') ) {
			$local_mempool->set('suggestion_cache_content:' . $cache_type, $action{list});
		}

		delete $action{processed};
	}

	return %action;
}
