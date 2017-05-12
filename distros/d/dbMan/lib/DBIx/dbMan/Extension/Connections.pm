package DBIx::dbMan::Extension::Connections;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;
use DBI;

our $VERSION = '0.10';

1;

sub IDENTIFICATION { return "000001-000005-000010"; }

sub preference { return 0; }

sub known_actions { return [ qw/CONNECTION/ ]; }

sub menu {
	my $obj = shift;

	my @menu_use = ();
	my @menu_close = ();
	my @menu_reopen = ();
	my @menu_open = ();
	my @menu_drop = ();

	for (@{$obj->{-dbi}->list('active')}) {
		my $sel = ' ';
		$sel = '*' if $_->{name} eq $obj->{-dbi}->current;
		push @menu_use,{ label => $sel.' '.$_->{name},
			action => { action => 'CONNECTION', operation => 'use',
			what => $_->{name} } };
		push @menu_close,{ label => $_->{name},
			action => { action => 'CONNECTION', operation => 'close',
			what => $_->{name} } };
		push @menu_reopen,{ label => $_->{name},
			action => { action => 'CONNECTION', operation => 'reopen',
			what => $_->{name} } };
	}
	for (@{$obj->{-dbi}->list('inactive')}) {
		push @menu_open,{ label => $_->{name},
			action => { action => 'CONNECTION', operation => 'open',
			what => $_->{name} } };
	}
	for (@{$obj->{-dbi}->list()}) {
		push @menu_drop,{ label => $_->{name}, submenu => [
			{ label => 'Temporarly', action => { action => 'CONNECTION',
				operation => 'drop', what => $_->{name} } },
			{ label => 'Permanently', action => { action => 'CONNECTION',
				operation => 'drop', what => $_->{name}, permanent => 1 } }
		] };
	}

	return ( { label => '_Connection', submenu => [
			{ label => 'Select current', preference => 100, submenu => \@menu_use },
			{ label => 'Close', preference => 1, submenu => \@menu_close },
			{ label => 'Reopen', preference => 2, submenu => \@menu_reopen },
			{ label => 'Open', preference => 3, submenu => \@menu_open },
			{ label => 'Drop', preference => -10, submenu => \@menu_drop },
			{ label => 'Show list', preference => 50, submenu => [
				{ label => 'All', preference => 5,
					action => { action => 'CONNECTION', operation => 'show' } }, 
				{ separator => 1, preference => 2 },
				{ label => 'Active',
					action => { action => 'CONNECTION', operation => 'show',
					what => 'active' } }, 
				{ label => 'Inactive',
					action => { action => 'CONNECTION', operation => 'show',
					what => 'inactive' } }
			] },
			{ separator => 1, preference => 25 },
			{ separator => 1, preference => -1 }
		] } );
}

sub init {
	my $obj = shift;
	$obj->{prompt_num} = $obj->{-interface}->register_prompt;
}

sub done {
	my $obj = shift;
	$obj->{-interface}->deregister_prompt($obj->{-prompt_num});
}

sub solve_open_error {
	my ($obj,$error,$name) = @_;

	if ($error == -1) {
		return "Can't find driver for ".$obj->{connections}->{$name}->{driver}.".\n";
	} elsif ($error == -2) {
		return "Can't connect to $name (reason: ".DBI->errstr.").\n";
	} elsif ($error == -3) {
		return "Unknown connection $name.\n";
	} elsif ($error == -4) {
		return "Already connected to $name.\n";
	} elsif (not $error) {
		return "Connection to $name established.\n";
	}
}

sub solve_close_error {
	my ($obj,$error,$name) = @_;

	if ($error == -1) {
		return "Unknown connection $name.\n";
	} elsif ($error == -2) {
		return "Not connected to $name.\n";
	} elsif (not $error) {
		return "Disconnected from $name.\n";
	}
}

