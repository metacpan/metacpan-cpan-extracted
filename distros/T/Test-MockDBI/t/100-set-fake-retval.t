use strict;
use warnings;
use Test::More;
use Test::Warn;

use_ok('Test::MockDBI');

my $instance = Test::MockDBI::get_instance();

my %methods = (
  'DBI::db' => ['prepare', 'prepare_cached', 'do', 'commit', 'rollback', 'begin_work', 'ping', 'disconnect'],
  'DBI::st' => ['bind_param', 'bind_param_inout', 'execute', 'fetchrow_arrayref', 'fetchrow_array', 'fetchrow_hashref',
                'fetchall_arrayref', 'finish', 'rows']
);

my $dbh = DBI->connect('DBI:mydb:somedb', 'user1', 'password1', { AutoCommit => undef } ); #AutoCommit to silence warnings!
my $sth = $dbh->prepare('SELECT something FROM sometable');
$sth->execute(); #Make sure its executed


{
  #Testing that we can set the returnvalue to plain undef
  #Testing the databasehandler
  foreach my $method ( @{ $methods{'DBI::db'} } ){
    #Setting a fake retval for the prepare method
    $instance->set_retval( method => $method, retval => undef );
    my $retval = $dbh->$method();
    ok(!$retval, $method . ' returned undef');
    
  }
  
  #Testing the statementhandler
  foreach my $method ( @{ $methods{'DBI::st'} } ){
    #Setting a fake retval for the prepare method
    $instance->set_retval( method => $method, retval => undef);
    my $retval = $sth->$method();
    ok(!$retval, $method . ' returned undef');
    
  }
  #Resetting the mock instance
  $instance->reset();
}
{
  #Testing that we can set the returnvalue and custom err and errstr
  
  
  #Testing the databasehandler
  foreach my $method ( @{ $methods{'DBI::db'} } ){
    my %args = ( method => $method, retval => undef, err => 99, errstr => 'Custom DBI error' );
    #Setting a fake retval for the prepare method
    $instance->set_retval( %args );
    my $retval = $dbh->$method();
    ok(!$retval, $method . ' returned undef');
    cmp_ok($dbh->err, '==', $args{err}, '$sth->err is ' . $args{err});
    cmp_ok($dbh->errstr, 'eq', $args{errstr}, '$sth->errstr is ' . $args{errstr});    
  }
  
  #Testing the statementhandler
  foreach my $method ( @{ $methods{'DBI::st'} } ){
    my %args = ( method => $method, retval => undef, err => 99, errstr => 'Custom DBI error' );
    #Setting a fake retval for the prepare method
    $instance->set_retval( %args );
    my $retval = $sth->$method();
    ok(!$retval, $method . ' returned undef');
    cmp_ok($sth->err, '==', $args{err}, '$sth->err is ' . $args{err});
    cmp_ok($sth->errstr, 'eq', $args{errstr}, '$sth->errstr is ' . $args{errstr});
  }
  $instance->reset();
}
{
  #Setting a fake retval should fail if no method is provided
  my %args = ( retval => undef, err => 99, errstr => 'Custom DBI error' );
  warning_like{
    ok(!$instance->set_retval( %args ), "set_retval fails without a method");
  } qr/No method provided/, "set_retval displays warning on no method";
}
{
  #Method must be a scalar string
  my %args = ( method => sub{ return 'somemethod';}, retval => undef, err => 99, errstr => 'Custom DBI error' );
  warning_like{
    ok(!$instance->set_retval( %args ), "set_retval fails with an invalid method");
  } qr/Parameter method must be a scalar string/, "set_retval displays warning on invalid method";
}

{
  #If provided sql must be a scalar string
  my %args = ( method => 'prepare', sql => ['sql'], retval => undef, err => 99, errstr => 'Custom DBI error' );
  warning_like{
    ok(!$instance->set_retval( %args ), "set_retval fails with an invalid sql");
  } qr/Parameter SQL must be a scalar string/, "set_retval displays warning on invalid sql";
}

{
  #A retval must be provided
  my %args = ( method => 'prepare', err => 99, errstr => 'Custom DBI error' );
  warning_like{
    ok(!$instance->set_retval( %args ), "set_retval fails without a retval");
  } qr/No retval provided/, "set_retval displays warning when called without a retval";
}
done_testing();