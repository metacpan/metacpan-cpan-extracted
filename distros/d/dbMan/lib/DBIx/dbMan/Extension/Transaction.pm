package DBIx::dbMan::Extension::Transaction;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.09';

1;

sub IDENTIFICATION { return "000001-000022-000009"; }

sub preference { return 0; }

sub known_actions { return [ qw/TRANSACTION/ ]; }

sub init {
	my $obj = shift;

	$obj->{prompt_num} = $obj->{-interface}->register_prompt(1000);
	$obj->{prompt_title} = $obj->{-config}->prompt_transaction || 'TRANSACTION';
}

sub menu {
	my $obj = shift;

	if ($obj->{-dbi}->current and $obj->{-dbi}->in_transaction) {
		return ( { label => 'Transaction', submenu => [
				{ label => 'Commit transaction',
					action => { action => 'TRANSACTION',
						operation => 'commit' } },
				{ label => 'Rollback transaction',
					action => { action => 'TRANSACTION',
						operation => 'rollback' } },
				{ label => 'Auto commit transaction', preference => -20,
					action => { action => 'TRANSACTION',
						operation => 'end' } },
				{ separator => 1, preference => -10 }
			] } );
	} else {
		return ( { label => 'Transaction', submenu => [
				{ label => 'Begin transaction',
					action => { action => 'TRANSACTION',
						operation => 'begin' } }
			] } );
	}
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'TRANSACTION') {
		if ($action{operation} =~ /^(begin|end|commit|rollback)$/) {
			$action{action} = 'NONE';
			unless ($obj->{-dbi}->current) {
				$obj->{-interface}->error("No current connection selected.");
				return %action;
			}
			if ($obj->{-dbi}->in_transaction and $action{operation} eq 'begin') {
				$obj->{-interface}->error('Transaction already started.');
				return %action;
			} elsif (not $obj->{-dbi}->in_transaction and $action{operation} =~ /^(end|commit|rollback)$/) {
				$obj->{-interface}->error('No transaction started.');
				return %action;
			}

			if ($action{operation} eq 'begin') {
				$obj->{-dbi}->trans_begin;
				$action{output} = "Transaction started.\n";
			} elsif ($action{operation} eq 'end') {
				$obj->{-dbi}->rollback;
				$obj->{-dbi}->trans_end;
				$action{output} = "Auto commit transaction mode started with implicit rollback.\n";
			} elsif ($action{operation} eq 'commit') {
				$obj->{-dbi}->commit;
				$action{output} = "Transaction commited.\n";
			} elsif ($action{operation} eq 'rollback') {
				$obj->{-dbi}->rollback;
				$action{output} = "Transaction rolled back.\n";
			}
			$action{action} = 'OUTPUT';
			$obj->{-interface}->rebuild_menu();
		} elsif ($action{operation} eq 'change') {
			$action{action} = 'NONE';
			$obj->{-interface}->rebuild_menu();
		}
	}

	if ($obj->{-dbi}->in_transaction) {
		$obj->{-interface}->prompt($obj->{prompt_num},$obj->{prompt_title});
	} else {
		$obj->{-interface}->prompt($obj->{prompt_num},'');
	}

	$action{processed} = 1;
	return %action;
}

sub done {
	my $obj = shift;
	
	$obj->{-interface}->deregister_prompt($obj->{prompt_num});

	for (@{$obj->{-dbi}->list('active')}) {
		my $name = $_->{name};
		$obj->{-dbi}->set_current($name);		# nic nevypisovat
		if ($obj->{-dbi}->in_transaction()) {
			$obj->{-dbi}->rollback;
			$obj->{-dbi}->trans_end;
			$obj->{-interface}->print("Transaction end with implicit rollback in connection $name.\n");
		}
	}
}
