#**********************************************************************
#               methods.t The perl iODBC extension 0.1                *
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
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN {
    $| = 1;
    print "1..38\n";
    print "[Loading]..." if $verbose;
}
END {
    print "not ok 1\n" unless $loaded;
}
use iodbc;
$verbose = 0;
$loaded = 1;
$MsgMax =64;
my($pcbColName)=0;
my($pibScale) = 0;
my($pfSqlType) = 0;
my($pcbValue) = 0;
my($pfNullable) = 0;
my($dsn)="";	#Set to your DataSource
my($uid)="";	#Set to your User ID
my($pwd)="";	#Set to your password
print "ok 1\n";
######################### End of black magic.

# Allocating the enviroment handle

print "[Allocate Environment]..." if $verbose;
$retcode=SQLAllocEnv($henv);
if ($retcode==SQL_SUCCESS) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}
$count++;


# Allocating an connection

print "[Allocate Connection]..." if $verbose;
$retcode=SQLAllocConnect($henv,$hdbc);
if ($retcode==SQL_SUCCESS) {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}
$count++;	


# Connecting
print "[Connecting to datasource]..." if $verbose;
$retcode=SQLConnect($hdbc,$dsn,SQL_NTS,$uid,SQL_NTS,$pwd,SQL_NTS);
if ($retcode==SQL_SUCCESS) {
    print "ok 4\n";
} else {
    print "not ok 4\n";
}
$count++;


# Allocate Statement

print "[Allocate Statement]..." if $verbose;
$retcode=SQLAllocStmt($hdbc,$hstmt);
if ($retcode==SQL_SUCCESS) {
    print "ok 5\n";
} else {
    print "not ok 5\n";
}



# Set Cursor Name 
$count=6;
print "[Set Cursor Name]..." if $verbose;
&checkretcode(SQLSetCursorName($hstmt,"cursor",SQL_NTS));


# Get Cursor Name
$count=7;
print "[Get Cursor Name]..." if $verbose;
&checkretcode(SQLGetCursorName($hstmt,$cursor,24,$size));


# Check Cursor Name and size value

print "[Check Cursor Name and Size]..." if $verbose;
if (($cursor=~"cursor") && ($size==6)) {
    print "ok 8\n";
} else {
    print "not ok 8", $verbose ?
          "[\"$cursor\" should be \"cursor\"][\"$size\" should be\"6\"]\n" : "\n";
}


# ExecDirect to Execute a SQL statement
$count =9;
print "[Executing SQL CREATE TABLE]..." if $verbose;
&checkretcode(SQLExecDirect($hstmt,"CREATE TABLE test_table_01 (one CHAR(32),two CHAR(32),three CHAR(32))",SQL_NTS));


# Prepare to setup adding rows
$count=10;
print "[Prepare SQL INSERT]..." if $verbose;
&checkretcode(SQLPrepare($hstmt,"INSERT INTO test_table_01 values ('one','two','three')",SQL_NTS));


# Execute adding rows
$count=11;
print "[Execute Statement]..." if $verbose;
&checkretcode(SQLExecute($hstmt));


# Count rows
$count=12;
print "[Counting Rows]..." if $verbose;
&checkretcode(SQLRowCount($hstmt,$pcrow));

# Check result
$count=13;
print "[Check Result]..." if $verbose;
if ($pcrow==1) {
    print "ok $count\n";
} else {
    print "not ok $count", $verbose ? "[\"$pcrow\" should be \"1\"]\n":"\n";
}


# Repeat execution
$count=14;
print "[Repeat Execution]..." if $verbose;
&checkretcode(SQLExecute($hstmt));


# Setup some more rows
$count=15;
print "[Setup another row]..." if $verbose;
&checkretcode(SQLExecDirect($hstmt,"INSERT INTO test_table_01 VALUES ('one','2','3')",SQL_NTS));

$count=16;
print "[Setup another row]..." if $verbose;
&checkretcode(SQLExecDirect($hstmt,"INSERT INTO test_table_01 VALUES ('1','2','3')",SQL_NTS));


# Execute SELECT statement
$count=17;
print "[Execute SELECT]..." if $verbose;
&checkretcode(SQLExecDirect($hstmt,"SELECT * FROM test_table_01 where one like 'one%' ",SQL_NTS));


