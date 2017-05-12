use Test::More tests => 2;

use URI;
use URI::QueryParam;
use URI::Escape ();
use WebService::Windows::LiveID::Auth;

my $appid = '00163FFF80003203';
my $secret_key = 'ApplicationKey123';
my $appctx = 'zigorou';

my $sign_in_url = URI->new('http://login.live.com/wlogin.srf');

my $auth = WebService::Windows::LiveID::Auth->new({
    appid => $appid,
    secret_key => $secret_key
});

my %query = (
    appid => $auth->appid,
    alg => $auth->algorithm,
    appctx => $appctx
);

{
    my $sign_in_url_clone = $sign_in_url->clone;
    $sign_in_url_clone->query_param($_, $query{$_}) for (qw/appid alg/);
    is($auth->sign_in_url()->as_string, $sign_in_url_clone->as_string);
}

{
    my $sign_in_url_clone = $sign_in_url->clone;
    $sign_in_url_clone->query_param($_, $query{$_}) for (qw/appid alg appctx/);
    is($auth->sign_in_url({ appctx => $appctx })->as_string, $sign_in_url_clone->as_string);
}
