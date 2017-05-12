#!/usr/bin/perl -w
#
# (c) DELTA E.S., 2002 - 2003
# This package is free software; you can use it under "Artistic License" from
# Perl.
# Author		: Martin Kula, 1999 <martin.kula@deltaes.com>
#							to object model rewritten by
#							Jakub Spicak <jakub.spicak@deltaes.cz>
# $Id: Database.pm,v 1.16 2003/10/13 06:28:34 spicak Exp $
#

package DeltaX::Database;
use strict;
use DBI;
use Carp;
use DeltaX::Trace;
use Time::HiRes qw/gettimeofday tv_interval/;
use vars qw(@ISA @EXPORT @EXPORT_OK
	$VERSION
	$Dcmdstatus
	$Dsqlstatus
	$Derror_message
	$Dstr_command
);
use Exporter;
@ISA = ('Exporter');
@EXPORT = ();
@EXPORT_OK = qw(
	$Dstr_command
	$Derror_message
	$Dsqlstatus
	$Dcmdstatus
);

#########################################################################
# Setting global module variables
#########################################################################
$DeltaX::Database::VERSION = '3.5';				# Module version

#########################################################################
# Procedure declaration
#########################################################################

#########################################################################
sub new {
	my $pkg = shift;
	my $self = {};
	bless($self, $pkg);

	$self->{driver} = '';
	$self->{dbname} = '';
	$self->{user}	= '';
	$self->{auth}	= '';
	$self->{autocommit} = 0;
	$self->{datestyle}	= '';
	$self->{close_curs} = 0;
	$self->{cursor_type} = 'INTERNAL';
	$self->{trace}	= 0;
	$self->{app}	= '';
	$self->{host}	= '';
        $self->{port}   = '';
	$self->{codepage}	= '';
	$self->{stat_type} = 'none';
	$self->{stat_max_high} = 3;
	$self->{stat_max_all} = 1000;
	$self->{imix_number_correct} = 0;
        $self->{use_sequences} = 0;     # Informix server 1-use internal sequences 0-use external sequences

	croak ("DeltaX::Database::new called with odd number of parameters -".
			 " should be of the form field => value")
		if (@_ % 2);

	for (my $x = 0; $x <= $#_; $x += 2) {
		croak ("Unknown parameter $_[$x] in DeltaX::Database::new()")
		unless exists $self->{lc($_[$x])};
		$self->{lc($_[$x])} = $_[$x+1];
	}
	$self->{transaction} = 0;
	$self->{cursors} = {};
	$self->{statements} = {};

	my $orig_driver = $self->{driver};
	$self->{driver} = get_driver($self->{driver});
	if (! $self->{driver}) {
		$Derror_message = "MODULE ERROR: Can't get a DBD driver";
		return -3;
	}

	my %attr = ('AutoCommit' => $self->{autocommit}, 'PrintError' => 0);
	$self->{driver} = $self->get_source($self->{driver}, $self->{dbname});
	if (! $self->{driver}) {
		$Derror_message = "MODULE ERROR: Can't get a DB source";
		return -4;
	}

	my ($user, $auth);
	SWITCH: for ($self->{driver}) {
		/Pg/		&& do {
			$ENV{'PGDATESTYLE'} = $self->{datestyle} if $self->{datestyle};
			$user = $self->{user};
			$auth = $self->{auth};
			last SWITCH;};
		/Oracle/	&& do {
			$ENV{'NLS_DATE_FORMAT'} = $self->{datestyle} if $self->{datestyle};
			$auth = '';
			$user = $self->{auth} ? $self->{user}.'/'.$self->{auth} :
									$self->{user};
			last SWITCH;};
		/Informix/	&& do {
			$ENV{'DBDATE'} = $self->{datestyle} if $self->{datestyle};
			$user = $self->{user};
			$auth = $self->{auth};
			last SWITCH;};
		/DB2/	&& do {
			$ENV{'DB2CODEPAGE'} = $self->{codepage} if $self->{codepage};
			$user = $self->{user};
			$auth = $self->{auth};
			last SWITCH;};
		/mysql/		&& do {
			$user = $self->{user};
			$auth = $self->{auth};
			last SWITCH;};
		/Sybase/	&& do {
			$user = $self->{user};
			$auth = $self->{auth};
			last SWITCH;};
		/mssql/		&& do {
			$user = $self->{user};
			$auth = $self->{auth};
			last SWITCH;};
		/Solid/		&& do {
			$user = $self->{user};
			$auth = $self->{auth};
			last SWITCH;};
		# Default (not supported)
		$Derror_message = "MODULE ERROR: DBD driver not supported";
		return -5;
	}
	$self->{conn} = DBI->connect($self->{driver}, $user, $auth, \%attr);
	$self->{driver} = $orig_driver;
	$Dcmdstatus = $DBI::state;
	$Dsqlstatus = $DBI::err;
	$Derror_message = $DBI::errstr;
	$self->_trace() if ! $self->{conn} and $self->{trace};
	return undef if ! $self->{conn};
	return $self;

} # sub new()
	
#########################################################################
sub close {

	my $self = shift;

	$self->transaction_end(1) if $self->{transaction};
	$self->{conn}->disconnect if $self->{conn};

} # sub close

#########################################################################
sub check {
	
	my $self = shift;

	return -1 if ! $self->{conn};
	return 0 if $self->{conn}->ping;
	return -1;

} # END check


##########################################################################
sub transaction_begin {

	my $self = shift;
	my $type_f = shift;
	if (! defined $type_f) {
		$type_f = 1;
	}

    my $result = 0;
    if ($self->{autocommit}) {
      if ($self->{driver} eq 'Pg') {
        $result = $self->{conn}->begin_work();
      }
    } else {
	  $result = $self->transaction_end($type_f);
    }
	$self->{transaction} = 1 if $result > 0;

	return $result;

} # transaction_begin

##########################################################################
sub transaction_end {

	my $self = shift;
	my $type_f = shift;
	if (! defined $type_f) {
		$type_f = 1;
	}
	my $result;

	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return -2;
	}
	if ($self->{autocommit}) {
        if ($self->{driver} ne 'Pg') {
  		        $Derror_message = "MODULE ERROR: Autocommit ON";
       	    	return -1;
        }
	}
    if (! $self->{autocommit} or $self->{transaction}) {
        if ($type_f or ! $self->{transaction}) {
            if ($self->{driver} ne 'Oracle') {
                $result = $self->{conn}->commit;
            }
            else {
                $result = $self->{conn}->do('COMMIT');
            }
        }
        else {
            if ($self->{driver} ne 'Oracle') {
                $result = $self->{conn}->rollback if ! $type_f;
            }
            else {
                $result = $self->{conn}->do('ROLLBACK');
            }
        }
        $self->{transaction} = 0;
        $self->{cursors} = {} if $self->{close_curs};
    }

	return 1 if $result;
	return 0;

} # transaction_end

#########################################################################
sub select {

	my $self = shift;
	my $sql_command = shift;
	my @ret_array;

	if (! defined $sql_command) {
		$Derror_message = "MODULE ERROR: SQL command not defined";
		return (-2);
	}
	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return (-3);
	}

	$self->_stat_start('SELECT', $sql_command, undef);

	$Dstr_command = $sql_command;
	my $statement = $self->{conn}->prepare($sql_command);
	if (! $statement ) {
		$Dcmdstatus = $self->{conn}->state;
		$Dsqlstatus = $self->{conn}->err;
		$Derror_message = $self->{conn}->errstr;
		$self->_trace() if $self->{trace};
		$self->_stat_end('ERROR');
		return (-1);
	}
	my $result = $statement->execute;
	$Dcmdstatus = $statement->state;
	$Dsqlstatus = $statement->err;
	$Derror_message = $statement->errstr;
	if ($self->{driver} eq 'mssql') {
		$result = !$self->{conn}->err;
	}
	if (! $result ) {
		# SQL command failed
		$self->_trace() if $self->{trace};
		$self->transaction_end(0) if ! $self->{transaction};
		$self->_stat_end('ERROR');
		return (-1);
	}
	my $ret_rows = $statement->rows;

	@ret_array = $statement->fetchrow_array;
	$ret_rows =  1 if scalar @ret_array and
		grep {$self->{driver} eq $_} ('Oracle','Informix','mssql','DB2','Solid');
	$ret_rows = 0 if $#ret_array < 0 and grep {$self->{driver} eq $_} ('mssql', 'DB2', 'Solid') and
		!$statement->err;
	if ($#ret_array < 0 and ($statement->err or $ret_rows)) {
		$Dcmdstatus = $statement->state;
		$Dsqlstatus = $statement->err;
		$Derror_message = $statement->errstr;
		$self->_trace() if $self->{trace};
		$self->transaction_end(0) if ! $self->{transaction};
		$self->_stat_end('ERROR');
		return (-1);
	}

	# convert data for MS SQL
	if ($self->{driver} eq 'mssql') {
		@ret_array = map { y/\x9a\x9e\x8a\x8e/¹¾©®/; $_ } @ret_array;
	}
	# correct numbers for Informix
  if ($self->{driver} eq 'Informix' and $self->{imix_number_correct}) {
		my @types = @{$statement->{TYPE}};
		for (my $i=0; $i<=$#ret_array; $i++) {
			next if $types[$i] != DBI::SQL_DECIMAL;
			next if !defined $ret_array[$i];
			$ret_array[$i] += 0;
		}
	}

	$self->_stat_end('OK');
	return ($ret_rows, @ret_array);

} # select
	
