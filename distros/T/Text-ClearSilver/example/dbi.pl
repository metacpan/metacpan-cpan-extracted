#!perl -w
use 5.010_000;
use strict;
use Config;
use DBI;
use Text::ClearSilver;

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef,
    { PrintError => 0, RaiseError => 1} );

$dbh->do(<<'SQL');
create table perl_config (
    name  text primary key,
    value text
);
SQL

my $sth = $dbh->prepare(<<'SQL');
insert into perl_config values(?, ?);
SQL

while(my($k, $v) = each %Config){
    $sth->execute($k, $v);
}

# output

$sth = $dbh->prepare(<<'SQL');
select * from perl_config where name like ?;
SQL

#use Data::Dumper; print Dumper tied(%$sth);
$sth->execute($ARGV[0] || '%');

my %row;
$sth->bind_columns(\@row{ @{$sth->{NAME_lc}} });

my $hdf = Text::ClearSilver::HDF->new;
my $i = 0;
while($sth->fetch) {
    $hdf->set_value("PerlConfig.$i.name"  => $row{name});
    $hdf->set_value("PerlConfig.$i.value" => $row{value} // 'undef');
    $i++;
}

#print $hdf->dump;

my $tcs = Text::ClearSilver->new();

$tcs->process(\<<'TCS', $hdf);
<?cs each:item = PerlConfig ?><?cs var:item.name ?> = <?cs var:item.value ?>
<?cs /each ?>
TCS

