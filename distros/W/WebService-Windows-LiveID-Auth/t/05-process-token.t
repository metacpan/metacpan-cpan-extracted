use Test::More tests => 4;

use URI;
use URI::QueryParam;
use URI::Escape ();
use WebService::Windows::LiveID::Auth;

my $appid = '00163FFF80003203';
my $secret_key = 'ApplicationKey123';
my $appctx = 'zigorou';
my $stoken = 'mYMCElEhcsYZgJAoRJTImlVOV39auyRXg%2FEthTKfJalcsAj3U12SoBQ%2BPBuqZLowfcnP5XsZW%2FGFvwmfo7UrHDFO9orCTc5TpHdyOf%2FqTzOP6usYyLi%2BMyoWpX5aVgTJ3eEqbxsPt2xEl8e1xw3uSn8nyO62zSF3MbHXp3yJ70Bnipg19fqHXiOwsYF6UjOa';
my $uid = "9c734ede6b08e7eaeac50a0fcab5445f";

my $auth = WebService::Windows::LiveID::Auth->new({
    appid => $appid,
    secret_key => $secret_key
});

{
    my $user = eval { $auth->process_token(join("", reverse split(//, $stoken)), $appctx); };
    ok(!$user);
    like($@, qr/Invalid stoken/);
}

{
    my $user = eval { $auth->process_token($stoken, $appctx); };
    ok($user);
    is($user->uid, $uid);
}
