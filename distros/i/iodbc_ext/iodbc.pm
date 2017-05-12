#**********************************************************************
#              iodbc.pm  The perl iODBC extension 0.1                 *
#**********************************************************************
#              Copyright (C) 1996 J. Michael Mahan and                *
#                  Rose-Hulman Institute of Technology                *
#**********************************************************************
#    This package is free software; you can redistribute it and/or    *
# modify it under the terms of the GNU General Public License or      *
# Larry Wall's "Artistic License".                                    *
#**********************************************************************
#    This package is distributed in the hope that it will be useful,  *
#  but WITHOUT ANY WARRANTY; without even the implied warranty of     *
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU  *
#  General Public License for more details.                           *
#**********************************************************************

package iodbc;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	SQLAllocEnv SQLAllocConnect SQLConnect SQLAllocStmt SQLPrepare
	SQLGetCursorName SQLSetCursorName SQLExecute SQLExecDirect 
	SQLRowCount SQLNumResultCols SQLDescribeCol SQLColAttributes
	SQLBindCol SQLFetch SQLError SQLFreeStmt SQLCancel SQLTransact
	SQLDisconnect SQLFreeConnect SQLFreeEnv

	SQL_SUCCESS SQL_SUCCESS_WITH_INFO SQL_NO_DATA_FOUND SQL_ERROR 
	SQL_INVALID_HANDLE SQL_STILL_EXECUTING SQL_NEED_DATA
	
	SQL_NULL_HENV SQL_NULL_HDBC SQL_NULL_HSTMT SQL_NTS SQL_NULL_DATA
	SQL_NO_TOTAL SQL_NO_NULLS SQL_NULLABLE SQL_NULLABLE_UNKNOWN
	
	SQL_DROP SQL_CLOSE SQL_UNBIND SQL_RESET_PARAMS
	
	SQL_COLUMN_AUTO_INCREMENT SQL_COLUMN_CASE_SENSITIVE 
	SQL_COLUMN_COUNT SQL_COLUMN_DISPLAY_SIZE SQL_COLUMN_LABEL 
	SQL_COLUMN_LENGTH SQL_COLUMN_MONEY SQL_COLUMN_NAME 
	SQL_COLUMN_NULLABLE SQL_COLUMN_OWNER_NAME SQL_COLUMN_PRECISION 
	SQL_COLUMN_QUALIFIER_NAME SQL_COLUMN_SCALE 
	SQL_COLUMN_SEARCHABLE SQL_COLUMN_TABLE_NAME 
	SQL_COLUMN_TYPE SQL_COLUMN_TYPE_NAME SQL_COLUMN_UNSIGNED 
	SQL_COLUMN_UPDATABLE
	
	SQL_C_BINARY SQL_C_BIT SQL_C_BOOKMARK SQL_C_CHAR SQL_C_DATE 
	SQL_C_DEFAULT SQL_C_DOUBLE SQL_C_FLOAT SQL_C_SLONG SQL_C_SSHORT 
	SQL_C_STINYINT SQL_C_TIME SQL_C_TIMESTAMP SQL_C_ULONG SQL_C_USHORT 
	SQL_C_UTINYINT SQL_C_LONG SQL_C_SHORT SQL_C_TINYINT
	
	TRUE FALSE SQL_UNSEARCHABLE SQL_LIKE_ONLY SQL_ALL_EXCEPT_LIKE
	SQL_SEARCHABLE SQL_ATTR_READONLY SQL_ATTR_WRITE 
	SQL_ATTR_READWRITE_UNKNOWN  
);

$VERSION = '0.01';

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
		croak "Your vendor has not defined iodbc macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap iodbc $VERSION;

# Preloaded methods go here.#

#These methods control bound columns in some way.#
%iodbc::fCType_hash = {};     #This keeps track a SQL type 
                              #  for each column in a statement
                              #  that is bound.
%iodbc::rgbValue_hash = {};   #This keeps track of a perl# 
                              #  reference for each column# in
                              #  a statement that is bound#
%iodbc::rgbPtr_hash = {};     #This keeps track of a ODBC
                              #  memory location for each
                              #  column in a statement that is 
                              #  bound. 
