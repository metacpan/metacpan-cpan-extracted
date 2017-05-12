use Test::More tests => 4;

use URI;
use URI::QueryParam;
use URI::Escape ();
use WebService::Windows::LiveID::Auth;

my $appid = '00163FFF80003203';
my $secret_key = 'ApplicationKey123';
my $appctx = 'zigorou';
my $style = {
    "font-family" => "Courier",
    "font-weight" => "bold",
    "font-style" => "italic",
    "font-size" => "x-small",
    "color" => "white",
    "background" => "#F7F7FF"
};
my $style_string = "font-family: Courier; font-weight: bold; font-style: italic; font-size: x-small; color: white; background: #F7F7FF;";
my $control_url = URI->new('http://login.live.com/controls/WebAuth.htm');

my $auth = WebService::Windows::LiveID::Auth->new({
    appid => $appid,
    secret_key => $secret_key
});

my %query = (
    appid => $auth->appid,
    alg => $auth->algorithm,
    appctx => $appctx,
    style => $style_string
);

{
    my $control_url_clone = $control_url->clone;
    $control_url_clone->query_param($_, $query{$_}) for (qw/appid alg/);
    is($auth->control_url()->as_string, $control_url_clone->as_string);
}

{
    my $control_url_clone = $control_url->clone;
    $control_url_clone->query_param($_, $query{$_}) for (qw/appid alg appctx/);
    is($auth->control_url({ appctx => $appctx })->as_string, $control_url_clone->as_string);
}

{
    my $control_url_clone = $control_url->clone;
    $control_url_clone->query_param($_, $query{$_}) for (qw/appid alg appctx style/);
    is($auth->control_url({ appctx => $appctx, style => $style_string })->as_string, $control_url_clone->as_string);
}

{
    my $control_url_clone = $control_url->clone;
    $control_url_clone->query_param($_, $query{$_}) for (qw/appid alg appctx style/);
    is($auth->control_url({ appctx => $appctx, style => $style })->as_string, $control_url_clone->as_string);
}