#########################################################################
sub open_cursor {

	my $self = shift;
	my $cursor_name = shift;

	if (!$self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return -3;
	}

	my $sql_command = shift;
	if (! defined $sql_command) {
		$Derror_message = "MODULE ERROR: SQL command not defined";
		return -2;
	}

	my $cursortype = $self->{cursor_type};
	my $result;
	my $statement;
	my $statement_name = undef;
	my @bind_values;

	if (exists $self->{statements}->{$self->{app}.$sql_command}) {
		# cursor from prepared statement
		$statement_name = $sql_command;
		$statement_name = $self->{app} . $statement_name;
		$Dstr_command = $self->{statements}->{$statement_name}->[5];
		return -20
			if !$self->{statements}->{$statement_name}->[3];	# not is_select
		$cursortype = 'INTERNAL';
		$statement = $self->{statements}->{$statement_name}->[0];
		if ($#_ < 0 ) {
			return -21 if ! $self->{statements}->{$statement_name}->[2] 
						and $self->{statements}->{$statement_name}->[1]; 
			@bind_values = @{$self->{statements}->{$statement_name}->[4]};
		}
		else {
			for (1 .. $self->{statements}->{$statement_name}->[1]) {
				push @bind_values, shift;
			}
		}
		return -22 if $self->{statements}->{$statement_name}->[1] !=
			scalar @bind_values;
		$self->{statements}->{$statement_name}->[4] = \@bind_values;

		$self->_stat_start('CURSOR_STATEMENT', $Dstr_command, \@bind_values, $sql_command);

		# MS SQL
		if ($self->{driver} eq 'mssql') {
			my $sql = $self->_replace_values($self->{statements}->{$statement_name}->[5],
				@bind_values);
			$statement = $self->{conn}->prepare($sql);
			if (! $statement ) {
				$Dcmdstatus = $self->{conn}->state;
				$Dsqlstatus = $self->{conn}->err;
				$Derror_message = $self->{conn}->errstr;
				$self->_trace(@bind_values) if $self->{trace};
				$self->_stat_end('ERROR');
				return -1;
			}
			$result = $statement->execute;
		}
		else {
			$result = $statement->execute(@bind_values);
		}
	}
	else {
		if ($#_ >= 0) {
			$cursortype = shift;
		}
		return -23 if $cursortype !~ /^INTERNAL|^EXTERNAL/;
		$cursortype = 'INTERNAL' if $self->{driver} eq 'mssql';

		$Dstr_command = $sql_command;
		$self->_stat_start('CURSOR_SQL', $Dstr_command, \@bind_values);

		if ( exists $self->{cursors}->{$cursor_name} ) {
			undef $self->{cursors}->{$cursor_name};
		}

		$statement = $self->{conn}->prepare($sql_command);
		if (! $statement ) {
			$Dcmdstatus = $self->{conn}->state;
			$Dsqlstatus = $self->{conn}->err;
			$Derror_message = $self->{conn}->errstr;
			$self->_trace(@bind_values) if $self->{trace};
			$self->_stat_end('ERROR');
			return -1;
		}
		$result = $statement->execute;
	}
	$Dcmdstatus = $statement ? $statement->state : $self->{conn}->state;
	$Dsqlstatus = $statement ? $statement->err : $self->{conn}->err;
	$Derror_message = $statement ? $statement->errstr : $self->{conn}->errstr;

	# Sybase driver returns -1 in case of success (?!)
	if (grep {$self->{driver} eq $_} ('mssql','DB2', 'Solid')
								and !$Derror_message and $result eq '-1') {
		$result = 1;
	}

	if (! $result ) {
		# SQL command failed
		$self->_trace(@bind_values) if $self->{trace};
		$self->transaction_end(0) if ! $self->{transaction};
		$self->_stat_end('ERROR');
		return -1;
	}
	if (defined $statement_name) { 
		$self->{statements}->{$statement_name}->[2]++;
	}
	my $ret_rows = $statement->rows;
	if ($self->{driver} eq 'Oracle' and ! $ret_rows) {
		$ret_rows = '0E0';
	}
	if (grep {$self->{driver} eq $_} ('mssql', 'DB2', 'Solid') and $ret_rows < 0) {
		$ret_rows = '0E0';
	}
	my $cur_ref;

	if ( $ret_rows >= 0 ) {
		if ($cursortype eq 'INTERNAL') {
			$cur_ref =	$statement->fetchall_arrayref;
			$ret_rows = scalar @$cur_ref;
			if (! $cur_ref and ($statement->err or $ret_rows)) {
				$Dcmdstatus = $statement->state;
				$Dsqlstatus = $statement->err;
				$Derror_message = $statement->errstr;
				$self->_trace(@bind_values) if $self->{trace};
				$self->transaction_end(0) if ! $self->{transaction};
				$self->_stat_end('ERROR');
				return -1;
			}
			else {
				$self->{cursors}->{$cursor_name} = [$cur_ref, $ret_rows, -1,
											 $cursortype, $Dstr_command];
			}
		}
		else {
			if ($self->{driver} eq 'Informix' and ! $ret_rows) {
				$ret_rows = 1;
			}
			$self->{cursors}->{$cursor_name} = [$statement, $ret_rows, -1,
										 $cursortype, $Dstr_command];
		}
	}
	$self->_stat_end('OK');
	return $ret_rows; 

} # open_cursor

#########################################################################
sub fetch_cursor {

	my $self = shift;
	my @ret_array;
	my $result;
	my $num_row;
	my @tmp_array;
	my $cursor_name = shift;

	if (! defined $cursor_name) {
		$Derror_message = "MODULE ERROR: cursor not defined";
		return (-2);
	}
	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return (-4);
	}

	if ( not exists $self->{cursors}->{$cursor_name} 
		or not defined $self->{cursors}->{$cursor_name}) {
		$Derror_message = "MODULE ERROR: cursor ($cursor_name) not exists";
		return (-3);
	}
	$Dstr_command = $self->{cursors}->{$cursor_name}->[4];
	$ret_array[0] = $self->{cursors}->{$cursor_name}->[1];
	if ($self->{cursors}->{$cursor_name}->[3] eq 'INTERNAL') {
		$num_row = $self->{cursors}->{$cursor_name}->[2] + 1;
		if ( $#_ >= 0 ) {
			$num_row = shift;
		}
		$num_row = $self->{cursors}->{$cursor_name}->[1] - 1
			if $num_row =~ /^LAST/;
		$num_row = 0 if $num_row =~ /^FIRST/;
		if ( $num_row > $self->{cursors}->{$cursor_name}->[1] - 1 ) {
			return (0);
		}

		push @ret_array, @{$self->{cursors}->{$cursor_name}->[0]->[$num_row]}
			if $ret_array[0];
	}
	else {
		$num_row = $self->{cursors}->{$cursor_name}->[2] + 1;
		@tmp_array = $self->{cursors}->{$cursor_name}->[0]->fetchrow_array;
		if (! @tmp_array) {
			return (0);
		}
		push @ret_array, @tmp_array;
	}
	if ($num_row >= $self->{cursors}->{$cursor_name}->[1]) {
		$self->{cursors}->{$cursor_name}->[2] = -1;
	}
	else {
		$self->{cursors}->{$cursor_name}->[2] = $num_row;
	}

	if ($self->{driver} eq 'Informix') {
		for (my $i=0; $i<=$#ret_array; $i++) {
			$ret_array[$i] =~ s/[ ]*$//g;
		}
	}

	# convert data for MS SQL
	if ($self->{driver} eq 'mssql') {
		@ret_array = map { y/\x9a\x9e\x8a\x8e/¹¾©®/; $_ } @ret_array;
	}
	# correct numbers for Informix
	if ($self->{driver} eq 'Informix' and $self->{imix_number_correct}) {
		my @types = @{$self->{cursors}->{$cursor_name}->[5]};
		for (my $i=1; $i<=$#ret_array; $i++) {
			next if $types[$i-1] != DBI::SQL_DECIMAL;
			next if !defined $ret_array[$i];
			$ret_array[$i] += 0;
		}
	}

	return @ret_array;

} # fetch_cursor

#########################################################################
sub close_cursor {

	my $self = shift;
	my $cursor_name = shift;

	if (! defined $cursor_name) {
		$Derror_message = "MODULE ERROR: cursor not defined";
		return -2;
	}
	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return -4;
	}

	if ( not exists $self->{cursors}->{$cursor_name} ) {
		$Derror_message = "MODULE ERROR: cursor ($cursor_name) not exists";
		return -3;
	}
	#$Dstr_command = $self->{cursors}->{$cursor_name}->[4];
	delete $self->{cursors}->{$cursor_name};

	return 0;

} # close_cursor

