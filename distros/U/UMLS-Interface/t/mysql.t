#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

# A script to test whether 
#  1. UMLS-Interface can be loaded
#  2. DBI can access the umls database in mysql
#  3. Information (Table names) can be accessed 
#  4. MRREL table exists 
#  5. MRCONSO table exists
#  6. MRSAB table exists
#  7. MRDOC table exists
#  8. MRDOC table can be accessed


BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}

use UMLS::Interface;
$loaded = 1;
print "ok 1\n";

use strict;
use warnings;

my $dsn = "DBI:mysql:umls;mysql_read_default_group=client;";
my $db = DBI->connect($dsn);

if(!$db || $db->err()) {
    print "not ok 2\n";
} else { print "ok 2\n"; }


my %tables = (); my $tableName = "";
my $sth = $db->prepare("show tables");
$sth->execute();
if($sth->err()) {
    print "not ok 3\n";
}
else {
    print "ok 3\n";
}

while(($tableName) = $sth->fetchrow()) {
    $tables{$tableName} = 1;
} $sth->finish();

# Check if MRREL exists
if(!defined $tables{"MRREL"}) {
    print "not ok 4\n";
}  
else {
    print "ok 4\n";
}

# Check if MRCONSO exists
if(!defined $tables{"MRCONSO"}) {
    print "not ok 5\n";
}
else {
    print "ok 5\n";
}

# Check if MRSAB exists
if(!defined $tables{"MRSAB"}) {
    print "not ok 6\n";
}
else {
    print "ok 6\n";
}

# Check if MDOC exists
if(!defined $tables{"MRDOC"}) {
    print "not ok 7\n";
}
else {
    print "ok 7\n";
}

#  Get version from the MRDOC table
my $arrRef = $db->selectcol_arrayref("select EXPL from MRDOC where VALUE = \'mmsys.version\'");
if($db->err()) {
    print "not ok 8\n";
}
else {
    print "ok 8\n";
}

