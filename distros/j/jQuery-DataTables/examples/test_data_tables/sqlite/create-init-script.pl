#!perl -w
use strict;
use DBI;

my $db = shift;
my $dbh = DBI->connect("dbi:SQLite:dbname=$db","","", {AutoCommit       => 0,});

$dbh->do(<<END);
	CREATE TABLE datatable (
	    id INTEGER,
	    col_int INTEGER,
	    col_text TEXT,
	    col_real REAL,
	    CONSTRAINT PK_datatable PRIMARY KEY (id)
	)
END


my $query="INSERT INTO datatable(id,col_int,col_text,col_real) VALUES (?,?,?,?)";
my $sth = $dbh->prepare($query);

my $id=0;
my @chars=(' ',' ',' ',' ','a'..'z', 0..1);
foreach my $i(1..1000){
	$id++;
	my($col_int,$col_text,$col_real)=(rand(1000),'',rand());
	$col_text .= $chars[int(rand($#chars+1))] foreach(1..rand(100));
	$sth->execute($id,$col_int,$col_text,$col_real);
#	$dbh->commit() unless $id % 1000;
}

$dbh->commit();