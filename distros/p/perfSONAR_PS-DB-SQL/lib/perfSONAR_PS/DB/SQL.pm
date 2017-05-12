package perfSONAR_PS::DB::SQL;

use fields 'NAME', 'USER', 'PASS', 'SCHEMA', 'HANDLE', 'LOGGER';

use strict;
use warnings;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::DB::SQL - A module that provides methods for dealing with common
SQL databases.

=head1 DESCRIPTION

This module creates common use cases with the help of the DBI module.  The
module is to be treated as an object, where each instance of the object
represents a direct connection to a single database and collection.  Each
method may then be invoked on the object for the specific database.  

=cut

use DBI;
use Log::Log4perl qw(get_logger);
use English qw( -no_match_vars );
use Params::Validate qw(:all);

use perfSONAR_PS::Common;
use perfSONAR_PS::ParameterValidation;

=head2 new($package, $name, $user, $pass, $schema)

Create a new SQL object.  All arguments are optional:

 * name - Name (DBI connection string) of sql based database
 * user - username to connect to said database
 * pass - password for said username
 * schema - array reference of field names for the table

The arguments can be set (and re-set) via the appropriate function calls.  

=cut

sub new {
    my ( $package, @args ) = @_;
    my $parameters = validateParams( @args, { name => 0, user => 0, pass => 0, schema => 0 } );

    my $self = fields::new($package);
    $self->{LOGGER} = get_logger("perfSONAR_PS::DB::SQL");
    if ( exists $parameters->{name} and $parameters->{name} ) {
        $self->{NAME} = $parameters->{name};
    }
    if ( exists $parameters->{user} and $parameters->{user} ) {
        $self->{USER} = $parameters->{user};
    }
    if ( exists $parameters->{pass} and $parameters->{pass} ) {
        $self->{PASS} = $parameters->{pass};
    }
    if ( exists $parameters->{schema} and $parameters->{schema} ) {
        @{ $self->{SCHEMA} } = @{ $parameters->{schema} };
    }
    return $self;
}

=head2 setName($self, { name })

Sets the name of the database (write as a DBI connection string).  

=cut

sub setName {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { name => 1 } );

    if ( $parameters->{name} ) {
        $self->{NAME} = $parameters->{name};
        return 0;
    }
    else {
        $self->{LOGGER}->error("Cannot set name.");
        return -1
    }
}

=head2 setUser($self, { user })

Sets the username for connectecting to the database.

=cut

sub setUser {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { user => 1 } );

    if ( $parameters->{user} ) {
        $self->{USER} = $parameters->{user};
        return 0;
    }
    else {
        $self->{LOGGER}->error("Cannot set username.");
        return -1;
    }
}

=head2 setPass($self, { pass })

Sets the password for the database.

=cut

sub setPass {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { pass => 1 } );

    if ( $parameters->{pass} ) {
        $self->{PASS} = $parameters->{pass};
        return 0;
    }
    else {
        $self->{LOGGER}->error("Cannot set password.");
        return -1;
    }
}

=head2 setSchema($self, { schema })

Sets the schema of the database (as a table).  

=cut

sub setSchema {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { schema => 1 } );

    if ( $parameters->{schema} ) {
        @{ $self->{SCHEMA} } = @{ $parameters->{schema} };
        return 0;
    }
    else {
        $self->{LOGGER}->error("Cannot set schema array.");
        return -1;
    }
}

=head2 openDB($self)

Opens the dabatase.

=cut

sub openDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    eval {
        my %attr = ( RaiseError => 1, );
        $self->{HANDLE} = DBI->connect( $self->{NAME}, $self->{USER}, $self->{PASS}, \%attr ) or $self->{LOGGER}->error( "Database \"" . $self->{NAME} . "\" unavailable with user \"" . $self->{NAME} . "\" and password \"" . $self->{PASS} . "\"." );
    };
    if ($EVAL_ERROR) {
        $self->{LOGGER}->error( "Open error \"" . $EVAL_ERROR . "\"." );
        return -1;
    }
    return 0;
}

=head2 closeDB($self)

Closes the database.

=cut

