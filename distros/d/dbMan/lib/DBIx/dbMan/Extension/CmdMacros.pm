package DBIx::dbMan::Extension::CmdMacros;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.03';

1;

sub IDENTIFICATION { return "000001-000085-000003"; }

sub preference { return 2000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^show\s+macros?$/i) {
			$action{action} = 'MACRO';
			$action{operation} = 'show';
		} elsif ($action{cmd} =~ /^(?:clear|erase)\s+macros?(\s+permanent(?:ly)?)?$/i) {
			$action{action} = 'MACRO';
			$action{operation} = 'clear';
			$action{permanent} = $1?1:0;
		} elsif ($action{cmd} =~ /^(re)?load\s+macros?$/i) {
			$action{action} = 'MACRO';
			$action{operation} = 'reload';
		} elsif ($action{cmd} =~ /^def(?:ine)?(?:\s+macro)?\s+(.+)$/i) {
			$action{action} = 'MACRO';
			$action{operation} = 'define';
			$action{macro} = $1;
		} elsif ($action{cmd} =~ /^undef(?:ine)?(?:\s+macro)?\s+(.+)$/i) {
			$action{action} = 'MACRO';
			$action{operation} = 'undefine';
			$action{macro} = $1;
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SHOW MACROS' => 'Show macros (substitutions)',
		'CLEAR MACROS [PERMAMENT]' => 'Clear macros (substitutions) - permanent or temporary',
		'RELOAD MACROS' => 'Reload macros (substitutions) from file',
		'DEFINE MACRO s/macro/substition/[ige]' => 'Define macro (substitution) as subscribed',
		'UNDEFINE MACRO <macro>' => 'Undefine macro (substitution) with <macro> in first part of substitution'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/PERMANENT/ if $line =~ /^\s*(CLEAR|ERASE)\s+MACROS\s+\S*$/i;
	return qw/MACROS/ if $line =~ /^\s*(SHOW|CLEAR|ERASE|RELOAD)\s+\S*$/i;
	return qw/MACRO/ if $line =~ /^\s*(UN)?DEF(INE)?\s+\S*$/i;
	return qw/SHOW CLEAR RELOAD DEFINE UNDEFINE/ if $line =~ /^\s*[A-Z]*$/i;

	if ($line =~ /^\s*(UN)?DEF(INE)?(\s+MACRO)?\s+.*$/i) {
		my @macros = @{$obj->{-mempool}->get('macros')};
		return () unless @macros;

		my @names = ();
		for (@macros) {
			s#^s/##;
			s#/([ige])?$##;
			s#^(.+)(?!\\)/.*$#$1#;
			push @names,$_ if $_;
		}

		my @result = ();
		for my $name (@names) {
			$name =~ s/\\s[+*]?/ /g;
			$name =~ s/^\^//;
			$name =~ s/\$$//;
			my @words = ();
			for (split /\s+/,$name) {
				if (/^[-a-z0-9_\\]+$/i) {
					push @words,$_;
				} else {
					last;
				}
			}
			if (@words) {
				if ($line =~ /^\s*(UN)?DEF(INE)?(\s+MACRO)?\s+\S*$/i) {
					push @result,$words[0];
				} else {
					my $saved = pop @words;
					while (@words) {
						$name = '$line =~ /^\s*(UN)?DEF(INE)?(\s+MACRO)?\s+'.join('\\s+',@words).'\s+\S*$/i';
						push @result,$saved if eval $name;
						$saved = pop @words;
					}
				}
			}
		}

		return @result;
	}

	return ();
}
