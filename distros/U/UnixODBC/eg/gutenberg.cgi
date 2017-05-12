#!/usr/bin/perl

# $Id: gutenberg.cgi,v 1.2 2004-03-13 23:34:53 kiesling Exp $

use CGI;
use UnixODBC (':all');
use DBIx::HTMLTable;

my $q = new CGI;

my $DSN = 'Gutenberg Catalog';
my $UserName = 'root';
my $PassWord = '';

my $env;
my $cnh;
my $sth;
my $r;

my $sqlquery = 'select * from titles;';

# GetDiagRec variables
my ($sqlstate, $native, $msg, $len);

# Table columns
my ($id, $id_len, $id_head);
my ($etext_no, $etext_no_len, $etext_head);
my ($col, $col_len, $col_head);
my ($auth, $auth_len, $auth_head);
my ($title, $title_len, $title_head);

# Refs to resultset rows
my (@resultset);

# Unused column attribute parameters
my ($head_len, $data_type, $column_size, $decimal_digits, $nullable);

print $q -> header;
print $q -> start_html('Gutenberg Catalog');
print qq|<body bgcolor="white">|;

$r = SQLAllocHandle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE, $evh);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_ENV, $evh, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLSetEnvAttr($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_ENV, $evh, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLAllocHandle ($SQL_HANDLE_DBC, $evh, $cnh);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_ENV, $evh, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLConnect ($cnh, $DSN, $SQL_NTS,
			    $UserName, $SQL_NTS,
			    $PassWord, $SQL_NTS);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_DBC, $cnh, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLAllocHandle ($SQL_HANDLE_STMT, $cnh, $sth);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_STMT, $sth, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLPrepare ($sth, $sqlquery, length ($sqlquery));
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_STMT, $sth, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLExecute ($sth);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_STMT, $sth, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLDescribeCol ($sth, 1, $id_head, 255, $head_len, 
		     $data_type, $column_size, $decimal_digits, $nullable);
$r = SQLDescribeCol ($sth, 2, $etext_head, 255, $head_len, 
		     $data_type, $column_size, $decimal_digits, $nullable);
$r = SQLDescribeCol ($sth, 3, $col_head, 255, $head_len, 
		     $data_type, $column_size, $decimal_digits, $nullable);
$r = SQLDescribeCol ($sth, 4, $auth_head, 255, $head_len, 
		     $data_type, $column_size, $decimal_digits, $nullable);
$r = SQLDescribeCol ($sth, 5, $title_head, 255, $head_len, 
		     $data_type, $column_size, $decimal_digits, $nullable);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_STMT, $sth, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

push @resultset, 
    \@{[$id_head, $etext_head, $col_head, $auth_head, $title_head]};

while (1) {
    $r = SQLFetch ($sth);
    last if $r == $SQL_NO_DATA;
    $r = SQLGetData ($sth, 1, $SQL_C_CHAR, $id, 255, $id_len);
    $r = SQLGetData ($sth, 2, $SQL_C_CHAR, $etext_no, 255, $etext_no_len);
    $r = SQLGetData ($sth, 3, $SQL_C_CHAR, $col, 255, $col_len);
    $r = SQLGetData ($sth, 4, $SQL_C_CHAR, $auth, 255, $auth_len);
    $r = SQLGetData ($sth, 5, $SQL_C_CHAR, $title, 255, $title_len);

    push @resultset, \@{[$id, $etext_no, $col, $auth, $title]};
}
DBIx::HTMLTable::HTMLTableByRef (\@resultset, {'border' => 'all'});
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_STMT, $sth, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLFreeHandle ($SQL_HANDLE_STMT, $sth);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_STMT, $sth, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLDisconnect ($cnh);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_DBC, $cnh, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLFreeConnect ($cnh);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_DBC, $cnh, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}

$r = SQLFreeHandle ($SQL_HANDLE_ENV, $evh);
if (($r!=$SQL_SUCCESS)&&($r!=$SQL_NO_DATA)) {
    SQLGetDiagRec ($SQL_HANDLE_ENV, $evh, 1, $sqlstate, 
		   $native, $message_text, 255, $len);
    print "$message_text\n";
    &endhtml;
}


sub endhtml {
    print qq|</body>|;
    print $q -> end_html;
}
