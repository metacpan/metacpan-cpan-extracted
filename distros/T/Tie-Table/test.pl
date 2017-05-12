use strict;
use Test;
use vars qw($a $b $loaded);
BEGIN { plan tests => 13; }
END {print "not ok 1\n" unless $loaded;}

######### Test 1: Module loading;
use Tie::Table;
$loaded = 1;
ok(1);

######### Test 2: Connecting to the database
use DBI;
my $db;
my $skip_db_tests = 0;

my $dbh=get_dbh();
skip($skip_db_tests, $dbh ? 1 : 0, 1);
$skip_db_tests ||= $dbh ? 0 : 1;
$skip_db_tests ? skip (1,1,1) : ok(&connect($dbh), 1);

sub connect { my ($dbh) = @_;
  my $seq= get_seq () or return undef;
  $db=new Tie::Table::DB( dbh=> $dbh, seq_mode => $seq );
  return 1;
};

sub get_dbh {
  my $dbh;
  print "
This module needs database access to test the functionality.
Do you want me to test the module with a database server? [Y/n]";
  my $blah=<STDIN>; chomp $blah;
  if ($blah =~ /^\s*n/i) {
    $skip_db_tests = 1;
    return undef;
  }

  $dbh = eval { DBI->connect(undef,undef,undef,{AutoCommit=>0,RaiseError=>0}) };
  return $dbh if $dbh;
  print "
I need database access to run my tests.
  Please give me data for doing that!
---------------------------------------

You may specify the DBI data source with
the environment variable DBI_DSN, and you won't
get answered next time.
Example: DBI:Pg:dbname=template1
Please enter the data source name: ";
  my $dsn=<>; chomp $dsn;
  print "
I need your database user name. Next time, you can set it
by using the DBI_USER environment variable
Please enter your user name:";
  my $uname=<>; chomp $uname;
  $dbh = eval { DBI->connect($dsn,$uname,undef,{AutoCommit=>0,RaiseError=>0}) };
  return $dbh if $dbh;
  print "
I need your database password.
Please enter your password (the password will be shown!):";
  my $pwd=<>; chomp $pwd;
  $dbh = eval { DBI->connect($dsn,$uname,$pwd,{AutoCommit=>0,RaiseError=>0}) };
  return $dbh if $dbh;
  print "
Sorry, I cannot connect to the database: error: $@ $DBI::errstr.
";
  return undef;
};

sub get_seq {
  my $seq;
  $seq=$ENV{DB_SEQ_MODE} and return $seq;
  print '
For using the insert function of the Tie::Table, I need to know
how your database server queries sequences. Currently
two kind is supported.
Oracle mode:
  "select seqname.nextval from dual"
Postgresql mode:
  "select seqname.last_value"

You can specify the mode by setting the DB_SEQ_MODE environment
variable and rerun the test.
Please specify the sequence handling (ora: oracle, pg: postgresql):';
  $seq=<>; chomp $seq;
  return $seq if $seq eq 'pg' || $seq eq 'ora';
  print '
You specified an illegal value. Please rerun the tests!
';
  return undef;
};

########## Test 3: Creating tables
$skip_db_tests ? skip(1,1,1) : ok(&createdb, 1);

sub createdb {
  {
  local $SIG{__WARN__} = sub { };
  eval { $db->sql("drop table tmap_test_user"); };
  $db->{dbh}->commit; # If error occures, ignoring it;
  eval { $db->sql("drop table tmap_test_company"); };
  $db->{dbh}->commit; # If error occures, ignoring it;
  eval { $db->sql("drop sequence tmap_test_u_seq"); };
  $db->{dbh}->commit; # If error occures, ignoring it;
  eval { $db->sql("drop sequence tmap_test_c_seq"); };
  $db->{dbh}->commit; # If error occures, ignoring it;
  }
  $db->sql("create sequence tmap_test_u_seq");
  $db->sql("create sequence tmap_test_c_seq");
  my $seq1= $db->{seq_mode} eq 'pg' ? "nextval('" : "";
  my $seq2= $db->{seq_mode} eq 'pg' ? "')"        : ".nextval";
  $db->sql("create table tmap_test_company (
    id              int primary key default ".$seq1."tmap_test_c_seq".$seq2.",
    name            varchar(128)
  )");
  $db->{dbh}->commit;
  $db->sql("create table tmap_test_user (
    id              int not null default ".$seq1."tmap_test_u_seq".$seq2.",
    company_id      int not null references tmap_test_company (id),
    name            varchar(128)
  )");
  $db->{dbh}->commit;
  return 1;
};

