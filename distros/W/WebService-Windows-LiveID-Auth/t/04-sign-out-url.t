use Test::More tests => 1;

use URI;
use URI::QueryParam;
use URI::Escape ();
use WebService::Windows::LiveID::Auth;

my $appid = '00163FFF80003203';
my $secret_key = 'ApplicationKey123';
my $appctx = 'zigorou';

my $sign_out_url = URI->new('http://login.live.com/logout.srf');

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
    my $sign_out_url_clone = $sign_out_url->clone;
    $sign_out_url_clone->query_param($_, $query{$_}) for (qw/appid/);
    is($auth->sign_out_url()->as_string, $sign_out_url_clone->as_string);
}
