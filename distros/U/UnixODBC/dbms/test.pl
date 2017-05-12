# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### 

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..140\n"}
END {print "not ok 1\n" unless $loaded;}
use UnixODBC ':all';
$loaded = 1;
print "ok 1\n";

######################### 

use Devel::Peek;

my $evh; # Environment handle
my $cnh;  # Connection handle
my $sth; # Statement handle
my $r; # SQL result
my $programname = 'test.pl';

# Connect parameters
my $DSN="Gutenberg Catalog";
#
#  Change to the DBMS user name and password.  For PostgreSQL after
#  installation, "postgres," should work.  For MySQL, "root" should
#  work after installation, or start 
#  mysqld_safe with --skip-grant-tables.
#
my $UserName="postgres";
my $PassWord="";

#
#  Uncomment this line if you are using the unixODBC 
#  postgresql driver.
#
# $SIG{PIPE} = sub { print "SIGPIPE: $!\n" };

# Variables for SQLGetDataSources
my ($dsnname,$drivername,$messagelength1, $messagelength2);

# Buffer and Get and Fetch results
my $rbuf;

# Variables for SQLGetInfo;
my $ibuf; # Buffer for returned info.
my $mlen; # length of returned information.

# Row and column results
my ($ncols, $nrows);

# Variables for extended fetch.
my $status; 
my $pcrow = 1;

# Column attributes
my ($char_attribute,$num_attribute);

# SQL query
my $query = "select \* from titles where etext_no \= \'893\'\;";

# Describe column buffers
my ($column_name, $name_length, $data_type, $column_size);
my ($decimal_digits, $nullable);

my $datafence = '-' x 20;

# Queries for test table

$SIG{PIPE} = sub{print "SIGPIPE: ". $!."\n"};

print "======================================================\n";
print "Handle Allocation, Data Sources, and ODBC Version.\n";
print "======================================================\n";

