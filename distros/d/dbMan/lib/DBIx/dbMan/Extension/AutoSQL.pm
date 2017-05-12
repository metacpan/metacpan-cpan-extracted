package DBIx::dbMan::Extension::AutoSQL;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000030-000004"; }

sub preference { return 0; }

sub known_actions { return [ qw/AUTO_SQL/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'AUTO_SQL') {
		$action{action} = 'OUTPUT';
		$action{output} = '';
		my $current = $obj->{-dbi}->current;
		$obj->{-dbi}->set_current($action{connection});		# nic nevypisovat
		my $asql = $obj->{-dbi}->autosql();
		my $silent = $obj->{-dbi}->silent_autosql() || 0;
		if (defined $asql) {
			if (not ref $asql and $asql eq '-1') {
				$action{output} = "No current connection.";
			} else {
				$asql = [ $asql ] unless ref $asql;
				if (@$asql) {
					$obj->{-interface}->add_to_actionlist({ action => 'COMMAND', cmd => 'use %save', output_quiet => 1 });
					$obj->{-interface}->add_to_actionlist({ action => 'COMMAND', cmd => "use $action{connection}", output_quiet => $silent });
					for (@$asql) {
						$obj->{-interface}->add_to_actionlist({ action => 'COMMAND', cmd => $_, output_quiet => $silent });
					}
					$obj->{-interface}->add_to_actionlist({ action => 'COMMAND', cmd => 'use %load', output_quiet => 1 });
				}
			}
		}
		$obj->{-dbi}->set_current($current);		# nic nevypisovat
	}

	$action{processed} = 1;
	return %action;
}
