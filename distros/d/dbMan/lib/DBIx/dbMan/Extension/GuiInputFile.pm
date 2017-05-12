package DBIx::dbMan::Extension::GuiInputFile;

use strict;
use base 'DBIx::dbMan::Extension';
use Curses::UI;
use Cwd;

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000094-000001"; }

sub preference { return 800; }

sub known_actions { return [ qw/GUI/ ]; }

sub menu {
	my $obj = shift;

	return ( { label => 'Input', submenu => [
			{ label => 'Execute SQL script...',
				action => { action => 'GUI', operation => 'input_sql_file' } }
		] } );
}

sub load_ok {
    my $obj = shift;

    return $obj->{-interface}->gui();
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'GUI') {
		if ($action{operation} eq 'input_sql_file') {
			if ($obj->{-interface}->can('is_curses')
				and $obj->{-interface}->is_curses()) {
				$action{action} = 'NONE';

				if (my $val = $obj->{-interface}->{ui}->loadfilebrowser(
					-title => 'Execute SQL script', -path => getcwd(),
					-mask => [ [ '.', 'All files (*)' ],
						[ '\.sql$', 'SQL scripts (*.sql)' ] ],
					-mask_selected => 1 )) {
					$action{action} = 'INPUT_FILE';
					$action{file} = $val;
				}
			}
		}
	}

	$action{processed} = 1;
	return %action;
}
