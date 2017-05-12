use strict;
use warnings;

use Test::More;

use_ok('Test::MockDBI');

my $mock = Test::MockDBI::get_instance();
my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');

sub get_sth{
  my $sth = $dbh->prepare('SELECT something FROM somewhere WHERE location = ?');
  $sth->bind_param(1, 'anywhere');
  $sth->execute();
  return $sth;
}

{
  #Check that rows default returns -1
  my $sth = get_sth();
  cmp_ok($sth->rows(), '==', -1, '$sth->rows default returns -1');
}

{
  my $resultset = [ { A => 1 }, { B => 1 }];
  $mock->set_retval(
    method => 'fetchrow_hashref',
    retval => $resultset
  );
  
  #Check that we can get rows to return the right number of rows
  my $sth = get_sth();
  $mock->set_retval(
    sql => 'SELECT something FROM somewhere WHERE location = ?',
    retval => sub{
      return scalar( @{ $resultset } );
    },
    method => 'rows'
  );
  cmp_ok($sth->rows(), '==', 2, '$sth->rows returns 2');
}
done_testing();