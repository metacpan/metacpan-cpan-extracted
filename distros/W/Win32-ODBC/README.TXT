

        +==========================================================+
        |                                                          |
        |              ODBC extension for Win32 Perl               |
        |                                                          |
        |                     ODBC.PM package                      |
        |                                                          |
        |              -----------------------------               |
        |                                                          |
        |              by Dave Roth <rothd@roth.net>               |
        |                                                          |
        |                                                          |
        |  Copyright (c) 1996-1997 Dave Roth. All rights reserved. |
        |   This program is free software; you can redistribute    |
        | it and/or modify it under the same terms as Perl itself. |
        |                                                          |
        +==========================================================+


          based on original code by Dan DeMaggio <dmag@umich.edu>

 Use under GNU General Public License or Larry Wall's "Artistic License"


    ---------------------------------------------------------------------
        CHECK OUT THE FAQ!!! HTTP://WWW.ROTH.NET/ODBC/ODBCFAQ.HTM
    ---------------------------------------------------------------------

 This is a hack of Dan DeMaggio's <dmag@umich.edu> NTXS.C ODBC implimentation.
 I have recoded and restructered most of it including most of the ODBC.PM
 package but its very core is still based on Dan's code (thanks Dan!).


 The history of this extension is found in the HISTORY.TXT file that comes
 with the archive.


Following in tradition...
*****************************************************************************
*                                                                           *
*  Use under GNU General Public License or Larry Wall's "Artistic License"  *
*                                                                           *
*****************************************************************************

        ----------------------------------------------------------------
NOTICE: I do not guarantee ANYTHING with this package. If you use it you
        are doing so AT YOUR OWN RISK! I may or may not support this
        depending on my time schedule and I am neither an ODBC nor SQL
        guru so don't ask me questions regarding them!

        This extension assumes that you are familiar with ODBC or have
        access to documentation on the ODBC API 2.0 or higher.
        ----------------------------------------------------------------


COMPILE NOTES:
    I compiled this using MSVC++ 2.2 on an Intel Pentium machine. I do not have
    access to other platforms to compile on so I will not be doing so. If
    someone else does I will gladly post them at FTP.ROTH.NET.


BENEFITS
    What is the deal with this?
    - The number of ODBC connections are limited by memory and ODBC itself
      (have as many as you want!)
    - The working limit to the size of a field is 10240 bytes but you can
      increase that limit (if needed) to a max of 2147483647. You can always
      recompile to increase the max limit.
    - You can open a connection by either specifing a DSN or a connection
      string!
    - You can open and close the connections in any order!
    - Other things that I can not think of right now.... :)

KNOWN PROBLEMS:
    What known problems does this thing have?
    - If the account that the process runs under does not have write permission
      on the default directory (for the process not the ODBC DSN) you will
      probably get a run time error durring an SQLConnection(). I don't think
      that this is a problem with the code, more like ODBC.
      This happens because some ODBC drivers need to write a temporary
      file. I noticed this using the MS Jet Engine (Access Driver).

    - This has been neither optimized for speed nor optimized for memory
      consumption.

TESTING:
  To test out this extension, install it then run the TEST.PL included with
  this archive...
  - This version of Win32::ODBC comes with a little database of trivial, non
    sensible data in MS Access 7.0 format. If you have the proper driver 
	installed, the test.pl will create a temporary DSN that points to this
	database and performs its tests on it. The temporary DSN is removed at the
	end of the test cycle.
  - If you want to run the test.pl against another DSN that you already have
    created
    then run the test.pl but specify your DSN (see syntax below).
  - You can limit the number of records that are retrieved during the test
    (assuming that the ODBC driver you use conforms to proper ODBC API
    standards). Specify after your DSN name the number of records to display.
    The default number of records is 15.

	Syntax:
        perl test.pl [[DSN Name] #OfRecords]

             DSN Name.......The DSN name of your choice (must have been pre
                            configured)
             #OfRecords.....If you specify a DSN you can also specify how
                            many records to display.


INSTALLATION:
  +--------------------------------------------------------------------------+
  | I use a directory structure of \Perl\lib for my library files and this   |
  | doc is assuming you do too. You will, of course, have to compensate for  |
  | deviations.                                                              |
  +--------------------------------------------------------------------------+

   T O   I N S T A L L   T H I S   B E A S T :
   =========================================

1) You will need to dump the ODBC.PM file into the \PERL\LIB\WIN32\ directory.

