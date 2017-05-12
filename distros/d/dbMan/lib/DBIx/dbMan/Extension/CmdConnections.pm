package DBIx::dbMan::Extension::CmdConnections;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.07';

1;

sub IDENTIFICATION { return "000001-000004-000007"; }

sub preference { return 2000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^open\s+(\S*)$/i) {
			$action{action} = 'CONNECTION';
			$action{operation} = 'open';
			$action{what} = $1;
		} elsif ($action{cmd} =~ /^close\s+(\S*)$/i) {
			$action{action} = 'CONNECTION';
			$action{operation} = 'close';
			$action{what} = $1;
		} elsif ($action{cmd} =~ /^reopen\s+(\S*)$/i) {
			$action{action} = 'CONNECTION';
			$action{operation} = 'reopen';
			$action{what} = $1;
		} elsif ($action{cmd} =~ /^use(?:\s+(\S*))?$/i) {
			$action{action} = 'CONNECTION';
			$action{operation} = 'use';
			if ($1 eq '%save') {
				$obj->{-mempool}->set('connection_saved',$obj->{-dbi}->current);
				$action{action} = 'NONE';
			} elsif ($1 eq '%load') {
				$action{what} = $obj->{-mempool}->get('connection_saved');
			} else {
				$action{what} = $1;
			}
		} elsif ($action{cmd} =~ /^show\s+(active|all)?\s*connections?$/i) {
			$action{action} = 'CONNECTION';
			$action{operation} = 'show';
			if (lc $1 eq 'active') {
				$action{what} = 'active';
			} else {
				$action{what} = 'all';
			}
		} elsif ($action{cmd} =~ /^create\s+(permanent\s+)?connection\s+(\S+)\s+as\s+(\S+?):\s*(.*?)\s+login\s+(\S+)(?:\s+(password\s+(\S+)|nopassword))?(\s+config\s+(\S+?))?(\s+autoopen)?$/i) {
			# as driver:dsn login user [password password]
			$action{action} = 'CONNECTION';
			$action{operation} = 'create';
			$action{permanent} = 'yes' if $1;
			$action{what} = $2;
			$action{driver} = $3;
			$action{dsn} = $4;
			$action{login} = $5;
			if (lc $6 eq 'nopassword') {
				$action{password} = '';
			} else {
				$action{password} = $7;
				unless ($action{password}) {
					$action{password} = $obj->{-interface}->get_password('Password: ');
				}
			}
			$action{config} = $9 || '';
			$action{auto_login} = 'yes' if $10;
		} elsif ($action{cmd} =~ /^drop\s+(permanent\s+)?connection\s+(\S+)$/i) {
			$action{action} = 'CONNECTION';
			$action{operation} = 'drop';
			$action{permanent} = 'yes' if $1;
			$action{what} = $2;
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'OPEN <connection_name>' => 'Open specific connection',
		'REOPEN <connection_name>' => 'Reopen specific connection',
		'CLOSE <connection_name>' => 'Close specific connection',
		'USE <connection_name>' => 'Set selected connecection as current',
		'SHOW [ACTIVE|ALL] CONNECTIONS' => 'Show list of active/all connections',
		'CREATE [PERMANENT] CONNECTION <name> AS <driver>:<dsn> LOGIN <login> [PASSWORD <password> | NOPASSWORD] [CONFIG <config>] [AUTOOPEN]' => 'Creating new connection',
		'DROP [PERMANENT] CONNECTION <name>' => 'Droping specific connection'
		];
}

sub connectionlist {
	my $obj = shift;
	my $oper = shift;
	my $type = '';
	if ($oper =~ /^(close|use)$/) { $type = 'active'; } else { $type = 'inactive'; }
	return map { $_->{name} } @{$obj->{-dbi}->list($type)};
}

sub driverlist {
	my $obj = shift;
	return map { $_.':' } $obj->{-dbi}->driverlist;
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return $obj->connectionlist(lc $1) if $line =~ /^\s*(REOPEN|OPEN|CLOSE|USE|DROP\s+(PERMANENT\s+)?CONNECTION)\s+\S*$/i;
	return qw/AUTOOPEN/ if $line =~ /^\s*CREATE\s+(PERMANENT\s+)?CONNECTION\s+\S+\s+AS\s+\S+:\s*\S*\s+LOGIN\s+\S+\s+(NOPASSWORD|PASSWORD\s+\S+)\s+CONFIG\s+\S+\s+\S*$/i;
	return qw/CONFIG AUTOOPEN/ if $line =~ /^\s*CREATE\s+(PERMANENT\s+)?CONNECTION\s+\S+\s+AS\s+\S+:\s*\S*\s+LOGIN\s+\S+\s+(NOPASSWORD|PASSWORD\s+\S+)\s+\S*$/i;
	return qw/PASSWORD NOPASSWORD/ if $line =~ /^\s*CREATE\s+(PERMANENT\s+)?CONNECTION\s+\S+\s+AS\s+\S+:\s*\S*\s+LOGIN\s+\S+\s+\S*$/i;
	return $obj->driverlist if $line =~ /^\s*CREATE\s+(PERMANENT\s+)?CONNECTION\s+\S+\s+AS\s+\S*$/i;
	return qw/LOGIN/ if $line =~ /^\s*CREATE\s+(PERMANENT\s+)?CONNECTION\s+\S+\s+AS\s+\S+:\s*\S*\s+\S*$/i;
	return qw/AS/ if $line =~ /^\s*CREATE\s+(PERMANENT\s+)?CONNECTION\s+\S+\s+\S*$/i;
	return qw/CONNECTION/ if $line =~ /^\s*(CREATE|DROP)\s+PERMANENT\s+\S*$/i;
	return qw/PERMANENT CONNECTION/ if $line =~ /^\s*(CREATE|DROP)\s+\S*$/i;
	return qw/CONNECTIONS/ if $line =~ /^\s*SHOW\s+(ACTIVE|ALL)\s+\S*$/i;
	return qw/ACTIVE ALL CONNECTIONS/ if $line =~ /^\s*SHOW\s+\S*$/i;
	return qw/REOPEN OPEN CLOSE USE SHOW CREATE DROP/ if $line =~ /^\s*[A-Z]*$/i and $obj->connectionlist('close');
	return qw/OPEN SHOW CREATE DROP/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
