package DBIx::dbMan::Extension::SuggestionCacheRetrieve;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000098-000001"; }

sub preference { return 6000; }

sub known_actions { return [ qw/SQL DESCRIBE/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;

	if ($action{action} eq 'SQL' && $action{oper} eq 'complete' and $action{what} eq 'list') {
		my $local_mempool = $obj->{-dbi}->mempool();

		my $cache_type = '';
		if ( $obj->{-dbi}->driver eq 'Oracle' ) {
			if ($action{context} =~ /\./) {
				$cache_type = 'sql_oracle_' . $action{type} . '___' . $action{context};
			} else {
				$cache_type = 'sql_oracle_' . $action{type};
			}
		} else {
			my $type = $action{type};
			$type = 'object' if lc $action{type} eq 'context';
			$cache_type = 'sql_type_' . lc( $type );
		}

		if ( $local_mempool and $local_mempool->get( 'suggestion_cache' ) ) {
			my $list = $local_mempool->get('suggestion_cache_content:' . $cache_type);
			if ( $list ) {
				$action{list} = [ @$list ];	# do copy (for sure)
				$action{processed} = 1;
				$action{action} = 'NONE';
			}
		}
	} elsif ($action{action} eq 'DESCRIBE' && $action{oper} eq 'complete' and $action{what} eq 'list') {
		my $local_mempool = $obj->{-dbi}->mempool();

		my $cache_type = '';
		if ( $obj->{-dbi}->driver eq 'Oracle' ) {
			$cache_type = 'describe_ora';
		} else {
			$cache_type = 'describe_std';
		}

		if ( $local_mempool and $local_mempool->get( 'suggestion_cache' ) ) {
			my $list = $local_mempool->get('suggestion_cache_content:' . $cache_type);
			if ( $list ) {
				$action{list} = [ @$list ];	# do copy (for sure)
				$action{processed} = 1;
				$action{action} = 'NONE';
			}
		}
	}

	return %action;
}