sub closeDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    eval { 
        $self->{HANDLE}->disconnect;
    };
    if ($EVAL_ERROR) {
        $self->{LOGGER}->error( "Close error \"" . $EVAL_ERROR . "\"." );
        return -1;
    }
    return 0;
}

=head2 query($self, { query })

Queries the database.

=cut

sub query {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 1 } );

    my $results = ();
    if ( $parameters->{query} ) {
        $self->{LOGGER}->debug( "Query \"" . $parameters->{query} . "\" received." );
        eval {
            my $sth = $self->{HANDLE}->prepare( $parameters->{query} );
            $sth->execute() or $self->{LOGGER}->error( "Query error on statement \"" . $parameters->{query} . "\"." );
            $results = $sth->fetchall_arrayref;
            
        };
        if ($EVAL_ERROR) {
            $self->{LOGGER}->error( "Query error \"" . $EVAL_ERROR . "\" on statement \"" . $parameters->{query} . "\"." );
            return -1;
        }
    }
    else {
      $self->{LOGGER}->error("Query not found.");
      return -1;
    }
    return $results;
}

=head2 count($self, { query })

Counts the number of results of a query in the database.

=cut

sub count {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 1 } );

    my $results = q{};
    if ( $parameters->{query} ) {
        $self->{LOGGER}->debug( "Query \"" . $parameters->{query} . "\" received." );
        eval {
            my $sth = $self->{HANDLE}->prepare( $parameters->{query} );
            $sth->execute() or $self->{LOGGER}->error( "Query error on statement \"" . $parameters->{query} . "\"." );
            $results = $sth->fetchall_arrayref;
        };
        if ($EVAL_ERROR) {
            $self->{LOGGER}->error( "Query error \"" . $EVAL_ERROR . "\" on statement \"" . $parameters->{query} . "\"." );
            return -1;
        }
    }
    else {
        $self->{LOGGER}->error("Query not found.");
        return -1;
    }
    return $#{$results} + 1;
}

=head2 insert($self, { table, argvalues })

Inserts items in the database.

=cut

sub insert {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { table => 1, argvalues => 1 } );

    if ( $parameters->{table} and $parameters->{argvalues} ) {
        my %values = %{ $parameters->{argvalues} };
        my $insert = "insert into " . $parameters->{table} . " (";

        my $len = $#{ $self->{SCHEMA} };
        for my $x ( 0 .. $len ) {
            if ( $x == 0 ) {
                $insert = $insert . $self->{SCHEMA}->[$x];
            }
            else {
                $insert = $insert . ", " . $self->{SCHEMA}->[$x];
            }
        }
        $insert = $insert . ") values (";
        $len    = $#{ $self->{SCHEMA} };
        for my $x ( 0 .. $len ) {
            if ( $x == 0 ) {
                $insert = $insert . "?";
            }
            else {
                $insert = $insert . ", ?";
            }
        }
        $insert = $insert . ")";
        $self->{LOGGER}->debug( "Insert \"" . $insert . "\" prepared." );
        eval {
            my $sth  = $self->{HANDLE}->prepare($insert);
            my $len2 = $#{ $self->{SCHEMA} };
            for my $x ( 0 .. $len2 ) {
                $sth->bind_param( $x + 1, $values{ $self->{SCHEMA}->[$x] } );
            }
            $sth->execute() or $self->{LOGGER}->error( "Insert error on statement \"" . $insert . "\"." );
        };
        if ($EVAL_ERROR) {
            $self->{LOGGER}->error( "Insert error \"" . $EVAL_ERROR . "\" on statement \"" . $insert . "\"." );
            return -1;
        }
    }
    else {
        $self->{LOGGER}->error("Missing argument.");
        return -1;
    }
    return 0;
}

=head2 update($self, { table, wherevalues, updatevalues })

Updates items in the database.

=cut

