package DBIx::dbMan::Extension::SimpleMacros;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000084-000001"; }

sub preference { return 4500; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'COMMAND') {
		my @macros = @{$obj->{-mempool}->get('macros')};
		if (@macros) {
			my $cmd = $action{cmd};
			unless ($cmd =~ /^undef(ine)?(\s+macro)?\s+/i) {
				++$action{macro_was}->{$cmd};
				my $changes = 0;
				for my $macro (@macros) {
					my $code = "++\$changes if \$cmd =~ $macro;";
					eval $code;
				}
				$action{cmd} = $cmd;
				if ($changes) {
					if (exists $action{macro_was}->{$cmd}) {
						$action{action} = 'OUTPUT';
						$action{output} = "Deep recursion in macro language detected.\n";
					} else {
						delete $action{processed};
					}
				}
			}
		}
	}

	return %action;
}
