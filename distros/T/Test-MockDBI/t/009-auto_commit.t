use strict;
use warnings;

use Test::More;
use Test::Warn;

use_ok('Test::MockDBI');

{
  #AutoCommit should reset after commit \ rollback calls
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');

  isa_ok($dbh, 'DBI::db');

  cmp_ok($dbh->{AutoCommit}, '==', 1, 'AutoCommit defaults to 1');
  
  $dbh->begin_work();
  
  cmp_ok($dbh->{AutoCommit}, '==', 0, 'AutoCommit is 0');
  
  $dbh->commit();
  
  cmp_ok($dbh->{AutoCommit}, '==', 1, 'AutoCommit is 1');
  
  $dbh->begin_work();
  
  cmp_ok($dbh->{AutoCommit}, '==', 0, 'AutoCommit is 0');
  
  $dbh->rollback();
  
  cmp_ok($dbh->{AutoCommit}, '==', 1, 'AutoCommit is 1');
}
{
  #Should be able to set AutoCommit on init
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1', { AutoCommit => 0 });
  cmp_ok($dbh->{AutoCommit}, '==', 0, "AutoCommit is turned off");
}
{
  #DBI should display a warning on commit without autocommit
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');
  
  warning_like{
    $dbh->commit();
  } qr/commit ineffective with AutoCommit enabled/, "commit displays warning when autocommit is enabled";
  
  warning_like{
    $dbh->rollback();
  } qr/rollback ineffective with AutoCommit enabled/, "rollback displays warning when autocommit is enabled";  
  
}

done_testing();