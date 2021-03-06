#!/usr/local/bin/perl

# $Id: example.pl,v 1.1 2000/04/04 19:20:02 mergl Exp $

######################### globals

$| = 1;
use Pg;

$dbmain = 'template1';
$dbname = 'pgperltest';
$trace  = '/tmp/pgtrace.out';
$DEBUG  = 0; # set this to 1 for traces

######################### the following methods will be used

#	connectdb
#	conndefaults
#	db
#	user
#	port
#	status
#	errorMessage
#	trace
#	untrace
#	exec
#	consumeInput
#	getline
#	putline
#	endcopy
#	resultStatus
#	ntuples
#	nfields
#	fname
#	fnumber
#	ftype
#	fsize
#	cmdStatus
#	oidStatus
#	cmdTuples
#	getvalue
#	print
#	notifies
#	lo_import
#	lo_export
#	lo_unlink

######################### the following methods will not be used

#	setdb
#	setdbLogin
#	reset
#	requestCancel
#	pass
#	host
#	tty
#	options
#	socket
#	backendPID
#	sendQuery
#	getResult
#	isBusy
#	getlineAsync
#	putnbytes
#	makeEmptyPGresult
#	fmod
#	getlength
#	getisnull
#	displayTuples
#	printTuples
#	lo_open
#	lo_close
#	lo_read
#	lo_write
#	lo_creat
#	lo_seek
#	lo_tell

######################### handles error condition

$SIG{PIPE} = sub { print "broken pipe\n" };

######################### create and connect to test database

$Option_ref = Pg::conndefaults();
($key, $val);
print "connection defaults:\n";
while (($key, $val) = each %$Option_ref) {
    printf "  keyword = %-12.12s val = >%s<\n", $key, $val;
}

$conn = Pg::connectdb("dbname=$dbmain");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
print "connected to $dbmain\n";

# do not complain when dropping $dbname
$conn->exec("DROP DATABASE $dbname");

$result = $conn->exec("CREATE DATABASE $dbname");
die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;
print "created database $dbname\n";

$conn = Pg::connectdb("dbname=$dbname");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
print "connected to $dbname\n";

######################### debug, trace

if ($DEBUG) {
    open(TRACE, ">$trace") || die "can not open $trace: $!";
    $conn->trace(TRACE);
    print "enabled tracing into $trace\n";
}

######################### check PGconn

$db = $conn->db;
print "  database: $db\n";

$user = $conn->user;
print "  user:     $user\n";

$port = $conn->port;
print "  port:     $port\n";

######################### create and insert into table

$result = $conn->exec("CREATE TABLE person (id int4, name char(16))");
die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;
print "created table, status = ", $result->cmdStatus, "\n";

for ($i = 1; $i <= 5; $i++) {
    $result = $conn->exec("INSERT INTO person VALUES ($i, 'Edmund Mergl')");
    die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;
}
print "insert into table, last oid = ", $result->oidStatus, "\n";

######################### copy to stdout, getline

$result = $conn->exec("COPY person TO STDOUT");
die $conn->errorMessage unless PGRES_COPY_OUT eq $result->resultStatus;
print "copy table to STDOUT:\n";

$ret = 0;
$i   = 1;
while (-1 != $ret) {
    $ret = $conn->getline($string, 256);
    last if $string eq "\\.";
    print "  ", $string, "\n";
    $i ++;
}

die $conn->errorMessage unless 0 == $conn->endcopy;

######################### delete and copy from stdin, putline

$result = $conn->exec("BEGIN");
die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;

$result = $conn->exec("DELETE FROM person");
die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;
print "delete from table, command status = ", $result->cmdStatus, ", no. of tuples = ", $result->cmdTuples, "\n";

$result = $conn->exec("COPY person FROM STDIN");
die $conn->errorMessage unless PGRES_COPY_IN eq $result->resultStatus;
print "copy table from STDIN: ";

for ($i = 1; $i <= 5; $i++) {
    # watch the tabs and do not forget the newlines
    $conn->putline("$i	Edmund Mergl\n");
}
$conn->putline("\\.\n");

die $conn->errorMessage unless 0 == $conn->endcopy;

$result = $conn->exec("END");
die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;
print "ok\n";

######################### select from person, getvalue

$result = $conn->exec("SELECT * FROM person");
die $conn->errorMessage unless PGRES_TUPLES_OK eq $result->resultStatus;
print "select from table:\n";

for ($k = 0; $k < $result->nfields; $k++) {
    print "  field = ", $k, "\tfname = ", $result->fname($k), "\tftype = ", $result->ftype($k), "\tfsize = ", $result->fsize($k), "\tfnumber = ", $result->fnumber($result->fname($k)), "\n";
}

while (@row = $result->fetchrow) {
    print " ", join(" ", @row), "\n";
}

######################### notifies

if (! defined($pid = fork)) {
    die "can not fork: $!";
} elsif (! $pid) {
    # I'm the child
    sleep 2;
    bless $conn;
    $conn = Pg::connectdb("dbname=$dbname");
    $result = $conn->exec("NOTIFY person");
    exit;
}

$result = $conn->exec("LISTEN person");
die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;
print "listen table: status = ", $result->cmdStatus, "\n";

while (1) {
    $conn->consumeInput;
    ($table, $pid) = $conn->notifies;
    last if $pid;
}
print "got notification: table = ", $table, "  pid = ", $pid, "\n";

######################### print

$result = $conn->exec("SELECT * FROM person");
die $conn->errorMessage unless PGRES_TUPLES_OK eq $result->resultStatus;
print "select from table and print:\n";
$result->print(STDOUT, 0, 0, 0, 0, 0, 0, " ", "", "", "");

######################### lo_import, lo_export, lo_unlink

$lobject_in  = '/tmp/gaga.in';
$lobject_out = '/tmp/gaga.out';

$data = "testing large objects using lo_import and lo_export";
open(FD, ">$lobject_in") or die "can not open $lobject_in";
print(FD $data);
close(FD);

$result = $conn->exec("BEGIN");
die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;

$lobjOid = $conn->lo_import("$lobject_in") or die $conn->errorMessage;
print "importing file as large object, Oid = ", $lobjOid, "\n";

die $conn->errorMessage unless 1 == $conn->lo_export($lobjOid, "$lobject_out");
print "exporting large object as temporary file\n";

$result = $conn->exec("END");
die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;

print "comparing imported file with exported file: ";
print "not " unless (-s "$lobject_in" == -s "$lobject_out");
print "ok\n";

die $conn->errorMessage if -1 == $conn->lo_unlink($lobjOid);
unlink $lobject_in;
unlink $lobject_out;
print "unlink large object\n";

######################### debug, untrace

if ($DEBUG) {
    close(TRACE) || die "bad TRACE: $!";
    $conn->untrace;
    print "tracing disabled\n";
}

######################### disconnect and drop test database

$conn = Pg::connectdb("dbname=$dbmain");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
print "connected to $dbmain\n";

$result = $conn->exec("DROP DATABASE $dbname");
die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;
print "drop database\n";

######################### EOF
