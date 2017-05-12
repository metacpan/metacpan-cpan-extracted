package DBIx::dbMan::Extension::CmdInputCSV;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000040-000005"; }

sub preference { return 1500; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^\\csvin(?:\[(.*)\])?\s*\((.*?)\)\s+(.*)$/i) {
			$action{action} = 'CSV_IN';
			$action{file} = $2;
			$action{sql} = $3;
			$action{opt_separator} = ',';
			$action{opt_quote} = '"';
			$action{opt_eol} = "\n";
			$action{opt_headings} = 0;
			$action{opt_escape} = '"';
			$action{opt_allow_loose_escapes} = 1;
			$action{opt_allow_loose_quotes} = 1;
			my $opt = $1;
			my @opts = split /\s+/,$opt;
			for (@opts) {
				my ($tag,$value) = split /=/,$_;
				$value =~ s/\\s/ /g;
				
				$value =~ s/\\(.)/my $v=''; my $src='$v="\\'.$1.'";'; eval $src; $v/eg;

				if ($tag =~ /^(separator|quote|eol|headings|escape|allow_loose_escapes|allow_loose_quotes)$/) {
					$action{"opt_$tag"} = $value;
				} else {
					$action{action} = 'NONE';
					$obj->{-interface}->error('Unknown option in \csvin');
				}
			}
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'\csvin[<options>](<file>) <command>' => 'Import CSV file <file> through placeholders in <command> (with optionable <options> defined like separator=, quote=" eol=\n headings=0 escape=" where headings=0 is no headings, =1 is headings skip, \s means space, \t means tabulator)'
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
	return () unless $obj->{-dbi}->current;
	return $obj->restart_complete($text,$1,$start-(length($line)-length($1))) if $line =~ /^\s*\\csvin(?:\[.*?\])?\s*\(.+?\)\s+(.*)$/i;
	return $obj->{-interface}->filenames_complete($text,$line,$start) if $line =~ /^\s*\\csvin(\[.*?\])?\s*\(\S*$/i;
	return ('\csvin') if $line =~ /^\s*$/i;
	return ('csvin(') if $line =~ /^\s*\\[A-Z]*$/i;
	return ();
}