2) There has been a change since version v960721: I am no longer supporting
   versions for the Win32 Perl build 105 (and lower). If you still use such
   a young build of Perl, consider updating it or recompile Win32::ODBC on your
   own.
   The next step depends upon which version of Win32 Perl you are using. To
   determine which build you have enter the following command line:
        perl -v


   IF YOU ARE USING PERL BUILDS 106-110 (Perl 5.001m):
           Copy lib\auto\win32\odbc\odbc.pll to
           your perl directory\lib\auto\win32\odbc\odbc.pll

   IF YOU ARE USING PERL BUILDS 303 OR HIGHER (Perl 5.003):
           Copy BETA\lib\auto\win32\odbc\odbc.pll to
           your perl directory\lib\auto\win32\odbc\odbc.pll


   ---------------------------------------------------------

To use this Win32::ODBC you need to define a DSN (Data Source Name) and have
all the stuff you need to use it (ie. proper ODBC drivers, database file, etc).

You are now ready to ODBC all over town!



USE:
    T O   U S E   T H I S   B E A S T :
    =================================

Your script will need to have the following line:

    use Win32::ODBC;

Then you need to create a data connection to your DSN...

    $Data = new Win32::ODBC("MyDSN");

NOTE: "MyDSN" should be either the DSN as defined in the ODBC Administrator

      -OR-

      It can be an honest-to-God DSN Connect string
                example: "DSN=My Database;UID=Brown Cow;PWD=Moo;"


You should check to see if $Data is indeed defined otherwise there has been an
error.

You can now send SQL queries and retrieve info to your heart's content!
See the description of functions below and also the test.pl to see how it
all works.

MAKE SURE that you close you connection when you are finished:
    $Data->Close();


 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  You can refer to the contstants by using ODBC::xxxxx where xxxxx is
  the constant. For example...
     print ODBC::SQL_SQL_COLUMN_NAME
 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




    L I S T   O F   F U N C T I O N S :
    =================================

The ODBC.PM Package supports the following functions:
	(* indicates a new or modified function for this version)

 Catalog($Qualifier, $Owner, $Name, $Type)
    Tells ODBC to create a data set that contains table information about
    the DSN.
	Use Fetch() and Data() or DataHash() to retrieve the data.
    The returned format is:
            [Qualifier] [Owner] [Name] [Type]
    returns: TRUE if error.

 ColAttributes($Attribute, [@FieldNames])
	Returns the attribute $Attribute on each of the fields @FieldNames in
	the current record set.
	If @FieldNames is empty then all fields are assumed.
	returns: associative array of attributes.

*ConfigDSN($Option, $Driver, ($Attribute1 [, $Attribute2, $Attribute3, ...]))
	Configures a DSN. You can specify 3 different options:
		ODBC_ADD_DSN.......Adds a new DSN.
		ODBC_MODIFY_DSN....Modifies an existing DSN.
		ODBC_REMOVE_DSN....Removes an existing DSN.
    You must specify the $Driver (which can be retrieved by using
    DataSources() or Drivers()).
    $Attribute1 *should* be "DSN=xxx" where xxx is the name of the DSN. Other
    attributes can be any DSN attribute such as:
		"UID=Cow"
		"PWD=Moo"
		"Description=My little bitty Data Source Name"

    -If you use ODBC_ADD_DSN, then you must include at least the "DSN=xxx" and
     the location of the database (ie. for MS Access databases you must specify
     the DatabaseQualifier: "DBQ=c:\\...\\MyDatabase.mdb").
    -If you use ODBC_MODIFY_DSN, then you need only to specify the the
     "DNS=xxx" attribute. Any other attribute you include will be changed to
     what you specify.
    -If you use ODBC_REMOVE_DSN, you only need to specify the "DSN=xxx"
     attribute.
	returns: TRUE.....successful
	         FALSE....failure

 Connection()
    Returns the connection number associated with the ODBC connection.
    returns: Number identifying an ODBC connection

 Close()
    Closes the ODBC connection.
    returns: Nothing.

 Data([$FieldName])
    Returns the contents of column name $FieldName or the current row (if
    nothing is specified).
    returns: String.

 DataHash([$Field1, $Field2, $Field3, ...])
    Returns the contents for $Field1, $Field2, ... or the entire row (if
    nothing is specified) into an associative array consisting of:
    {Field Name}=>Field Data
	returns: Associative array with keys = Field Names and values = Field Data.

*DataSources()
    Returns an associative array of Data Sources and ODBC remarks about them.
    They are returned in the form of:
        $ArrayName{'DSN'}=Driver
    Where DSN is the Data Source Name and ODBC Driver used.
    returns: Associative array.