#########################################################################
sub exists_cursor {
	
	my $self = shift;
	my $cursor_name = shift;
	
	return 0 if ! $cursor_name;
	if ( not exists $self->{cursors}->{$cursor_name} 
		or not defined $self->{cursors}->{$cursor_name}) {
		$Derror_message = "MODULE ERROR: cursor ($cursor_name) not exists";
		return 0;
	}
	return 1;

} # END exists_cursor


#########################################################################
sub open_statement {

	my $self = shift;
	my $statement_name = shift;
	$statement_name = $self->{app} . $statement_name;

	if (! defined $statement_name) {
		$Derror_message = "MODULE ERROR: statement not defined";
		return -2;
	}

	my $sql_command = shift;

	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return -4;
	}

	if (! defined $sql_command) {
		$Derror_message = "MODULE ERROR: SQL command not defined";
		return -2;
	}

	my $is_select = 1 if uc($sql_command) =~ /^[	\n]*SELECT[  \n]/;

	my $bind_re = '\?\w?|!';
	my @sqlc_tmp = $sql_command =~ /$bind_re/g;
	my $number_bval = scalar @sqlc_tmp;
	$sql_command =~ s/$bind_re/?/g;
	if ($#_ >= 0) {
		if ($number_bval != shift) {
			$Derror_message = "MODULE ERROR: Number of the bind value not matched";
			return -3;
		}
	}

	if ( exists $self->{statements}->{$statement_name} ) {
		undef $self->{statements}->{$statement_name};
	}

	# MS SQL cannot prepare statements
	if ($self->{driver} eq 'mssql') {
		$self->{statements}->{$statement_name} =
			[undef, $number_bval, 0, $is_select, [], $sql_command];
		return $number_bval;
	}

	my $statement = $self->{conn}->prepare($sql_command);
	$Dstr_command = $sql_command;
	if (! $statement ) {
		$Dcmdstatus = $self->{conn}->state;
		$Dsqlstatus = $self->{conn}->err;
		$Derror_message = $self->{conn}->errstr;
		$self->_trace() if $self->{trace};
		return -1;
	}

	if ($self->{driver} eq 'Oracle') {
		for (my $i = 0; $i < scalar @sqlc_tmp; $i++) {
			# BLOB
			if ($sqlc_tmp[$i] eq '!' or uc($sqlc_tmp[$i]) eq '?B') {
				return if ! $statement->bind_param($i + 1, undef,
				 {ora_type => 113});
			}
			# CLOB
			if (uc($sqlc_tmp[$i]) eq '?C') {
				return if ! $statement->bind_param($i + 1, undef,
				 {ora_type => 112});
			}
		}
	}

	$self->{statements}->{$statement_name} =
		[$statement, $number_bval, 0, $is_select, [], $sql_command];
	return $number_bval; 

} # open_statement

#########################################################################
sub perform_statement {

	my $self = shift;
	my @ret_array;
	my $result;
	my $num_rows;
	my @tmp_array;
	my @bind_values;
	my $statement;
	my $statement_name = shift;
	$statement_name = $self->{app} . $statement_name;

	if (! defined $statement_name) {
		$Derror_message = "MODULE ERROR: statement name not defined";
		return (-2);
	}

	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return (-4);
	}

	if ( not exists $self->{statements}->{$statement_name} 
		or not defined $self->{statements}->{$statement_name}) {
		$self->_trace_msg("Statement '$statement_name' does not exists!") 
			if $self->{trace};
		$Derror_message = "MODULE ERROR: Statement ($statement_name) not exists";
		return (-3);
	}
	$Dstr_command = $self->{statements}->{$statement_name}->[5];
	$statement = $self->{statements}->{$statement_name}->[0];
	if ($#_ < 0 ) {
		if (! $self->{statements}->{$statement_name}->[2] 
					and $self->{statements}->{$statement_name}->[1]) {
			$Derror_message = "MODULE ERROR: Number of the bind value not matched";
			return -2;
		}
		@bind_values = @{$self->{statements}->{$statement_name}->[4]};
	}
	else {
		for (1 .. $self->{statements}->{$statement_name}->[1]) {
			push @bind_values, shift;
		}
	}
		
	if ($self->{statements}->{$statement_name}->[1] != scalar @bind_values) {
		$Derror_message = "MODULE ERROR: Number of the bind value not matched";
		return -2;
	}
	$self->{statements}->{$statement_name}->[4] = \@bind_values;

	$self->_stat_start('PERFORM', $Dstr_command, \@bind_values, $statement_name);
		
	# MS SQL
	if ($self->{driver} eq 'mssql') {
		# replace values
		my $sql = $self->_replace_values($self->{statements}->{$statement_name}->[5],
			@bind_values);
		if ($self->{statements}->{$statement_name}->[3]) {	 # is_select
			return $self->select($sql);
		}
		else {
			return $self->command($sql);
		}	
	}
	
	$result = $statement->execute(@bind_values);
	$Dcmdstatus = $statement->state;
	$Dsqlstatus = $statement->err;
	$Derror_message = $statement->errstr;
	if (! $result ) {
		# SQL command failed
		$self->_trace(@bind_values) if $self->{trace};
		$self->transaction_end(0) if ! $self->{transaction};
		$self->_stat_end('ERROR');
		return (-1);
	}
	$num_rows = $statement->rows;

	if ($self->{statements}->{$statement_name}->[3]) {	 # is_select
		@ret_array = $statement->fetchrow_array;
		if (grep {$self->{driver} eq $_} ('DB2', 'Solid', 'Oracle', 'Informix')) {
			if (scalar @ret_array) {
				$num_rows =  1
			}
			elsif ($statement->err) {
				$Dcmdstatus = $statement->state;
				$Dsqlstatus = $statement->err;
				$Derror_message = $statement->errstr;
				$self->_trace(@bind_values) if $self->{trace};
				$self->transaction_end(0) if ! $self->{transaction};
				$self->_stat_end('ERROR');
				return (-1);
			}
			else {
				$num_rows = 0;
			}
			$statement->finish;
		}
		elsif ($#ret_array < 0 and ($statement->err or $num_rows)) {
			$Dcmdstatus = $statement->state;
			$Dsqlstatus = $statement->err;
			$Derror_message = $statement->errstr;
			$self->_trace(@bind_values) if $self->{trace};
			$self->transaction_end(0) if ! $self->{transaction};
			$self->_stat_end('ERROR');
			return (-1);
		}
	}
	$self->{statements}->{$statement_name}->[2]++;

	if ($self->{driver} eq 'Informix') {
		for (my $i=0; $i<=$#ret_array; $i++) {
			$ret_array[$i] =~ s/[ ]*$//g;
		}
	}

	# Transakci automaticky neukoncuji, pokud se jedna o select!!!
	# JS
	#Dtransaction_end($sid, 1) if ! $Dtransaction[$sid];
	$self->_stat_end('OK');
	if ($self->{statements}->{$statement_name}->[3]) {	 # is_select
		if ($self->{driver} eq 'Informix' and $self->{imix_number_correct}) {
			my @types = @{$statement->{TYPE}};
			for (my $i=0; $i<=$#ret_array; $i++) {
				next if $types[$i] != DBI::SQL_DECIMAL;
				next if !defined $ret_array[$i];
				$ret_array[$i] += 0;
			}
		}
		return ($num_rows, @ret_array);
	}
	else {
		$self->transaction_end(1) if ! $self->{transaction};
		return($num_rows);
	}

} # perform_statement


#########################################################################
sub close_statement {

	my $self = shift;
	my $statement_name = shift;
	$statement_name = $self->{app} . $statement_name;

	if (! defined $statement_name) {
		$Derror_message = "MODULE ERROR: statement name not defined";
		return -2;
	}

	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return -4;
	}

	if ( not exists $self->{statements}->{$statement_name} ) {
		$Derror_message = "MODULE ERROR: Statement ($statement_name) not exists";
		return -3;
	}

	#$Dstr_command = $self->{statements}->{$statement_name}->[5];
	delete $self->{statements}->{$statement_name};

	return 0;

} # close_statement

#########################################################################
sub exists_statement {

	my $self = shift;
	my $statement_name = shift;
	$statement_name = $self->{app} . $statement_name;
	
	return 0 if ! defined $statement_name;
	if ( not exists $self->{statements}->{$statement_name} ) {
		$Derror_message = "MODULE ERROR: Statement ($statement_name) not exists";
		return 0;
	}
	return 1;
} # END exists_statement

#########################################################################
sub insert {

	my $self = shift;
	my $insert_command = shift;

	if (! defined $insert_command) {
		$Derror_message = "MODULE ERROR: INSERT command not defined";
		return -2;
	}

	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return -3;
	}


	$self->_stat_start('INSERT', $insert_command, undef);

	$Dstr_command = $insert_command;
	my $result = $self->{conn}->do($insert_command);
	if ($self->{driver} eq 'mssql') {
		$result = !$self->{conn}->err;
	}

	$Dsqlstatus = $self->{conn}->err;
	$Dcmdstatus = $self->{conn}->state;
	$Derror_message = $self->{conn}->errstr;
	if (! $result) {
		$self->_trace() if $self->{trace};
		$self->transaction_end(0) if ! $self->{transaction};
		$self->_stat_end('ERROR');
		return -1;
	}
	$self->transaction_end(1) if ! $self->{transaction};
	$self->_stat_end('OK');
	return $result;

} # insert

