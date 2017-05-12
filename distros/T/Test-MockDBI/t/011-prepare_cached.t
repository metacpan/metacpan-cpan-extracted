use strict;
use warnings;
use Test::More;

use_ok('Test::MockDBI');

my $mockinst = Test::MockDBI::get_instance();
my $dbh = DBI->connect('DBI:somedb:something', 'user1', 'password1');

{
  #Without attributes
  my $sth1 = $dbh->prepare_cached('select id from users');
  
  cmp_ok(ref($sth1), 'eq', 'DBI::st', 'Statement handler #1 is a DBI::st');
  
  my $sth2 = $dbh->prepare_cached('select id from users');
  
  cmp_ok(ref($sth2), 'eq', 'DBI::st', 'Statement handler #2 is a DBI::st');
  
  cmp_ok($sth1, 'eq', $sth2, "$sth1 eq $sth2");
  
  my $sth3 = $dbh->prepare_cached('select id from users where id = ?');
  
  cmp_ok(ref($sth3), 'eq', 'DBI::st', 'Statement handler #3 is a DBI::st');
  
  cmp_ok($sth2, 'ne', $sth3, "$sth2 ne $sth3");
  
  
}
{
  #With attributes
  my $sth1 = $dbh->prepare_cached('select id from users', { something => 1 });
  
  cmp_ok(ref($sth1), 'eq', 'DBI::st', 'Statement handler #1 is a DBI::st');
  
  my $sth2 = $dbh->prepare_cached('select id from users', { something => 1 });
  
  cmp_ok(ref($sth2), 'eq', 'DBI::st', 'Statement handler #2 is a DBI::st');
  
  cmp_ok($sth1, 'eq', $sth2, "$sth1 eq $sth2");
  
  my $sth3 = $dbh->prepare_cached('select id from users', { somethingelse => 1 });
    
  cmp_ok(ref($sth3), 'eq', 'DBI::st', 'Statement handler #3 is a DBI::st');
  
  cmp_ok($sth1, 'ne', $sth3, "$sth1 ne $sth3");
  
}


done_testing();