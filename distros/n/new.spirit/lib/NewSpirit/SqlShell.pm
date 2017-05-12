package NewSpirit::SqlShell;

use strict;
use Data::Dumper;
use Config;

sub new {
	my $type = shift;
	
	my %par = @_;
	
	my $source      = $par{source};
	my $username    = $par{username};
	my $password    = $par{password};
	my $autocommit  = $par{autocommit};
	my $selected_db = $par{selected_db};
	my $prefs_file  = $par{preference_file};

	my $sql         = $par{sql};
	my $get_line_cb = $par{get_line_cb};
	my $echo        = $par{echo};
	
	my $self = {
		sql_sref        => $sql,
		abort_mode      => 0,
		current_command => undef,
		errors          => [],
		command_cnt     => 0,
		get_line_cb     => $get_line_cb,
		echo            => $echo,
		command_completed => 1,
		source		=> $source,
		username        => $username,
		selected_db     => $selected_db,
		preference_file	=> $prefs_file,
		preferences     => {
			'display_style'  => 'auto',
			'screen_width'   => 0,
			'prefs_autosave' => 'on',
			'history_size'   => 100,
		},
		preferences_declaration => {
			'display_style' => {
				'boxed' => 1,
				'row'   => 1,
				'auto'  => 1,
				'tab'   => 1,
			},
			'screen_width'  => 'integer',
			'history_size'  => 'integer',
			'prefs_autosave' => {
				'on' => 1,
				'off' => 1
			},
		}
	};
	
	${$self->{sql_sref}} .= "\n";

	bless $self, $type;
	
	my $dbh = DBI->connect (
		$source,
		$username,
		$password,
		{
			PrintError => 0,
			AutoCommit => $autocommit
		}
	);

	if ( $DBI::errstr ) {
		$self->{abort_mode} = 1;
		$self->error (
			"Can't connect to database",
			$DBI::errstr
		);
	} else {
		$self->{dbh} = $dbh;

		$self->info (
			"Connected to '$source' as user '$username'"
		);

		$self->info (
			'AutoCommit is initially set to '.
			($autocommit?'ON!':'OFF!')
		);
	}

	$self->load_preferences;

	return $self;
}

sub DESTROY {
	my $self = shift;

	if ( $self->get_preference ('prefs_autosave') eq 'on' ) {
		$self->save_preferences;
	}

	$self->info ("Disconnecting from '$self->{source}'");

	if ( defined $self->{dbh} ) {
		$self->{dbh}->disconnect;
	}
}

sub load_preferences {
	my $self = shift;
	
	my $prefs_file = $self->{preference_file};
	return if not -f $self->{preference_file};

	$self->info ("Loading preferences from '$prefs_file'...");

	my $prefs_href;
	{
		no strict 'vars';
		$prefs_href = do $prefs_file;
	}
	
	foreach my $key ( keys %{$self->{preferences_declaration}} ) {
		if ( exists $prefs_href->{$key} ) {
			$self->set_preference ( $key, $prefs_href->{$key} );
		}
	}
}

sub save_preferences {
	my $self = shift;
	
	my $prefs_file = $self->{preference_file};
	
	open (FH, "> $prefs_file") or
		return $self->error ("Can't write '$prefs_file'");
	print FH Dumper ($self->{preferences});
	close FH;

	$self->info ("Preferences successfully saved to '$prefs_file'...");

	1;
}

sub get_next_command_line {
	my $self = shift;
	
	# return if we are already at EOF
	return if $self->{eof};

	# call get_line callback if defined
	my $get_line_cb = $self->{get_line_cb};

	if ( $get_line_cb ) {
		return &$get_line_cb();
	}
	
	# otherwise take line from sql_sref
	my $sql_sref = $self->{sql_sref};

	if ( $$sql_sref =~ m/(.*)\n?/g ) {
		return $1;
	} else {
#		print "no line found<br>\n";
		$self->{eof} = 1;
		return;
	}
}

