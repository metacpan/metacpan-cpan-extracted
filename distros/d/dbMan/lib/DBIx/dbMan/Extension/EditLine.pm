package DBIx::dbMan::Extension::EditLine;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000069-000005"; }

sub preference { return 0; }

sub known_actions { return [ qw/EDIT_LINE/ ]; }

sub menu {
	my $obj = shift;

	return ( { label => 'Input', submenu => [
			{ label => 'Edit current line in editor',
				action => { action => 'EDIT_LINE', get_what => 1 } }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'EDIT_LINE') {
		$action{what} = $obj->{-interface}->current_line() if $action{get_what};
		my $text = $action{what} || '';
		my $editor = $ENV{DBMAN_EDITOR} || $ENV{EDITOR} || 'vi';
		my $filename = "/tmp/dbman.edit_line.$$.sql";
		if (open F,">$filename") {
			print F $text;
			close F;
			$text = '';
			my $modi = -M $filename;
			$obj->{-interface}->go_away();
			system "$editor $filename";
			$obj->{-interface}->come_back();
			if (-M $filename ne $modi and open F,$filename) {
				$text = join '',<F>;
				close F;
			}
			unlink $filename if -e $filename;
		} else { $text = ''; }
		$action{action} = 'OUTPUT';
		if ($text) {
			$text =~ s/\n$//gs;
			$text =~ s/^\n//gs;
			$action{output} = "\nI execute next long command:\n".$text."\n";
			$text =~ s/--.*?\n/ /gs;
			$text =~ s/\n/ /gs;
			$text =~ s/\t+/ /gs;
			$text =~ s/\s{2,}/ /gs;
			$obj->{-interface}->history_add($text);
			$obj->{-interface}->add_to_actionlist({ action => 'COMMAND', cmd => $text });
		} else {
			$action{output} = "\nI needn't execute entered long command.\n";
		}
	}

	return %action;
}
