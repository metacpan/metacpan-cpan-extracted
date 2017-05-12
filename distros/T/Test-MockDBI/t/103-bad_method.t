# Test::MockDBI bad DBI method tests


# ------ use/require pragmas
use strict;      # better compile-time checking
use warnings;    # better run-time checking

use Test::More tests => 76;    # advanced testing
use File::Spec::Functions;
use lib catdir qw ( blib lib );            # use local module
use Test::MockDBI;             # what we are testing
use Test::Warn;

# ------ define variables
my $md = Test::MockDBI::get_instance();

{
  #Testing bad_method on the raw DBI package
  
  warning_like{
    is($md->bad_method("connect", 2, ""), 1, q{Expect 1});
  } qr/bad_method in an deprecated way/, "Legacy call to bad_method displays warning";
  is(DBI->connect(), undef, "DBI connect()");
  
  #Reset the mock object
  $md->reset();
}

{
  #Testing bad_method on the database handler
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1', { AutoCommit => undef }); #AutoCommit => undef to silence warnings!
  cmp_ok(ref($dbh), 'eq', 'DBI::db', 'Ref of dbh is DBI::db');

  my @methods = qw( disconnect prepare prepare_cached do commit rollback );
  
  #Legacy interface
  foreach my $method (@methods){
    warning_like{
      is($md->bad_method($method, 2, ""), 1, q{Expect 1});
    } qr/bad_method in an deprecated way/, "Legacy call to bad_method displays warning";
  }

  #Executing bad methods
  foreach my $method (@methods){
    my $retval = 1;
    eval('$retval = $dbh->' . $method . '();');
    ok(!$retval, $method . ' failed successfully');
  }
  $md->reset();
  
  #New interface
  is($md->bad_method( method => $_ ), 1, q{Expect 1}) for(@methods);

  #Executing bad methods
  is(eval('$dbh->' . $_ . '();'), undef, $_ . ' failed successfully') for(@methods);

  #Executing bad methods
  foreach my $method (@methods){
    my $retval = 1;
    eval('$retval = $dbh->' . $method . '();');
    ok(!$retval, $method . ' failed successfully');
  }
  $md->reset();
}

{
  #Testing bad_method in the statement handler
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1', { AutoCommit => undef }); #AutoCommit => undef to silence warnings
  my $sth = $dbh->prepare('select something from somewhere where anything = ?');
  
  my @methods = qw( rows bind_param execute finish fetchall_arrayref fetchrow_arrayref fetchrow_array );
  
  #Legacy interface
  foreach my $method (@methods){
    warnings_like{
      is($md->bad_method($method, 2, ""), 1, q{Expect 1});
    } qr/bad_method in an deprecated way/, "Legacy call to bad_method displays warning";    
  }

  

  #Executing bad methods
  foreach my $method (@methods){
    my $retval = 1;
    eval('$retval = $sth->' . $method . '();');
    ok(!$retval, $method . ' failed successfully');
  }
  $md->reset();  
  

  #New interface
  is($md->bad_method( method => $_), 1, q{Expect 1}) for(@methods);

  #Executing bad methods
  foreach my $method (@methods){
    my $retval = 1;
    eval('$retval = $sth->' . $method . '();');
    ok(!$retval, $method . ' failed successfully');
  }
  $md->reset();  
    
}
{
  #Testing bad_method with sql
  $md->bad_method( sql => qr/.*/, method => 'prepare' );
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1', { AutoCommit => undef }); #AutoCommit => undef to silence warnings
  my $sth = $dbh->prepare('select something from somewhere where anything = ?');  
  ok(!$sth, '$sth should be undef');
  $md->reset();
}
done_testing();
__END__