#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;

use WWW::Foursquare::Request;
use WWW::Foursquare::Config;

my $user_id      = 732223;
my $access_token = 'access_token';

my $request = WWW::Foursquare::Request->new({
    access_token => $access_token,
});

diag('Testing request');

# send GET request
my $path   = 'users';
my $params = { 
    email        => 'paul.vlasov@gmail.com',
    search       => 'улан-удэ',
    show_request => 1,
};

my $email_escape  = 'paul.vlasov%40gmail.com';
my $search_escape = '%D1%83%D0%BB%D0%B0%D0%BD-%D1%83%D0%B4%D1%8D';
my $get_result    = sprintf "%susers?email=%s&oauth_token=access_token&search=%s&v=%s", $API_ENDPOINT, $email_escape, $search_escape, $API_VERSION;

my $get_test_result = $request->GET($path, $params);
ok($get_result eq $get_test_result, 'GET request generate right url');

# send POST request
$params->{show_request} = 1;
my $post_result      = sprintf "%susers?oauth_token=access_token&v=%s", $API_ENDPOINT, $API_VERSION;
my $post_test_result = $request->POST($path, $params);
ok($post_result eq $post_test_result, 'POST request generate right url');

# send MULTI request
my @multi_urls   = qw(badges friends lists mayorships checkins); 
my $multi_result = 'https://api.foursquare.com/v2/multi?oauth_token=access_token&requests=%2Fusers%2FUSER_ID%2Fbadges%2C%2Fusers%2FUSER_ID%2Ffriends%2C%2Fusers%2FUSER_ID%2Flists%2C%2Fusers%2FUSER_ID%2Fmayorships%2C%2Fusers%2FUSER_ID%2Fcheckins&v=20120915';

for (my $i = 0; $i < scalar(@multi_urls); $i++) {

    my $path = sprintf "users/USER_ID/%s", $multi_urls[$i];
    my $desc       = sprintf "put '%s' to queue", $path;
    my $multi_test_result = $request->GET($path, { multi => 1, show_request => 1 });

    if ($i < scalar(@multi_urls) - 1) {

        my $cur_number = $i + 1;
        ok($cur_number == $multi_test_result, $desc);
    }
    else {

        $desc .= ' and send MULTI request';
        ok($multi_result eq $multi_test_result, $desc);
    }
}