*Debug([1|0])
    Sets the debug option to on or off. If nothing is specified then
    nothing is changed.
	returns: The debugging value (1 or 0)
	 
 Drivers()
    Returns an associative array of ODBC Drivers and thier attributes.
    They are returned in the form of:
        $ArrayName{'DRIVER'}=Attrib1;Attrib2;Attrib3;...
    Where DRIVER is the ODBC Driver Name and AttribX are the driver defined
    attributes.
    returns: Associative array.

*DropCursor([$CloseType])
    Drops the cursor associated with the ODBC object. This forces the
    cursor to be deallocated.
    This overrides SetStmtCloseType() but the ODBC object does not lose
    the StmtCloseType setting.
    $CloseType can be any valid SmtpCloseType and will perform a close on
    the stmt using the specified close type.
    returns....TRUE if successful.
               FALSE if not successful.

 DumpData()
    Dumps to the screen the fieldnames and all records of the current data
    set. This is used primarily for debugging.
    returns: Nothing

*Error()
    Returns the last encountered error. The returned value is context dependent. If
	it is called in a scalar context a 3 element array is returned:
		($ErrorNumber, $ErrorText, $ConnectionNumber)
	if called in a string context a string is returned:
		"[$ErrorNumber] [$ConnectionNumber] [$ErrorText]"
	If debugging is on then two more variables are returned:
		(..., $Function, $Level)
			$Function = $Function name the error occured in.
			$Level = Extra information about the error (usually the location of the error)
    returns: Array or String.

*FetchRow([$Row [, $Type]])
    Retrieves the next record from the keyset.
    When $Row and/or $Type are specified the call is made using
    SQLExtendedFetch() instead of SQLFetch().

    NOTE: If you are unaware of SQLExtendedFetch() and it's implications
          stay with just regular FetchRow() with no parameters.
    NOTE: The ODBC API explicitly warns against mixing calls to SQLFetch()
          and SQLExtendedFetch(); use one or the other but not both.

    If $Row is specified it moves the keyset RELATIVE $Row number of rows.
    If $Row is specified and $Type is not then the type used is RELATIVE.
    returns: TRUE...There is a record to read.
	         FALSE..There are no more records to read.

 FieldNames()
    Returns an array of fieldnames found in the current data set. There is
    no guarantee on order.
    returns: Array of field names.

 GetConnections()
    Returns an array of connection numbers showing what connections are
    currently open.
    returns: Array of connections

*GetConnectOption($Option)
    Returns the value of the specified connect $Option. Refer to ODBC
    documentation for more information on the options and values.
	returns: String or Scalar depending upon the option specified.

*GetCursorName()
    Returns the name of the current cursor.
    returns: String or undef.

*GetData()
    Retrieves the current row from the dataset. This is not generally
    used by users, it is used internally.
    returns: Array of field data where the first element is either:
            ...TRUE....NOT successful.
            ...FALSE...successful

*GetDSN([$DSN])
    Returns the configuration for the specified DSN.
    If no DSN is specified then the current connection is used.
    The returning associative array consists of
    keys=DSN keyword; values=Keyword value.
        $Data{$Keyword}=Value
    returns: Associative array.

*GetFunctions([$Function1, $Function2, ...])
    Returns an associateive array of indicating the ODBC Drivers ability to
    support specified functions.
    If no functions are specifed then a 100 element associative array is
    returned containing all possible functions and their values.
	$Function must be in the form of an ODBC API constant like:
		SQL_API_SQLTRANSACT
	The returned array will contain the results like:
		$Results{SQL_API_SQLTRANSACT}=Value
	Example:
        $Results = $O->GetFunctions($O->SQL_API_SQLTRANSACT, SQL_API_SQLSETCONNECTOPTION)
		$ConnectOption = $Results{SQL_API_SQLSETCONNECTOPTION};
		$Transact = $Results{SQL_API_SQLTRANSACT};
	returns: Sssociative array.

*GetInfo($Option)
	Returns the value of the particular option specified.
	returns: Scalar or String.

 GetMaxBufSize()
    This will report the current allocated limit for the MaxBufSize. For info
    see SetMaxBufSize().
    returns: Max number of bytes.

 GetStmtCloseType([$Connection])
    Returns the type of closure that will be used everytime the hstmt is freed.
    See SetStmtClsoeType() for details.
    By default, the currect object's connection will be used. If $Connection
    is a valid connection number, then it will be used.
    returns: String.

*GetStmtOption($Option)
    Returns the value of the specified statement $Option. Refer to ODBC
    documentation for more information on the options and values.
	returns: String or Scalar depending upon the option specified.

 MoreResults()
	This will report whether or not there is data yet to be retrieved from the
	query. This can happen if the query was a multiple select 
		(eg: "SELECT * FROM [foo] SELECT * FROM [bar]")
   *** NOTE: Not all drivers support this.
	returns: 1 if there is more data
	         undef if there is no more data

