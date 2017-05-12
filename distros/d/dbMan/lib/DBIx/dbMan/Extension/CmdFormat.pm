package DBIx::dbMan::Extension::CmdFormat;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.03';

1;

sub IDENTIFICATION { return "000001-000062-000003"; }

sub preference { return 2000; }

sub known_actions { return [ qw/COMMAND SQL_RESULT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'SQL_RESULT' and ref $action{result} eq 'ARRAY' and not exists $action{old_output_format} and $obj->{-mempool}->get('single_output_format')) {
		if (scalar @{$action{result}} == 1) {
			$action{old_output_format} = $obj->{-mempool}->get('output_format');
			$obj->{-mempool}->set('output_format',$obj->{-mempool}->get('single_output_format'));
			delete $action{processed};
		}
	} elsif ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^set\s+singleoutput\s+to(?:\s+(\S+))?$/i) {
                        my $want = lc $1;
			if ($1) {
				my @fmts = $obj->{-mempool}->get_register('output_format');
				my %fmts = ();  for (@fmts) { ++$fmts{$_}; }
				if ($fmts{$want}) {
					$obj->{-mempool}->set('single_output_format',$want);
					$action{action} = 'OUTPUT';
					$action{output} = "Single output format set to $want.\n";
				} else {
					$action{action} = 'OUTPUT';
					$action{output} = "Unknown output format.\n".
						"Registered formats: ".(join ',',sort @fmts)."\n";
				}
			} else {
				$obj->{-mempool}->set('single_output_format','');
				$action{action} = 'OUTPUT';
				$action{output} = "Single output format unset.\n";
			}
		} elsif ($action{cmd} =~ s/^\\f\s*\((.*?)\)\s+//i) {
			$action{old_output_format} = $obj->{-mempool}->get('output_format');
			my $want = lc $1;
			$want =~ s/^\s+//;
			my @fmts = $obj->{-mempool}->get_register('output_format');
			my %fmts = ();  for (@fmts) { ++$fmts{$_}; }
                        if ($fmts{$want}) {
                                $obj->{-mempool}->set('output_format',$want);
				delete $action{processed};
                        } else {
				$action{action} = 'OUTPUT';
				$action{output} = "Unknown output format.\n".
					"Registered formats: ".(join ',',sort @fmts)."\n";
			}
		}
	}

	return %action;
}

sub cmdhelp {
	return [
		'\f(<format>) <command>' => 'Format output of <command> as <format>',
		'SET SINGLEOUTPUT TO [<format>]' => 'Set output format for one-line output SQL'
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

sub formatlist {
        my $obj = shift;
        return $obj->{-mempool}->get_register('output_format');
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return $obj->restart_complete($text,$1,$start-(length($line)-length($1))) if $line =~ /^\s*\\f\s*\(.+?\)\s+(.*)$/i;
	return $obj->formatlist if $line =~ /^\s*\\f\s*\(\s*\S*$/i;
        return $obj->formatlist if $line =~ /^\s*SET\s+SINGLEOUTPUT\s+TO\s+\S*$/i;
        return qw/TO/ if $line =~ /^\s*SET\s+SINGLEOUTPUT\s+\S*$/i;
        return qw/SINGLEOUTPUT/ if $line =~ /^\s*SET\s+\S*$/i;
	return ('\f','SET') if $line =~ /^\s*$/i;
	return ('f(','SET') if $line =~ /^\s*\\[A-Z]*$/i;
	return ();
}
