use strict;
use warnings;

use WebService::Dropbox::TokenFromOAuth1;

my $key = shift;
my $secret = shift;
my $oauth1_access_token = shift;
my $oauth1_access_secret = shift;

my $oauth2_access_token = WebService::Dropbox::TokenFromOAuth1->token_from_oauth1({
    consumer_key    => $key,
    consumer_secret => $secret,
    access_token    => $oauth1_access_token,
    access_secret   => $oauth1_access_secret,
});

warn $oauth2_access_token;
