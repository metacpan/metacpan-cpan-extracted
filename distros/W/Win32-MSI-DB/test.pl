# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 7;
BEGIN { unshift @INC,"." };

use DB;

#########################

ok(1,"use Win32::MSI::DB"); 

$file="test1.msi";

unlink $file if -e $file;

$db1=Win32::MSI::DB::new($file,$Win32::MSI::DB::MSIDBOPEN_CREATE);
ok($db1, "create database");

ok($db1->view("CREATE TABLE tbl1 ( id INT NOT NULL, text CHAR(32) PRIMARY KEY id )"),
"create table");

$max=10;

for ($ok=1,$i=0; $i<$max; $i++)
{
  $ok=0 if !$db1->view("INSERT INTO tbl1 ( id, text) VALUES (?,?)",
	  $i, "t$i" );
}

ok($ok, "insert $max rows");

$tbl=$db1->table("tbl1");
ok($tbl,"open table");

@rec=$tbl->records();
ok(@rec == $max, "# of records");

$ok=1;
for (@rec)
{
  $ok=0 if ("t" . $_->get("id")) ne $_->get("text");
}

ok($ok, "values in records");

undef @rec;
undef $db1;


unlink $file if -e $file;

