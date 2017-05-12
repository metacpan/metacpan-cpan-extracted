package DBIx::dbMan::Extension::ShowTablesOracle;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;

our $VERSION = '0.06';

1;

sub IDENTIFICATION { return "000001-000039-000006"; }

sub preference { return 50; }

sub known_actions { return [ qw/SHOW_TABLES/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'SHOW_TABLES' and $obj->{-dbi}->driver eq 'Oracle') {
		my $table = new Text::FormatTable '| l | l |';
		$table->rule;
		$table->head('NAME','TYPE');
		$table->rule;

		my $sth = $obj->{-dbi}->table_info( { TABLE_SCHEM => uc($obj->{-dbi}->login) } );
		if (defined $sth) {
			my $ret = $sth->fetchall_arrayref();
			study $action{mask};
			eval {
				if (defined $ret) {
					for (sort { $a->[2] cmp $b->[2] } @$ret) {
						if (($action{type} eq 'object'
						  or $action{type} eq lc $_->[3]) and
						  $action{mask} and $_->[2] =~ /$action{mask}/i) {
							$table->row($_->[2],$_->[3]);
						}
					}
				}
			};
			$sth->finish;
			$table->rule;
			$action{output} = $@?"Invalid regular expression.\n":$table->render($obj->{-interface}->render_size);
		} else {
			$action{output} = "Interrupted.\n"; 
		}
		$action{action} = 'OUTPUT';
	}

	$action{processed} = 1;
	return %action;
}
