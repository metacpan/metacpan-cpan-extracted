use strict;
use warnings;
use Test::More;

use_ok('Test::MockDBI');

my $instance = Test::MockDBI::get_instance();

#Test all methods with a coderef retval

my %methods = (
  'DBI::db' => ['prepare', 'prepare_cached', 'do', 'commit', 'rollback', 'begin_work', 'ping', 'disconnect'],
  'DBI::st' => ['bind_param', 'bind_param_inout', 'execute', 'fetchrow_arrayref', 'fetchrow_array', 'fetchrow_hashref',
                'fetchall_arrayref', 'finish', 'rows']
);

my $dbh = DBI->connect('DBI:mydb:somedb', 'user1', 'password1', { AutoCommit => undef }); #AutoCommit => undef to silence warnings!
my $sth = $dbh->prepare('SELECT something FROM sometable');
$sth->execute(); #Make sure its executed

{
  
  #Testing the databasehandler
  foreach my $method ( @{ $methods{'DBI::db'} } ){
    #Setting a fake retval for the prepare method
    $instance->set_retval( method => $method, retval => sub {
      return "The returnvalue";
    });
    my $retval = $dbh->$method();
    cmp_ok($retval, 'eq', 'The returnvalue', $method . ' returned \'The returnvalue\'');
    
  }
  
  #Testing the statementhandler
  foreach my $method ( @{ $methods{'DBI::st'} } ){
    #Setting a fake retval for the prepare method
    $instance->set_retval( method => $method, retval => sub {
      return "The returnvalue";
    });
    my $retval = $sth->$method();
    cmp_ok($retval, 'eq', 'The returnvalue', $method . ' returned \'The returnvalue\'');
    
  }  
}

done_testing();