sub next_command {
	my $self = shift;
	
	my $sql_sref = $self->{sql_sref};

	$self->{command_completed} = 1;

	my $command;
#	print "command empty<br>\n";

	while (1) {
		my $line = $self->get_next_command_line;
		last if not defined $line;
		next if not $line;

#		print "got line: $line<br>\n";

		$self->{command_completed} = 0;

		# skip comments
		next if $line =~ m!^\s*(--|#)!;

		# add line to command variable
		$command .= $line;
		$command =~ s/\s+$//;
		$command .= "\n";

		if ( $command =~ /^\s*;\n$/ ) {
#			print "got empty command!<br>\n";
			$command = '';
			next;
		}
		
		# a semicolon a the end of the line terminates a command
		last if $command =~ /;\n$/;
		
		# internal commands need no semicolon
		last if $command =~ /^\s*(quit|exit|help|reload|saveprefs)\s*$/;
		last if $command =~ /^\s*(desc|autocommit|abort|set|\!)\s*([^\s]+\s*)*$/;
	}
	
	$command =~ s/^\s+//;
	$command =~ s/\s$//;
	$command =~ s/;$//;

	return $command;
}

sub error {
	my $self = shift;

	my ($msg, $comment) = @_;
	$msg ||= $DBI::errstr;

	if ( not ref $self) {
		# if called as a class method call print_error function
		# of the doughter class
		my $cmd = "$self:\:print_error ({}, \$msg, \$comment)";
		eval $cmd;
		die $@ if $@;
	} else {
		push @{$self->{errors}}, {
			command => $self->{current_command},
			command_cnt => $self->{command_cnt},
			msg => $msg
		};
		$self->print_error ($msg, $comment);
	}
}

sub loop {
	my $self = shift;
	
	return if $self->{abort_mode} and @{$self->{errors}};

	my $sql_command;
	while ( $sql_command = $self->next_command ) {
		$self->execute ($sql_command) or return;
		if ( $self->{abort_mode} and @{$self->{errors}} ) {
			$self->error ("Execution aborted!");
			last;
		}
	}

	1;
}

sub has_errors {
	my $self = shift;
	
	return scalar @{$self->{errors}};
}

sub execute {
	my $self = shift;
	
	my ($command) = @_;
	
	$self->{current_command} = $command;
	++$self->{command_cnt};

	$self->print_current_command;

	my ($cmd) = $command =~ m!^(\w+)!;
	$cmd =~ tr/A-Z/a-z/;

	return if $cmd eq 'quit' or $cmd eq 'exit';

	eval {
		my $method = "cmd_$cmd";
		$method = "cmd_system" if $command =~ m/^\!/;
		$self->$method ($command, $cmd);
	};

	if ( $@ =~ /object method/ ) {
		# No specific method for this cmd. Execute
		# it using the select schema. Maybe the
		# command returns a result set (Sybase often
		# does ;)
		
		#-- probably unescape the first character
		#-- (probably it's an escaped dbshell command)
		$command =~ s/^\\//;
		$self->cmd_select ($command, $cmd);
	} elsif ( $@ ) {
		die $@;
	}

	1;
}

sub get_preference {
	my $self = shift;
	
	my ($name) = @_;
	
	return $self->{preferences}->{$name};
}

sub set_preference {
	my $self = shift;
	
	my ($name, $value) = @_;
	
	$self->{preferences}->{$name} = $value;
}

sub print_preferences {
	my $self = shift;
	
	# display style is always 'row'
	my $old_pref = $self->get_preference ('display_style');
	$self->set_preference ('display_style', 'row');

	# print column titles
	$self->print_query_result_start (
		title_lref => [qw(NAME VALUE)]
	);

	my $prefs = $self->{preferences};

	my $i = 0;
	foreach my $key (sort keys %{$prefs} ) {

		$self->print_query_result_row (
			row_lref => [
				$key,
				$key eq 'display_style' ? $old_pref : $prefs->{$key},
			]

		);

		++$i;
	}
	
	$self->print_query_result_end;
	
	# restore display style
	$self->set_preference ('display_style', $old_pref);

	1;
}

#---------------------------------------------------------------------
# The following methods implement SQL command execution
#---------------------------------------------------------------------

sub cmd_help {
	my $self = shift;
	
	$self->print_help_header;
	
	print <<__EOH;
These commands are recognized by the shell, all other commands are
passed through the database without change:

---------------------------------------------------------------------
autocommit {on|off}	Switch AutoCommit on or off
abort {on|off}		Switch 'abort on error' on or off
desc table		Show definition of this table
exit | quit		Exit the shell
help			This help page
reload			Reload SqlShell modules (for debugging only)
saveprefs		Save preferences
set [par=value]		Sets user preferences. Currently possible
			parameters are:
			  display_style  = {row|boxed|auto|tab}
			  history_size   = number
			  prefs_autosafe = {on|off}
			  screen_width   = number (0 for autosize)
			If you ommit par=value a table of the
			current settings is printed
! [command]		Executes command with system shell.
			Starts a system shell, if command is omitted.
---------------------------------------------------------------------

SQL statements must be terminated with a ; sign and may be continued
over several lines. The internal commands described above may be
optionally terminated with a ; sign, if you like it.

Lines beginning with a hash or double dash sign (# or --) are treated
as comments and ignored by the interpreter.

__EOH
	
	$self->print_help_footer;
}

sub cmd_select {
	my $self = shift;
	
	my ($command, $cmd) = @_;

	my $dbh = $self->{dbh};
	
	my $sth = $dbh->prepare ($command);
	return $self->error if $DBI::errstr;
	
	my $rv = $sth->execute;
	return $self->error if $DBI::errstr;

	my $row;
	my $cnt;
	
	# Enter result fetch loop, only if there is a
	# result set (NUM_OF_FIELDS indicates that)

	if ( $sth->{NUM_OF_FIELDS} ) {
		while ( $row = $sth->fetchrow_arrayref ) {
			++$cnt;

			if ( $cnt == 1 ) {
				$self->print_query_result_start (
					title_lref => $sth->{NAME}
				);
			}

			if ( $DBI::errstr ) {
				$self->print_query_result_end;
				return $self->error;
			}

			# create a copy of the row, because DBI
			# works on a single buffer for all rows
			my @row = @{$row};

			$self->print_query_result_row (
				row_lref => \@row
			);
		}
	}
	
	$self->print_query_result_end;

	if ( $cnt ) {
		$self->info ("$cnt row".($cnt==1?'':'s')." fetched!");
	} else {
		if ( $cmd ne 'select' ) {
			if ( $rv ne '0E0' and $rv != -1 ) {
				$self->info("Rows processed: $rv");
			} else {
				$self->info("Ok");
			}
		} else {
			$self->info ("Empty result set!");
		}
	}

	$sth->finish;
	return $self->error if $DBI::errstr;
}

sub cmd_create {
	my $self = shift;
	
	my ($command) = @_;
	
	my $dbh = $self->{dbh};
	
	$dbh->do ($command);

	return $self->error if $DBI::errstr;
	
	my ($object) = $command =~ m!^\w+\s*(\w+)!;
	substr($object,0,1) = uc(substr($object,0,1));
	
	$self->info ("$object successfully created!");
}

sub cmd_drop {
	my $self = shift;
	
	my ($command) = @_;
	
	my $dbh = $self->{dbh};
	
	$dbh->do ($command);

	return $self->error if $DBI::errstr;
	
	my ($object) = $command =~ m!^\w+\s*(\w+)!;
	substr($object,0,1) = uc(substr($object,0,1));
	
	$self->info ("$object successfully dropped!");
}

sub cmd_desc {
	my $self = shift;
	
	my ($command) = @_;
	
	my $table = $command;
	$table =~ s/^desc\s+//i;
	
	my $dbh = $self->{dbh};
	
	my $sth = $dbh->prepare ("select * from $table");
	return $self->error if $DBI::errstr;
	
	$sth->execute;
	return $self->error if $DBI::errstr;

	# display style is always 'row'
	my $old_pref = $self->get_preference ('display_style');
	$self->set_preference ('display_style', 'row');

	# build hash of data types
	my $type_info_all = $dbh->type_info_all;

	my %data_types;
	my $DATA_TYPE_idx = $type_info_all->[0]->{DATA_TYPE};
	my $TYPE_NAME_idx = $type_info_all->[0]->{TYPE_NAME};
	
	my $len = @{$type_info_all};

	for (my $i=1; $i < $len; ++$i) {
		$data_types{$type_info_all->[$i]->[$DATA_TYPE_idx]}
			= $type_info_all->[$i]->[$TYPE_NAME_idx];
	}

	# print column titles
	$self->print_query_result_start (
		title_lref => [qw(NAME TYPE SIZE NULL)]
	);

	my $i = 0;
	foreach my $col (@{$sth->{NAME_lc}}) {

		$self->print_query_result_row (
			row_lref => [
				$col,
				$data_types{$sth->{TYPE}->[$i]} || 'N/A',
				$sth->{PRECISION}->[$i],
				$sth->{NULLABLE}->[$i] ? 'yes' : 'no'
			]

		);

		++$i;
	}
	
	$self->print_query_result_end;
	
	$sth->finish;

	# restore display style
	$self->set_preference ('display_style', $old_pref);
	
	1;
}

sub cmd_autocommit {
	my $self = shift;
	
	my ($command) = @_;
	
	my $par = $command;
	$par =~ s/^autocommit\s+//i;
	$par =~ s/\s+$//;
	$par =~ tr/A-Z/a-z/;

	if ( $par ne 'off' and $par ne 'on' ) {
		return $self->error ("usage: autocommit {on|off}");
	}

	my $dbh = $self->{dbh};
	$dbh->{AutoCommit} = ($par eq 'on');
	
	$self->info ("AutoCommit is now $par!");
}

sub cmd_abort {
	my $self = shift;
	
	my ($command) = @_;
	
	my $par = $command;
	$par =~ s/^abort\s+//i;
	$par =~ s/\s+$//;
	$par =~ tr/A-Z/a-z/;

	if ( $par ne 'off' and $par ne 'on' ) {
		return $self->error ("usage: abort {on|off}");
	}

	$self->{abort_mode} = ($par eq 'on');
	
	$self->info ("Abort mode is now $par!");
}

sub cmd_commit {
	my $self = shift;
	
	my $dbh = $self->{dbh};

	if ( $dbh->{AutoCommit} ) {
		return $self->error ('Commit with AutoCommit ON is impossible!');
	}
	
	$dbh->commit;
	return $self->error if $DBI::errstr;
	
	$self->info ("Changes successfully committed!");
}

sub cmd_rollback {
	my $self = shift;
	
	my $dbh = $self->{dbh};
	
	if ( $dbh->{AutoCommit} ) {
		return $self->error ('Rollback with AutoCommit ON is impossible!');
	}
	
	$dbh->rollback;
	return $self->error if $DBI::errstr;
	
	$self->info ("Changes successfully rolled back!");
}

sub cmd_reload {
	my $self = shift;
	
	$self->info ("reloading NewSpirit::SqlShell");
	do "NewSpirit/SqlShell.pm";
#	$self->info ("reloading NewSpirit::SqlShell::Text");
#	do "NewSpirit/SqlShell/Text.pm";
}

sub cmd_use {
	my $self = shift;
	
	my ($command) = @_;
	
	my $par = $command;
	$par =~ s/^use\s+//i;
	$par =~ s/\s+$//;

	$self->{dbh}->do ( $command );
	return $self->error if $DBI::errstr;

	$self->{selected_db} = $par;
	$self->info ("Database successfully changed to '$par'");
}

sub cmd_set {
	my $self = shift;
	
	my ($command) = @_;
	
	my $par = $command;
	$par =~ s/^set\s*//i;
	$par =~ s/\s*$//;

	if ( $par eq '') {
		$self->print_preferences;
		return 1;
	}

	my ($key, $value) = split (/\s*=\s*|\s+/, $par, 2);
	$value =~ s/^['"]//;
	$value =~ s/['"]$//;

	if ( not exists $self->{preferences}->{$key} ) {
		return $self->error ("Preference '$key' is unknown!");
	}
	
	if ( ref $self->{preferences_declaration}->{$key} ) {
		if ( not exists $self->{preferences_declaration}->{$key}->{$value} ) {
			return $self->error (
				"Preference value '$value' is unknown!",
				"Possible values are: ".
				join(", ", sort (keys(%{$self->{preferences_declaration}->{$key}})))
				);
		}
	} elsif ( $self->{preferences_declaration}->{$key} eq 'integer' ) {
		if ( $value !~ /^\d+$/ ) {
			return $self->error (
				"Preference value '$value' is not a number!"
				);
		}
	}
		
	$self->{preferences}->{$key} = $value;

	$self->info ("Preference '$key' set to '$value'");
}

sub cmd_saveprefs {
	my $self = shift;
	
	$self->save_preferences;
}

sub cmd_system {
	my $self = shift;
	
	my ($command) = @_;
	
	my $par = $command;
	$par =~ s/^\!\s*//i;
	
	if ( $par ) {
		system ($par);
	} else {
		my $shell = $Config{bash}||$Config{startsh};
		$shell =~ s/^#\!\s*//;
		$shell = 'cmd.exe' if not -f $shell;
		$self->info ("Starting subshell '$shell'");
		system ($shell);
	}
}

1;
