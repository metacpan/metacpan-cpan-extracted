use Test::Tester;
use Test::More qw(no_plan);

BEGIN {
use_ok( 'Test::Net::Connect' );
use_ok( 'Test::Net::Connect::ConfigData' );
}

my %good_parms = ( host => Test::Net::Connect::ConfigData->config('good_host'),
		   port => Test::Net::Connect::ConfigData->config('good_port'),
		   proto => 'tcp' );

my %bad_parms = ( host => Test::Net::Connect::ConfigData->config('bad_host'),
		  port => Test::Net::Connect::ConfigData->config('bad_port'),
		  proto => 'tcp' );

my $v = { %good_parms };

check_test(sub { connect_ok( $v, "Check host:port from user"); },
	   { ok => 1, name => "Check host:port from user",
	     diag => '', },
	   "Basic call with all arguments succeeds");

$v = { %good_parms };
delete $v->{proto};

check_test(sub { connect_ok( $v, "Check host:port from user"); },
	   { ok => 1, name => "Check host:port from user",
	     diag => '', },
	   "Basic call with default proto arguments succeeds");

$v = { %good_parms };
delete $v->{proto};
$v->{host} .= ':' . $v->{port};
delete $v->{port};

check_test(sub { connect_ok( $v, "Check host:port from user"); },
	   { ok => 1, name => "Check host:port from user", },
	   "Basic call with default proto and host:port form succeeds");

$v = { %good_parms };

check_test(sub { connect_ok( $v ); },
	   { ok => 1, name => "Connecting to $v->{proto}://$v->{host}:$v->{port}" },
	   "Basic call with no test name succeeds");

# -- using an IP address:port

$v = { host => Test::Net::Connect::ConfigData->config('good_ip')};

check_test(sub { connect_ok( $v, "Check host:port from user"); },
	   { ok => 1, name => "Check host:port from user", },
	   "Basic call with IP address succeeds");

$v = { %bad_parms };

check_test(sub { connect_not_ok($v, "Check badhost:badport from user"); },
	   { ok => 1, name => 'Check badhost:badport from user',
	     diag => '', },
	   "Basic call succeeds");

$v = { %bad_parms };

check_test(sub { connect_not_ok($v); },
	   { ok => 1, name => 'Connecting to tcp://localhost:23',
	     diag => '', },
	   "Basic call with no test name succeeds");

# Things that should fail

# Failing because the params are wrong

foreach my $sub (qw(connect_ok connect_not_ok)) {
  no strict 'refs';

  check_test(sub { &$sub(); },
	     { ok => 0, name => "$sub()",
	       diag => "    $sub() called with no arguments" },
	     "$sub()");

  check_test(sub { &$sub('localhost'); },
	     { ok => 0, name => "$sub()",
	       diag => "    First argument to $sub() must be a hash ref"},
	     "$sub(SCALAR)");

  check_test(sub { &$sub('localhost', 'test name'); },
	     { ok => 0, name => 'test name',
	       diag => "    First argument to $sub() must be a hash ref"},
	     "$sub(SCALAR, SCALAR)");

  check_test(sub { &$sub({ port => 22 }); },
	     { ok => 0, name => "$sub()",
	       diag => "    $sub() called with no hostname"},
	     "$sub() with no host name");

  check_test(sub { &$sub({ host => undef }); },
	     { ok => 0, name => "$sub()",
	       diag => "    $sub() called with no hostname"},
	     "$sub() with undef host name");

  check_test(sub { &$sub({ host => '' }); },
	     { ok => 0, name => "$sub()",
	       diag => "    $sub() called with no hostname"},
	     "$sub() with undef host name");

  check_test(sub { &$sub({ host => '' }, 'test name'); },
	     { ok => 0, name => 'test name',
	       diag => "    $sub() called with no hostname"},
	     "$sub() with undef host name");
}

$v = { %good_parms };
delete $v->{port};
delete $v->{proto};

check_test(sub { connect_ok($v); },
	   { ok => 0, name => 'connect_ok()',
	     diag => '    connect_ok() called with no port' },
	   "connect_ok() with no port");

$v->{port} = '';

check_test(sub { connect_ok($v); },
	   { ok => 0, name => 'connect_ok()',
	     diag => '    connect_ok() called with no port' },
	   "connect_ok() with no port");

check_test(sub { connect_ok($v, 'test name'); },
	   { ok => 0, name => 'test name',
	     diag => '    connect_ok() called with no port' },
	   "connect_ok() with no port");

check_test(sub { connect_ok({ host => 'localhost', port => 25, foo => 'bar'} ); },
	   { ok => 0, name => 'Connecting to tcp://localhost:25',
	     diag => "    Invalid field 'foo' given" },
	   "connect_ok() with key 'foo'");

# Failing because the host is not reachable

$v = { %bad_parms };

check_test(sub { connect_ok($v, "Connect with a bad host"); },
	   { ok => 0, name => "Connect with a bad host", },
	   "Connecting to a bad host");

# Failing because the host does not exist

$v = { %good_parms };

$v->{host} = 'foo.invalid';

check_test(sub { connect_ok($v, "Connect with a bad host"); },
	   { ok => 0, name => "Connect with a bad host", 
	   diag => '    DNS lookup for \'foo.invalid\' failed'},
	   "Connecting to a non-existent host");

$v = { %good_parms };

$v->{host} = 'foo.invalid';

check_test(sub { connect_not_ok($v, "Connect with a bad host"); },
	   { ok => 0, name => "Connect with a bad host", 
	   diag => '    DNS lookup for \'foo.invalid\' failed'},
	   "Connecting to a non-existent host");

# Failing because the host is reachable

$v = { %good_parms };

check_test(sub { connect_not_ok( $v, "Check host:port from user"); },
	   { ok => 0, name => "Check host:port from user",
	     diag => '    Connection to tcp://127.0.0.1:22 succeeded', },
	   "Connecting to a good host:port fails");