print "Allocate environment handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 2 \n";
} else {
    print "not ok 2\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set environment attribute... "; 
$r = &UnixODBC::SQLSetEnvAttr ($evh, $SQL_ATTR_ODBC_VERSION,
			       $SQL_OV_ODBC2, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 3 \n";
} else {
    print "not ok 3\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Get environment attribute... ";
$r = &UnixODBC::SQLGetEnvAttr ($evh, $SQL_ATTR_ODBC_VERSION,
			       $rbuf, 255, $mlen);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 4 \n";
} else {
    print "not ok 4\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Get driver descriptions... ";
my ($driver_desc,$pcb_driver_desc,$driver_attributes,
    $pcb_attr_max);
$r = &UnixODBC::SQLDrivers ($evh, $SQL_FETCH_FIRST, $driver_desc, 255,
				    $pcb_driver_desc, $driver_attributes,
				    255, $pcb_attr_max);
if ($r==$SQL_SUCCESS) {
    while (1) {
	$r = &UnixODBC::SQLDrivers ($evh, $SQL_FETCH_NEXT,
				     $driver_desc, 255, $pcb_driver_desc,
				     $driver_attributes, 255,
				     $pcb_attr_max);
	last if $r = $SQL_NO_DATA;
    }
}
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 5 \n";
} else {
    print "not ok 5\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Allocate connection handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_DBC, $evh, $cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 6 \n";
} else {
    print "not ok 6\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Get ODBC version... ";
$r = &UnixODBC::SQLGetInfo ($cnh, $SQL_ODBC_VER, $ibuf, 255, $mlen);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 7 \n";
} else {
    print "not ok 7\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get Data Sources... ";
$r = &UnixODBC::SQLDataSources ( $evh, $SQL_FETCH_FIRST, $dsnname, 255, 
				 $messagelength1, $drivername, 255, 
				 $messagelength2 );
while (1) {
    $r = &UnixODBC::SQLDataSources ( $evh, $SQL_FETCH_NEXT, $dsnname, 255,
				     $messagelength1, $drivername, 255,
				     $messagelength2 );
    last if $r == $SQL_NO_DATA;
}
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 8 \n";
} else {
    print "not ok 8\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Free connection handle... ";
$r = &UnixODBC::SQLFreeConnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 9 \n";
} else {
    print "not ok 9\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free environment handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_ENV, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 10 \n";
} else {
    print "not ok 10\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

##
## Connection to DSN
##

print "======================================================\n";
print "Connect to DSN\n";
print "======================================================\n";

print "Allocate environment handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 11 \n";
} else {
    print "not ok 11\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set environment attribute... "; 
$r = &UnixODBC::SQLSetEnvAttr ($evh, $SQL_ATTR_ODBC_VERSION,
			       $SQL_OV_ODBC2, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 12 \n";
} else {
    print "not ok 12\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Allocate connection handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_DBC, $evh, $cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 13 \n";
} else {
    print "not ok 13\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set connection timeout... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_LOGIN_TIMEOUT, 5, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 14 \n";
} else {
    print "not ok 14\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Set connection read-write mode... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_ACCESS_MODE,
				   $SQL_MODE_READ_WRITE, TRUE);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 15 \n";
} else {
    print "not ok 15\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Connect... ";
$r = &UnixODBC::SQLConnect ($cnh, $DSN, $SQL_NTS, $UserName, $SQL_NTS, 
			    $PassWord, $SQL_NTS);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 16 \n";
} else {
    print "not ok 16\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Check for API functions in driver... ";
my $s; #supported
$r = &UnixODBC::SQLGetFunctions ($cnh, $SQL_API_SQLALLOCHANDLESTD, $s);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 17 \n";
} else {
    print "not ok 17\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get diagnostics record... \n";
$r = &getdiagrec ($SQL_HANDLE_DBC, $cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 18 \n";
} else {
    print "not ok 18\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get DBMS name info... ";
$ibuf = '';
$r = &UnixODBC::SQLGetInfo ($cnh, $SQL_DBMS_NAME, $ibuf, 255, $mlen);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 19 \n";
} else {
    print "not ok 19\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Disconnect... ";
$r = &UnixODBC::SQLDisconnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 20 \n";
} else {
    print "not ok 20\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free connection handle... ";
$r = &UnixODBC::SQLFreeConnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 21 \n";
} else {
    print "not ok 21\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free environment handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_ENV, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 22 \n";
} else {
    print "not ok 22\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

##
## SQL Query and Fetch
##

print "======================================================\n";
print "SQL Query and Data Fetch.\n";
print "======================================================\n";
print "Allocate environment handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 23 \n";
} else {
    print "not ok 23\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set environment attribute... "; 
$r = &UnixODBC::SQLSetEnvAttr($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 24 \n";
} else {
    print "not ok 24\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Allocate connection handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_DBC, $evh, $cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 25 \n";
} else {
    print "not ok 25\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set connection timeout... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_LOGIN_TIMEOUT, 5, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 26 \n";
} else {
    print "not ok 26\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Set connection read-write mode... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_ACCESS_MODE,
				   $SQL_MODE_READ_WRITE, TRUE);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 27 \n";
} else {
    print "not ok 27\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Connect... ";
$r = &UnixODBC::SQLConnect ($cnh, $DSN, $SQL_NTS,
			    $UserName, $SQL_NTS,
			    $PassWord, $SQL_NTS);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 28 \n";
} else {
    print "not ok 28\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 29 \n";
} else {
    print "not ok 29\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get table names...";
$r = &UnixODBC::SQLTables ($sth, '', 0, '', 0, '', 0, '', 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 30 \n";
} else {
    print "not ok 30\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Get number of columns in result ... ";
$r = &UnixODBC::SQLNumResultCols ($sth,$ncols);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 31 \n";
} else {
    print "not ok 31\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Get number of rows in result ... ";
$r = &UnixODBC::SQLRowCount ($sth,$nrows);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 32 \n";
} else {
    print "not ok 32\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Fetch data rows ...";
while (1) {
    $r = &UnixODBC::SQLFetch ($sth);
    last if $r == $SQL_NO_DATA;
    $r = &UnixODBC::SQLGetData ($sth, 3, $SQL_C_CHAR, $rbuf, 255, $mlen);
}
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 33 \n";
} else {
    print "not ok 33\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Get column name attributes... ";
$r = &UnixODBC::SQLColAttribute ($sth, 3, $SQL_COLUMN_NAME, $char_attribute, 
				 255, $mlen, $num_attribute);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 34 \n";
} else {
    print "not ok 34\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Get column type attributes... ";
$r = &UnixODBC::SQLColAttribute ($sth, 1, $SQL_COLUMN_TYPE, $char_attribute, 
				 255, $mlen, $num_attribute);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 35 \n";
} else {
    print "not ok 35\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 36 \n";
} else {
    print "not ok 36\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Disconnect... ";
$r = &UnixODBC::SQLDisconnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 37 \n";
} else {
    print "not ok 37\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free connection handle... ";
$r = &UnixODBC::SQLFreeConnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 38 \n";
} else {
    print "not ok 38\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free environment handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_ENV, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 39 \n";
} else {
    print "not ok 39\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

###
### Get info for data types
###
print "======================================================\n";
print "Data Types Info.\n";
print "======================================================\n";

print "Allocate environment handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 40 \n";
} else {
    print "not ok 40\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set environment attribute... "; 
$r = &UnixODBC::SQLSetEnvAttr ($evh, $SQL_ATTR_ODBC_VERSION,
			       $SQL_OV_ODBC2, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 41 \n";
} else {
    print "not ok 41\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Allocate connection handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_DBC,
				 $evh,
				 $cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 42 \n";
} else {
    print "not ok 42\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Connect... ";
$r = &UnixODBC::SQLConnect ($cnh, $DSN, $SQL_NTS,
			    $UserName, $SQL_NTS,
			    $PassWord, $SQL_NTS);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 43 \n";
} else {
    print "not ok 43\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 44 \n";
} else {
    print "not ok 44\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get info for data types... ";
$r = &UnixODBC::SQLGetTypeInfo ($sth, $SQL_ALL_TYPES);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 45 \n";
} else {
    print "not ok 45\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Fetch data rows ...";
while (1) {
    $r = &UnixODBC::SQLFetch ($sth);
    last if $r == $SQL_NO_DATA;
    foreach my $cn (1..4) {
	$r=&UnixODBC::SQLGetData ($sth, $cn, $SQL_C_CHAR, $rbuf, 255, $mlen);
    }
}
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 46 \n";
} else {
    print "not ok 46\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeStmt ($sth,$SQL_DROP);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 47 \n";
} else {
    print "not ok 47\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Disconnect... ";
$r = &UnixODBC::SQLDisconnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 48 \n";
} else {
    print "not ok 48\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free connection handle... ";
$r = &UnixODBC::SQLFreeConnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 49 \n";
} else {
    print "not ok 49\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free environment handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_ENV, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 50 \n";
} else {
    print "not ok 50\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

##
## Execute and fetch with prepared SQL query.
##

print "======================================================\n";
print "Prepared Query and Data Fetch\n";
print "======================================================\n";
print "Allocate environment handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 51 \n";
} else {
    print "not ok 51\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set environment attribute... "; 
$r = &UnixODBC::SQLSetEnvAttr($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 52 \n";
} else {
    print "not ok 52\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Allocate connection handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_DBC, $evh, $cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 53 \n";
} else {
    print "not ok 53\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set connection timeout... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_LOGIN_TIMEOUT, 5, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 54 \n";
} else {
    print "not ok 54\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Set connection read-write mode... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_ACCESS_MODE,
				   $SQL_MODE_READ_WRITE, TRUE);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 55 \n";
} else {
    print "not ok 55\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Connect... ";
$r = &UnixODBC::SQLConnect ($cnh, $DSN, $SQL_NTS,
			    $UserName, $SQL_NTS,
			    $PassWord, $SQL_NTS);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 56 \n";
} else {
    print "not ok 56\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 57 \n";
} else {
    print "not ok 57\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Set cursor name... ";
my $cname = 'test';
$r = &UnixODBC::SQLSetCursorName ($sth, $cname, length ($cname));
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 58 \n";
} else {
    print "not ok 58\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Get cursor name... ";
$r = &UnixODBC::SQLGetCursorName ($sth, $rbuf, 255, $mlen);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 59 \n";
} else {
    print "not ok 59\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Prepare query... ";
$r = &UnixODBC::SQLPrepare ($sth, $query, length ($query));
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 60 \n";
} else {
    print "not ok 60\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Execute... ";
$r = &UnixODBC::SQLExecute ($sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 61 \n";
} else {
    print "not ok 61\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

my ($id_no, $etext_no, $collection, $author, $title);

print "Fetch data rows ...";
while (1) {
    $r = &UnixODBC::SQLFetch ($sth);
    last if $r == $SQL_NO_DATA;
    $r = &UnixODBC::SQLGetData ($sth, 1, $SQL_C_CHAR, $id_no, 255, $mlen);
    $r = &UnixODBC::SQLGetData ($sth, 2, $SQL_C_CHAR, $etext_no, 255, $mlen);
    $r = &UnixODBC::SQLGetData ($sth, 3, $SQL_C_CHAR, $collection, 255, $mlen);
    $r = &UnixODBC::SQLGetData ($sth, 4, $SQL_C_CHAR, $author, 255, $mlen);
    $r = &UnixODBC::SQLGetData ($sth, 5, $SQL_C_CHAR, $title, 255, $mlen);
}
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 62 \n";
} else {
    print "not ok 62\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Describe columns... ";
print "\n$datafence\n";
$r = &UnixODBC::SQLDescribeCol ($sth, 1, $column_name, 255, $name_length, 
				$data_type, $column_size, $decimal_digits, 
				$nullable);
print "$column_name, $name_length, $data_type, $column_size";
print "$decimal_digits, $nullable\n";
$r = &UnixODBC::SQLDescribeCol ($sth, 2, $column_name, 255, $name_length, 
				$data_type, $column_size, $decimal_digits, 
				$nullable);
print "$column_name, $name_length, $data_type, $column_size";
print "$decimal_digits, $nullable\n";
$r = &UnixODBC::SQLDescribeCol ($sth, 3, $column_name, 255, $name_length, 
				$data_type, $column_size, $decimal_digits, 
				$nullable);
print "$column_name, $name_length, $data_type, $column_size";
print "$decimal_digits, $nullable\n";
$r = &UnixODBC::SQLDescribeCol ($sth, 4, $column_name, 255, $name_length, 
				$data_type, $column_size, $decimal_digits, 
				$nullable);
print "$column_name, $name_length, $data_type, $column_size";
print "$decimal_digits, $nullable\n";
$r = &UnixODBC::SQLDescribeCol ($sth, 5, $column_name, 255, $name_length, 
				$data_type, $column_size, $decimal_digits, 
				$nullable);
print "$column_name, $name_length, $data_type, $column_size";
print "$decimal_digits, $nullable\n";
print "$datafence\n";
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 63 \n";
} else {
    print "not ok 63\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 64 \n";
} else {
    print "not ok 64\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Disconnect... ";
$r = &UnixODBC::SQLDisconnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 65 \n";
} else {
    print "not ok 65\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free connection handle... ";
$r = &UnixODBC::SQLFreeConnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 66 \n";
} else {
    print "not ok 66\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free environment handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_ENV, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 67 \n";
} else {
    print "not ok 67\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

##
## Translate SQL statement
##

print "======================================================\n";
print "Translate SQL Statement\n";
print "======================================================\n";
print "Allocate environment handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_ENV,
				 $SQL_NULL_HANDLE, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 68 \n";
} else {
    print "not ok 68\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set environment attribute... "; 
$r = &UnixODBC::SQLSetEnvAttr ($evh, $SQL_ATTR_ODBC_VERSION,
				       $SQL_OV_ODBC2, 0);      
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 69 \n";
} else {
    print "not ok 69\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Allocate connection handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_DBC, $evh, $cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 70 \n";
} else {
    print "not ok 70\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set connection timeout... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_LOGIN_TIMEOUT, 5, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 71\n";
} else {
    print "not ok 71\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Set connection read-write mode... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_ACCESS_MODE,
				   $SQL_MODE_READ_WRITE, TRUE);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 72\n";
} else {
    print "not ok 72\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Connect... ";
$r = &UnixODBC::SQLConnect ($cnh, $DSN, $SQL_NTS,
			    $UserName, $SQL_NTS,
			    $PassWord, $SQL_NTS);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 73\n";
} else {
    print "not ok 73\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Translate SQL statement... ";
$r = &UnixODBC::SQLNativeSql ($cnh, $query, length ($query), $rbuf, 
			      255, $mlen);
print "\n$datafence\n";
print "Statement: \"$rbuf\" Length: \"$mlen\"\n";
print "$datafence\n";
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 74\n";
} else {
    print "not ok 74\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Disconnect... ";
$r = &UnixODBC::SQLDisconnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 75\n";
} else {
    print "not ok 75\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free connection handle... ";
$r = &UnixODBC::SQLFreeConnect ($cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 76\n";
} else {
    print "not ok 76\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Free environment handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_ENV, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 77\n";
} else {
    print "not ok 77\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

##
## SQL Query and FetchScroll
##

print "======================================================\n";
print "SQL Query and FetchScroll\n";
print "======================================================\n";
print "Allocate environment handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 78\n";
} else {
    print "not ok 78\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set environment attribute... "; 
$r = &UnixODBC::SQLSetEnvAttr($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 79\n";
} else {
    print "not ok 79\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Allocate connection handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_DBC, $evh, $cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 80\n";
} else {
    print "not ok 80\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set connection timeout... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_LOGIN_TIMEOUT, 5, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 81\n";
} else {
    print "not ok 81\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Set connection read-write mode... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_ACCESS_MODE,
				   $SQL_MODE_READ_WRITE, TRUE);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 82\n";
} else {
    print "not ok 82\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Connect... ";
$r = &UnixODBC::SQLConnect ($cnh, $DSN, $SQL_NTS, $UserName, $SQL_NTS,
			    $PassWord, $SQL_NTS);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 83\n";
} else {
    print "not ok 83\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 84\n";
} else {
    print "not ok 84\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

# print "Set ODBC cursor... ";
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_ATTR_ODBC_CURSORS,
				   $SQL_CUR_USE_ODBC, TRUE);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 85\n";
} else {
    print "not ok 85\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "SQLExecDirect query: " . $query . " ... ";
$r = &UnixODBC::SQLExecDirect ($sth, $query, length($query));
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 86\n";
} else {
    print "not ok 86\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Get number of columns in result ... ";
$r = &UnixODBC::SQLNumResultCols ($sth,$ncols);
print "\n$ncols\n";
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 87\n";
} else {
    print "not ok 87\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Get number of rows in result ... ";
$r = &UnixODBC::SQLRowCount ($sth,$nrows);
print "\n$nrows\n";
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 88\n";
} else {
    print "not ok 88\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Get diagnostics field... ";
$r = &UnixODBC::SQLGetDiagField ($SQL_HANDLE_DBC, $cnh, 1, 
				 $SQL_DIAG_RETURNCODE, $ibuf, 255, $mlen);
if (($r==$SQL_SUCCESS) || ($r==$SQL_NO_DATA)) {
    print "ok 89\n";
} else {
    print "not ok 89\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "SQLFetchScroll... ";
print "\n";
print "$datafence\n";
my $row = 1;
while (1) {
    $r = &UnixODBC::SQLFetchScroll ($sth, $SQL_FETCH_NEXT, $row++);
    last if $r == $SQL_NO_DATA;
    $r = &UnixODBC::SQLGetData ($sth, 1, $SQL_C_CHAR, $id_no, 255, $mlen);
    print "$id_no ";
    $r = &UnixODBC::SQLGetData ($sth, 2, $SQL_C_CHAR, $etext_no, 255, $mlen);
    print "$etext_no ";
    $r = &UnixODBC::SQLGetData ($sth, 3, $SQL_C_CHAR, $collection, 255, $mlen);
    print "$collection ";
    $r = &UnixODBC::SQLGetData ($sth, 4, $SQL_C_CHAR, $author, 255, $mlen);
    print "$author ";
    $r = &UnixODBC::SQLGetData ($sth, 5, $SQL_C_CHAR, $title, 255, $mlen);
    print "$title\n";
}
print "$datafence\n";

print "Set position... ";
$r = &UnixODBC::SQLSetPos ($sth, 1, $SQL_UPDATE, $SQL_LOCK_UNLOCK);
if ($r==$SQL_SUCCESS) {
    print "ok 91\n";
} else {
    print "not ok 91\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Check for more results... ";
$r = &UnixODBC::SQLMoreResults ($sth);
if (($r==$SQL_SUCCESS) || ($r==$SQL_NO_DATA)) {
    print "ok 92\n";
} else {
    print "not ok 92\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if ($r==$SQL_SUCCESS) {
    print "ok 93\n";
} else {
    print "not ok 93\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 94\n";
} else {
    print "not ok 94\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get column names...";
$r = &UnixODBC::SQLColumns ($sth, '', 0, '', 0, 
			    'titles', $SQL_NTS,
			    '', 0);
if ($r==$SQL_SUCCESS) {
    print "ok 95\n";
} else {
    print "not ok 95\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}
while (1) {
    $r = &UnixODBC::SQLFetch ($sth);
    last if $r == $SQL_NO_DATA;
    foreach my $cn (1..4) {
	$r=&UnixODBC::SQLGetData ($sth, $cn, $SQL_C_CHAR, $rbuf, 4096, $mlen);
	print "$rbuf ";
    }
    print "\n";
}
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 96 \n";
} else {
    print "not ok 96\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if ($r==$SQL_SUCCESS) {
    print "ok 97\n";
} else {
    print "not ok 97\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 98\n";
} else {
    print "not ok 98\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get primary keys... ";
$r = &UnixODBC::SQLPrimaryKeys ($sth, '', 0, '', 0, 'titles', $SQL_NTS);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 99 \n";
} else {
    print "not ok 99\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if ($r==$SQL_SUCCESS) {
    print "ok 100\n";
} else {
    print "not ok 100\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 101\n";
} else {
    print "not ok 101\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get foreign keys... ";
$r = &UnixODBC::SQLForeignKeys ($sth, '', 0, '', 0, '', 0, '', 0, '', 0, '', 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 102 \n";
} else {
    print "not ok 102\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if ($r==$SQL_SUCCESS) {
    print "ok 103\n";
} else {
    print "not ok 103\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 104\n";
} else {
    print "not ok 104\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get column privileges...";
$r = &UnixODBC::SQLColumnPrivileges ($sth, '', 0, '', 0, 'titles', $SQL_NTS,
				     'id_no', $SQL_NTS);
if ($r==$SQL_SUCCESS) {
    print "ok 105\n";
} else {
    print "not ok 105\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if ($r==$SQL_SUCCESS) {
    print "ok 106\n";
} else {
    print "not ok 106\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 107\n";
} else {
    print "not ok 107\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get procedure columns... ";
$r = &UnixODBC::SQLProcedureColumns ($sth, '', 0, '', 0, '', 0, '', 0);
if ($r==$SQL_SUCCESS) {
    print "ok 108\n";
} else {
    print "not ok 108\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if ($r==$SQL_SUCCESS) {
    print "ok 109\n";
} else {
    print "not ok 109\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 110\n";
} else {
    print "not ok 110\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get procedures... ";
$r = &UnixODBC::SQLProcedures ($sth, '', 0, '', 0, '', 0);
if ($r==$SQL_SUCCESS) {
    print "ok 111\n";
} else {
    print "not ok 111\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if ($r==$SQL_SUCCESS) {
    print "ok 112\n";
} else {
    print "not ok 112\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 113\n";
} else {
    print "not ok 113\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get special columns... ";
$r = &UnixODBC::SQLSpecialColumns ($sth, $SQL_ROWVER, '', 0, '', 0, 'titles', 6,
				   $SQL_SCOPE_CURROW, 0);
if ($r==$SQL_SUCCESS) {
    print "ok 114\n";
} else {
    print "not ok 114\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if ($r==$SQL_SUCCESS) {
    print "ok 115\n";
} else {
    print "not ok 115\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 116\n";
} else {
    print "not ok 116\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get statistics... ";
$r = &UnixODBC::SQLStatistics ($sth, '', 0, '', 0, 'titles', 6,
			       1, 1);
if ($r==$SQL_SUCCESS) {
    print "ok 117\n";
} else {
    print "not ok 117\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if ($r==$SQL_SUCCESS) {
    print "ok 118\n";
} else {
    print "not ok 118\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 119\n";
} else {
    print "not ok 119\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Get table privileges... ";
$r = &UnixODBC::SQLTablePrivileges ($sth, '', 0, '', 0, 'titles', 6);
if ($r==$SQL_SUCCESS) {
    print "ok 120\n";
} else {
    print "not ok 120\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Cancel... ";
$r = &UnixODBC::SQLCancel ($sth);
if ($r==$SQL_SUCCESS) {
    print "ok 121\n";
} else {
    print "not ok 121\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "End transaction... ";
$r = &UnixODBC::SQLEndTran ($SQL_HANDLE_STMT, $sth, 0);
if ($r==$SQL_SUCCESS) {
    print "ok 123\n";
} else {
    print "not ok 123\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Disconnect... ";
$r = &UnixODBC::SQLDisconnect ($cnh);
if ($r==$SQL_SUCCESS) {
    print "ok 124\n";
} else {
    print "not ok 124\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Free connection handle... ";
$r = &UnixODBC::SQLFreeConnect ($cnh);
if ($r==$SQL_SUCCESS) {
    print "ok 125\n";
} else {
    print "not ok 125\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Free environment handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_ENV, $evh);
if ($r==$SQL_SUCCESS) {
    print "ok 126\n";
} else {
    print "not ok 126\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Allocate environment handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE, $evh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 127\n";
} else {
    print "not ok 127\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set environment attribute... "; 
$r = &UnixODBC::SQLSetEnvAttr($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 128\n";
} else {
    print "not ok 128\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Allocate connection handle... "; 
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_DBC, $evh, $cnh);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 129\n";
} else {
    print "not ok 129\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Set connection timeout... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_LOGIN_TIMEOUT, 5, 0);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 130\n";
} else {
    print "not ok 130\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Set connection read-write mode... "; 
$r = &UnixODBC::SQLSetConnectAttr ($cnh, $SQL_ACCESS_MODE,
				   $SQL_MODE_READ_WRITE, TRUE);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 131\n";
} else {
    print "not ok 131\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Connect... ";
$r = &UnixODBC::SQLConnect ($cnh, $DSN, $SQL_NTS, $UserName, $SQL_NTS,
			    $PassWord, $SQL_NTS);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 132\n";
} else {
    print "not ok 132\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

print "Allocate statement handle... ";
$r = &UnixODBC::SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 133\n";
} else {
    print "not ok 133\n";
    &getdiagrec ($SQL_HANDLE_DBC, $cnh);
}

$query = 'select from titles;';;
print "Make bad query: $query... ";
print "SQLExecDirect query: " . $query . " ... ";
$r = &UnixODBC::SQLExecDirect ($sth, $query, length($query));
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 134\n";
} else {
    print "not ok 134\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Get SQL Error... ";
my ($sqlstate, $native_error); 
$r = &UnixODBC::SQLError ($evh, $cnh, $sth, $sqlstate, $native_error,
			  $ibuf, 255, $mlen);
if (($r==$SQL_SUCCESS)||($r==$SQL_NO_DATA)) {
    print "ok 135\n";
} else {
    print "not ok 135\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Free statement handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if ($r==$SQL_SUCCESS) {
    print "ok 136\n";
} else {
    print "not ok 136\n";
    &getdiagrec ($SQL_HANDLE_STMT, $sth);
}

print "Disconnect... ";
$r = &UnixODBC::SQLDisconnect ($cnh);
if ($r==$SQL_SUCCESS) {
    print "ok 137\n";
} else {
    print "not ok 138\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Free connection handle... ";
$r = &UnixODBC::SQLFreeConnect ($cnh);
if ($r==$SQL_SUCCESS) {
    print "ok 139\n";
} else {
    print "not ok 139\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

print "Free environment handle... ";
$r = &UnixODBC::SQLFreeHandle ($SQL_HANDLE_ENV, $evh);
if ($r==$SQL_SUCCESS) {
    print "ok 140\n";
} else {
    print "not ok 140\n";
    &getdiagrec ($SQL_HANDLE_ENV, $evh);
}

sub getdiagrec {
    my ($handle_type, $handle) = @_;
    my ($sqlstate, $native, $message_text);
    print 'SQLGetDiagRec: ';
    $r = &UnixODBC::SQLGetDiagRec ($handle_type, $handle, 1, $sqlstate,
				   $native, $message_text, 4096,
				   $mlen);
    if ($r == $SQL_NO_DATA) { 
	print "result \= SQL_NO_DATA\n";
    } elsif (($r == 1) || ($r == 0)) { 
     print "$message_text\n";
    } else { 
     print "sqlresult = $r\n";
    }
    return $r;
}
