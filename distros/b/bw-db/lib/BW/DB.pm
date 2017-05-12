# BW::DB.pm
# Normalized database routines
#   with support for MySQL and SQLite
# 
# by Bill Weinman - http://bw.org/
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#
# See HISTORY file. 
#

package BW::DB;
use strict;
use warnings;

use base qw( BW::Base );
use BW::Constants;
use DBI;

our $VERSION = "1.1.1";

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    if ( $self->{connect} or $self->{dsn} or $self->{database} or $self->{dbengine} ) {
        $self->init_db;
    }

    return SUCCESS;
}

# _setter_getter entry points
sub connect  { BW::Base::_setter_getter(@_); }
sub database { BW::Base::_setter_getter(@_); }
sub dbname   { BW::Base::_setter_getter(@_); }
sub host     { BW::Base::_setter_getter(@_); }
sub port     { BW::Base::_setter_getter(@_); }
sub socket   { BW::Base::_setter_getter(@_); }
sub user     { BW::Base::_setter_getter(@_); }
sub password { BW::Base::_setter_getter(@_); }
sub dsn      { BW::Base::_setter_getter(@_); }
sub dbh      { BW::Base::_setter_getter(@_); }
sub dbengine { BW::Base::_setter_getter(@_); }  # may be 'mysql' or 'SQLite'

# setup the database connection
sub init_db
{
    my $sn   = 'init_db';
    my $self = shift;

    my ( $dsn, $dbengine, $dbname, $database, $host, $port, $socket, $user, $password );
    $dbengine = $self->{dbengine} || 'mysql';   # default to mysql for backward compatibility

    if ( $self->connect ) {
        my @dsnarray = split( /:/, $self->{connect} );
        if( scalar @dsnarray == 2 ) {
            ( $dbengine, $dbname ) = @dsnarray;
        } else {
            ( $database, $host, $port, $user, $password ) = split( /:/, $self->{connect} );
        }
    } elsif ( $self->{dsn} ) {
        $dsn = $self->{dsn};
    } elsif ( $self->{dbname} ) {
        $dbengine = 'SQLite';
        $dbname = $self->{dbname};
    } elsif ( $self->{database} ) {
        $database = $self->{database};
        $host     = $self->{host};
        $port     = $self->{port};
        $socket   = $self->{socket};
    }

    if(lc $dbengine eq 'sqlite') { $dbengine = 'SQLite' }; # correct any miscapitalization

    $self->dbengine($dbengine) if $dbengine;    # use the setters
    $self->dbname($dbname) if $dbname;

    $user     = $self->{user}     if $self->{user};
    $password = $self->{password} if $self->{password};
    $dsn = "DBI:${dbengine}"        unless $dsn;
    $dsn .= ":database=$database"   if $database;
    $dsn .= ":dbname=$dbname"       if $dbname;
    $dsn .= ";host=$host"           if $host;
    $dsn .= ";port=$port"           if $port;
    $dsn .= ";mysql_socket=$socket" if $socket;

    $self->{dbh} = DBI->connect( $dsn, $user, $password, { PrintError => 0 } );
    return $self->_error("$sn: DBI connect error: $DBI::errstr") if $DBI::errstr;
    return $self->_error("$sn: database not connected") unless $self->{dbh};
}

# sql_do ( $query, @bind_values )
# returns number of rows affected
# use for non-SELECT ad-hoc queries
sub sql_do
{
    my $sn          = 'sql_do';
    my $self        = shift;
    my $query       = shift or return VOID;
    my @bind_values = @_;

    $self->init_db()                                unless $self->{dbh};
    return $self->_error("Database not connected.") unless $self->{dbh};

    my $rc = $self->{dbh}->do( $query, undef, @bind_values );
    if ($DBI::err) {
        return $self->_error("$sn: DBI: $DBI::errstr");
    } else {
        return $rc;
    }
}

# sql_select ( $query, @bind_values )
# returns arrayref of hashrefs or FAILURE
# hash keys are equiv of column (or query) names
sub sql_select
{
    my $sn          = 'sql_select';
    my $self        = shift;
    my $query       = shift or return VOID;
    my @bind_values = @_;

    $self->init_db()                                     unless $self->{dbh};
    return $self->_error("$sn: Database not connected.") unless $self->{dbh};

    my $rc = $self->{dbh}->selectall_arrayref( $query, { Slice => {} }, @bind_values );
    if ($DBI::err) {
        return $self->_error("$sn: DBI: $DBI::errstr");
    } elsif ( $rc && ref($rc) eq 'ARRAY' ) {
        return $rc;
    } else {
        return FAILURE;
    }
}

# sql_select_column ( $query, @bind_values )
# returns arrayref of values (scalars) or FAILURE
sub sql_select_column
{
    my $sn          = 'sql_select_column';
    my $self        = shift;
    my $query       = shift or return VOID;
    my @bind_values = @_;

    $self->init_db()                                     unless $self->{dbh};
    return $self->_error("$sn: Database not connected.") unless $self->{dbh};

    my $rc = $self->{dbh}->selectcol_arrayref( $query, undef, @bind_values );
    if ($DBI::err) {
        return $self->_error("$sn: DBI: $DBI::errstr");
    } elsif ( $rc && ref($rc) eq 'ARRAY' ) {
        return $rc;
    } else {
        return FAILURE;
    }
}