sub solve_use_error {
	my ($obj,$error,$name) = @_;

	if ($error == 1) {
		return "Unset current connection.\n";
	} elsif ($error == -1) {
		return "Unknown connection $name.\n";
	} elsif ($error == -2) {
		return "Not connected to $name.\n";
	} elsif (not $error) {
		return "Set current connection to $name.\n";
	}
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'CONNECTION') {
		if ($action{operation} eq 'open') {
			my $error = $obj->{-dbi}->open($action{what});
			$action{action} = 'OUTPUT';
			$action{output} = $obj->solve_open_error($error,$action{what});
			$obj->{-interface}->rebuild_menu;
		} elsif ($action{operation} eq 'reopen') {
			my $reuse = 0;
			$reuse = 1 if $obj->{-dbi}->current eq $action{what};

			$action{action} = 'OUTPUT';
			my $error = $obj->{-dbi}->close($action{what});
			$action{output} = $obj->solve_close_error($error,$action{what});

			$error = $obj->{-dbi}->open($action{what});
			$action{output} .= $obj->solve_open_error($error,$action{what});

			if ($reuse) {
				$error = $obj->{-dbi}->set_current($action{what});
				$action{output} .= $obj->solve_use_error($error,$action{what});
			}
			$obj->{-interface}->add_to_actionlist({ action => 'NOTIFY', notify => 'connection_change' });
			$obj->{-interface}->rebuild_menu;
		} elsif ($action{operation} eq 'close') {
			$action{action} = 'OUTPUT';
			my $error = $obj->{-dbi}->close($action{what});
			$action{output} = $obj->solve_close_error($error,$action{what});
			$obj->{-interface}->add_to_actionlist({ action => 'NOTIFY', notify => 'connection_change' });
			$obj->{-interface}->rebuild_menu;
		} elsif ($action{operation} eq 'use') {
			$action{action} = 'OUTPUT';
			my $error = $obj->{-dbi}->set_current($action{what});
			$action{output} = $obj->solve_use_error($error,$action{what});
			$obj->{-interface}->rebuild_menu;
			$obj->{-interface}->add_to_actionlist({ action => 'TRANSACTION', operation => 'change' });
			$obj->{-interface}->add_to_actionlist({ action => 'NOTIFY', notify => 'connection_change' });
		} elsif ($action{operation} eq 'show') {
			my @list = @{$obj->{-dbi}->list($action{what})};
			my $clist = '';
			if (@list) {
				$clist .= ($action{what} eq 'active'?'Active c':'C')."onnections:\n";
				my $table = new Text::FormatTable '| l l | l | l | l | l | l | l |';
				$table->rule;
				$table->head('C','NAME','ACTIVE','PERMANENT','DRIVER','LOGIN','DSN','CONFIG');
				$table->rule;
				for (@list) {
					$table->row((($obj->{-dbi}->current eq $_->{name})?'*':' '),$_->{name},($_->{-logged}?'yes':'no'),($obj->{-dbi}->is_permanent_connection($_->{name})?'yes':'no'),$_->{driver},$_->{login},$_->{dsn},$_->{config} || '');
				}
				$table->rule;
				$clist .= $table->render($obj->{-interface}->render_size);
			} else {
				$action{what} = '' if $action{what} ne 'active';
				$clist .= "No".($action{what}?' '.$action{what}:'')." connection.\n";
			}
			$action{action} = 'OUTPUT';
			$action{output} = $clist;
		} elsif ($action{operation} eq 'create') {
			my %parm = ();
			for (qw/driver dsn login password auto_login config/) { $parm{$_} = $action{$_} || ''; }

			$action{action} = 'NONE';
			my $error = $obj->{-dbi}->create_connection($action{what},\%parm);
			if ($error == -1) {
				$action{action} = 'OUTPUT';
				$action{output} = "Connection with name $action{what} already exists.\n";
			} elsif ($error >= 0) {
				$action{action} = 'OUTPUT';
				$action{output} = "Connection $action{what} created.\n";
				if ($error > 50) {
					$action{output} .= $obj->solve_open_error($error-100,$action{what}) if $error > 50;
				}
				if ($action{permanent}) {
					$error = $obj->{-dbi}->save_connection($action{what});
					if ($error == -1) {
						$action{output} .= "Connection with name $action{what} not exists.\n";
					} elsif (not $error) {
						$action{output} .= "Making connection $action{what} permanent.\n";

					}
				}
				$obj->{-interface}->rebuild_menu;
			}
		} elsif ($action{operation} eq 'drop') {
			$action{action} = 'NONE';
			my $error = $obj->{-dbi}->drop_connection($action{what});
			if ($error == -1) {
				$action{action} = 'OUTPUT';
				$action{output} = "Connection with name $action{what} not exists.\n";
			} elsif (not $error) {
				$action{action} = 'OUTPUT';
				$action{output} = "Connection $action{what} dropped.\n";
				if ($action{permanent}) {
					$error = $obj->{-dbi}->destroy_connection($action{what});
					if ($error == -2) {
						$action{output} .= "Can't destroy connection $action{what}.\n";
					} elsif (not $error) {
						$action{output} .= "Destroying permanent connection $action{what}.\n";
					}
				}
				$obj->{-interface}->rebuild_menu;
			}
		}

		my $db = '';
		$db = '<'.$obj->{-dbi}->current.'>' if $obj->{-dbi}->current;
		$obj->{-interface}->prompt($obj->{prompt_num},$db);
	}

	$action{processed} = 1;
	return %action;
}

