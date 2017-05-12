package Apache::WeSQL::SqlFunc;

use 5.006;
use strict;
use warnings;
use lib(".");

use Apache::Constants qw(:common);
use Apache::WeSQL;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Apache::WeSQL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	sqlConnect sqlDisconnect sqlSelect sqlSelectMany 
	sqlPrepareInsert sqlExecuteInsert sqlInsert sqlInsertReturn
	sqlUpdate sqlDelete sqlGeneric
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.53';

# Preloaded methods go here.

############################################################
# sqlGeneric performs a generic SQL query, and returns
# a handler to the resulting data
############################################################
sub sqlGeneric {
	my ($dbh, $sql) = @_;
	$sql ||= "";
	my $c=${$dbh}->prepare($sql);

	my $dbtype = 0;	#MySQL
	$dbtype = 1 if (${$dbh}->{Driver}->{Name} =~ /^Pg/);

	&Apache::WeSQL::log_error("$$: sqlGeneric: $sql") if ($Apache::WeSQL::DEBUG);

	if($c->execute()) {
		if ($dbtype) { ${$dbh}->commit; }
		return $c;
	} else {
		if ($dbtype) { ${$dbh}->rollback; }
		$c->finish();
		&Apache::WeSQL::log_error("$$: sqlGeneric: bad query: $sql: " . ${$dbh}->errstr);
		return undef;
	}
}

