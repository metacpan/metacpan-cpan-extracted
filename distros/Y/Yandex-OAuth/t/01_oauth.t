use strict;
use Test::More 0.98;
use JSON::XS;

use_ok('Yandex::OAuth');

my $oauth = Yandex::OAuth->new(
        client_id     => '76df1cffb31d0289',
        client_secret => 'e3a28554de3c2afc',
    );

is( $oauth->get_code(), 'https://oauth.yandex.ru/authorize?response_type=code&client_id=76df1cffb31d0289', 
    'get_code' );

is( $oauth->get_code(state => 'a28554df'), 'https://oauth.yandex.ru/authorize?response_type=code&client_id=76df1cffb31d0289&state=a28554df', 
    'get_code with state' );

my $answer = '{"token_type": "bearer", "access_token": "e93d2da298624260a848438f1d11ed07", "expires_in": 31536000}';

my $oauth = Yandex::OAuth->new(
        client_id     => '76df1cffb31d0289',
        client_secret => 'e3a28554de3c2afc',
        demo          => $answer,
    );

is_deeply( $oauth->get_token(), JSON::XS->new->decode($answer), 'get_token' );



done_testing;

