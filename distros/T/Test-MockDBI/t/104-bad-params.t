use strict;
use warnings;

use Test::More;
use Test::Warn;

use_ok('Test::MockDBI');
my $mockinst = Test::MockDBI::get_instance();

my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');

{
  my $sql = 'SELECT id FROM db WHERE id < ?';
  my $sth = $dbh->prepare($sql);
  #Setting 10 as a bad parameter
  ok($mockinst->bad_param( p_value => 10, sql => $sql), "Successfully set 10 to be a bad_param");
  
  ok(!$sth->bind_param(1, 10), "bind_param fails for value 10");
  ok($sth->bind_param(1, 11), "bind_param succeeds for value 11");
}
{
  #Checking the legacy interface
  my $sql = 'SELECT id FROM db WHERE id < ?';
  my $sth = $dbh->prepare($sql);
  #Setting 10 as a bad parameter
  warning_like{
    ok($mockinst->bad_param(1, 1, 10), "Successfully set 10 to be a bad_param");
  } qr/You have called bad_param in an deprecated way. Please consult the documentation/, "Warning displayed for legacy interface";
  
  
  ok(!$sth->bind_param(1, 10), "bind_param fails for value 10");
  ok($sth->bind_param(1, 11), "bind_param succeeds for value 11");  
}


done_testing();