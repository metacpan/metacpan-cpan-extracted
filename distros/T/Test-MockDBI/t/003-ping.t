use strict;
use warnings;
use Test::More;

use_ok('Test::MockDBI');


my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');

#Testing that ping is available
{
  ok($dbh->can('ping'), "Ping is available");
}
done_testing();