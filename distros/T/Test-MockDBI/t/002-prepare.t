use strict;
use warnings;
use Test::More;

use_ok('Test::MockDBI');

#Testing that we actually get back a sth
{
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');
  
  cmp_ok(ref($dbh), 'eq', 'DBI::db', 'Ref of the database handler is DBI::db');
  
  my $sth = $dbh->prepare('SELECT * FROM sometable WHERE id = ?');
  
  cmp_ok(ref($sth), 'eq', 'DBI::st', 'Ref of the database handler is DBI::st');
}

#Test that the statement handler has the correct NUM_OF_PARAMS set
{
  my @testdata = (
    { sql => 'Something wierd ? ? ', num => 2 },
    { sql => 'SELECT one, two FROM sometable where id = ? and number = ? and is_stupid = ?', num => 3 }
  );
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');
  
  cmp_ok(ref($dbh), 'eq', 'DBI::db', 'Ref of the database handler is DBI::db');
  
  foreach my $item ( @testdata ){
    my $sth = $dbh->prepare($item->{sql});
    cmp_ok($sth->{NUM_OF_PARAMS}, '==', $item->{num}, 'NUM_OF_PARAMS is set to ' . $item->{num});
  }
}
done_testing();