#########################################################################
sub delete {

	my $self = shift;
	my $delete_command = shift;

	if (! defined $delete_command) {
		$Derror_message = "MODULE ERROR: DELETE command not defined";
		return -2;
	}

	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return -3;
	}

	$self->_stat_start('DELETE', $delete_command, undef);

	$Dstr_command = $delete_command;
	my $result = $self->{conn}->do($delete_command);
	if ($self->{driver} eq 'mssql') {
		$result = !$self->{conn}->err;
	}
				$result = 1 if $self->{driver} eq 'mysql' && $result eq '0E0';

	$Dsqlstatus = $self->{conn}->err;
	$Dcmdstatus = $self->{conn}->state;
	$Derror_message = $self->{conn}->errstr;
	if (! $result) {
		$self->_trace() if $self->{trace};
		$self->transaction_end(0) if ! $self->{transaction};
		$self->_stat_end('ERROR');
		return -1;
	}
	$self->transaction_end(1) if ! $self->{transaction};
	$self->_stat_end('OK');
	return $result;

} # delete

#########################################################################
sub update {

	my $self = shift;
	my $update_command = shift;

	if (! defined $update_command) {
		$Derror_message = "MODULE ERROR: UPDATE command not defined";
		return -2;
	}

	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return -3;
	}

	$self->_stat_start('UPDATE', $update_command, undef);

	$Dstr_command = $update_command;
	my $result = $self->{conn}->do($update_command);
	if ($self->{driver} eq 'mssql') {
		$result = !$self->{conn}->err;
	}

	$result = 1 if $self->{driver} eq 'mysql' && $result eq '0E0';

	$Dsqlstatus = $self->{conn}->err;
	$Dcmdstatus = $self->{conn}->state;
	$Derror_message = $self->{conn}->errstr;
	if (! $result) {
		$self->_trace() if $self->{trace};
		$self->transaction_end(0) if ! $self->{transaction};
		$self->_stat_end('ERROR');
		return -1;
	}
	$self->transaction_end(1) if ! $self->{transaction};
	$self->_stat_end('OK');
	return $result;

} # update

#########################################################################
sub command {

	my $self = shift;
	my $sql_command = shift;

	if (! defined $sql_command) {
		$Derror_message = "MODULE ERROR: SQL command not defined";
		return -2;
	}

	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return -3;
	}

	$self->_stat_start('COMMAND', $sql_command, undef);

	$Dstr_command = $sql_command;
	my $result = $self->{conn}->do($sql_command);
	if ($self->{driver} eq 'mssql') {
		$result = !$self->{conn}->err;
	}

	$Dsqlstatus = $self->{conn}->err;
	$Dcmdstatus = $self->{conn}->state;
	$Derror_message = $self->{conn}->errstr;
	if (! $result) {
		$self->_trace() if $self->{trace};
		$self->transaction_end(0) if ! $self->{transaction};
		$self->_stat_end('ERROR');
		return -1;
	}
	$self->transaction_end(1) if ! $self->{transaction};
	$self->_stat_end('OK');
	return 1;

} # command

#########################################################################
sub func {

	my $self = shift;

	my $result = $self->{conn}->func(@_);
	$Dsqlstatus = $self->{conn}->err;
	$Dcmdstatus = $self->{conn}->state;
	$Derror_message = $self->{conn}->errstr;
	$self->_trace() if $self->{trace} and ! $result;

	return $result;
	
} # func

#########################################################################
sub const {

	my $self = shift;
	my $const_name = shift;
	my $value = shift;
	
	if (defined $value) {
		$self->{conn}->{$const_name} = $value;
	}

	return $self->{conn}->{$const_name};
	
} # const

#########################################################################
sub nextval {

	my $self = shift;
	my $seq_name = shift;
	my @sqlresult;

	if (! defined $seq_name) {
		$Derror_message = "MODULE ERROR: Sequence name not defined";
		return -2;
	}

	if (! $self->{conn}) {
		$Derror_message = "MODULE ERROR: DB connect not exists";
		return -3;
	}

	if ($self->{driver} eq 'Pg') {
		@sqlresult = $self->select("select nextval('$seq_name')");
		return -1 if $sqlresult[0] < 1;
		return $sqlresult[1];
	}
        elsif ($self->{use_sequences} && $self->{driver} eq 'Informix') {
                @sqlresult = $self->select("select $seq_name.nextval from kdb_sequences ".
                        "where sequence_name = 'dual'");
                return -1 if $sqlresult[0] < 1;
                return $sqlresult[1];
        }
	elsif ($self->{driver} eq 'Oracle') {
		@sqlresult = $self->select("select $seq_name.nextval from dual");
		return -1 if $sqlresult[0] < 1;
		return $sqlresult[1];
	}
	elsif ($self->{driver} eq 'Solid') {
		@sqlresult = $self->select("select $seq_name.nextval");
		return -1 if $sqlresult[0] < 1;
		return $sqlresult[1];
	}
	elsif (grep {$self->{driver} eq $_} ('Informix', 'mssql', 'DB2', 'mysql')) {
		my $trans = $self->{transaction};
		my $sqlresult = 0;
		my $ret_val;
		$trans = 1 if $self->{autocommit};
		$sqlresult = $self->transaction_begin(1) if ! $trans;
		return -1 if $sqlresult < 0;
		$sqlresult = $self->open_cursor('Kdb-CUR_SEQ',
									 "select init_v, step_v, finish_v, act_v ".
									 "from kdb_sequences where ".
									 "sequence_name = '$seq_name'");
		if ($sqlresult < 0) {
			$self->transaction_end(0) if ! $trans;
			return -1;
		}
		@sqlresult = $self->fetch_cursor('Kdb-CUR_SEQ');
		if ($sqlresult[0] < 1) {
			$self->transaction_end(0) if ! $trans;
			return -1;
		}
		$self->close_cursor('Kdb-CUR_SEQ');
		if ($sqlresult[4] == 0) {
			$ret_val = $sqlresult[1];
		}
		elsif (($sqlresult[4] + $sqlresult[2]) <= $sqlresult[3]) {
			$ret_val = $sqlresult[4] + $sqlresult[2];
		}
		else {
			$ret_val = 0;
		}
		if ($ret_val) {
			$sqlresult = $self->update("update kdb_sequences set ".
								 "act_v = $ret_val ".
								 "where sequence_name = '$seq_name'");
			if ($sqlresult < 0) {
				$self->transaction_end(0) if ! $trans;
				return -1;
			}
		}
		$self->transaction_end(1) if ! $trans;
		return $ret_val;
	}

	$Derror_message = "MODULE ERROR: DBD driver not supported";
	return -2;

} # nextval

#########################################################################
sub quote {

	my $self = shift;
	my $string;
	my @retstr = ();

	for (@_) {
		push @retstr, $self->{conn}->quote($_);
	}

	return @retstr;

} # quote

