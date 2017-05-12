# Handle things that each test script will have to do.

=head1 NAME

TestConfig - Set up for WWW::Myspace dist tests

=head1 SYNOPSIS

 use lib 't';
 use TestConfig;

 $CONFIG->{'acct1'}->{'myspace'}->method;

TestConfig exports a single variable (a hashref), "$CONFIG".
$CONFIG is loaded from t/config.yaml, then for "acct1" and
"acct2", a "myspace" item is added by doing this:
 $CONFIG->{'acct1'}->{'myspace'} = new WWW::Myspace(
    $CONFIG->{'acct1'}->{'username'},
    $CONFIG->{'acct1'}->{'password'} );
 $CONFIG->{'acct2'}->{'myspace'} = new WWW::Myspace(
    $CONFIG->{'acct2'}->{'username'},
    $CONFIG->{'acct2'}->{'password'} );

See config.yaml for layout and all values of $CONFIG.

=head1 AUTHOR

Grant Grueninger, grantg <at> cpan.org

=cut

package TestConfig;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( $CONFIG login_myspace );

#warn "Loading WWW::Myspace\n";
use WWW::Myspace;
use YAML qw'LoadFile Dump';
use File::Spec::Functions;

# See if there's a config file so we can test login-specific features
our $CONFIG = _read_config();

# This is our exported login routine.
sub login_myspace {

	# If we're not supposed to log in, setup new objects and return true.
	if ( ! $CONFIG->{login} ) {
		$CONFIG->{acct1}->{myspace} = new WWW::Myspace( auto_login=>0 );
		$CONFIG->{acct2}->{myspace} = new WWW::Myspace( auto_login=>0 );
		return 1;
	}

#	warn "Logging into " . $CONFIG->{'acct1'}->{'username'} . "\n";

	_login( $CONFIG->{acct1} );
	_login( $CONFIG->{acct2} );
	
#	$CONFIG->{'acct1'}->{'myspace'} = new WWW::Myspace( $CONFIG->{'acct1'}->{'username'},
#	$CONFIG->{'acct1'}->{'password'} );
#	if ( $CONFIG->{'acct1'}->{'myspace'}->error ) {
#		warn $CONFIG->{'acct1'}->{'myspace'}->error
#	}
	
#	warn "Logging into " . $CONFIG->{'acct2'}->{'username'} . "\n";
#	$CONFIG->{'acct2'}->{'myspace'} = new
#		WWW::Myspace( $CONFIG->{'acct2'}->{'username'},
#					  $CONFIG->{'acct2'}->{'password'}
#					);
#	if ( $CONFIG->{'acct2'}->{'myspace'}->error ) {
#		warn $CONFIG->{'acct2'}->{'myspace'}->error
#	}

	if ( $CONFIG->{'acct1'}->{'myspace'}->{'logged_in'} &&
		 $CONFIG->{'acct2'}->{'myspace'}->{'logged_in'} ) {
		return 1;
	} else {
		return 0;
	}
}

# Set up the configuration.
# If there's a test_config file in the user's myspace cache dir, use
# it to run full tests.  Otherwise run the basic tests using the
# basic config included with the distribution.
sub _read_config {
	my $myspace = new WWW::Myspace( auto_login => 0, human => 0 );
	my $login = 1;
	my $config = "";
	my $configfile = catfile( $myspace->cache_dir, 'test_config.yaml' );

	# If there's a local config file, and we're not supposed to
	# ignore it (presence of "eu" file means run as an end-user),
	# read the local config file. Otherwise, read the generic one
	# in the distribution.
	if ( ( -f $configfile ) && ( ! -f "eu" ) ) {
		$config = LoadFile( $configfile );
		$config->{login} = 1;
	} else {
		$configfile = catfile( 't', 'config.yaml' );
		$config = LoadFile( $configfile );
		$config->{login} = 0 ;
	}

	return $config
}

# Log into the passed account
sub _login {
	my ( $acct ) = @_;

	# Log in and set the myspace object.
	$acct->{myspace} = new WWW::Myspace( $acct->{username}, $acct->{password} );

	# Spout a warning if there was a problem
	if ( $acct->{'myspace'}->error ) { warn $acct->{'myspace'}->error }

}
1;
