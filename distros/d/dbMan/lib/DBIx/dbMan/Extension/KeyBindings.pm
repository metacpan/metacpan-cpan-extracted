package DBIx::dbMan::Extension::KeyBindings;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;

our $VERSION = '0.02';

1;

sub IDENTIFICATION { return "000001-000087-000002"; }

sub preference { return 0; }

sub known_actions { return [ qw/KEYS/ ]; }

sub menu {
	my $obj = shift;

	return ( { label => 'Input', submenu => [
			{ label => 'Key bindings', submenu => [
				{ label => 'Show',
					action => { action => 'KEYS', operation => 'show' } },
				{ label => 'Clear',
					action => { action => 'KEYS', operation => 'clear' } },
				{ label => 'Reload',
					action => { action => 'KEYS', operation => 'reload' } }
		] } ] } );
}

sub keysfile {
	my $obj = shift;

	return $ENV{DBMAN_KEYSFILE} if $ENV{DBMAN_KEYSFILE};
	return $obj->{-config}->keys_file if $obj->{-config}->keys_file;
	return $ENV{DBMAN_KEYSFILE_INTERNAL} if $ENV{DBMAN_KEYSFILE_INTERNAL};
	return $ENV{HOME}.'/.dbman/keys';
}

sub load_keys {
	my $obj = shift;

	my @keys = ();

	$obj->clear_keys;

	if (open F,$obj->keysfile) {
		while (<F>) {
			chomp;
			if (/^(.*?)\s+(.*)$/) {
				push @keys,{ key => $1, text => $2 };
				$obj->{-interface}->bind_key($1,$2);
			}
		}
		close F;
	}

	$obj->{-mempool}->set(keys => \@keys);
}

sub clear_keys {
	my $obj = shift;

	for my $def (@{$obj->{-mempool}->get('keys')}) {
		$obj->{-interface}->bind_key($def->{key},'');
	}
	$obj->{-mempool}->set(keys => []);
}

sub init {
	my $obj = shift;

	$obj->{-mempool}->set(keys => []);
	$obj->load_keys;
}

sub done {
	my $obj = shift;

	$obj->clear_keys;
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'KEYS') {
		if ($action{operation} eq 'clear') {
			$obj->clear_keys;
			my $add = '';
			$add = 'permanently ' if ($action{permanent} and unlink $obj->keysfile);
			$action{action} = 'OUTPUT';
			$action{output} = "Key bindings $add"."cleared.\n";
		} elsif ($action{operation} eq 'reload') {
			$obj->load_keys;
			my $count = @{$obj->{-mempool}->get('keys')};
			$action{action} = 'OUTPUT';
			$action{output} = "Key bindings reloaded ($count binding".($count == 1?'':'s').").\n";
		} elsif ($action{operation} eq 'show') {
			my @list = @{$obj->{-mempool}->get('keys')};
			$action{action} = 'OUTPUT';
			unless (@list) {
				$action{output} = "No key bindings yet.\n";
			} else {
				my $table = new Text::FormatTable '| l | l |';
				$table->rule;
				$table->head('KEY','TEXT');
				$table->rule;
				for my $def (@list) {
					$table->row($def->{key},$def->{text});
				}
				$table->rule;
				$action{output} = $table->render($obj->{-interface}->render_size);
			}
		} elsif ($action{operation} eq 'define') {
			$obj->{-interface}->print_prompt("Please press selected key.");
			$action{key} = $obj->{-interface}->get_key();
			$obj->{-interface}->print("Pressed ".$action{key}."\n");

			$obj->{-interface}->bind_key($action{key},$action{text});
			my @keys = @{$obj->{-mempool}->get('keys')};
			my @newkeys = ();
			for my $key (@keys) {
				push @newkeys,$key if $key->{key} ne $action{key};
			}
			push @newkeys,{ key => $action{key}, text => $action{text} };
			$obj->{-mempool}->set(keys => \@newkeys);
				
			my @all = ();
			if (open F,$obj->keysfile) {
				@all = <F>;
				close F;
			}
			if (open F,">".$obj->keysfile) {
				for my $line (@all) {
					chomp $line;
					if ($line =~ /^(.*?)\s+(.*)$/) {
						print F "$line\n" if $1 ne $action{key};
					}
				}
				print F "$action{key} $action{text}\n";
				close F;
			}

			$action{action} = 'OUTPUT';
			$action{output} = "Key binding defined.\n";
		} elsif ($action{operation} eq 'undefine') {
			$obj->{-interface}->print_prompt("Please press selected key.");
			$action{key} = $obj->{-interface}->get_key();
			$obj->{-interface}->print("Pressed ".$action{key}."\n");

			$obj->{-interface}->bind_key($action{key},'');
			my @keys = @{$obj->{-mempool}->get('keys')};
			my @newkeys = ();
			for my $key (@keys) {
				push @newkeys,$key if $key->{key} ne $action{key};
			}
			$obj->{-mempool}->set(keys => \@newkeys);

			if (open F,$obj->keysfile) {
				my @all = <F>;
				close F;
				if (open F,">".$obj->keysfile) {
					for my $line (@all) {
						chomp $line;
						if ($line =~ /^(.*?)\s+(.*)$/) {
							print F "$line\n" if $1 ne $action{key};
						}
					}
					close F;
				}
			}

			$action{action} = 'OUTPUT';
			$action{output} = "Key binding undefined.\n";
		}
	}

	$action{processed} = 1;
	return %action;
}