*new($ODBC_Object | $DSN [, ($Option1, $Value1), ($Option2, $Value2) ...])
    Creates a new ODBC connection based on $DSN or if you specify an already
    existing ODBC object then a new ODBC object will be created but using
    the ODBC Connection specified by $ODBC_Object (the new object will be
    a new hstmt using the hdbc connection in $ODBC_Object).

    $DSN = Data Source Name or a proper ODBCDriverConnect string.
	You can specify SQL Connect Options that are implimented before the actual
    connection to the DSN takes place. These option/values are the same
    specified in Get/SetConnectOption() (see below) and are defined in the ODBC
    API specs.
    returns: Undef if it failed.

 RowCount($Connection)
    For UPDATE, INSERT, and DELETE statements the returned value is the number
    of rows affected by the request or -1 if the number of affected rows is
    not available.
    *** NOTE: This function is not supported by all ODBC drivers! Some
              drivers do support this but not for all statements (eg. it
              is supported for UPDATE, INSERT and DELETE commands but
              not for the SELECT command).
    *** NOTE: Many data sources cannot return the number of rows in a result
              set before fetching them; for maximum interoperability,
              applications should not rely on this behavior.
    returns: Number of affected rows or -1 if not supported by driver in the
             current context.

 Run($Sql)
    This will execute the $Sql command and dump to the screen info about it.
    This is used primarily for debugging.
    returns: Nothing

*SetConnectOption($Option)
    Sets the value of the specified connect $Option. Refer to ODBC
    documentation for more information on the options and values.
	returns: TRUE....change was successful
	         FALSE...change was not successful

*SetCursorName($Name)
    Sets the name of the current cursor.
    returns: TRUE....successful
             FALSE...not successful

*SetPos($Row [, $Option, $Lock])
    Moves the cursor to the row $Row within the current keyset (not the current
    data/result set).
    returns: TRUE....successful
             FALSE...not successful

 SetMaxBufSize($Size)
    This will set the MaxBufSize for a particular connection.
    This will most likely never be needed but...
    The amount of memory that is allocated to retrieve a records field data
    is dynamic and changes when it need to be larger. I found that a memo
    field in an MS Access database ended up requesting 4 Gig of space. This was
    a bit much so there is an imposed limit (2,147,483,647 bytes) that can be 
    allocated for data retrieval. Since it is possible that someone has a 
    database with field data greater than 10240 you can use this function to 
    increase the limit up to a ceiling of 2,147,483,647 (recompile if you need
    more).
    returns: Max number of bytes.

 SetStmtCloseType($Type [, $Connection])
    This will set a particular hstmt close type for the connection. This is
    the same as ODBCFreeStmt(hstmt, $Type).
    By default, the currect object's connection will be used. If $Connection
    is a valid connection number, then it will be used.
    Types:
        SQL_CLOSE
        SQL_DROP
        SQL_UNBIND
        SQL_RESET_PARAMS
    Returns the newly set type.
    returns: String.

*SetStmtOption($Option)
    Sets the value of the specified statement $Option. Refer to ODBC
    documentation for more information on the options and values.
	returns: TRUE.....change was successful.
	         FALSE....change was not successful.

 ShutDown()
    This will close the ODBC connection and dump to the screen info about it.
    This is used primarily for debugging.
    returns: Nothing

 Sql($SQLString)
    Executes the SQL command $SQLString on a particular connection.
    returns: Error number if it failed

 TableList($Qualifier, $Owner, $Name, $Type)
    Returns the catalog of tables that are availabe in the DSN.
    If you do not know what the parameters are just leave them "".
    returns: Array of table names.

*Transact($Type)
	Forces the ODBC connection to perform a Rollback or Commit transaction.
	$Type may be:
		SQL_COMMIT
		SQL_ROLLBACK
	*** NOTE: This only works with ODBC Drivers that support transactions.
	          Your Driver supports it if TRUE is returned from:
			       $O->GetFunctions($O->SQL_API_SQLTRANSACT)[1]
				   (see GetFunctions for more details)
	returns: TRUE....success.
	         FALSE...failure.

 Version(@Packages)
	Returns the version numbers for the requested packages ("ODBC.PM" or
	"ODBC.PLL"). If @Packages is empty then all version numbers will be
	returned.
	returns: Array of version numbers.


======================================
	See the test.pl file for an example of Win32::ODBC's usage.

Last Modified 96.10.16