sub update {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { table => 1, wherevalues => 1, updatevalues => 1 } );

    if ( $parameters->{table} and $parameters->{wherevalues} and $parameters->{updatevalues} ) {
        my $first = q{};
        my %w     = %{ $parameters->{wherevalues} };
        my %v     = %{ $parameters->{updatevalues} };

        my $where = q{};
        foreach my $var ( keys %w ) {
            $where .= " and " if ($where);
            $where .= $var . " = " . $w{$var};
        }

        my $values = q{};
        foreach my $var ( keys %v ) {
            $values .= ", " if ($values);
            $values .= $var . " = " . $v{$var};
        }

        my $sql = "update " . $parameters->{table} . " set " . $values . " where " . $where;
        $self->{LOGGER}->debug( "Update \"" . $sql . "\" prepared." );
        eval {
            my $sth = $self->{HANDLE}->prepare($sql);
            $sth->execute() or $self->{LOGGER}->error( "Update error on statement \"" . $sql . "\"." );
        };
        if ($EVAL_ERROR) {
            $self->{LOGGER}->error( "Update error \"" . $EVAL_ERROR . "\" on statement \"" . $sql . "\"." );
            return -1;
        }
    }
    else {
        $self->{LOGGER}->error("Missing argument.");
        return -1;
    }
    return 0;
}

=head2 remove($self, { delete })

Removes items from the database.

=cut

sub remove {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { delete => 1 } );

    if ( $parameters->{delete} ) {
        $self->{LOGGER}->debug( "Delete \"" . $parameters->{delete} . "\" received." );
        eval {
            my $sth = $self->{HANDLE}->prepare( $parameters->{delete} );
            $sth->execute() or $self->{LOGGER}->error( "Remove error on statement \"" . $parameters->{delete} . "\"." );
        };
        if ($EVAL_ERROR) {
            $self->{LOGGER}->error( "Remove error \"" . $EVAL_ERROR . "\" on statement \"" . $parameters->{delete} . "\"." );
            return -1;
        }
    }
    else {
        $self->{LOGGER}->error("Missing argument.");
        return -1;
    }
    return 0;
}

1;

__END__

=head1 SYNOPSIS

    use perfSONAR_PS::DB::SQL;

    my @dbSchema = ("id", "time", "value", "eventtype", "misc");
    my $db = new perfSONAR_PS::DB::SQL({
      name => "DBI:SQLite:dbname=/home/jason/Netradar/MP/SNMP/netradar.db", 
      user => "",
      pass => "",
      schema => \@dbSchema
    });

    # or also:
    # 
    # my $db = new perfSONAR_PS::DB::SQL;
    # $db->setName({ name => "DBI:SQLite:dbname=/home/jason/netradar/MP/SNMP/netradar.db" });
    # $db->setUser({ user => "" });
    # $db->setPass({ pass => "" });    
    # $db->setSchema({ schema => \@dbSchema });     

    if ($db->openDB == -1) {
      print "Error opening database\n";
    }

    my $count = $db->count({ query => "select * from data" });
    if($count == -1) {
      print "Error executing count statement\n";
    }
    else {
      print "There are " , $count , " rows in the database.\n";
    }

    my $result = $db->query({ query => "select * from data where time < 1163968390 and time > 1163968360" });
    if($#result == -1) {
      print "Error executing query statement\n";
    }   
    else { 
      for(my $a = 0; $a <= $#{$result}; $a++) {
        for(my $b = 0; $b <= $#{$result->[$a]}; $b++) {
          print "-->" , $result->[$a][$b] , "\n";
        }
        print "\n";
      }
    }

    my $delete = "delete from data where id = '192.168.1.4-snmp.1.3.6.1.2.1.2.2.1.16-5'";
    $delete = $delete . " and time = '1163968370'";
    my $status = $db->remove({ delete => $delete });
    if($status == -1) {
      print "Error executing remove statement\n";
    }

    my %dbSchemaValues = (
      id => "192.168.1.4-snmp.1.3.6.1.2.1.2.2.1.16-5", 
      time => 1163968370, 
      value => 9724592, 
      eventtype => "ifOutOctets",  
      misc => ""
    );  
    $status = $db->insert({ table => "data", argvalues => \%dbSchemaValues });
    if($status == -1) {
      print "Error executing insert statement\n";
    }

    if ($db->closeDB == -1) {
      print "Error closing database\n";
    }
       
=head1 SEE ALSO

L<DBI>, L<Log::Log4perl>, L<English>, L<Params::Validate>,
L<perfSONAR_PS::Common>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 VERSION

$Id$

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along 
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
