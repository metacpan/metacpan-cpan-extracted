#!perl 

use Test::More tests => 19;
use Test::Exception;
use Data::Dumper qw( Dumper );

BEGIN {
    use_ok( 'WWW::DirectAdmin::API' ) || print "Bail out!\n";
}

my %live_test = load_test_from_env();
my $is_admin_test = 0;

$ENV{DA_TEST_LIVE} = 1;

my $skip_msg = <<'END_MSG';
To run live tests please set the following ENV values: 
   $ENV{'DA_TEST_HOSTNAME'} - server to connect to
   $ENV{'DA_TEST_PORT'}     - port to use (optional)
   $ENV{'DA_TEST_USERNAME'} - username 
   $ENV{'DA_TEST_PASSWORD'} - password
   $ENV{'DA_TEST_DOMAIN'}   - domain for user tests 
   $ENV{'DA_LIVE_TEST'}     - true to run create and delete tests 
END_MSG

diag $skip_msg unless $ENV{DA_LIVE_TEST};

# add SKIP unless those are there
SKIP: {
    skip "Not setup for live test", 6
        unless $ENV{DA_LIVE_TEST};

    my $da;

    lives_ok {
        $da = WWW::DirectAdmin::API->new( %live_test );
    } 'live test new';
  
    # need different user for both of these tests 
    if ( $is_admin_test ) {
        skip 'Not admin test', 1;
        lives_ok { $da->get_users; } 'get_users';
    }

    #
    # User API tests
    #
    
    # not sure about wrapping each in lives block
    my @domains = $da->get_domains;
    ok scalar( @domains ), 'get_domains';

    my @subdomains;
    lives_ok { @subdomains = $da->get_subdomains; } 'get_subdomains';
    cmp_ok scalar @subdomains, '>', 0, 'number of domains';

    my @dbs;

    lives_ok { @dbs = $da->get_databases; } 'get_databases';
    cmp_ok scalar @dbs, '>', 1, 'database counts';
}

# live tests

SKIP: {

   skip "Not setup for live test", 12 
        unless $ENV{DA_LIVE_TEST};

    lives_ok {
        $da = WWW::DirectAdmin::API->new( %live_test );
    } 'live test new';
 
   # constructive/destructive tests
    my $rc;
    throws_ok { $rc = $da->create_subdomain } 
        qr/Mandatory parameter 'subdomain' missing/, 'create_subdomain - bad param';

    # random-ish
    my $name = time();

    lives_ok { $rc = $da->create_subdomain( subdomain => $name ) } 'create subdomain';
    ok $rc, 'created rc';

    lives_ok { $rc = $da->delete_subdomain( subdomain => $name ) } 'delete subdomain';
    ok $rc, 'deleted rc';
    
    my $dbname = time;

    throws_ok {
        $rc = $da->create_database( 
            name   => $dbname, 
            user   => 'joe',
            passwd => 'joe',
            passwd2 => 'jofadse'
        );
    } qr/Response returned an error/, 'create_database (bad password)';

    ok defined $da->error->{details}, "details";
    
    skip "Missing details", 1
        unless defined $da->error->{details};

    like $da->error->{details}, qr/Passwords do not match/, 'detail contents';

    $rc = 0;

    lives_ok {
        $rc = $da->create_database( 
            name   => $dbname, 
            user   => 'joe',
            passwd => 'joe',
            passwd2 => 'joe'
        );
    } 'create_database';

    ok $rc, "create_database rc: $dbname";

    skip "Unable to delete db since not created", 1
        unless $rc; 

    # delete it now
    $rc = $da->delete_database( name => sprintf( "%s_%s", $live_test{username}, $dbname ) );
    ok $rc, "delete_database: $dbname";
}

# done
exit;

# helper sub
sub load_test_from_env {
    return ( 
        host   => $ENV{'DA_TEST_HOSTNAME'},
        ( exists $ENV{'DA_TEST_PORT'} ? ( port => $ENV{'DA_TEST_PORT'} ) : () ),
        user   => $ENV{'DA_TEST_USERNAME'},
        pass   => $ENV{'DA_TEST_PASSWORD'}, 
        domain => $ENV{'DA_TEST_DOMAIN'}
    );
}

exit;

