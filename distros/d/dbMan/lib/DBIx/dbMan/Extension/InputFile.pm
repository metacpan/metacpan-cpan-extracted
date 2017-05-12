package DBIx::dbMan::Extension::InputFile;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.03';

1;

sub IDENTIFICATION { return "000001-000024-000003"; }

sub preference { return 0; }

sub known_actions { return [ qw/INPUT_FILE/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'INPUT_FILE') {
		$action{action} = 'NONE';
		unless (open F,$action{file}) {
			$obj->{-interface}->error("Can't load input file $action{file}.");
			return %action;
		}
		while (<F>) {
			chomp;
			my $newaction = { action => 'COMMAND', cmd => $_ };
			$obj->{-interface}->add_to_actionlist($newaction);
		}
		close F;
	}

	$action{processed} = 1;
	return %action;
}