%iodbc::sqlcdefault = {};
$iodbc::sqlcdefault{SQL_CHAR()}=SQL_C_CHAR();
$iodbc::sqlcdefault{SQL_VARCHAR()}=SQL_C_CHAR();
$iodbc::sqlcdefault{SQL_LONGVARCHAR()}=SQL_C_CHAR();
$iodbc::sqlcdefault{SQL_DECIMAL()}=SQL_C_CHAR();
$iodbc::sqlcdefault{SQL_NUMERIC()}=SQL_C_CHAR();
$iodbc::sqlcdefault{SQL_SMALLINT()}=SQL_C_SHORT();
$iodbc::sqlcdefault{SQL_INTEGER()}=SQL_C_LONG();
$iodbc::sqlcdefault{SQL_REAL()}=SQL_C_FLOAT();
$iodbc::sqlcdefault{SQL_FLOAT()}=SQL_C_DOUBLE();
$iodbc::sqlcdefault{SQL_DOUBLE()}=SQL_C_DOUBLE();
$iodbc::sqlcdefault{SQL_C_DEFAULT()}=SQL_C_CHAR();

sub SQLBindCol {
    my ($hstmt,$icol,$fCType,$rgbValue,$cbValueMax,$pcbValue) = @_;
    if ($fCType==SQL_C_DEFAULT()){
	my($rgbDesc);
	my($cbDescMax);
        my($pcbDesc);
	my($pfDesc);
	my($retcode);
	$retcode=SQLColAttributes($hstmt,$icol,SQL_COLUMN_TYPE(),$rgbDesc,0,$pcbDesc,$pfDesc);
	if ($retcode != SQL_SUCCESS()) {return $retcode;}
	if (exists $iodbc::sqlcdefault{$pfDesc}) {
	    $fCType=$iodbc::sqlcdefault{$pfDesc}
	} else {
	    $fCType=$iodbc::sqlcdefault{SQL_C_DEFAULT()};
	}
   }
    $iodbc::fCType_hash{$hstmt}{$icol}=$fCType;
    $iodbc::rgbValue_hash{$hstmt}{$icol}=$rgbValue;
   return SQLBindColint($hstmt,$icol,$fCType,$iodbc::rgbPtr_hash{$hstmt}{$icol},$cbValueMax,$pcbValue);
}
#Whenever a new row is fetched, the data in the perl reference that is
#  bound to a column need to be updated with the new data.
sub SQLFetch {
    my ($hstmt) = @_;
    my $icol;
    my $retval;
    $retval = SQLFetchint($hstmt);
#We loop though every column that is bound in the statement.
    foreach $icol (keys %{$iodbc::rgbPtr_hash{$hstmt}}) {
	${$iodbc::rgbValue_hash{$hstmt}{$icol}} = 
	    SQLRefreshCol($iodbc::rgbPtr_hash{$hstmt}{$icol},
			  $iodbc::fCType_hash{$hstmt}{$icol});
    }
return $retval;
}
#When SQLFreeStmt is called with the parameters SQL_DROP or SQL_UNBIND,
# the bound columns for the statement are released.  We first free the
# actuall memory by calling SQLFreeCol, then we remove the references to
#the columns in the statement
sub SQLFreeStmt {
    my $icol;
    my ($hstmt,$fOption) = @_;
    if (($fOption == SQL_UNBIND()) or ($fOption== SQL_DROP())) {
	foreach $icol (keys %{$iodbc::rgbPtr_hash{$hstmt}}) {
	    SQLFreeCol($iodbc::rgbPtr_hash{$hstmt}{$icol});
	}		
	delete $iodbc::rgbPtr_hash{$hstmt};
	delete $iodbc::fCType_hash{$hstmt};
	delete $iodbc::rgbValue_hash{$hstmt};	
    }
    return SQLFreeStmtint($hstmt,$fOption);
} 

1;
__END__

=head1 NAME

iodbc - Perl extension for the iODBC API

=head1 SYNOPSIS

This man page is not intended to be a manual on the ODBC API.  Please see an ODBC manual for extended documentation on the usage of ODBC commands.

To use iodbc functions:

C<use iodbc;>

=head1 DESCRIPTION   

Everything in the extension follows the ODBC core API except that all function calls are pass by value.  The one exception is SQLBindCol which needs to be passed a reference to a scalar.  For More information please seek a ODBC manual and remember that this extension only works with core implementations.


=head2 Functions

