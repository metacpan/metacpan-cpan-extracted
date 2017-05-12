package DBIx::dbMan::Extension::MacroWorks;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;

our $VERSION = '0.03';

1;

sub IDENTIFICATION { return "000001-000086-000003"; }

sub preference { return 0; }

sub known_actions { return [ qw/MACRO/ ]; }

sub menu {
	my $obj = shift;

	return ( { label => 'Input', submenu => [
			{ label => 'Macros', submenu => [
				{ label => 'Show',
					action => { action => 'MACRO', operation => 'show' } },
				{ label => 'Clear',
					action => { action => 'MACRO', operation => 'clear' } },
				{ label => 'Reload',
					action => { action => 'KEYS', operation => 'reload' } }
		] } ] } );
}

sub macrofile {
	my $obj = shift;

	return $ENV{DBMAN_MACROFILE} if $ENV{DBMAN_MACROFILE};
	return $obj->{-config}->macro_file if $obj->{-config}->macro_file;
	return $ENV{HOME}.'/.dbman/macros';
}

sub load_macros {
	my $obj = shift;

	my @macros = ();

	if (open F,$obj->macrofile) {
		while (<F>) {
			chomp;
			push @macros,$_ if m#^s/(.+)/(.*)/[gei]?#;
		}
		close F;
	}

	$obj->{-mempool}->set(macros => \@macros);
}

sub clear_macros {
	my $obj = shift;

	$obj->{-mempool}->set(macros => []);
}

sub init {
	my $obj = shift;

	$obj->load_macros;
}

sub done {
	my $obj = shift;

	$obj->clear_macros;
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'MACRO') {
		if ($action{operation} eq 'clear') {
			$obj->clear_macros;
			my $add = '';
			$add = 'permanently ' if ($action{permanent} and unlink $obj->macrofile);
			$action{action} = 'OUTPUT';
			$action{output} = "Macro definitions $add"."cleared.\n";
		} elsif ($action{operation} eq 'reload') {
			$obj->load_macros;
			my $count = @{$obj->{-mempool}->get('macros')};
			$action{action} = 'OUTPUT';
			$action{output} = "Macro definitions reloaded ($count substitution".($count == 1?'':'s').").\n";
		} elsif ($action{operation} eq 'show') {
			my @list = @{$obj->{-mempool}->get('macros')};
			$action{action} = 'OUTPUT';
			unless (@list) {
				$action{output} = "No macro definition yet.\n";
			} else {
				my $table = new Text::FormatTable '| l | l | l |';
				$table->rule;
				$table->head('MACRO','SUBSTITUTION','FLAGS');
				$table->rule;
				for my $macro (sort @list) {
					$macro =~ s/^s\///;
					my $flags = '';
					$flags = $1 if $macro =~ s#/([ige])?$##;
					my $name = '';
					$name = $1 if $macro =~ s#^(.+?)\$?(?!\\)/##;
					$name =~ s/^\^//;
					
					$table->row($name,$macro,$flags);
				}
				$table->rule;
				$action{output} = $table->render($obj->{-interface}->render_size);
			}
		} elsif ($action{operation} eq 'define') {
			my $def = $action{macro};
			$action{action} = 'OUTPUT';
			if ($def !~ m#^s/(.+)/(.*)/[gei]?#) {
				$action{output} = "Invalid substitution definition.\n";
			} else {
				my @macros = @{$obj->{-mempool}->get('macros')};
				push @macros,$def;
				$obj->{-mempool}->set(macros => \@macros);
				my $addenum = '';
				if (open F,">>".$obj->macrofile) {
					print F "$def\n";
					close F;
				} else {
					$addenum = ", but not permanently";
				}
				$action{output} = "New macro substitution defined$addenum.\n";
			}
		} elsif ($action{operation} eq 'undefine') {
			my $def = $action{macro};
			my @macros = @{$obj->{-mempool}->get('macros')};
			my $i = 0;
			my @clearlist = ();
			for (@macros) {
				my $name = '';
				s#/([ige])?$##;
				$name = $1 if m#^s/\^?(.+?)\$?(?!\\)/#;
				push @clearlist,$i if ($name and $name eq $def);
				++$i;
			}
			$action{action} = 'OUTPUT';
			if (@clearlist) {
				delete $macros[$_] for reverse sort @clearlist;
				$obj->{-mempool}->set(macros => \@macros);

				if (open F,$obj->macrofile) {
					my @all = <F>;
					close F;
					if (open F,">".$obj->macrofile) {
						for my $line (@all) {
							chomp $line;
							my $test = $line;
							my $name = '';
							$test =~ s#/([ige])?$##;
							$name = $1 if $test =~ m#^s/(.+)(?!\\)/#;
							print F "$line\n" if ($name and $name ne $def);
						}
						close F;
					}
				}

				$action{output} = "Macro named $def undefined.\n";
			} else {
				$action{output} = "No macro named $def found.\n";
			}
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;

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
			if ($line =~ /^\s*[A-Z]*$/i) {
				push @result,$words[0];
			} else {
				my $saved = pop @words;
				while (@words) {
					$name = '$line =~ /^\s*'.join('\\s+',@words).'\s+\S*$/i';
					push @result,$saved if eval $name;
					$saved = pop @words;
				}
			}
		}
	}

	return @result;
}
