use strict;
use warnings;

use Devel::Confess;
use Path::Tiny qw( path );
use Test::RequiresInternet (
    'oauth.reddit.com' => 443,
    'www.reddit.com'   => 443,
);
use Test2::Bundle::Extended;
use Test2::Compare qw( compare );
use WWW::Mechanize;
use WebService::Reddit ();

my $ua;

if ( $ENV{DEBUG_REDDIT} ) {
    require LWP::ConsoleLogger::Easy;
    $ua = WWW::Mechanize->new( autocheck => 0 );
    LWP::ConsoleLogger::Easy::debug_ua($ua);
}

{
    my $reddit = WebService::Reddit->new(
        access_token  => 'qux',
        app_key       => 'foo',
        app_secret    => 'bar',
        refresh_token => 'baz',
        $ua ? ( ua => $ua ) : (),
    );

    ok( $reddit,                               'create object' );
    ok( !$reddit->has_access_token_expiration, 'no expiration by default' );

    like(
        dies { $reddit->get('/api/v1/me') },
        qr{Cannot refresh token}i,
        'exception on bad auth'
    );
}

my $filename = 'credentials.conf';
my $config   = get_config();

# cp credentials.conf.sample credentials.conf
#
# to enable testing with credentials

SKIP: {
    skip "$filename not found", 1, unless $config;
    ok( 'placeholder', 'placeholder test' );
    my $reddit
        = WebService::Reddit->new( %{$config}, $ua ? ( ua => $ua ) : (), );
    my $me = $reddit->get('/api/v1/me');
    ok( $me->success,               'success' );
    ok( $me->content->{link_karma}, 'response includes link_karma' );
    ok( $reddit->has_access_token_expiration, 'expiration predicate' );
    ok( $reddit->has_access_token_expiration, 'expiration' );

    my $perly_bot = $reddit->get('/user/_perly_bot/about');
    ok( $perly_bot->content->{data}->{link_karma}, '_perly_bot link karma' );

    my $latest = $reddit->get( '/r/perl/new', { limit => 3 } );
    is( @{ $latest->content->{data}->{children} }, 3, 'limit applied' );

    my $post = $reddit->post(
        '/api/search_reddit_names',
        { exact => 1, query => 'perl' }
    );
    is( $post->content, { names => ['perl'] }, 'search_reddit_names' );

    my $delete = $reddit->delete(
        '/api/v1/me/friends/someusernamethathopefullydoesnotexist!!!',
        { id => 'asdf2897???!####' }
    );
    is(
        $delete->content->{reason}, 'USER_DOESNT_EXIST',
        'user does not exist'
    );
}

sub get_config {
    my $file = path($filename);
    return undef unless $file->exists;
    my $contents = $file->slurp;
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    return eval $contents || die $!;
}

done_testing;