#########################################################################
sub date2db {

	my $self = shift;
	my $type = shift;
	my ($year, $mon, $day, $hour, $min, $sec);
	my ($d, $t);
	my ($idatetime, $odatetime);

	if (uc $type eq 'PREPARED') {
		$type = 0;
		$idatetime = shift;
		if (defined $idatetime and
			 ($idatetime eq '?' or $idatetime eq '??')) {
			if ($self->{driver} eq 'Oracle') {
				if ($idatetime eq '?') {
					return "TO_DATE(?, 'dd.mm.yyyy')";
				}
				else {
					return "TO_DATE(?, 'dd.mm.yyyy hh24:mi:ss')";
				}
			}
			elsif ($self->{driver} eq 'mssql') {
				return "convert(datetime, ?, 120)";
			}
			elsif (grep {$self->{driver} eq $_} ('Pg','Informix','Sybase','DB2','mysql','Solid')) {
				return '?';
			}
			else {
				return undef;
			}
		}
	}
	elsif ( uc $type eq 'COMMON') {
		$type = 1;
		$idatetime = shift;
	}
	else {
		$idatetime = $type;
		$type = 1;
	}
	if ($#_ < 0) {		# input is in the $idatetime
		if (defined $idatetime && $idatetime !~ /!/) {
			($d, $t) = split / /, $idatetime;
			($day, $mon, $year) = split /\./, $d;
			if (defined $t) {
				($hour, $min, $sec) = split /:/, $t;
				$t = 1;
			}
			else {
				$t = 0;
			}
		}
		else {
			($sec, $min, $hour, $day, $mon, $year) = localtime;
			if (!defined $idatetime || $idatetime ne '!') {
				$t = 1;
			}
			else {
				$t = 0;
			}
		}
	}
	elsif ($#_ < 1) { # input is mon and year
		$mon = $idatetime;
		$year = shift;
		$t = 0;
	}
	elsif ($#_ < 2) { # input is day, mon and year
		$day = $idatetime;
		$mon = shift;
		$year = shift;
		$t = 0;
	}
	elsif ($#_ < 3) { # input is hour, day, mon and year
		$hour = $idatetime;
		$day = shift;
		$mon = shift;
		$year = shift;
		$t = 1;
		$min = 0;
		$sec = 0;
	}
	elsif ($#_ < 4) { # input is min, hour, day, mon and year
		$min = $idatetime;
		$hour = shift;
		$day = shift;
		$mon = shift;
		$year = shift;
		$t = 1;
		$sec = 0;
	}
	else {				# input is sec, min, hour, day, mon and year
		$sec = $idatetime;
		$min = shift;
		$hour = shift;
		$day = shift;
		$mon = shift;
		$year = shift;
		$t = 1;
	}

	if ($mon == 0 or $year < 1000) { # perl-localtime output
		$mon++;
		$year += 1900;
	}
	if ($mon == 1 or $mon == 3 or $mon == 5 or $mon == 7 or $mon == 8 or
		$mon == 10 or $mon == 12) {
		if (! defined $day) {
			$day = 31;
		}
		elsif ($day > 31) {
			return undef;
		}
	}
	elsif ($mon == 4 or $mon == 6 or $mon == 9 or $mon == 11) {
		if (! defined $day) {
			$day = 30;
		}
		elsif ($day > 30) {
			return undef;
		}
	}
	elsif ($year % 4 or (!($year % 100) and $year % 1000)) {
		if (! defined $day) {
			$day = 28;
		}
		elsif ($day > 28) {
			return undef;
		}
	}
	else {
		if (! defined $day) {
			$day = 29;
		}
		elsif ($day > 29) {
			return undef;
		}
	}
	# some tests
	return undef if $mon < 1 or $mon > 12 or $day < 1;
	return undef if $t and ($hour < 0 or $hour > 23 or $min < 0 or $min > 59 or
							$sec < 0 or $sec > 59);

	if ($self->{driver} eq 'Oracle') {
		if ($type) {
			if ($t) {
				$odatetime = sprintf "TO_DATE('%02d.%02d.%04d %02d:%02d:%02d',".
									 "'dd.mm.yyyy hh24:mi:ss')",
									 $day, $mon, $year, $hour, $min, $sec;
			}
			else {
				$odatetime = sprintf "TO_DATE('%02d.%02d.%04d', 'dd.mm.yyyy')",
									 $day, $mon, $year;
			}
		}
		else {
			# WARNING - IT'S A BUG (FEATURE).
			# IT SHOULD BE FORMATTED ACCORDING TO NLS_DATE_FORMAT
			if ($t) {
				$odatetime = sprintf "%02d.%02d.%04d %02d:%02d:%02d",
									 $day, $mon, $year, $hour, $min, $sec;
			}
			else {
				$odatetime = sprintf "%02d.%02d.%04d", $day, $mon, $year;
			}
		}
	}
	elsif ( grep {$self->{driver} eq $_} ('Pg','DB2','Solid','mysql')) {
		if ($type) {
			if ($t) {
				$odatetime = sprintf "'%04d-%02d-%02d %02d:%02d:%02d'",
									 $year, $mon, $day, $hour, $min, $sec;
			}
			else {
				$odatetime = sprintf "'%04d-%02d-%02d'", $year, $mon, $day;
			}
		} else {
			if ($t) {
				$odatetime = sprintf "%04d-%02d-%02d %02d:%02d:%02d",
									 $year, $mon, $day, $hour, $min, $sec;
			}
			else {
				$odatetime = sprintf "%04d-%02d-%02d", $year, $mon, $day;
			}
		}
	}
	elsif ($self->{driver} eq 'Informix') {
		if ($type) {
			if ($t) {
				$odatetime = sprintf "'%04d-%02d-%02d %02d:%02d:%02d'",
									 $year, $mon, $day, $hour, $min, $sec;
			}
			else {
				$odatetime = sprintf "'%02d.%02d.%04d'", $day, $mon, $year;
			}
		} else {
			if ($t) {
				$odatetime = sprintf "%04d-%02d-%02d %02d:%02d:%02d",
									 $year, $mon, $day, $hour, $min, $sec;
			}
			else {
				$odatetime = sprintf "%02d.%02d.%04d", $day, $mon, $year;
			}
		}
	}
	elsif ($self->{driver} eq 'mssql') {
		if ($type) {
			if ($t) {
				$odatetime = sprintf "convert(datetime, '%04d-%02d-%02d %02d:%02d:%02d', 120)",
					$year, $mon, $day, $hour, $min, $sec;
			}
			else {
				$odatetime = sprintf "convert(datetime, '%04d-%02d-%02d %02d:%02d:%02d', 120)", 
					$year, $mon, $day, 0, 0, 0;
			}
		} else {
			if ($t) {
				$odatetime = sprintf "%04d-%02d-%02d %02d:%02d:%02d",
					$year, $mon, $day, $hour, $min, $sec;
			}
			else {
				$odatetime = sprintf "%04d-%02d-%02d %02d:%02d:%02d", 
					$year, $mon, $day, 0, 0, 0;
			}
		}
	}
	else { # other drivers not supported
		$Derror_message = "MODULE ERROR: DBD driver not supported";
		return undef;
	}

	return $odatetime;

} # date2db

#########################################################################
sub db2date {

	my $self = shift;
	my $idatetime = shift || return wantarray ? () : undef;
	my ($year, $mon, $day, $hour, $min, $sec);
	my ($d, $t);

	if ($self->{driver} eq 'Oracle') {	# assumed NLS_DATE_FORMAT = DD.MM.YYYY
		($d, $t) = split / /, $idatetime;
		($day, $mon, $year) = split /\./, $d;
		($hour, $min, $sec) = split /:/, $t if $t;
	}
	elsif (grep {$self->{driver} eq $_} ('Pg','DB2','Solid','mysql')) { # assumed PGDATESTYLE = 'ISO'
		($d, $t) = split / /, $idatetime;
		($year, $mon, $day) = split /-/, $d;
		if ($t) {
			($t) = split /\+/, $t;		# tz in postgresql
			($t) = split /\./, $t;		# fraction in solid
			($hour, $min, $sec) = split /:/, $t;
		}
	}
	elsif ($self->{driver} eq 'Informix') { # assumed DBDATE=dmy4.
		($d, $t) = split / /, $idatetime;
		if ($t) {
			($year, $mon, $day) = split /-/, $d;
			($hour, $min, $sec) = split /:/, $t;
		}
		else {
			($day, $mon, $year) = split /\./, $d;
		}
	}
	elsif ($self->{driver} eq 'mssql') {
		($d, $t) = split / /, $idatetime;
		($year, $mon, $day) = split /-/, $d;
		if ($t) {
			($t) = split /\+/, $t;
			($hour, $min, $sec) = split /:/, $t;
		}
		#($day, $mon, $year) = split /\./, $d;
		#($hour, $min, $sec) = split /:/, $t if $t;
	}
	else { # other drivers not supported
		$Derror_message = "MODULE ERROR: DBD driver not supported";
		return wantarray ? () : undef;
	}

	if ($t) {
		return wantarray ? ($sec, $min, $hour, $day, $mon, $year) :
				sprintf "%02d.%02d.%04d %02d:%02d:%02d",
						$day, $mon, $year, $hour, $min, $sec;
	}
	return wantarray ? ($day, $mon, $year) :
				sprintf "%02d.%02d.%04d", $day, $mon, $year;

} # db2date

###########################################################################
sub ping {
	my $self = shift;

	my $result = $self->{conn}->ping();
	return 1 if $result eq '0 but true';
	return $result;
}

###########################################################################
sub get_driver {

	my $driver = shift;
	my @drv_arr = DBI->available_drivers;

	if ( ! $driver) {
		return @drv_arr;
	}
	return 'mssql' if grep 'Sybase' eq $_, @drv_arr and $driver eq 'mssql';
	return $driver if grep $driver eq $_, @drv_arr;
	return undef;

} # get_driver

