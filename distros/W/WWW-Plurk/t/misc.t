use strict;
use warnings;
use Test::More tests => 12;
use WWW::Plurk;

my %URIS = (
    login     => 'http://www.plurk.com/Users/login?redirect_page=main',
    add_plurk => 'http://www.plurk.com/TimeLine/addPlurk',
    notifications => 'http://www.plurk.com/Notifications',
    accept_friend => 'http://www.plurk.com/Notifications/allow',
    deny_friend   => 'http://www.plurk.com/Notifications/deny',
    get_friends   => 'http://www.plurk.com/Users/getFriends',
    get_plurks    => 'http://www.plurk.com/TimeLine/getPlurks',
    add_response  => 'http://www.plurk.com/Responses/add',
    get_responses => 'http://www.plurk.com/Responses/get2',
    get_unread_plurks =>
      'http://www.plurk.com/TimeLine/getUnreadPlurks',
    get_completion => 'http://www.plurk.com/Users/getCompletion',
);

my $plurk = WWW::Plurk->new;

while ( my ( $key, $uri ) = each %URIS ) {
    is $plurk->_uri_for( $key ), $uri, "uri for $key";
}

is_deeply $plurk->_decode_json(
    q{[ new Date("Sun, 05 Apr 1964 00:00:00 GMT"), "\"Q\"" ]} ),
  [ -181180800, '"Q"' ],
  'json';
