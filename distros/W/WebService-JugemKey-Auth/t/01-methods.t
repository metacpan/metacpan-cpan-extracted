#!perl -T
use strict;
use warnings;
use Test::More tests => 16;
use WebService::JugemKey::Auth;
use URI::QueryParam;
use XML::Atom::Entry;

my $api = WebService::JugemKey::Auth->new({
    api_key => 'test',
    secret  => 'hoge',
});

is 'b781fcdbc80db33ad5f35e403bd8758aed595fa7', $api->api_sig({ api_key => 'test' });
is 'secure.jugemkey.jp', $api->uri_to_login->host;
is 'b781fcdbc80db33ad5f35e403bd8758aed595fa7', $api->uri_to_login->query_param('api_sig');
is '93e72791cb8ab8c53793db75be469ea99a0fdb97', $api->uri_to_login({
    callback_url => 'http://jugemkey.jp/'
})->query_param('api_sig');
is 'http://jugemkey.jp/?param2=value2&param1=value1', $api->uri_to_login({
    callback_url => 'http://jugemkey.jp/',
    param1       => 'value1',
    param2       => 'value2',
})->query_param('callback_url');
is 'b41708303d6bcfb9ddb6a68829fec688b942ff8a', $api->uri_to_login({
    callback_url => 'http://jugemkey.jp/',
    param1       => 'value1',
    param2       => 'value2',
})->query_param('api_sig');
isa_ok $api->ua, 'LWP::UserAgent';

ok not $api->get_token('invalidfrob');
like $api->errstr, qr/Invalid X-JUGEMKEY-API-KEY/;

{
    # hacking for testing
    no warnings;

    *HTTP::Response::code = sub {
        return 200;
    };

    my $xml =<<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<entry xmlns="http://purl.org/atom/ns#" xmlns:auth="http://paperboy.co.jp/atom/auth#">
  <title xmlns="http://purl.org/atom/ns#">miyashita</title>
  <auth:token xmlns="http://purl.org/atom/ns#">93e72791cb8ab8c5</auth:token>
</entry>
EOF

    my $entry = XML::Atom::Entry->new(Stream => \$xml);
    *XML::Atom::Entry::new = sub {
        return $entry;
    };
}

my $user = $api->get_token('dummy_frob');
ok ref($user);
is ref($user), 'WebService::JugemKey::Auth::User';
is $user->name, 'miyashita';
is $user->token, '93e72791cb8ab8c5';

$user = $api->get_user('dummy_token');
ok ref($user);
is ref($user), 'WebService::JugemKey::Auth::User';
is $user->name, 'miyashita';

1;
