use Test::More;
use Test::MockObject;
use Test::LWP::UserAgent;
use Data::Dumper;
use WWW::Xunlei;

my $client = WWW::Xunlei->new( 'zshengli@cpan.org', 'matrix' );
ok( defined $client && ref $client eq 'WWW::Xunlei', "WWW::Xunlei Use OK" );

$client->{'ua'} = Test::LWP::UserAgent->new();
$client->{'ua'}->cookie_jar( { ignore_discard => 0 } );
$client->{'ua'}->agent($WWW::Xunlei::DEFAULT_USER_AGENT);

my $check_response = HTTP::Response->new(
    '200', 'OK',
    [   'Content-Type' => 'text/html; charset=utf-8',
        'Set-Cookie'   => 'check_result=0:!fQs; PATH=/; DOMAIN=xunlei.com;',
        'Set-Cookie'   => 'deviceid='
            . 'wdi10.96f8fefa547b7e74b9e4516bc7ce7d107ce9aadde044108955d4f1a6a79aaf97;'
            . ' PATH=/; DOMAIN=xunlei.com;EXPIRES=Mon, 27-Oct-25 02:09:57 GMT;',
    ],
    ''
);

$client->{'ua'}->map_response(
    qr{login.xunlei.com/check},
    $check_response,
);


is( $client->_get_verify_code(), '!fQs', 'Get Verify Code OK' );

done_testing();
