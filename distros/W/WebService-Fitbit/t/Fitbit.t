use strict;
use warnings;

use Devel::Confess;
use Path::Tiny qw( path );
use Test::RequiresInternet ( 'api.fitbit.com' => 443 );
use Test2::Bundle::Extended;
use Test2::Compare qw( compare );
use WWW::Mechanize;
use WebService::Fitbit ();

my $ua;

if ( $ENV{DEBUG_FITBIT} ) {
    require LWP::ConsoleLogger::Easy;
    $ua = WWW::Mechanize->new( autocheck => 0 );
    LWP::ConsoleLogger::Easy::debug_ua($ua);
}

{
    my $fitbit = WebService::Fitbit->new(
        access_token  => 'qux',
        app_key       => 'foo',
        app_secret    => 'bar',
        refresh_token => 'baz',
        $ua ? ( ua => $ua ) : (),
    );

    ok( $fitbit,                               'create object' );
    ok( !$fitbit->has_access_token_expiration, 'no expiration by default' );

    #like(
    #dies { $fitbit->get('/1/user/-/profile.json') },
    #qr{Cannot refresh token}i,
    #'exception on bad auth'
    #);
}

my $filename = 'credentials.conf';
my $config   = get_config();

# cp credentials.conf.sample credentials.conf
#
# to enable testing with credentials

SKIP: {
    skip "$filename not found", 1, unless $config;
    ok( 'placeholder', 'placeholder test' );

    my $fitbit
        = WebService::Fitbit->new( %{$config}, $ua ? ( ua => $ua ) : (), );
    my $me = $fitbit->get('/1/user/-/profile.json');
    ok( $me->success,                     'success' );
    ok( $me->content->{user}->{fullName}, 'response includes fullName' );

    my $activities
        = $fitbit->get('/1/user/-/activities/date/2017-02-15.json');
}

sub get_config {
    my $file = path($filename);
    return undef unless $file->exists;
    my $contents = $file->slurp;
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    return eval $contents || die $!;
}

done_testing;
