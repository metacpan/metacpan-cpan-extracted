package DBIx::dbMan::Extension::CmdPager;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000036-000004"; }

sub preference { return 2000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ s/^\\p\s+//i) {
			++$action{output_pager};
			delete $action{processed};
		}
	}

	return %action;
}

sub cmdhelp {
	return [
		'\p <command>' => 'Pager <command> (like less or more)',
	];
}

sub restart_complete {
	my ($obj,$text,$line,$start) = @_;
	my %action = (action => 'LINE_COMPLETE', text => $text, line => $line,
		start => $start);
	do {
		%action = $obj->{-core}->handle_action(%action);
	} until ($action{processed});
	return @{$action{list}} if ref $action{list} eq 'ARRAY';
	return $action{list} if $action{list};
	return ();
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return $obj->restart_complete($text,$1,$start-(length($line)-length($1))) if $line =~ /^\s*\\p\s+(.*)$/i;
	return ('\p') if $line =~ /^\s*$/i;
	return ('p') if $line =~ /^\s*\\[A-Z]*$/i;
	return ();
}