############################################################
# sqlPrepareInsert allows a prepare for a SQL 'insert' query
# parameter 1: $dbh: database handler
# parameter 2: $table: database table
# parameter 3: @columns: 'columns' of the SQL statement
############################################################
sub sqlPrepareInsert {
	my $dbh = shift;
	my ($table, @columns) = @_;

	# First build the SQL statement
	my $sql = qq{INSERT INTO $table (};
	$sql .= join(',',@columns);
	$sql .= qq{) VALUES (} . "?," x ($#columns+1);
	chop($sql);
	$sql .= q{)};

	&Apache::WeSQL::log_error("$$: sqlPrepareInsert: $sql") if ($Apache::WeSQL::DEBUG);

	# Then prepare it
#	my $sth=${$dbh}->prepare_cached($sql) or die "Sql has gone away\n";
# Does this help against the weird DBI bug (see sqlExecuteInsert)? WVW 2002-6-4
	my $sth=${$dbh}->prepare($sql) or die "Sql has gone away\n";
	return ($sth);
}

############################################################
# sqlExecuteInsert allows execution of a prepared SQL 'insert' query
# parameter 1: $dbh: database handler
# parameter 2: $sth: query handler
# parameter 3: @values: 'values' of the SQL statement
############################################################
sub sqlExecuteInsert {
	my $dbh = shift;
	my $sth = shift;
	my @values = @_;
	my $dbtype = 0;	#MySQL
	$dbtype = 1 if (${$dbh}->{Driver}->{Name} =~ /^Pg/);

	if ($Apache::WeSQL::DEBUG) {
		my $logstr = "$$: sqlExecuteInsert: parameters (";
		foreach (@values) { 
			my $tmp = $_; 
			$tmp = substr($tmp,0,100); #Chop off after 100 chars to keep logs readable
			$logstr .= "$tmp,";
		}
		chop($logstr); 
		$logstr .= ")";
		&Apache::WeSQL::log_error($logstr);
	}
	# We need to reassure that all @values items that contain non-digit characters are actually stored as strings.
	# This is necessary for values like word.word which seem to be wrongly interpreted by the MySQL code as
	# dbname.tablename without the following three lines. Why? Beats me. WVW, 2002-02-08
	# Not necessary anymore after an upgrade from MySQL 3.23.37 and DBI 1.20 to MySQL 3.23.49 and DBI 1.21 ??? WVW, 2002-05-08
	# Correction, bug persists. Have now removed Msql-mysql perl module and switched to DBD-mysql. Seems to have solved the issue. WVW, 2002-05-12
#	for (my $cnt = 0; $cnt < $#values; $cnt++) {
#		$values[$cnt] = ${$dbh}->quote($values[$cnt]) if ($values[$cnt] =~ /\D/);
#	}
	if(not $sth->execute(@values)) {
		$sth->finish;
		${$dbh}->rollback if ($dbtype);
		&Apache::WeSQL::log_error("$$: sqlExecuteInsert: bad query: " . ${$dbh}->errstr);
		return undef;
	}
	$sth->finish;

	if ($dbtype) { ${$dbh}->commit; }
	return 1;
}

############################################################
# sqlInsert allows a SQL 'insert' query
# parameter 1: $dbh: database handler
# parameter 2: $table: database table
# parameter 3: \@columns: 'columns' of the SQL statement
# parameter 4: \@values: 'values' of the SQL statement
############################################################
sub sqlInsert {
	my $dbh = shift;
	my ($table, $colref, $valref)= @_;
	my $sth = &sqlPrepareInsert($dbh,$table,@{$colref});
	&sqlExecuteInsert($dbh,$sth,@{$valref});
	return "";
}

############################################################
# sqlInsertReturn allows a SQL 'insert' query, and can return (a) column(s) from the just inserted row
# parameter 1: $dbh: database handler
# parameter 2: $table: database table
# parameter 3: \@columns: 'columns' of the SQL statement
# parameter 4: \@values: 'values' of the SQL statement
# parameter 5: $retcols: comma-separated list of columns whose values should be returned by this sub
# parameter 6: $pkey: 
#									MySQL: name of the autoincrement column in this table (default: pkey)
#									PostgreSQL: name of the SEQUENCE used in this table (default: tablename_pkey_seq)
############################################################
sub sqlInsertReturn {
	my $dbh = shift;
	my ($table, $colref, $valref, $retcols, $pkey)= @_;
	&sqlInsert($dbh,$table,$colref,$valref);

	# Determine the database type
	my $dbtype = 0;	#MySQL
	$dbtype = 1 if (${$dbh}->{Driver}->{Name} =~ /^Pg/);

  if ($dbtype == 0) { 
		$pkey ||= "pkey";
		my @r = &sqlSelect($dbh,"SELECT LAST_INSERT_ID()");
		my @r2 = &sqlSelect($dbh,"SELECT $retcols FROM $table WHERE $pkey=$r[0]");
		return @r2;
  } else {
		my $sequence = $pkey; 
		$sequence ||= "$table" . "_pkey_seq";
		($pkey) = $sequence =~ /$table\L_(.*?)_seq/;
		my @r = &sqlSelect($dbh,"SELECT last_value FROM $sequence");
		my @r2 = &sqlSelect($dbh,"SELECT $retcols FROM $table WHERE $pkey=$r[0]");
		return @r2;
  }
}

############################################################
# sqlDelete allows a SQL 'delete' query
# parameter 1: $dbh: database handler
# parameter 2: $table: database table
# parameter 3: $where: where-part of the SQL statement
# paramater 4: $other: last part of the SQL statement (optional)
# Returns: number of rows affected by the delete or undef upon failure
############################################################
sub sqlDelete {
	my $dbh = shift;
	my ($table, $where, $other)=@_;

	my $dbtype = 0;	#MySQL
	$dbtype = 1 if (${$dbh}->{Driver}->{Name} =~ /^Pg/);

	my $sql="DELETE FROM $table ";
	$sql.="WHERE $where " if $where;
	$sql.="$other" if $other;
 
	my $c=${$dbh}->prepare_cached($sql) or die "Sql has gone away\n";
	if(not $c->execute()) {
		if ($dbtype) { ${$dbh}->rollback; }
		&Apache::WeSQL::log_error("$$: sqlDelete: bad query: $sql: " . ${$dbh}->errstr);
		return undef;
	}
	my $rows = $c->rows();
	$c->finish();
	if ($dbtype) { ${$dbh}->commit; }
	return $rows;
}   

############################################################
# sqlUpdate is an easy interface to an UPDATE sql query
# parameter 1: $dbh: database handler
# parameter 2: $table: database table
# parameter 3: $what: what to update
# parameter 4: $where: condition
# parameter 5: $other: any rest of the sql statement
# Returns: number of rows affected by the update or undef upon failure
############################################################
sub sqlUpdate {
	my $dbh = shift;
	my ($table, $what, $where, $other)=@_;

	# Determine the database type
	my $dbtype = 0;	#MySQL
	$dbtype = 1 if (${$dbh}->{Driver}->{Name} =~ /^Pg/);

	my $sql="UPDATE $table ";
	$sql.="SET $what " if $what;
	$sql.="WHERE $where " if $where;
	$sql.="$other" if $other;

	&Apache::WeSQL::log_error("$$: sqlUpdate: $sql") if ($Apache::WeSQL::DEBUG);

	my $c=${$dbh}->prepare_cached($sql) or die "Sql has gone away\n";
	if(not $c->execute()) {
		if ($dbtype) { ${$dbh}->rollback; }
		&Apache::WeSQL::log_error("$$: sqlUpdate: bad query: $sql" . ${$dbh}->errstr);
		return undef;
	}
	my $rows = $c->rows();
	$c->finish();
	if ($dbtype) { ${$dbh}->commit; }
	return $rows; #return the number of rows affected by the update
}        

############################################################
# sqlSelect
# Takes a select statement and returns the first row of results
############################################################

sub sqlSelect {
	my ($dbh,$sql) = @_;
	my $c;

	# Determine the database type
	my $dbtype = 0;	#MySQL
	$dbtype = 1 if (${$dbh}->{Driver}->{Name} =~ /^Pg/);

	# Save the database from much unnecessary work, we only want the first record returned!
	$sql .= " LIMIT 1" if (!($sql =~ / LIMIT /i) && ($sql =~ / FROM /i));

	&Apache::WeSQL::log_error("$$: sqlSelect: $sql") if ($Apache::WeSQL::DEBUG);
 
	unless($c=${$dbh}->prepare($sql)) {
		&Apache::WeSQL::log_error("$$: sqlSelect: error: $sql");
		return undef;
	}

	if(not $c->execute()) {
		$c->finish();
		if ($dbtype) { ${$dbh}->rollback; }
		&Apache::WeSQL::log_error("$$: sqlSelect: bad query: $sql");
		return undef;
	}
	my @r=$c->fetchrow();
	$c->finish();
	return @r;
} 

############################################################
# sqlSelectMany
# Takes a sql select statement and returns a handle to the results.
############################################################

sub sqlSelectMany {
	my ($dbh,$sql) = (shift,@_);
	my $c;

	# Determine the database type
	my $dbtype = 0;	#MySQL
	$dbtype = 1 if (${$dbh}->{Driver}->{Name} =~ /^Pg/);

	&Apache::WeSQL::log_error("$$: sqlSelectMany: $sql") if ($Apache::WeSQL::DEBUG);

	unless($c=${$dbh}->prepare($sql)) {
		&Apache::WeSQL::log_error("$$: sqlSelectMany: error: $sql");
		return undef;
	}

	if ($c->execute()) {
		return $c;
	} else {
		$c->finish();
		if ($dbtype) { ${$dbh}->rollback; }
		&Apache::WeSQL::log_error("$$: sqlSelectMany: bad query: $sql");
		return undef;
	}
}

########################################################
# sqlConnect makes a connection to the database, and returns a reference to the database
# handler. Called from Apache::WeSQL::AppHandler
########################################################
sub sqlConnect {
	my ($dsn, $dbuser, $dbpass, $dbtype) = @_;

	my $dbh;
	my $autocommit = { AutoCommit => 1 };
	if ($dbtype == 1) { #PostgreSQL supports transactions, MySQL doesn't
		$autocommit = { AutoCommit => 0 };
	}

	if (!($dbh=DBI->connect($dsn,$dbuser,$dbpass,$autocommit))) {
		print &Apache::WeSQL::error("Serious problem on the server. Please contact the webmaster.","Could not open database connection: " . ${$dbh}->errstr);
		exit;
	}
 
	DBI->trace(1) if ($Apache::WeSQL::DEBUG > 1);

	&Apache::WeSQL::log_error("$$: New connection to $dsn as $dbuser") if ($Apache::WeSQL::DEBUG);

	return \$dbh;
}

########################################################
# sqlDisconnect disconnects the database handler
########################################################
sub sqlDisconnect {
	my $dbh = shift;
  ${$dbh}->disconnect;
  undef($dbh);   
}

1;
__END__

=head1 NAME

Apache::WeSQL::SqlFunc - A library of functions to deal with the SQL database

=head1 SYNOPSIS

  use Apache::WeSQL::SqlFunc qw( :all );

=head1 DESCRIPTION

This module contains all functions necessary to deal with SQL databases in an easy way.
You may call these functions directly from any WeSQL document.

This module is part of the WeSQL package, version 0.53

(c) 2000-2002 by Ward Vandewege

=head2 EXPORT

None by default. Possible:
  sqlConnect sqlDisconnect sqlSelect sqlSelectMany 
  sqlPrepareInsert sqlExecuteInsert sqlInsert 
	sqlInsertReturn sqlUpdate sqlDelete sqlGeneric

=head1 AUTHOR

Ward Vandewege, E<lt>ward@pong.beE<gt>

=head1 SEE ALSO

L<Apache::WeSQL>, L<Apache::WeSQL::AppHandler>

=cut
