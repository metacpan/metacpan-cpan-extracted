use v5.10;

use lib './lib';

use WebService::FogBugz::XML;
my $fb = WebService::FogBugz::XML->new();

use Test::More;
if ($ENV{AUTOMATED_TESTING} && !-e $fb->config_filename){
    plan skip_all => "No fogbugz config file, and no user to provide config";
}
else {
    plan tests => 2;
}

# See if they work!

ok($fb, 'Got FB object');
ok($fb->token, 'Returns valid token '.$fb->token);