# Count Columns
$count=18;
print "[Count columns of result]..." if $verbose;
&checkretcode(SQLNumResultCols($hstmt,$pccol));


# Check result
$count=19;
print "[Check Result]..." if $verbose;
if ($pccol==3) {
    print "ok $count\n";
} else {
    print "not ok $count", $verbose ? "[\"$pcrow\" should be \"3\"]\n":"\n";
}


# Describe Column 1
$count=20;
print "[Describe Column]..." if $verbose;
my($szColName) = 0;
my($pcbColDef) = 0;
&checkretcode(SQLDescribeCol($hstmt,1,$szColName,24,$pcbColName,$pfSqlType,$pcbColDef,$pibScale,$pfNullable));


# Check result
$count=21;
print "[Check Result]..." if $verbose;
if ($szColName eq "one") {
    print "ok $count\n";
} else {
    print "not ok $count", $verbose ? "[\"$szColName\" should be \"one\"]\n":"\n";
}

# SQLColAttributes
$count=22;
print "[Column Attributes]..." if $verbose;
&checkretcode(SQLColAttributes($hstmt,1,SQL_COLUMN_COUNT,$rgbDesc,24,$size,$pfDesc));


# Check result
$count=23;
print "[Check Result]..." if $verbose;
if ($pfDesc==3) {
    print "ok $count\n";
} else {
    print "not ok $count", $verbose ? "[\"$pfDesc\" should be \"3\"]\n":"\n";
}


# SQLColAttributes
$count=24;
print "[Column Attributes]..." if $verbose;
&checkretcode(SQLColAttributes($hstmt,1,1,$rgbDesc,24,$size,$pfDesc));


# Check result
$count=25;
print "[Check Result]..." if $verbose;
if ($rgbDesc eq "one") {
    print "ok $count\n";
} else {
    print "not ok $count", $verbose ? "[\"$rgbDesc\" should be \"one\"]\n":"\n";
}


# Bind Column 1
$count=26;
print "[Bind Column]..." if $verbose;
&checkretcode(SQLBindCol($hstmt,1,SQL_C_DEFAULT,\$rgbValue,$pcbColDef,SQL_NULL_DATA));


# Fetch all rows with 'one' and count the number
$count=27;
print "[Fetch Rows]..." if $verbose;
$retcode=SQL_SUCCESS;
$pcrow=0;
while (1) {
    $retcode=SQLFetch($hstmt);
    if ($retcode==SQL_SUCCESS) {
    } elsif ($retcode==SQL_ERROR) {
	print "not ok $count";
	&stmterr($hstmt);
	last;
    } elsif ($retcode==SQL_SUCCESS_WITH_INFO) {
	&stmterr($hstmt);
    } elsif ($retcode==SQL_NEED_DATA) {
	print "not ok $count",$verbose ? "[SQL_NEED_DATA]\n":"\n";
	last;
    } elsif ($retcode==SQL_INVALID_HANDLE) {
	print "not ok $count", $verbose ? "[SQL_INVALID_HANDLE]\n":"\n";
	last;
    } elsif ($retcode==SQL_STILL_EXECUTING){
	print "not ok $count", $verbose ? "[SQL_STILL_EXECUTING]\n":"\n";
	last;
    } elsif ($retcode==SQL_NO_DATA_FOUND){
	print "ok $count\n";
	last;
    } else {
	print $verbose ? "ERRORCODE:$retcode which should not happen\n":"\n";
	last;
    }
    $pcrow++;
}

# Check result
$count=28;
print "[Check Result]..." if $verbose;
if ($rgbValue =~ "one") {
    print "ok $count\n";
} else { 
    print "not ok $count", $verbose ? "[\"$rgbValue\" should be \"one\"]\n":"\n";
}


# Delete rows with 'one'
$count=29;
print "[Delete rows]..." if $verbose;
&checkretcode(SQLExecDirect($hstmt,"DELETE FROM test_table_01 WHERE one LIKE '%one%'",SQL_NTS));


# Count rows
$count=30;
print "[RowCount of Deleted Rows]..." if $verbose;
&checkretcode(SQLRowCount($hstmt,$pcrow2));


# Check result
$count=31;
print "[Check Result]..." if $verbose;
if ($pcrow2==$pcrow) {
    print "ok $count\n";
} else {
    print "not ok $count", $verbose ? "[\"$pcrow2\" should be \"$pcrow\"]\n":"\n";
}


