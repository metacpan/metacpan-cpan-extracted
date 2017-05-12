package DBIx::dbMan::Extension::CmdOutputToFile;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000017-000004"; }

sub preference { return 2000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ s/^\\s(c)?\s*\((.*?)\)\s+//i) {
			$action{output_save_copy} = $1;
			$action{output_device} = $2;
			delete $action{processed};
		}
	}

	return %action;
}

sub cmdhelp {
	return [
		'\s(<file>) <command>' => 'Save output of <command> to <file>',
		'\sc(<file>) <command>' => 'Save copy of output of <command> to <file>'
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
	return $obj->restart_complete($text,$1,$start-(length($line)-length($1))) if $line =~ /^\s*\\sc?\s*\(.+?\)\s+(.*)$/i;
	return $obj->{-interface}->filenames_complete($text,$line,$start) if $line =~ /^\s*\\sc?\s*\(\S*$/i;
	return ('\s','\sc') if $line =~ /^\s*$/i;
	return ('s(','sc(') if $line =~ /^\s*\\[A-Z]*$/i;
	return ();
}