###########################################################################
sub get_source {

	my $self = shift;
	my $driver = shift;

	return undef if ! $driver or ! get_driver($driver);
	my $source = shift;
	my @src_arr;
	if ($driver ne 'Oracle' and $driver ne 'mssql' and $driver ne 'Solid') {
		@src_arr = DBI->data_sources($driver);
		if ($driver eq 'Informix' and $source !~ /@/) {
			for (my $i = 0; $i < scalar @src_arr; $i++) {
				$src_arr[$i] =~ s/@.*//;
			}
		}
	}
	elsif ($driver eq 'Oracle') {
		@src_arr = ("dbi:Oracle:$source", $source, "dbi:Oracle:");
	}
	elsif ($driver eq 'mssql') {
		@src_arr = ("dbi:Sybase:", $source, "dbi:Sybase:");
	}
	elsif ($driver eq 'Solid') {
		@src_arr = ("dbi:Solid:$source", $source, "dbi:Solid:");
	}
	return @src_arr if ! defined $source;
	SWITCH: for ($driver) {
		/Pg/		&& do {
			$source = 'dbi:Pg:dbname=' . $source if $source !~ /dbi:Pg:dbname=/;
			$source .= ';host=' . $self->{host} if $self->{host};
			$source .= ';port=' . $self->{port} if $self->{port};
			last SWITCH;};
		/Oracle/	&& do {
			$source = 'dbi:Oracle:' . $source if $source !~ /dbi:Oracle:/;
			last SWITCH;};
		/Informix/	&& do {
			$source = 'dbi:Informix:' . $source if $source !~ /dbi:Informix:/;
			last SWITCH;};
		/DB2/					&& do {
			$source = 'dbi:DB2:' . $source if $source !~ /dbi:DB2:/;
			last SWITCH;};
		/mysql/		&& do {
			$source = 'dbi:mysql:database=' . $source;
			$source .= ';host=' . $self->{host} if $self->{host};
			last SWITCH;};
		/mssql/		&& do {
			$source = 'dbi:Sybase:database=' . $source;
			$source .= ';server=' . $self->{host} if $self->{host};
			$source .= ';language=czech';
			last SWITCH;};
		/Solid/	&& do {
			$source = 'dbi:Solid:' . $source if $source !~ /dbi:Solid:/;
			last SWITCH;};
		# Default (not supported)
		return undef;
	}
	#if ($Dconnecttype[$sid] eq 'PROXY') {
	#	 $driver = "dsn=$source";
	#	 $source = "dbi:Proxy:hostname=$Dhost[$sid];port=$Dport[$sid];"; 
	#	 $source .= "cipher=$Dcipher[$sid];key=$Dkey[$sid];" if $Dkey[$sid];
	#	 $source .= "usercipher=$Dusercipher[$sid];userkey=$Duserkey[$sid];"
	#		 if $Duserkey[$sid];
	#	 $source .= $driver;
	#}

	#return $source if $Dconnecttype[$sid] eq 'PROXY' or grep $source eq $_, @src_arr;
	return $source;
	return undef;

} # get_source

###########################################################################
sub trace_on {
#
# Enable trace
#

	my (undef, $level, $file) = @_;
	DBI->trace($level, $file);

} # trace_on

###########################################################################
sub trace_off {
#
# Disable trace
#

	DBI->trace(0);

} # trace_off

###########################################################################
sub trace_level {

	my $self = shift;

	$self->{trace} = shift;
}

###########################################################################
sub _trace {
	
	my $self = shift;

	my $errnum = '';
	$errnum = $Dcmdstatus if $Dcmdstatus;
	$errnum = $Dsqlstatus if $Dsqlstatus;
	$errnum = " [$errnum]" if $errnum; 
	my $msg = "DB$errnum: $Derror_message";
	if ($self->{trace} > 1) {
		$msg .= " ($Dstr_command)" if defined $Dstr_command;
		if ($#_ >= 0) { # doplneni dat
			$msg .= " [data: ".join(',',map {defined $_ ? $_ : 'undef'} @_)."]";
		}
	}
	trace('E', $msg);

} # END _trace

###########################################################################
sub _trace_msg {

	my $self = shift;
	my $msg = shift;

	trace('E', $msg);
} # END _trace_msg

###########################################################################
sub _set_app {

	my $self = shift;
	my $app  = shift;

	$self->{app} = $app;
}

###########################################################################
sub _replace_values {

	my $self = shift;
	my $sql = shift;
	my @val = @_;

	foreach (@val) {
		$_ = 'null' if !defined $_;
		($_) = $self->quote($_) if ! /^[0-9.]+$/;
		$sql =~ s/\?/$_/;
	}

	return $sql;
}

###########################################################################
sub DESTROY {

	my $self = shift;

	$self->close();
}

###########################################################################
sub _stat_start {

	my $self = shift;

	my ($type, $sql, $param, $name) = @_;
	if ($self->{stat_type} eq 'none') { return; }

	$self->{stat_act}{start} = [gettimeofday()];
	$self->{stat_act}{type} = $type;
	$self->{stat_act}{sql} = $sql;
	$self->{stat_act}{par} = $param;
	$self->{stat_act}{name} = $name || '';
}

###########################################################################
sub _stat_end {

	my $self = shift;

	my $status = shift;
	if ($self->{stat_type} eq 'none') { return; }

	# celkovy cas
	my $time = tv_interval($self->{stat_act}{start});

	# soucty vzdy
	$self->{stat_all}{total_time} += $time;
	$self->{stat_all}{total_comm}++;
	$self->{stat_all}{total_err}++ if $status eq 'ERROR';

	if ($self->{stat_type} eq 'sums') { return; }

	# info o prikaze
	my $tmp = { time => $time, type => $self->{stat_act}{type},
		sql => $self->{stat_act}{sql}, par => $self->{stat_act}{par},
		name => $self->{stat_act}{name} };
	if ($status eq 'ERROR') {
		$tmp->{error} = $Derror_message;
	}

	# tri nejdelsi
	push @{$self->{stat_all}{high}}, $tmp;
	# setridit
	@{$self->{stat_all}{high}} =
		sort { $b->{time} <=> $a->{time} }
		@{$self->{stat_all}{high}};
	if (scalar @{$self->{stat_all}{high}} > $self->{stat_max_high}) {
		# posledni pryc
		pop @{$self->{stat_all}{high}};
	}

	if ($self->{stat_type} eq 'high') { return; }

	# info o vsech prikazech
	push @{$self->{stat_all}{all}}, $tmp
		if (!$self->{stat_all}{all} or scalar @{$self->{stat_all}{all}} < $self->{stat_max_all});
}

###########################################################################
sub set_stat {
	
	my $self = shift;

	$self->{stat_type} = shift;
	my ($max_high, $max_all) = @_;
	$self->{stat_max_high} = $max_high if $max_high;
	$self->{stat_max_all}  = $max_all  if $max_all;
}

###########################################################################
sub reset_stat {

	my $self = shift;

	$self->{stat_all}{total_time} = 0;
	$self->{stat_all}{total_comm} = 0;
	$self->{stat_all}{total_err} = 0;

	$self->{stat_all}{high} = [];
	$self->{stat_all}{all} = [];
}

###########################################################################
sub get_stat {

	my $self = shift;

	my $total_time = $self->{stat_all}{total_time} || 0;
	my $total_comm = $self->{stat_all}{total_comm} || 0;
	my $total_err  = $self->{stat_all}{total_err} || 0;

	my $ref_high = $self->{stat_all}{high};
	my $ref_all  = $self->{stat_all}{all};

	return ($total_time, $total_comm, $total_err, $ref_high, $ref_all);
}

###########################################################################
sub test_err {

	my $self = shift;
	my $teste = shift;
	my @teste = ();
	my $rete = -1;

	while (defined $teste) {
		$teste = uc($teste);
		if ($teste eq 'TABLE_NOTEXIST' or $teste eq '1') { push @teste, 1;}
		elsif ($teste eq 'TABLE_EXIST' or $teste eq '2') { push @teste, 2;}
		elsif ($teste eq 'REC_EXIST' or $teste eq '3') { push @teste, 3;}
		elsif ($teste eq 'SCHEMA_NOTEXIST' or $teste eq '4') { push @teste, 4;}
		elsif ($teste eq 'SCHEMA_EXIST' or $teste eq '5') { push @teste, 5;}
		else { return 0; }
		$teste = shift;
	}
	no warnings "uninitialized";
	if ($self->{driver} eq 'Pg') {
		if ($Dsqlstatus eq '7' && $Derror_message =~ /(Relation|relation|table) .* does not exist/) { $rete = 1; }
		elsif ($Dsqlstatus eq '7' && $Derror_message =~ /(R|r)elation .* already exists/) { $rete = 2; }
		elsif ($Dsqlstatus eq '7' && $Derror_message =~ /duplicate key/) { $rete = 3; }
		elsif ($Dsqlstatus eq '7' && $Derror_message =~ /(Namespace|Schema|schema) .* does not exist/) { $rete = 4; }
		elsif ($Dsqlstatus eq '7' && $Derror_message =~ /(namespace|schema) .* already exists/) { $rete = 5; }
	}
	elsif ($self->{driver} eq 'Oracle') {
		if ($Dsqlstatus eq '942' || $Dsqlstatus eq '4043') { $rete = 1; }
		elsif ($Dsqlstatus eq '955') { $rete = 2; }
		elsif ($Dsqlstatus eq '1') { $rete = 3; }
	}
	elsif ($self->{driver} eq 'Informix') {
		if ($Dsqlstatus eq '-206') { $rete = 1; }
		elsif ($Dsqlstatus eq '-310') { $rete = 2; }
		elsif ($Dsqlstatus eq '-239') { $rete = 3; }
	}
	elsif ($self->{driver} eq 'DB2') {
		if (($Dsqlstatus eq '-204' && $Derror_message =~ /"[^\.]+\.[^\.]+"/)
			|| ($Dsqlstatus eq '-99999' && $Derror_message =~ /CLI0125E/)) { $rete = 1; }
		elsif ($Dsqlstatus eq '-601' && $Derror_message =~ /type "TABLE"/) { $rete = 2; }
		elsif ($Dsqlstatus eq '-803') { $rete = 3; }
		elsif ($Dsqlstatus eq '-204' && $Derror_message =~ /"[^\.]+"/) { $rete = 4; }
		elsif ($Dsqlstatus eq '-601' && $Derror_message =~ /type "SCHEMA"/) { $rete = 5; }
	}
	elsif ($self->{driver} eq 'mysql') {
		if ($Dsqlstatus eq '1051' || $Dsqlstatus eq '1146') { $rete = 1; }
		elsif ($Dsqlstatus eq '1050') { $rete = 2; }
		elsif ($Dsqlstatus eq '1062') { $rete = 3; }
	}
	elsif ($self->{driver} eq 'mssql') {
		if ($Dsqlstatus eq '3701' || $Dsqlstatus eq '208') { $rete = 1; }
		elsif ($Dsqlstatus eq '2714') { $rete = 2; }
		elsif ($Dsqlstatus eq '2601') { $rete = 3; }
	}
	elsif ($self->{driver} eq 'Solid') {
		if ($Dsqlstatus eq '13011') { $rete = 1; }
		elsif ($Dsqlstatus eq '13013') { $rete = 2; }
		elsif ($Dsqlstatus eq '10005' || $Dsqlstatus eq '10033') { $rete = 3; }
		elsif ($Dsqlstatus eq '13141' || $Dsqlstatus eq '13046') { $rete = 4; }
		elsif ($Dsqlstatus eq '13142') { $rete = 5; }
	}
	else {
		return -1 if !scalar @teste;
		return 0;
	}

	return $rete if ! scalar @teste;
	return (grep({$rete == $_} @teste) ? $rete : 0);
	
} # test_err

