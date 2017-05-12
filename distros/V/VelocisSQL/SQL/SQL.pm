#! /usr/local/bin/perl

package Velocis;
use vars qw($errorstr $errorstate);

package Velocis::SQL;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
	db_connect
);

@EXPORT_OK = qw(
	SQL_CDATA
	SQL_ROWID
	SQL_CHAR
	SQL_DECIMAL
	SQL_DATE
	SQL_DOUBLE
	SQL_FLOAT
	SQL_INTEGER
	SQL_REAL
	SQL_SMALLINT
	SQL_TIME
	SQL_TIMESTAMP
	SQL_VARCHAR
);

%EXPORT_TAGS = (
    SQLTYPES => [@EXPORT_OK],
);

$VERSION = 0.0 + substr(q$Revision: 1.3 $, 10);

require 5.003;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Velocis::SQL macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Velocis::SQL $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Velocis::SQL - Perl interface to the Raima Velocis SQL database engine

=head1 SYNOPSIS

 use Velocis::SQL;

 $conn = db_connect($database,$user,$password)
   or die "could not connect -- ($Velocis::errorstate) $Velocis::errorstr";

 $query = $conn->execute($sql_statement)
   or die "Error -- ($Velocis::errorstate) $Velocis::errorstr";

 @array = $query->fetchrow();

 $val = $query->numrows();
 $val = $query->numcolumns();
 $val = $query->columntype($column_index);
 $val = $query->columnname($column_index);
 $val = $query->columnlength($column_index);

=head1 DESCRIPTION

This package is designed as close as possible to its C API
counterpart. The C Programmer Guide that comes with Velocis describes most
things you need.

Once you db_connect() to a database, you can then issue commands to the
execute() method.  If either of them returns an error from the
underlying API, the value returned will be C<undef> and the variable 
C<$Velocis::errorstr> will contain the error message from the
database, and the variable C<$Velocis::errorstate> will contain the
Velocis error state.

The function fetchrow() returns an array of the values from the next
row fetched from the server.  It returns an empty list when there is
no more data available.  Calling fetchrow() on a statement handle
which is B<not> from a SELECT statement has undefined behavior.  Other
functions work identically to their similarly-named C API functions.

To import all the SQL type definitions for use with columntype(), use:

    use Velocis::SQL qw(:DEFAULT :SQLTYPES);

=head2 No disconnect or free statements

Whenever the scalar that holds the statement or connection handle
loses its value, the underlying data structures will be freed and
appropriate connections closed.  This can be accomplished by
performing one of these actions:

=over 4

=item undef the handle

=item use the handle for another purpose

=item let the handle run out of scope

=item exit the program.

=back

=head2 Error messages

A global variable C<$Velocis::errorstr> always holds the last error
message.  It is never reset except on the next error.  The only time
it holds a valid message is after execute() or db_connect() returns
C<undef>.  If fetchrow() encountered an error from the database, it
will set the error string to indicate the error and return an empty
array; however, it will not clear the error string upon successful
return, so you must first set it to the empty string if you wish to
check it later (when fetchrow() returns an empty array).

=head1 PREREQUISITES

You need to have the Velocis database server installed and configured on
your system to use this module.

Be sure to set the proper DEFINES in the C<Makefile.PL> file for your
architecture.

=head1 AUTHOR

Vivek Khera (C<vivek@khera.org>).  Many ideas were taken from the
MsqlPerl module.

=cut
