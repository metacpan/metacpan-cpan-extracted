use strict;
use warnings;
use Test::More;

use_ok('Test::MockDBI');

my $mockdbi = Test::MockDBI::get_instance();

my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');

isa_ok($dbh, 'DBI::db');

{
  #Checking that bind_param_inout works
  my $number = 10;
  
  #The sql to be used
  my $sql = 'CALL PROCEDURE update_number(?)';
  
  #Setting the retval for the inout parameter
  #This should ensure that $number is 15 after execute is called
  $mockdbi->set_inout_value($sql, 1, 15);
  
  my $sth = $dbh->prepare($sql);
  
  $sth->bind_param_inout(1, \$number);
  
  $sth->execute();
  
  cmp_ok($number, '==', 15, '$number should be 15');
}
{
  #Having a mixture of normal params and inout params
  my $inout1 = 10;
  my $inout2 = 20;
  
  my $sql = 'CALL PROCEDURE switchandmultiply(?, ?, ?)';
  
  #Setting the retval for the inout parameter
  #This should ensure that $inout1 is 40 after execute is called
  $mockdbi->set_inout_value($sql, 1, 40);
  #This should ensure that $inout2 is 20 after execute is called
  $mockdbi->set_inout_value($sql, 3, 20);
  
  my $sth = $dbh->prepare($sql);
  
  $sth->bind_param_inout(1, \$inout1);
  $sth->bind_param(2, 2);
  $sth->bind_param_inout(3, \$inout2);
  
  
  $sth->execute();
  cmp_ok($inout1, '==', 40, '$inout1 == 40');
  cmp_ok($inout2, '==', 20, '$inout2 == 20');
  
}
{
  #Bind param should die if it has to few parameters
  my $sth = $dbh->prepare('CALL something(?, ?)');
  
  eval{
    #No parameters provided. DBI dies
    $sth->bind_param_inout();
  };
  ok($@, '$@ is set');
  like($@, qr/bind_param_inout: invalid number of arguments/, "Correct error thrown");
}
{
  #bind_param_inout should return undef if $p_num is a non digit
  my $sth = $dbh->prepare('CALL something(?, ?)');
  
  my $inout = 'something';
  
  #$p_num is a non digit
  ok(!$sth->bind_param_inout('asdf', \$inout), 'Return undef on non-digit $p_num');
  cmp_ok($sth->err, '==', 16, '$sth->err is set to 16');
  cmp_ok($sth->errstr, 'eq', 'Illegal parameter number', '$sth->errstr is set to \'llegal parameter number\'');
}
{
  #bind_param_inout should return undef if we try to bind to many values
  my $sth = $dbh->prepare('CALL something(?, ?)');
  
  my $inout1 = 'something';
  my $inout2 = 'somethingelse';
  my $inout3 = 'somethingelseelse';
  
  #$p_num is a non digit
  ok($sth->bind_param_inout(1, \$inout1), 'bind_param_inout #1');
  ok($sth->bind_param_inout(2, \$inout2), 'bind_param_inout #2');
  ok(!$sth->bind_param_inout(3, \$inout3), 'bind_param_inout #3 fails');
  cmp_ok($sth->err, '==', 16, '$sth->err is set to 16');
  cmp_ok($sth->errstr, 'eq', 'Illegal parameter number', '$sth->errstr is set to \'llegal parameter number\'');  
}
{
  #The bind_param_inout $bind_value must be a scalar ref
  my $sth = $dbh->prepare('CALL something(?, ?)');
  eval{
    $sth->bind_param_inout(1, 'something');
  };
  ok($@, '$@ is set - dies on bind_param_inout not being scalar ref');
  like($@, qr/bind_param_inout needs a reference to a scalar value/, "Error is bind_param_inout needs a reference to a scalar value")
  
}
done_testing();