The following functions are included with this iodbc extension.  Parameters marked [i] are for input into the function while parameters marked [r] return data from a function.

=over 2

=item *

SQLAllocEnv

=over 4

=item Syntax

C<SQLAllocEnv($hEnv);>

=item Parameters

=item

$hEnv 

=over 4

=item

[o]  The environment handle.  This will be passed to other functions.

=back

=back





=item *

SQLAllocConnect

=over 4

=item Syntax

C<SQLAllocConnect($hEnv, $hDbc);>

=item Parameters

=item

$hEnv 

=over 4

=item

[i]  The environment handle as it is returned from C<SQLAllocEnv()>.

=back

=item

$hDbc

=over 4

=item

[o]  The connection handle.  This will be passed to other functions.

=back

=back




=item *

SQLConnect

=over 4

=item Syntax

C<SQLConnect($hDbc, $pvDsn, $ivfDsnSize, $pvUid, $ivfUidSize, $pvPwd, $ivfPwdSize);>

=item Parameters

=item

$hDbc 

=over 4

=item

[i]  The connection handle as it is returned from C<SQLAllocConnect()>.

=back

=item

$pvDsn

=over 4

=item

[i]  The data source name.  This should be a string.

=back

=item

$ivfDsnSize

=over 4

=item

[i]  The size of $pvDsn.  It should be C<SQL_NTS>.  This stands for a null terminated string.

=back

=item

$pvUid 

=over 4

=item

[i]  The user id.  This should also be a string.  

=back

=item

$ivfUidSize

=over 4

=item

[i]  The size of $pvUid.  It should also be C<SQL_NTS>.

=back

=item

$pvPwd 

=over 4

=item

[i]  The password.  Once again it should be a string.

=back

=item

$ivfPwdSize 

=over 4

=item

[i]  The size of pvPwd.  Once again it should be C<SQL_NTS>

=back

=back




=item *

SQLAllocStmt

=over 4

=item Syntax

C<SQLAllocStmt($hDbc, $hStmt);>

=item Parameters

=item

$hDbc 

=over 4

=item

[i]  The connection handle as it is returned from C<SQLAllocConnect()>.

=back

=item

$hStmt

=over 4

=item

[o]  The statement handle.  This will be passed to other functions.

=back

=back





=item *

SQLGetCursorName

=over 4

=item Syntax

C<SQLGetCursorName($hStmt, $pvCursor, $ivCursorMax, $ivCursorSize);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item

$pvCursor

=over 4

=item

[o]  The cursor name associated with the $hStmt.  This will be returned from the function as a string of maximum length $ivCursorMax.

=back

=item

$ivCursorMax

=over 4

=item

[i]  The maximum size of $ivCursor.

=back

=item

$ivCursorSize

=over 4

=item

[i]  The actual size of the string available for return to $pvCursor.

=back

=back




=item *

SQLSetCursorName

=over 4

=item Syntax

C<SQLSetCursorName($hStmt, $pvCursor, $ivfCursorSize);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item

$pvCursor

=over 4

=item

[i]  The Cursor Name to be associated with the $hStmt.  This should be a string.

=back

=item

$ivfCursorSize

=over 4

=item

[i]  The size of $pvCursor.  This should be C<SQL_NTS>.

=back

=back




=item *

SQLPrepare

=over 4

=item Syntax

C<SQLPrepare($hStmt, $pvSql, $ivfSqlSize);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item

$pvSql

=over 4

=item

[i]  The SQL statement to be prepared.  This should be a string.

=back

=item

$ivfSqlSize

=over 4

=item

[i]  The size of $Sql.  This should be C<SQL_NTS>.

=back

=back





=item *

SQLExecute

=over 4

=item Syntax

C<SQLExecute($hStmt);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=back





=item *

SQLExecDirect

=over 4

=item Syntax

C<SQLExecDirect($hStmt, $pvSql, $ivfSqlSize);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item

$pvSql

=over 4

=item

[i]  The SQL statement to be prepared.  This should be a string.

=back

=item

$ivfSqlSize

=over 4

=item

[i]  The size of $pvSql.  This should be C<SQL_NTS>.

=back

=back




=item *

SQLRowCount

=over 4

=item Syntax

C<SQLRowCount($hStmt, $ivNumRows);>

=item Parameters

=item

$hStmt

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item

$ivNumCols

=over 4

=item

