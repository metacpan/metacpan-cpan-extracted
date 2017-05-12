#!perl -T

use Test::More;

my $api_key    = $ENV{API_KEY};
my $api_secret = $ENV{API_SECRET};

plan skip_all => "API_USER_IDENTIFIERS must be set to run this test (and appropriate permissions set for your API key)"
    unless $ENV{API_USER_IDENTIFIERS};

plan skip_all => "API_KEY and API_SECRET environment variables must be set"
    unless $api_key and $api_secret;

plan tests => 8;

use_ok( 'YellowBot::API' );

ok(my $api = YellowBot::API->new
   (api_key    => $api_key,
    api_secret => $api_secret,
   ), 'new');

$api->server($ENV{API_SERVER} || 'http://www.yellowbot.com/');

ok(my $data = $api->call('thumbs/down', location => 968305,
      api_user_identifier => 'abc123',
  ), 'set thumbs');
is($data->{thumb}, 'down', 'thumb was set down');
is($data->{location}, 968305, 'id was returned');

ok( $data = $api->call(
        'thumbs/up',
        location            => '/solfo-burbank-ca.html',
        api_user_identifier => 'abc124',
    ),
    'set thumbs'
);
is($data->{thumb}, 'up', 'thumb was set up');
is($data->{location}, '/solfo-burbank-ca.html', 'location uid was returned');

#use Data::Dump qw(pp);
#pp($response);
