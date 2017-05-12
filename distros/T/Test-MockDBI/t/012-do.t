use strict;
use warnings;

use Test::More;

use_ok('Test::MockDBI');

my $dbh = DBI->connect('DBI:mydb:somedb', 'user1', 'password1');

{
  #Do should default return -1 (Return value of rows)
  
  my $retval = $dbh->do('INSERT INTO something VALUES(1)');
  cmp_ok($retval, '==', -1, '$dbh->do returned -1');
}

done_testing();