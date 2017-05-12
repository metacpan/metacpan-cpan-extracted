use strict;
use warnings;
use Test::More;

use_ok('Test::MockDBI');

my $mockinst = Test::MockDBI::get_instance();

#Testing that we actually get back a dbh
{
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');
  
  cmp_ok(ref($dbh), 'eq', 'DBI::db', 'Ref of the database handler is DBI::db');
}

#Testing that the connect attributes are correctly set
{
  my %attr = ( AutoCommit => 1, RaiseError => 1, PrintError => 1 );
  my $dbh = DBI->connect('DBI:Db2:somedb', 'user1', 'password1', \%attr);
  cmp_ok(ref($dbh), 'eq', 'DBI::db', 'Ref of the database handler is DBI::db');
  
  foreach my $key (keys %attr){
    cmp_ok($dbh->{$key}, '==', $attr{$key}, $key . ' is successfully set to ' . $attr{$key});
  }
}
{
  #Check that we can set a fake retval
  $mockinst->bad_method( method => 'connect' );
  
  my $dbh = DBI->connect();
  #$dbh should now be undef
  ok(!$dbh, '$dbh is undef');
}
{
  #Check that we can set a fake retval to a coderef
  $mockinst->set_retval( method => 'connect', retval => sub{ return 42; });
  
  my $dbh = DBI->connect();
  #$dbh should now be 42
  cmp_ok($dbh, '==', 42, '$dbh should now be 42');
}

done_testing();