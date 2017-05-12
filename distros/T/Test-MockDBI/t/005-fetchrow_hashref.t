use strict;
use warnings;

use Test::More;

use_ok('Test::MockDBI');

my $instance = Test::MockDBI::get_instance();
my $dbh = DBI->connect('DBI:mysql:something', 'user1', 'password1');

{
  #Setting up a global resultset
  
  my @expected = ( { number => 1 }, { number => 2 }, { number => 3 } );
  
  $instance->set_retval( method => 'fetchrow_hashref', retval => \@expected );
  
  my $sth = $dbh->prepare('SELECT * FROM sometable');
  
  $sth->execute();
  
  
  my @got = ();
  my $cnt = 0;
  
  while( my $row = $sth->fetchrow_hashref()){
    push(@got, $row);
    $cnt++;
  }
  
  is_deeply(\@got, \@expected, "Got the expected resultset");
  cmp_ok($cnt, '==', scalar(@expected), "Executed the while loop the expected number of times");
  
}
{
  #Testing setting a resultset based on the sql
  my @expected = ( { letter => 'A' }, { letter => 'B' }, { letter => 'C' } );
  my $sql = "SELECT * FROM atable";
  
  
  $instance->set_retval( method => 'fetchrow_hashref', retval => \@expected,  sql => $sql );
  
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  
  my @got = ();
  my $cnt = 0;
  
  while( my $row = $sth->fetchrow_hashref()){
    push(@got, $row);
    $cnt++;
  }
  
  is_deeply(\@got, \@expected, "Got the expected resultset");
  cmp_ok($cnt, '==', scalar(@expected), "Executed the while loop the expected number of times");  
}

{
  #Testing that a sql resultset should have precedence over a global resultset
  my @expected = ( { letter => 'A' }, { letter => 'B' }, { letter => 'C' } );
  my @not_expected = ( { number => 1 }, { number => 2 }, { number => 3 } );
  my $sql = "SELECT * FROM atable";
  
  
  $instance->set_retval( method => 'fetchrow_hashref', retval => \@expected, sql => $sql );
  $instance->set_retval( method => 'fetchrow_hashref', retval => \@not_expected );
  
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  
  my @got = ();
  my $cnt = 0;
  
  while( my $row = $sth->fetchrow_hashref()){
    push(@got, $row);
    $cnt++;
  }
  
  is_deeply(\@got, \@expected, "Got the expected resultset");
  cmp_ok($cnt, '==', scalar(@expected), "Executed the while loop the expected number of times");  
}

done_testing();