package DBIx::dbMan::Extension::GuiLoadExtension;

use strict;
use base 'DBIx::dbMan::Extension';
use Curses::UI;


our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000091-000001"; }

sub preference { return 800; }

sub known_actions { return [ qw/GUI/ ]; }

sub menu {
	return { label => 'dbMan', submenu => [
		{ label => 'Extensions', submenu => [
			{ label => 'Load new...', preference => 3,
				action => { action => 'GUI', operation => 'load_extension'} },
		] } ] };
}

sub load_ok {
    my $obj = shift;

    return $obj->{-interface}->gui();
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'GUI') {
		if ($action{operation} eq 'load_extension') {
			if ($obj->{-interface}->can('is_curses')
				and $obj->{-interface}->is_curses()) {
				$action{action} = 'NONE';

				if (my $val = $obj->{-interface}->ask_value(
					-title => 'Load extension', -button => 'Load',
					-question => 'Input name of extension')) {
					$action{action} = 'EXTENSION';
					$action{operation} = 'load';
					$action{what} = $val;
				}
			}
		}
	}

	$action{processed} = 1;
	return %action;
}