[o]  The number of rows affected by the SQL statement just executed in $hStmt.  This works for C<UPDATE>, C<INSERT> and C<DELETE> statements.

=back

=back





=item *

SQLNumResultCols

=over 4

=item Syntax

C<SQLNumResultCols($hStmt, $ivNumCols);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item

$ivNumCols

=over 4

=item

[o]  The Number of columns returned in a result set of a SQL statement in $hStmt.  

=back

=back





=item *

SQLDescribeCol

=over 4

=item Syntax

C<SQLDescribeCol($hStmt, $ivCol, $pvColName, $ivColNameMax, $ivColNameSize, $fSqlType, $ivPrecision, $ivScale, $fNullable);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item

$ivCol

=over 4

=item

[i]  The function will return a description of this column.

=back

=item

$pvColName

=over 4

=item

[o]  A string that contains the name of column $ivCol

=back

=item

$ivColNameMax

=over 4

=item

[i]  The maximum size of the column name to return to $pvColName

=back

=item

$ivColNameSize

=over 4

=item

[o]  The size of the column name available to return to $pvColName

=back

=item

$fSqlType

=over 4

=item

[o]  The type of data contained in column $ivCol.

=back

=item

$ivPrecision 

=over 4

=item

[o]  The precision of column $ivCol.

=back

=item

$ivScale

=over 4

=item

[o]  The scale of column $ivCol.

=back

=item

$fNullable

=over 4

=item

[o]  Returns whether column $ivCol allows null values.

=back

=back




=item *

SQLColAttributes

=over 4

=item Syntax

C<SQLColAttributes($hStmt, $ivCol, $fType, $pvAttrib, $ivAttribMax, $ivAttribSize, $ivAttrib);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item

$ivCol

=over 4

=item

[i]  The function will return a attributes from column $ivCol.

=back

=item

$fType

=over 4

=item

[i]  The type of attribute to return. 

=back

=item

$pvAttrib

=over 4

=item

[o]  The attribute.   This will be returned from the function as a string.

=back

=item

$ivAttribMax

=over 4

=item

[i]  The maximum size of $pvAttrib

=back

=item

$ivAttribSize 

=over 4

=item

[o]  The size of the attribute string available to return to $pvAttrib.

=back

=item

$ivAttrib

=over 4

=item

[o]  The attribute.  This will be returned as an integer.

=back

=back




=item *

SQLBindCol

=over 4

=item Syntax

C<SQLBindCol($hStmt, $ivCol, $fType, $svValue, $ivValueMax, $ivValueSize);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item

$ivCol

=over 4

=item

[i]  The function will bind this column.

=back

=item

$fType

=over 4

=item

[i]  The data type to bind.

=back

=item

$svValue

=over 4

=item

[i]  A reference to a scalar that will store the data from a result set.

=back

=item

$ivValueMax

=over 4

=item

[i]  The maximum size allowed for the scalar referenced by $svValue

=back

=item

$ivValueSize

=over 4

=item

[i]  Size available to return to the scalar referenced by $svValue before C<SQLFetch()> is called.

=back

=back



=item *

SQLFetch

=over 4

=item Syntax

C<SQLFetch($hStmt);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item Notes

C<SQLFetch()> returns data from each bound column to the scalar that was referenced by the $svValue parameter when the C<SQLBindCol()> function was called.

=back





=item *

SQLError

=over 4

=item Syntax

C<SQLError($hfEnv, $hfDbc, $hfStmt, $pvSqlState, $fNativeError, $pvErrorMsg, $ivErrorMsgMax, $ivErrorMsgSize);>

=item Parameters

=item

$hfEnv 

=over 4

=item

[i]  The environment handle as it is returned from C<SQLAllocEnv()> or SQL_NULL_HENV.

=back

=item

$hfDbc

=over 4

=item

[i]  The connection handle as it is returned from C<SQLAllocConnect()> or SQL_NULL_HDBC.

=back

=item

$hfStmt

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()> or SQL_NULL_HSTMT.

=back

=item

$pvSqlState

=over 4

=item

[o]  This returns the SQLSTATE as a string.

=back

=item

$fNativeError

=over 4

=item

[o]  This returns a Native Error Code.

=back

=item

$pvErrorMsg

=over 4

=item

[o]  This returns an Error Message as a string.

=back

=item