# Check to see if they were deleted
$count=32;
print "[Check for Deletion]..." if $verbose;
SQLExecDirect($hstmt,"SELECT * FROM test_table_01 WHERE one LIKE '%one%'",SQL_NTS);
if (SQL_NO_DATA_FOUND==&iodbc::SQLFetch($hstmt)) {
    print "ok $count\n";
} else {
    print "not ok $count\n";
}


# ExecDirect to clean up garbage
$count=33;
print "[Executing SQL DELETE * FROM TABLE]..." if $verbose;
&checkretcode(SQLExecDirect($hstmt,"DELETE FROM test_table_01",SQL_NTS));

$count=34;
print "[Drop the table]..." if $verbose;
&checkretcode(SQLExecDirect($hstmt,"DROP TABLE test_table_01",SQL_NTS));


# Free Statement Handle
$count=35;
print "[Free Statement Handle]..." if $verbose;
$retcode=SQLFreeStmt($hstmt,SQL_DROP);
if ($retcode==SQL_SUCCESS) {
    print "ok $count\n";
} else {
    print "not ok $count\n";
}


# Disconnect
$count=36;
print "[Disconnect from datasource]..." if $verbose;
$retcode=SQLDisconnect($hdbc);
if ($retcode==SQL_SUCCESS) {
    print "ok $count\n";
} else {
    print "not ok $count\n";
}


# Free Connection
$count=37;
print "[Free Connection]..." if $verbose;
$retcode=SQLFreeConnect($hdbc);
if ($retcode==SQL_SUCCESS) {
    print "ok $count\n";
} else {
    print "not ok $count\n";
}


# Free Environment
$count=38;
print "[Free Environment]..." if $verbose;
$retcode=SQLFreeEnv($henv);
if ($retcode==SQL_SUCCESS) {
    print "ok $count\n";
} else {
    print "not ok $count\n";
}		


sub checkretcode {
    my($retcode) = shift;
    if ($retcode==SQL_SUCCESS) {
	print "ok $count\n";
    } elsif ($retcode==SQL_ERROR) {
	print "not ok $count";
	&stmterr($hstmt) if $verbose;
	print "\n";
    } elsif ($retcode==SQL_SUCCESS_WITH_INFO) {
	print "ok $count\n";
	&stmterr($hstmt);
    } elsif ($retcode==SQL_NEED_DATA) {
	print "not ok $count",$verbose ? "[SQL_NEED_DATA]\n":"\n";
    } elsif ($retcode==SQL_INVALID_HANDLE) {
	print "not ok $count",$verbose ? "[SQL_INVALID_HANDLE]\n":"\n";
    } elsif ($retcode==SQL_STILL_EXECUTING){
	print "not ok $count",$verbose ? "[SQL_STILL_EXECUTING]\n":"\n";
    } elsif ($retcode==SQL_NO_DATA_FOUND) {
	print "not ok $count",$verbose ? "[SQL_NO_DATA_FOUND]\n":"\n";
    } else {
	print $verbose ? "ERRORCODE:$retcode which should not happen\n":"\n";
    }
}
sub stmterr {
    my($hstmt) = shift;
    my($size) = $MsgMax;
    my($sqlstate) = 0;
    my($native) = 0;
    my($errmsg) = 0;
    my($retcode)=0;
    my($end) = 1;
    if ($verbose) {
	do {
	    $end=1;
	    $retcode = SQLError(SQL_NULL_HENV,
				SQL_NULL_HDBC,
				$hstmt,
				$sqlstate,
				$native,
				$errmsg,
				$size+1,
				$size);
	    
	    if ($retcode == SQL_SUCCESS) {
		print "[SqlState:$sqlstate][$native][$errmsg]";
	    } elsif ($retcode == SQL_INVALID_HANDLE) {
		print "[SQLERROR:INVALID_HANDLE]";
	    } elsif ($retcode == SQL_ERROR) {
		print "[SQLERROR:ERROR]";
	    } elsif ($retcode == SQL_SUCCESS_WITH_INFO) {
		print "[SQLERROR:SUCCESS_WITH_INFO]";
		$end=0;
	    } elsif ($retcode == SQL_NO_DATA_FOUND) {
		print "[SQLERROR:NO_DATA_FOUND]";
	    } else {
		print "[NOERROR:something wierd happened]";
	    }
	} until ($end);
    }
}








