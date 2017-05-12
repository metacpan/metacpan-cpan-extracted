#!/usr/bin/env perl

# Twitter::API - OAuth desktop app example
#
use 5.14.1;
use warnings;
use Data::Dumper;
use Twitter::API;

# You can replace the consumer key/secret with your own.  These credentials are
# for the Net::Twitter example app.
my $client = Twitter::API->new_with_traits(
    traits          => 'Enchilada',
    # Net::Twitter example app credentials
    map(tr/A-Za-z/N-ZA-Mn-za-m/r, qw/
        pbafhzre_xrl i8g3WVYxFglyotakTYBD
        pbafhzre_frperg 5e31eFZp0ACgOcUpX8ZiaPYt2bNlSYk5rTBZxKZ
    /),
    # To use your own:
    # consumer_key    => 'your-app-key',
    # consumer_secret => 'your-app-secret',
);

# 1. First, we get a request token and secret:
my $request = $client->oauth_request_token;

# 2. We use the request token to generate an authorization URL:
my $auth_url = $client->oauth_authorization_url({
    oauth_token => $request->{oauth_token},
});

# 3. Authorize the app in a web browser to get a verifier PIN:
print "
Authorize this application at: $auth_url
Then, enter the returned PIN number displayed in the browser: ";

# 4. Enter the PIN
my $pin = <STDIN>; # wait for input
chomp $pin;
say '';

# 5. Exchange the request token for an access token
my $access = $client->oauth_access_token({
    token        => $request->{oauth_token},
    token_secret => $request->{oauth_token_secret},
    verifier     => $pin,
});

my ( $token, $secret ) = @{$access}{qw(oauth_token oauth_token_secret)};

# Now you have user credentials
say 'access_token.......: ', $token;
say 'access_token_secret: ', $secret;

my $status = $client->user_timeline({
    count         => 1,
    -token        => $token,
    -token_secret => $secret,
});
say Dumper $status;
