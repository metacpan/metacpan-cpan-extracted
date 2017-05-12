use Test::More tests => 4;

use WebService::Windows::LiveID::Auth;

my $appid = '00163FFF80003203';
my $secret_key = 'ApplicationKey123';

{
    my $auth = eval {
        WebService::Windows::LiveID::Auth->new;
    };
    ok(!$auth);
    like($@, qr/required parameter/);
}

{
    my $auth = eval {
        WebService::Windows::LiveID::Auth->new({
            appid => $appid,
            secret_key => $secret_key
        });
    };
    ok($auth);
    is($auth->appid, $appid);
}