# sql_select_value ( $query, @bind_values )
# returns scalar value or FAILURE
sub sql_select_value
{
    my $sn          = 'sql_select_value';
    my $self        = shift;
    my $query       = shift or return VOID;
    my @bind_values = @_;

    $self->init_db()                                     unless $self->{dbh};
    return $self->_error("$sn: Database not connected.") unless $self->{dbh};

    my $rc = $self->{dbh}->selectcol_arrayref( $query, { MaxRows => 1 }, @bind_values );
    if ($DBI::err) {
        return $self->_error("$sn: DBI: $DBI::errstr");
    } elsif ( $rc && ref($rc) eq 'ARRAY' ) {
        return $rc->[0];
    } else {
        return FAILURE;
    }
}

# insert( table, { name => value, ... } )
# returns SUCCESS or FAILURE
sub insert
{
    my $sn      = 'insert';
    my $self    = shift or return undef;
    my $table   = shift or return undef;
    my $nvpairs = shift or return undef;
    my @cols;
    my @vals;

    $self->init_db()                                     unless $self->{dbh};
    return $self->_error("$sn: Database not connected.") unless $self->{dbh};

    foreach my $k ( keys %{$nvpairs} ) {
        push @cols, $k;
        push @vals, $nvpairs->{$k};
    }
    return FAILURE unless ( @cols and @vals );

    my $query =
        "INSERT INTO $table (" .
        join( ', ', @cols ) .
        ") VALUES (" .
        join( ', ', ('?') x @vals ) .
        ")";

    $self->{dbh}->do( $query, undef, @vals ) or return $self->_error("$sn: $DBI::errstr");
    return SUCCESS;
}

# insert_id
# returns the insert id from the last insert operation
sub insert_id
{
    my $self = shift;
    return $self->{dbh}->last_insert_id( '', '', '', '' );      # use the DBI function
}

sub table_exists
{
    my $sn         = 'table_exists';
    my $self       = shift;
    my $table_name = shift or return $self->_error("no table name");

    if($self->{dbengine} eq 'SQLite') {
        my $rc = $self->sql_select( "pragma table_info($table_name)" );
        return scalar @$rc;     # pragma returns no rows if table doesn't exist
    } elsif($self->{dbengine} eq 'mysql') {
        my $rc = $self->sql_select("describe $table_name");
        if ( $self->error ) {
            return FALSE;
        } else {
            return TRUE;
        }
    }
}

# create an sql date from a unix epoch date
sub sql_date
{
    my ( $self, $t ) = @_;
    $t = time unless defined $t;

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = gmtime($t);
    my $tstr = sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );
    return $tstr;
}

1;

__END__

=head1 NAME

BW::DB - Normalized database routines

=head1 SYNOPSIS

    use BW::DB;
    my $errstr;

    my $db = BW::DB->new( connect => "database:host:3306:user:password" );
    error($errstr) if (($errstr = $db->error));

    my $db = BW::DB->new(
        dsn => 'DBI:mysql:database=database;mysql_socket=/tmp/mysql2.sock",
        user => "me", password => "foo!bar" );
    error($errstr) if(($errstr = $db->error));

    my $db = BW::DB->new(
        database => "database", host => "host", port => "3306",
        user => "user", password => "pass");
    error($errstr) if (($errstr = $db->error));

    # experimental SQLite support ...
    my $db = BW::DB->new(dbengine => "SQLite", dbname => "dbfile");
    error($errstr) if (($errstr = $db->error));

=head1 METHODS

=over 4

=item B<new>( connect => $connect_string )

Constructs a new DB object. Connect string is in the format: 

  database:host:port:user:password

... or for experimental SQLite support:

  SQLite:dbfile

Returns a blessed DB object reference. Returns VOID if an object 
cannot be created. If the object is constructed but there is an 
error connecting to the database, the object reference is returned 
and $db->error is set. 

Alternately you can call new() with separate parameters for the 
database connection thusly:

    my $db = BW::DB->new(
        database => "database", host => "host", port => "3306",
        user => "user", password => "pass"
    );

... or for experimental SQLite support:

    my $db = BW::DB->new(
        dbengine => "SQLite", dbname => "dbfile"
    );

If your database is listening on a named pipe you can connect using 
a DBI DSN like this:

  my $db = BW::DB->new(
    dsn => "DBI:mysql:database=database;mysql_socket=/tmp/mysql2.sock",
    user => "me", password => "foo!bar" );
  error($errstr) if(($errstr = $db->error));

=item B<sql_do>( $query, @bind_values )

Calls DBD::do for queries that don't return data, like INSERT or 
DELETE. Returns SUCCESS or FAILURE. 

=item B<sql_select>( $query, @bind_values )

Performs the query with the bind values and returns an arrayref 
where each element in the array is a hashref with a row of data 
returned from the query. Keys are set to column names. 

Returns FAILURE and sets $db->error if a DBI error was encountered.

=item B<sql_select_column>( $query, @bind_values )

Performs the query with the bind values and returns an arrayref 
where each element in the array is a scalar value from the first 
column returned from the query. 

Returns FAILURE and sets $db->error if a DBI error was encountered.

=item B<sql_select_value>( $query, @bind_values )

Performs the query with the bind values and returns a scalar with
a single value from the query. The query should return a single 
value from a single column. 

Returns FAILURE and sets $db->error if a DBI error was encountered.

=item B<insert>( $table, $hashref )

Performs an insert into table with the names/values in $hashref.
Use the B<insert_id> method to get the value of any auto_increment field. 

Returns SUCCESS or FAILURE (and sets $db->error). 

=item B<insert_id>

Returns the value of any auto_increment field from the last insert operation. 

=item B<table_exists>( $table )

Performs a "describe" and returns TRUE or FALSE. 

=item B<error>

Returns and clears the object error message. 

=back

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

See HISTORY file.

=cut

