#!/usr/local/bin/perl

#**********************************************************************
#               example.pl  The perl iODBC extension 0.1              *
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

use iodbc;

my($dns)=0;
my($uid)=0;
my($pwd)=0;
my($i)=0;
my($henv)=0;
my($hdbc)=0;
my($hstmt)=0;
my(@rgbValue)=[];
my($numcols)=0;
my($garb1)=0;
my($garb2)=0;
my(@width)=[];
my($MsgMax)=64;
my $SqlStmt = 0;
my $label = 0;

#Find out the width of the screen
open SIZE,"stty size|";
chop($size=<SIZE>);
$size =~ s/\A\w*\W//;
$screenwidth=$size;
close SIZE;

checkretcode(SQLAllocEnv($henv));
checkretcode(SQLAllocConnect($henv, $hdbc));

#Get connection info
print  "Welcome to the Sample iODBC Perl Program (SiPP)\n";
print  "Enter DSN> ";
chop($dsn=<STDIN>);
print  "Enter UID> ";
chop($uid=<STDIN>);
system  "stty -echo";
print  "Enter PWD> ";
chop($pwd=<STDIN>);
system "stty echo";
print  "\n";

checkretcode(SQLConnect($hdbc, $dsn, SQL_NTS, $uid, SQL_NTS, $pwd, SQL_NTS));
print  "ok\n";
print  "Type quit to exit.\n";

checkretcode(SQLAllocStmt($hdbc,$hstmt));

print  "SQL> ";

#loop until quit
while (($SqlStmt = <STDIN>) !~ /\Aquit/i){

    chop($SqlStmt);
    eval{checkretcode(SQLExecDirect($hstmt,$SqlStmt, SQL_NTS));};
    if ($@) {
	warn "$@";
    } else {
	checkretcode(SQLNumResultCols($hstmt,$numcols));
	unless ($numcols==0){
	    $maxwidth=($screenwidth/$numcols)-2;

	    #print a horizontal line
	    print ("\n" . "-" x $screenwidth . "\n");
	    print "|";
            #loop through columns gathering info.
	    for ($i=1;$i<=$numcols;$i++) { 
		checkretcode(SQLColAttributes($hstmt,
					      $i,
					      SQL_COLUMN_DISPLAY_SIZE,
					      $garb1,
					      0,
					      $garb2,
					  $width[$i]));
		if ($width[$i]>$maxwidth){$width[$i]=$maxwidth;}
		checkretcode(SQLColAttributes($hstmt,
					      $i,
					      SQL_COLUMN_LABEL,
					      $label,
					      $width[$i],
					      $garb1,
					      $garb2));
		printf  ("%"."$width[$i].$width[$i]"."s|",$label);
		checkretcode(SQLBindCol($hstmt,
					$i,
					SQL_C_DEFAULT,
					\$rgbValue[$i],
					$width[$i],
					SQL_NULL_DATA));
	    }
	    print  ("\n" . "-" x $screenwidth . "\n");

            #Fetch all rows and print out the columns
	    while(checkretcode(SQLFetch($hstmt))==SQL_SUCCESS){
		print  "|";
		for ($i=1;$i<=$numcols;$i++){
		    $rgbValue[$i] =~ s/\s*\Z//; #Strip trailing whitespace
		    printf  ("%"."$width[$i].$width[$i]"."s|",
				 $rgbValue[$i]);
		}
		print  "\n";
	    }
	    print  ("-" x $screenwidth . "\n");
	    checkretcode(SQLFreeStmt($hstmt,SQL_UNBIND));
	}
    }
    print  "SQL> ";
}
print  "Good...";
checkretcode(SQLFreeStmt($hstmt,SQL_DROP));
checkretcode(SQLDisconnect($hdbc));
checkretcode(SQLFreeConnect($hdbc));
checkretcode(SQLFreeEnv($henv));
print  "Bye\n";

sub checkretcode {
    my($retcode) = shift;
    if ($retcode==SQL_SUCCESS) {
    } elsif ($retcode==SQL_ERROR) {
	die (&stmterr($hstmt));
    } elsif ($retcode==SQL_SUCCESS_WITH_INFO) {
	warn(&stmterr($hstmt));
    } elsif ($retcode==SQL_NEED_DATA) {
	warn("SQL_NEED_DATA");
    } elsif ($retcode==SQL_INVALID_HANDLE) {
	warn("SQL_INVALID_HANDLE");
    } elsif ($retcode==SQL_STILL_EXECUTING){
	warn("SQL_STILL_EXECUTING");
    } elsif ($retcode==SQL_NO_DATA_FOUND) {
    }
    return $retcode;
}

sub stmterr {
    my($hstmt) = shift;
    my($size) = $MsgMax;
    my($sqlstate) = 0;
    my($native) = 0;
    my($errmsg) = 0;
    my($retcode)=0;
    my($end) = 1;
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
	    return "[SqlState:$sqlstate][$native][$errmsg]";
	} elsif ($retcode == SQL_INVALID_HANDLE) {
	    return "[SQLERROR:INVALID_HANDLE]";
	} elsif ($retcode == SQL_ERROR) {
	    return "[SQLERROR:ERROR]";
	} elsif ($retcode == SQL_SUCCESS_WITH_INFO) {
	    $end=0;
	} elsif ($retcode == SQL_NO_DATA_FOUND) {
	    return "[SQLERROR:NO_DATA_FOUND]";
	} else {
	    return "[NOERROR:something wierd happened]";
	}
    } until ($end);
}

