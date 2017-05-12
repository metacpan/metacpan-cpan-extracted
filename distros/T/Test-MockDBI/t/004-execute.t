use warnings;
use strict;
use Test::More;

use_ok('Test::MockDBI');

my $dbh = DBI->connect('DBI:mysql:somedatabase', 'user1', 'password1');

{
  my $sth = $dbh->prepare("SELECT id FROM table1 where id = ?");
  ok($sth->bind_param(1, 1), "bind_param called successfully");
  
  cmp_ok($sth->execute(), '==', -1, "Execute returned -1");
}
done_testing();