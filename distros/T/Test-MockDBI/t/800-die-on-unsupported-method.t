use strict;
use warnings;
use Test::More;

use_ok('Test::MockDBI');

my $dbh = DBI->connect('DBI:mysql:something', 'user1', 'password1');

#take_imp_data will probably never be implemented!
eval{
  $dbh->take_imp_data();
};

ok($@, '$@ should be set');

done_testing();