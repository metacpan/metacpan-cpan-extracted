package DBIx::dbMan::Extension::CmdSetOracleSpecials;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000099-000001"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^set\s+oracle\s+xplan\s+(on|off)$/i) {
			my $want = lc $1;  my $owant = $want;
			$want = ($want eq 'off')?0:1;
			$action{action} = 'OUTPUT';

			my $local_mempool = $obj->{-dbi}->mempool();
			if ( $local_mempool ) {
				$local_mempool->set( 'oracle_special_xplan', $want );
				$action{output} = "Oracle DBMS_XPLAN module support $owant.\n";
			} else {
				$action{output} = "There is no active connection where DBMS_XPLAN module can be used.\n";
			}

			$obj->{-interface}->rebuild_menu();
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SET ORACLE XPLAN [ON|OFF]' => 'Set Oracle DBMS_XPLAN module on or off (for db version 10 or newer).'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;

	my $local_mempool = $obj->{-dbi}->mempool();
	if ( $local_mempool ) {
		return qw/ON OFF/ if $line =~ /^\s*SET\s+ORACLE\s+XPLAN\s+\S*$/i;
		return qw/XPLAN/ if $line =~ /^\s*SET\s+ORACLE\s+\S*$/i;
		return qw/ORACLE/ if $line =~ /^\s*SET\s+\S*$/i;
		return qw/SET/ if $line =~ /^\s*[A-Z]*$/i;
	}
	return ();
}
