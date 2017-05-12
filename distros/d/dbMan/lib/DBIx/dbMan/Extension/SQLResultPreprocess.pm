package DBIx::dbMan::Extension::SQLResultPreprocess;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000054-000005"; }

sub preference { return 50; }

sub known_actions { return [ qw/SQL_RESULT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'SQL_RESULT' and not $action{sql_result_preprocess} and ref $action{result} eq 'ARRAY') {
		@$_ = map { (defined) ? join '',(map { ($_ >= 32 && $_ <= 254 && $_ != 127)?chr:sprintf "<%02x>",$_; } unpack "C*",$_) : undef } @$_ for @{$action{result}};

		$action{sql_result_preprocess} = 1;
		delete $action{processed};
	}

	return %action;
}