###########################################################################
sub imix_number_correct {

	my $self = shift;
	my $arg = shift;

	$self->{imix_number_correct} = $arg;

} # imix_number_correct()

#######################################################################
# Initialization code of module
#######################################################################

1;

=head1 NAME

DeltaX::Database - Perl module which hiddens DB differences on DBI level

		 _____
		/		\ _____		 ______ ______ ___________
	 /	\ /  \\__  \	/  ___//	___// __ \_  __ \
	/		 Y		\/ __ \_\___ \ \___ \\	___/|  | \/
	\____|__	(____  /____	>____  >\___	>__|
		\/	 \/	\/		 \/			\/	project


 Supported drivers:
	Oracle	[Oracle]
	PostgreSQL	[Pg]
	MySQL		[mysql]
	Sybase	[Sybase]		[not tested]
	MS SQL	[mssql]			[using Sybase driver]
	DB2		[DB2]
	Solid		[Solid]

=head1 SYNOPSIS

=head2 Public functions

	new					- New DB connect
	close					- Close DB connect
	check					- DB connect check
	transaction_begin		- Begin transaction
	transaction_end			- End transaction
	select				- Performing SQL select
	open_cursor				- Cursor openning
	fetch_cursor				- Get row by opened cursor
	close_cursor				- Close cursor
	exists_cursor				- Checks existence of cursor
	insert				- Performing SQL insert
	delete				- Performing SQL delete
	update				- Performing SQL update
	command				- Performing any SQL command
	open_statement			- Prepare statement (for bind values)
	perform_statement		- Perform prepared statement
	close_statement			- Close prepared statement
	exists_statement		- Checks existence of statement
	quote					- Quotting string
	date2db				- Converting datetime to db format
	db2date				- Converting db format of date to datetime
	nextval				- Select next value from sequence
	func					- Performs DBD specific function
	const					- Sets DBD specific constant
	ping					- Checks DB connect
	trace					- set trace level
	trace_on				- DBI trace ON
	trace_off				- DBI trace OFF
	set_stat				- set statistics type
	reset_stat				- reset statistics
	get_stat				- get statistics
	test_err				- test sqlerror

=head2 Public variables

	$Dsqlstatus				- SQL status (error) code
	$Dcmdstatus				- Command status (error) code
	$Derror_message			- Actual error message
	$VERSION				- Module wersion
	$Dstr_command				- last used SQL command

=head2 Private functions

	get_driver		- Returns DBD driver
	get_source		- Returns DBD specific connect string
	_trace		- Error trace (using DeltaX::Trace)
	_trace_msg		- Error trace (using DeltaX::Trace)
	_set_app		- Sets application prefix (for statements)
	_replace_values - replaces values for placeholders

=head2 Private variables


=head1 DESCRIPTION

=head2 new

Connects to DB and creates new object which handles it.
Parameters are given in key => value form.
 
 Possible parameters:
	driver [required]	 - DB driver to use (eg. Oracle, Pg, ...)
	dbname [required]	 - database name
	host [def: none]	 - host on which database resides
	user [required]	 - user to connect to DB
	auth			 - password to connect to DB
	autocommit [def: 0]	 - use autocommit?
	datestyle [def: none]  - DB specific datestyle
		(eg. PGDATESTYLE for PostgreSQL, NLS_DATE_FORMAT for Oracle,
		 DBDATE for Informix)
	close_curs [def: 0]	 - close cursors when ending transaction?
	cursor_type [def: INTERNAL]
			 - default cursor type <INTERNAL|EXTERNAL>
	trace [def: 0]	 - tracing: 0 - none, 1 - errors, 2 - with SQL string
	app [def: none]	 - application prefix for 

 Returns:
	undef in case of error (check $Derror_message for reason)
	otherwise returns new DeltaX::Database object

=head2 close

Closes DB connect

 Returns: -nothing-

=head2 check

Checks DB connect (via ping()).

 Syntax:
	check()

 Args:
	-none-

 Returns:
	-1 - error
	 0 - ok/connected

=head2 ping

Interface to DBH->ping().

 Syntax:
	ping()

 Args:
	-none-

 Returns:
	value returned by DBH->ping().

=head2 transaction_begin

Starts new transaction by performing COMMIT ($type == 1, it's default)
or ROLLBACK ($type == 0).
 
 Syntax:
	transaction_begin([$type])
 
 Args:
	$type [def: 1] - see above

 Returns:
	 1 - ok
	 0 - SQL command failed (see $Derror_message)
	-1 - autocommit is enabled
	-2 - not connected

Note:
It erases all cursors if close_curs enabled (see L<"new">).

=head2 transaction_end

Ends transaction by performing COMMIT ($type == 1, it's default) or
ROLLBACK ($type == 0).

 Syntax:
	transaction_begin([$type])

 Args:
	$type [def: 0] - see above

 Returns:
	 1 - ok
	 0 - SQL command failedc (see $Derror_message)
	-1 - autocommit is enabled
	-2 - not connected

Note:
It erases all cursors if close_curs enabled (see L<"new">).

=head2 select

Performs SQL command (SELECT assumed) and returns array with first returned
row.

 Syntax:
	select($select_str)

 Args:
	$select_str - SELECT command string

 Returns:
	array, first value:
		0 - no records found
	 >0 - record found (on index 1 starts selected row values)
	 -1 - SQL error (see $Derror_message)
	 -2 - bad parameters
	 -3 - not connected

Note:
If transaction not started, it performs transaction_end(0)

=head2 open_cursor

Opens new cursor $cursor_name. For fetching rows use fetch_cursor().

 Syntax:
	open_cursor($cursor_name, {$select_str | $prepared_name, [$cursor_type,] [@bind_values]})

 Args:
	$cursor_name [required] - cursor name (existing cursor with the same name will
		be replaced)
	$select_str			- SQL SELECT command
	- or -
	$prepared_name		- name of prepared statement
	$cursor_type			- INTERNAL [emulated], EXTERNAL [by DBI - DB]
	@bind_values			- values for prepared statement

 Returns:
	 0 - no rows found
	>0 - ok, for INTERNAL returns number of rows, for EXTERNAL DBD specific value
	-1 - SQL command failed (see $Derror_message)
	-2 - bad parameters
	-3 - not connected

Note:
Cursor from prepared statement is always INTERNAL.

Note:
For MS SQL, cursor is always INTERNAL.

=head2 fetch_cursor

Returns next row from cursor.

 Syntax:
	fetch_cursor($cursor_name, [$num_row])

 Args:
	$cursor_name [required] - cursor name
	$num_row [def: next]		- position of required row (from 0, for INTERNAL 
	 cursors only!)

 Returns:
	array with result, first value indicates status:
		0 - last row, next fetch_cursor() returns first row again
	 >0 - next row, not last
	 -1 - SQL error (see $Derror_message)
	 -2 - bad parameters
	 -3 - cursor doesn't exist
	 -4 - not connected

=head2 close_cursor

Closes cursor and releases data from it.

 Syntax:
	close_cursor($cursor_name)

 Args:
	$cursor_name [required] - cursor name to close

 Returns:
	 0 - cursor closed
	-1 - bad paramaters
	-2 - cursor doesn't exist
	-3 - not connected

=head2 exists_cursor

Check existence of cursor of given name.

 Syntax:
	exists_cursor($cursor_name)

 Args:
	$cursor_name [required] - cursor name

 Returns:
	0 - not exists
	1 - exists

=head2 open_statement

Prepares SQL command, which can bind variables and can be repeatly exexuted
(using L<"perform_statement"> or L<"open_cursor">).

 Syntax:
	open_statement($stmt_name, $sql_string, $num_binds)

 Args:
	$stmt_name [required]  - statement name, if exists will be replaced
	$sql_string [required] - SQL command to prepare
	$num_binds [optional]  - number of binded values (for check only)

 Returns:
	>0 - number of binded variables [ok]
	 0 - no bind values [ok]
	-1 - SQL command failed [not supported by all drivers]
	-2 - bad parameters
	-3 - bad number of binded variables
	-4 - not connected

Note:
Use only question marks, no :a form!

Note:
[Oracle only] For BLOBs use exclamation marks or ?B instead of question marks.
[Oracle only] For CLOBs use ?C instead of question marks.

=head2 perform_statement

Performs prepared statement.

 Syntax:
	perform_statement($stmt_name, [@bind_values])

 Args:
	$stmt_name [required] - statement name (must be prepared using
	 prepare_statement())
	@bind_values		- values which will be binded to statement,
	 there must be not less values than there is in prepared statement,
	 redundant will be ignored

 Returns:
	array, first value indicates status:
		0 - no row returned/affected, but success
	 >0 - ok, number of returned/affected rows
		(for SELECT it returns just one row (see select()), for
		 INSERT/UPDATE/DELETE returns number of affected rows)
	 -1 - SQL error (see $Derror_message)
	 -2 - bad parameters
	 -3 - statement doesn't exist
	 -4 not connected
	for SELECT other values in array represents returned row

=head2 close_statement

Closes (destroys) prepared statement.

 Syntax:
	close_statement($stmt_name)

 Args:
	$stmt_name [required] - statement name to close

 Returns:
	 0 - closed
	-2 - bad parameters
	-3 - statement doesn't exist
	-4 - not connected

=head2 exists_statement

Checks existence of statement of given name.

 Syntax:
	exists_statement($stmt_name)

 Args:
	$stmt_name [required] - statement name to check

 Returns:
	1 - exists
	0 - not exists or no statement name given

=head2 insert

Performs SQL command (assumes INSERT) and returns number of inserted rows.

 Syntax:
	insert($insert_string)

 Args:
	$insert_string [required] - the SQL command (INSERT)

 Returns:
	>=0 - number of inserted rows
	-1 - sql command failed (check Dsqlstatus, Dcmdstatus, Derror_message
	-2 - bad parameter
	-3 - not connected

=head2 delete

Performs SQL command (assumes DELETE) and returns number of deleted rows.

 Syntax:
	delete($delete_string)

 Args:
	$delete_string [required] - the SQL command (DELETE)

 Returns:
	>=0 - number of deleted rows
	 -1 - sql command failed (check Dsqlstatus, Dcmdstatus, Derror_message)
	 -2 - bad parameter
	 -3 - not connected

=head2 update

Performs SQL command (assumes UPDATE) and returns number of updated rows.

 String:
	update($update_string)

 Args:
	$update_str [required] - the SQL command (UPDATE)

 Returns:
	>=0 - number of updated rows
	 -1 - sql command failed (check Dsqlstatus, Dcmdstatus, Derror_message)
	 -2 - bad parameter
	 -3 - not connected

=head2 command

Performs generic command.

 String:
	command($command_string)

 Args:
	$command_string [required] - SQL command

 Returns:
	>0 - ok
	-1 - sql command failed (check Dsqlstatus, Dcmdstatus, Derror_message)
	-2 - bad parameter
	-3 - not connected

=head2 func

Interface to DBH->func().

 Syntax:
	func(@func_params)

 Args:
	@func_params - parameters for func()

 Returns:
	value(s) returned by DBH->func()

=head2 const

Interface to DBH->constants.

 Syntax:
	const($const_name[, $value])

 Args:
	$const_name [required] - constant name
	$value		 - if defined, set constant to this value

 Returns:
	constant $const_name value

=head2 nextval

Returns next value from sequence.

 Syntax:
	nextval($seq_name)

 Args:
	$seq_name [required] - sequence name

 Returns:
	>0 - next value from sequence
	-1 - SQL error (see Derror_message)
	-2 - bad parameters
	-3 - not connected

=head2 quote

Quotes given string(s).

Note: You should not quote values used in prepared statements.

 Syntax:
	quote(@array)

 Args:
	@array - array of strings to quote

 Returns:
	array with quoted strings

=head2 date2db

Formats string (date or datetime) to DB format.

 String:
	date2db([$format_type][, @date_value])

 Args:
	$format_type - DB format type COMMON [default] or PREPARED [for prepared
	 statements]
	-other parameters are optional, default is now-
	1. param - date [dd.mm.yyyy] or datetime [dd.mm.yyyy hh:mm:ss] or seconds
			 or ! now (date) !! now (datetime)
	2. param - minutes
	3. param - hours
	4. param - day in month
	5. param - month (0 will be replaced to 1)
	6. param - year (if <1000, 1900 will be added)

 Returns:
	according to number of arguments without $format_type if given:
		0 - current datetime
		1 - input is date(time) string, output date(time)
		2 - input is month and year, returns date with last day in month
		3 - date
	 >3 - datetime
	 undef - bad parameters

 Returned: see above
			 undef - bad parameters or not connected

 Note:
	For driver	 Must be set			To
	Pg		 DBDATESTYLE			ISO				*)
	Oracle	 NLS_DATE_FORMAT		dd.mm.yyyy hh24:mi:ss *)
	Informix	 DBDATE				dmy4.			*)
	Sybase	 [freedts.conf]
	mssql		 [freedts.conf]

*) You can use datestyle parameter of L<"new">.

