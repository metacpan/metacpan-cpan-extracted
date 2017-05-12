package DBIx::dbMan::Extension::EditOracle;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;

our $VERSION = '0.07';

1;

sub IDENTIFICATION { return "000001-000047-000007"; }

sub preference { return 0; }

sub known_actions { return [ qw/EDIT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'EDIT' and $obj->{-dbi}->driver eq 'Oracle') {
		if ($action{testerror}) {
			$action{action} = 'NONE';
			my $d = $obj->{-dbi}->selectall_arrayref(q!SELECT line, position, text FROM user_errors WHERE name = ? AND type = ? ORDER BY sequence!,{},$action{what},$action{type});
			if (defined $d and @$d) {
				$action{action} = 'OUTPUT';
				$action{output} = "I detect some errors on object $action{what} (type $action{type}):\n";
				my $tab = new Text::FormatTable '| r | r | l |';
				$tab->rule;
				$tab->head('ROW','COLUMN','ERROR');
				$tab->rule;
				for (@$d) { $tab->row(@$_); }
				$tab->rule;
				$action{output} .= $tab->render($obj->{-interface}->render_size);
			}
			return %action;
		}
		if ($action{type} =~ /^(FUNCTION|PROCEDURE|PACKAGE|PACKAGE BODY|TRIGGER|VIEW)$/) {
			$action{action} = 'NONE';
			my $d;
			my $lr = $obj->{-dbi}->longreadlen();
			$obj->{-dbi}->longreadlen(100000);
			my $schema = '';
			$schema = uc $1 if $action{what} =~ s/^([^.]+)\.//;
			my $schema_add = '';
			my @schema = ();
			if ($schema) {
				$schema_add = ' AND owner = ?';
				push @schema,$schema;
			}
			my $basetable = $schema?'all':'user';
			if ($action{type} eq 'TRIGGER') {
				$d = $obj->{-dbi}->selectall_arrayref(q!SELECT description,trigger_body FROM !.$basetable.q!_triggers WHERE trigger_name = ?!.$schema_add,{},$action{what},@schema);
			} elsif ($action{type} eq 'VIEW') {
				$d = $obj->{-dbi}->selectall_arrayref(q!SELECT text FROM !.$basetable.q!_views WHERE view_name = ?!.$schema_add,{},$action{what},@schema);
			} else {
				$d = $obj->{-dbi}->selectall_arrayref(q!SELECT text FROM !.$basetable.q!_source WHERE name = ? AND type = ?!.$schema_add.q! ORDER BY line!,{},$action{what},$action{type},@schema);
			}
			$action{what} = "$schema.".$action{what} if $schema;
			$obj->{-dbi}->longreadlen($lr);
			if (defined $d and @$d) {
				my $text = "CREATE OR REPLACE ";
				if ($action{type} eq 'TRIGGER') {
					my $desc = $d->[0][0];
					$desc =~ s/\n/ /gs;
					$text .= 'TRIGGER '.$desc."\n".$d->[0][1];
				} elsif ($action{type} eq 'VIEW') {
					$text .= 'VIEW '.$action{what}." AS\n".join '',map { $_->[0] } @$d;
				} else {
					$text .= join '',map { $_->[0] } @$d;
				}
				my $nt = '';
				my $started = 0;
				for my $t (split /\n/,$text) {
					next if $t =~ /-- \|dbMan\| /;
					$t =~ s/\s+$//;
					next if not $started and $t =~ /^\s*$/;
					++$started;
					$nt .= "$t\n";
				}
				$text = $nt;
				$text =~ s/\n+$//s;
				$text =~ s/\s+$//s;
				$text .= ";" if $text =~ /end$/;
				$text .= "\n\n";

				if ($obj->{-mempool}->get('edit_object_errors')) {
					$d = $obj->{-dbi}->selectall_arrayref(q!SELECT line, position, text FROM user_errors WHERE name = ? AND type = ? ORDER BY sequence!,{},$action{what},$action{type});
					if (defined $d and @$d) {
						my $tab = new Text::FormatTable '| r | r | l |';
						$tab->rule;
						$tab->head('ROW','COLUMN','ERROR');
						$tab->rule;
						for (@$d) { $tab->row(@$_); }
						$tab->rule;
						$text = "-- |dbMan|  Errors in object $action{what} (type $action{type}):\n" . join("\n", map { "-- |dbMan|  ".$_ } split /\n/,$tab->render($obj->{-interface}->render_size)) . "\n-- |dbMan|  Note: Rows are numbered from line with CREATE OR REPLACE.\n\n" . $text;
					}
				}
				my $editor = $ENV{DBMAN_EDITOR} || $ENV{EDITOR} || 'vi';
				my $t = $action{type};  $t =~ s/ /_/g;
				my $filename = "/tmp/dbman.edit_object.$t.$action{name}.$$.plsql";
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
				if ($text) {
					my $started = 0;
					my $nt = '';
					for my $t (split /\n/,$text) {
						next if $t =~ /-- \|dbMan\| /;
						$t =~ s/\s+$//;
						next if not $started and $t =~ /^\s*$/;
						++$started;
						$nt .= "$t\n";
					}
					$text = $nt;
					$text =~ s/\n+$//s;
					$text .= "\n\n";

					$action{action} = 'OUTPUT';
					$action{output} = "I must save edited object into database.\n";
					$obj->{-interface}->add_to_actionlist({ action => 'SQL', type => 'do', sql => $text, longreadlen => 100000});
					$obj->{-interface}->add_to_actionlist({ action => 'EDIT', what => $action{what}, type => $action{type}, testerror => 1 });
				} else {
					$action{action} = 'OUTPUT';
					$action{output} = "I needn't save edited object into database.\n";
				}
			}
		} else {
			$action{action} = 'OUTPUT';
			$action{output} = "Editing of $action{type} isn't implemented yet.\n";
		}
	}

	return %action;
}
