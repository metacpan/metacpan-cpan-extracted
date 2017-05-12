use strict;
use warnings;
use Test::More;
use Test::MockDBI::Constants;

use_ok('Test::MockDBI');


my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');

{
  my $sth = $dbh->prepare('SELECT name FROM sometable where id = ? OR id = ? OR age = ? OR age = ?');
  
  ok($sth->bind_param(1, 'Donald Duck'), "bind_param called successfully");
  ok($sth->bind_param(2, 'Fetter Anton'), "bind_param called successfully");
  ok($sth->bind_param(3, 25, SQL_INTEGER), "bind_param called successfully");
  ok($sth->bind_param(4, 30, { TYPE => SQL_INTEGER }), "bind_param called successfully");
  
  #Check that we have bound some variables
  cmp_ok($sth->{ParamValues}->{1}, 'eq', 'Donald Duck', "Param bound to position 1 eq Donald Duck");
  cmp_ok($sth->{ParamValues}->{2}, 'eq', 'Fetter Anton', "Param bound to position 2 eq Fetter Anton");
  cmp_ok($sth->{ParamValues}->{3}, '==', 25, "Param bound to position 3 == 25");
  cmp_ok($sth->{ParamValues}->{4}, '==', 30, "Param bound to position 4 == 30");
  
  #Check that the appropriate SQL types are set
  is_deeply( $sth->{ParamTypes}->{1}, { TYPE => SQL_VARCHAR }, 'Param type bound to position 1 is SQL_VARCHAR');
  is_deeply( $sth->{ParamTypes}->{2}, { TYPE => SQL_VARCHAR }, 'Param type bound to position 2 is SQL_VARCHAR');
  is_deeply( $sth->{ParamTypes}->{3}, { TYPE => SQL_INTEGER }, 'Param type bound to position 3 is SQL_INTEGER');
  is_deeply( $sth->{ParamTypes}->{4}, { TYPE => SQL_INTEGER }, 'Param type bound to position 4 is SQL_INTEGER');
}
{
  #Test that we get the appropriate warning if we bind a param with an invalid parameter number
  
  my $sth = $dbh->prepare('SELECT name FROM sometable where id = ?');
  
  #0 should be invalid, DBI starts bind_param starts at 1
  ok(!$sth->bind_param(0, 'Donald Duck'), "bind_param called unsuccessfully");
  #2 should be invalid as we only have one placeholder in the sql
  ok(!$sth->bind_param(2, 'Donald Duck'), "bind_param called ununsuccessfully");
}

done_testing();