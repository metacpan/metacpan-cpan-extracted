package DBIx::dbMan::Extension::CmdExtensions;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000007-000005"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^show\s+extensions?(?:\s+by\s+(id|preference|name))?$/i) {
			$action{action} = 'EXTENSION';
			$action{operation} = 'show';
			$action{sort} = lc($1) || 'preference';
		} elsif ($action{cmd} =~ /^unload\s+(?:extension\s+)?(\S+)$/i) {
			$action{action} = 'EXTENSION';
			$action{operation} = 'unload';
			$action{what} = $1;
		} elsif ($action{cmd} =~ /^load\s+(?:extension\s+)?(\S+)$/i) {
			$action{action} = 'EXTENSION';
			$action{operation} = 'load';
			$action{what} = $1;
		} elsif ($action{cmd} =~ /^reload\s+(?:extension\s+)?(\S+)$/i) {
			$action{action} = 'EXTENSION';
			$action{operation} = 'reload';
			$action{what} = $1;
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SHOW EXTENSIONS [BY ID|NAME|PREFERENCE]' => 'Show list of loaded extensions',
		'UNLOAD [EXTENSION] <name>' => 'Unload specific extension',
		'LOAD [EXTENSION] <name>' => 'Load specific extension',
		'RELOAD [EXTENSION] <name>' => 'Reload specific extension'
	];
}

sub extensionlist {
	my $obj = shift;
	my @all = ();
	for my $ext (@{$obj->{-core}->{extensions}}) {
		my $name = $ext;
		$name =~ s/=.*$//;  $name =~ s/^.*:://;
		push @all,$name;
	}
	return @all;
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/ID NAME PREFERENCE/ if $line =~ /^\s*SHOW\s+EXTENSIONS?\s+BY\s+\S*$/i;
	return qw/BY/ if $line =~ /^\s*SHOW\s+EXTENSIONS?\s+\S*$/i;
	return qw/EXTENSIONS/ if $line =~ /^\s*SHOW\s+\S*$/i;
	return $obj->extensionlist if $line =~ /^\s*(LOAD|UNLOAD|RELOAD)\s+EXTENSION\s+\S*$/i;
	return ('EXTENSION',$obj->extensionlist) if $line =~ /^\s*(LOAD|UNLOAD|RELOAD)\s+\S*$/i;
	return qw/SHOW UNLOAD LOAD RELOAD/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