$ivErrorMsgMax

=over 4

=item

[i]  The maximum size of $pvErrorMsg 

=back

=item

$ivErrorMsgSize

=over 4

=item

[o]  The size of the string available to return to $pvErrorMsg 

=back

=back




=item *

SQLFreeStmt

=over 4

=item Syntax

C<SQLFreeStmt($hStmt, $fOption);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=item

$fOption

=over 4

=item

[i]  The action to be taken by the function.

=back

=back





=item *

SQLCancel

=over 4

=item Syntax

C<SQLCancel($hStmt);>

=item Parameters

=item

$hStmt 

=over 4

=item

[i]  The statement handle as it is returned from C<SQLAllocStmt()>.

=back

=back





=item *

SQLTransact

=over 4

=item Syntax

C<SQLTransact($hEnv, $hDbc, $fType);>

=item Parameters

=item

$hEnv 

=over 4

=item

[i]  The environment handle as it is returned from C<SQLAllocEnv()>.

=back

=item

$hDbc

=over 4

=item

[i]  The connection handle as it is returned from C<SQLAllocConnect>.

=back

=item

$fType

=over 4

=item

[i]  The type of transaction to take

=back

=back





=item *

SQLDisconnect

=over 4

=item Syntax

C<SQLDisconnect($hDbc);>

=item Parameters

=item

$hDbc 

=over 4

=item

[i]  The connection handle as it is returned from C<SQLAllocConnect()>.

=back

=back





=item *

SQLFreeConnect

=over 4

=item Syntax

C<SQLFreeConnect($hDbc);>

=item Parameters

=item

$hDbc 

=over 4

=item

[i]  The connection handle as it is returned from C<SQLAllocConnect()>.

=back

=back



=item *

SQLFreeEnv

=over 4

=item Syntax

C<SQLFreeEnv($hEnv);>

=item Parameters

=item

$hEnv 

=over 4

=item

[i]  The connection handle as it is returned from C<SQLAllocEnv()>.

=back

=back

=back

=head1 EXAMPLES

C<use iodbc;>

#

#To start I allocate handles and connect to my favorite data source.  Notice I check every return code.

C<checkretcode(&SQLAllocEnv($henv));>

C<checkretcode(SQLAllocConnect($henv, $hdbc));>

C<checkretcode(SQLConnect($hdbc, "favorite_datsource", SQL_NTS, "user", SQL_NTS, "password", SQL_NTS));>

C<checkretcode(SQLAllocStmt($hdbc,$hstmt));>

#

#Then I execute a simple SQL statement

C<checkretcode(SQLExecDirect($hstmt, "SELECT * FROM sample_table", SQL_NTS));>

#Bind column one to $rgbValue

C<checkretcode(SQLBindCol($hstmt, 1, SQL_C_DEFAULT, \$rgbValue, 24, SQL_NULL_DATA));>

#Fetch all the rows and print them out

C<while(checkretcode(SQLFetch($hstmt))==SQL_SUCCESS){>

C<    print "$rgbValue\n";>

C<}>

#

#Finally close up shop by freeing statements and disconnecting.

C<checkretcode(SQLFreeStmt($hstmt, SQL_DROP));>

C<checkretcode(SQLDisconnect($hdbc));>

C<checkretcode(SQLFreeConnect($hdbc));>

C<checkretcode(SQLFreeEnv($henv));>

#

#This subroutine checks the return code to make sure that the function executed correctly

C<sub checkretcode {>

C<    my $retcode = shift;>

C<>

C<    if (($retcode==SQL_SUCCESS)||($retcode==SQL_NO_DATA_FOUND)) {>

C<	return $retcode;>

C<    } else {>

C<	die "some error";>

C<    }>

C<}>



=head1 TO DO

=over 4

=item *

Further testing.  In particular add C<SQLCancel()> and C<SQLTransact()> to the test scripts.

=item *

Add ODBC 1.0 and then ODBC 2.0 support.

=item *

Put an DBD/DBI face on top of iODBC.

=item *

Improvement of the documentation.

=back

=head1 BUGS

Let me know if you find any.

=head1 AUTHOR

J. Michael Mahan, mahanm@nextwork.rose-hulman.edu

=head1 SEE ALSO

perl(1).

=cut
#  LocalWords:  foreach SQLGetCursorName pvCursor ivCursorMax
