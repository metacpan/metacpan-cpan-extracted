package DBIx::dbMan::Extension::CmdDescribe;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000031-000005"; }

sub preference { return 1200; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^(?:describe|\\d)\s+(.*)$/i) {
			$action{action} = 'DESCRIBE';
			$action{what} = $1;
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'DESCRIBE <table>' => 'Describe structure of <table>'
	];
}

sub listoftables {
	my $obj = shift;
	my %action = (action => 'DESCRIBE', oper => 'complete', what => 'list');
	do {
		%action = $obj->{-core}->handle_action(%action);
	} until ($action{processed});
	return @{$action{list}} if ref $action{list} eq 'ARRAY';
	return ();
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return () unless $obj->{-dbi}->current;
	return $obj->listoftables if $line =~ /^\s*(DESCRIBE|\\d)\s+\S*$/i;
	return qw/DESCRIBE/ if $line =~ /^\s*[A-Z]*$/i;
	return ('d') if $line =~ /^\s*\\[A-Z]*$/i;
	return ('\d') if $line =~ /^\s*$/;
	return ();
}