=head2 db2date

Formats string from DB format.

 Syntax:
	db2date($datetime)

 Args:
	$datetime [required] - date(time) from DB

 Returns: 
	- in the scalar context is returned datetime string
	- in the array context is returned array
		($sec, $min, $hour, $day, $mon, $year)
	undef or () depend on context 
		bad parameters or not connected

 Note:
	For driver	 Must be set			To
	Pg		 DBDATESTYLE			ISO				*)
	Oracle	 NLS_DATE_FORMAT		dd.mm.yyyy hh24:mi:ss *)
	Informix	 DBDATE				dmy4.			*)
	Sybase	 [freedts/locales.conf]
	mssql		 [freedts/locales.conf]

*) You can use datestyle parameter of L<"new">.

=head2 trace_on

Interface to DBI->trace().

 Syntax:
	trace_on($level, $file)

 Args:
	$level - trace level
	$file  - filename to store log

 Returns:
	-nothing-

Note: See DBI manpage.

=head2 trace_off

Stops tracing started by trace_on().

 Syntax:
	trace_off()

 Args:
	-none-

 Returns:
	-nothing-

=head2 _set_app

Sets application prefix.

 Syntax:
	_set_app($prefix)

 Args:
	$prefix - used for statements and cursors

 Returns:
	-nothing-

Note: Default prefix is empty, to set it to this default just call _set_app('').

=head2 set_stat

Sets statistics.

 Syntax:
	set_stat(type[,max_high[,max_all]])

 Args:
	type - type of statistics:
		none - no statistics
		sums - only sumaries
		high - sums & top statements
		all  - high & all statements
	max_high - max. number of stored top statements (default: 3)
	max_all  - max. number of stored all statements (default: 1000)

 Returns:
	-nothing-

=head2 reset_stat

Resets statistic counters and arrays.

 Syntax:
	reset_stat()

 Args:
	-none-

 Returns:
	-nothing-

=head2 get_stat

Gets module statistics.

 Syntax:
	get_stat()

 Args:
	-none-

 Returns:
	array with statistics:
	 field 0 ... total time for statements (sums, high, all)
	 field 1 ... number of performed statements (sums, high, all)
	 field 2 ... number of errors (sums, high, all)
	 field 3 ... reference to array with top statements (high, all)
	 field 4 ... reference to array with all statements (all)

	For field 3 and 4: it's an array of references to hashes with these keys:
	 type - action performed (SELECT, INSERT, UPDATE, DELETE, COMMAND, PERFORM,
		CURSOR_PERFORM, CURSOR_SQL)
	 sql	- SQL command
	 name - statement name (if any)
	 par	- reference to an array with parameters (if any)
	 time - time needed to perform statement
	 error- error string in case of error

=head2 reset_stat

Resets local statistics (global leaves untouched).

 Syntax:
	reset_stat()

 Args:
	-none-

 Returns:
	-nothing-

=head2 test_err

Test last sqlerror.

 Syntax:
	test_err(supp_errs)

 Args:
	supp_errs (optional)	- list of supp_error (below)
	supp_error (optional) - supposed error.
				May be: 1 or TABLE_NOEXIST	 - not existing table (objects)
					2 or TABLE_EXIST		 - table (object) already exists
					3 or REC_EXIST		 - duplicate value in unique key
					4 or SCHEMA_NOTEXIST - not existing schema 
					5 or SCHEMA_EXIST		 - schema already exists

	4 and 5 are not sopported by some drivers (Oracle, Informix, mysql, mssql).

 Returns:
	Without args returns error number 1,2,3,4,5 or -1 (unknown).
	With args return the (args) error number (if equal with any) or 0.


=head1 AUTHOR

Originally created by Martin Kula <martin.kula@deltaes.com>

Rewritten to object model by Jakub Spicak <jakub.spicak@deltaes.cz> for masser.

Delta E.S., Brno (c) 2000-2002.

=cut