########## Test 4: Creating Tie::Table objects;
$skip_db_tests ? skip(1,1,1) : ok(&create_Tie::Table, 1);

my ($user,$company);
sub create_Tie::Table {
  $company=$db->new_table(
    table => "tmap_test_company",
    key   => "id",
    seq   => "tmap_test_c_seq",
  );
  $user=$db->new_table(
    table => "tmap_test_user",
    key   => "id",
    seq   => "tmap_test_u_seq",
    "ref" => { company_id => [ $company, "users" ] }
  );
  $db->{dbh}->commit;
  return 1;
};

########## Test 5: Filling tables with Tie::Table objects
my ($zerou,$zeroc);
$skip_db_tests ? skip(1,1,1) : ok(&filldb, 1);

sub filldb {
  $zeroc=$company->insert( { name => "First Company" } );
  return 0 if $company->insert ( { name => "Second Company" } ) != $zeroc+1;
  return 0 if $company->insert ( { name => "Third Company" } ) != $zeroc+2;
  $zerou=$user->insert( { 
    name => "First User",
    company_id => $zeroc
  } );
  return 0 if $user->insert( {
    name => "Second User",
    company_id => $zeroc,
  } ) != $zerou+1;
  for my $i (0..5) {
    $company->{ $zeroc+int($i/2) }->users->insert( { name => "Test User: $i" } );
  };
  return 1;
};

########## Test 6: Querying the user names
$skip_db_tests ? skip(1,1,1) : ok(&querynames,1);

sub querynames {
  my $cnames=["First Company","Second Company","Third Company"];
  my @k=sort { $a <=> $b } keys %$company;
  for my $i (@k) {
    return 0 if shift(@$cnames) ne $company->{$i}->{name};
  };
  my $unames=["First User","Second User",
    "Test User: 0", "Test User: 1", "Test User: 2",
    "Test User: 3", "Test User: 4", "Test User: 5"];
  @k=sort { $a <=> $b } keys %$user;
  for my $i (@k) {
    return 0 if shift (@$unames) ne $user->{$i}->{name};
  };
  return 1;
};

########## Test 7: Querying the ID-s of the user-ids in one company
$skip_db_tests ? skip(1,1,1) : ok(&query_ids, 1);

sub query_ids {
  my $ids=[ [ 0,1,2,3 ],[4,5],[6,7] ];
  for (my $cid=0; $cid<@$ids; $cid++) {
    my $ciid=$ids->[$cid];
    for my $uid (@$ciid) {
      return 0 if !exists $company->{$zeroc+$cid}->users->{$zerou+$uid};
    };
  };
  return 1;
};

########## Test 8: Querying the companies for each user;
$skip_db_tests ? skip(1,1,1) : ok(&query_company, 1);

sub query_company {
  my $ids=[0,0,0,0,1,1,2,2];
  my @k=sort { $a <=> $b } keys %$user;
  foreach my $i (@k) {
    return 0 if shift(@$ids)+$zeroc != $user->{$i}->company_id->{id};
  };
  return 1;
};

########## Test 9: Select test
$skip_db_tests ? skip(1,1,1) : ok(&select, join(" ",$zerou+1..$zerou+7));

sub select {
  return join(" ",keys %{ $user->select("id>$zerou") });
};

########## Test 10: Modification test
$skip_db_tests ? skip(1,1,1) : ok(&modify_test, "QQQEEE");

sub modify_test {
  my $user5=$user->{$zerou+4};
  $user5->{name}="QQQEEE";
  $user5->write;
  $db->{dbh}->commit;
  return $user->{$zerou+4}->{name};
};

########## Test 11: Delete test
$skip_db_tests ? skip(1,1,1) : ok (&delete_test,join(" ",grep { $_ != $zerou + 1 } $zerou..$zerou+7 ));

sub delete_test {
  delete $user->{$zerou+1};
  $db->{dbh}->commit;
  return join(" ",sort { $a <=> $b } keys  %$user);
};

########## Test 12: Cleanup

$skip_db_tests ? skip(1,1,1) : ok (&cleanup,1);

sub cleanup {
  local $SIG{__WARN__} = sub { };
  $db->sql("drop table tmap_test_company");
  $db->sql("drop table tmap_test_user");
  $db->sql("drop sequence tmap_test_u_seq");
  $db->sql("drop sequence tmap_test_c_seq");
  $db->{dbh}->commit;
  return 1;
};
