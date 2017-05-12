#!/usr/bin/perl

use Modern::Perl;

use Test::More tests => 11;
use HTTP::Daemon;
use HTTP::Status qw(:constants);
use HTTP::Response;
use URI::QueryParam;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/lib";
use T::OverDrive;

my $DEFAULT_LISTEN_TIMEOUT = 600; # secs

use_ok('WebService::ILS::OverDrive::Patron');

SKIP: {
    skip "Not testing OverDrive Granted (3-legged) auth API WEBSERVICE_ILS_TEST_OVERDRIVE_AUTH not set", 10
      unless $ENV{WEBSERVICE_ILS_TEST_OVERDRIVE_AUTH};

    my $od_id     = $ENV{OVERDRIVE_TEST_CLIENT_ID}
        or BAIL_OUT("Env OVERDRIVE_TEST_CLIENT_ID not set");
    my $od_secret = $ENV{OVERDRIVE_TEST_CLIENT_SECRET}
        or BAIL_OUT("Env OVERDRIVE_TEST_CLIENT_SECRET not set");
    my $od_library_id = $ENV{OVERDRIVE_TEST_LIBRARY_ID}
        or BAIL_OUT("Env OVERDRIVE_TEST_LIBRARY_ID not set");
    my $auth_url = $ENV{OVERDRIVE_TEST_AUTH_REDIRECT_URL}
        or BAIL_OUT("Env OVERDRIVE_TEST_AUTH_REDIRECT_URL not set");
    my $port = $ENV{OVERDRIVE_TEST_AUTH_LISTEN_PORT}
        or BAIL_OUT("Env OVERDRIVE_TEST_AUTH_LISTEN_PORT not set");
    my $listen_timeout = $ENV{OVERDRIVE_TEST_AUTH_LISTEN_TIMEOUT} || $DEFAULT_LISTEN_TIMEOUT;
    my $browser_command = $ENV{OVERDRIVE_TEST_AUTH_WEB_BROWSER_EXE};

    my $od = WebService::ILS::OverDrive::Patron->new({
        test => 1,
        client_id => $od_id,
        client_secret => $od_secret,
        library_id => $od_library_id,
    });

    my $od_url = $od->auth_url($auth_url);
    ok( $od_url, "Auth URL");

    diag("Will listen on port $port.");
    my $d = HTTP::Daemon->new(LocalPort => $port)
      or BAIL_OUT("Cannot listen on $port: $!");
    $d->timeout($listen_timeout);
    system(qq{$browser_command "$od_url" &}) if $browser_command;
    diag("Authenticate in your browser $od_url");
    diag('When authenticated, please push "Always allow" button');
    diag("You have $listen_timeout secs to do that...");
    my $code;
    my $c = $d->accept or BAIL_OUT("No redirect back request received: $!");
    if (my $req = $c->get_request("HEADERS_ONLY")) {
        my $uri = $req->uri;
        if ($code = $uri->query_param("code")) {
            my $resp = HTTP::Response->new( HTTP_OK );
            $resp->content_type("text/plain");
            $resp->content("Received auth code\nYou can close the browser now");
            $c->send_response($resp);
        }
        else {
            $c->send_error(HTTP_BAD_REQUEST);
            BAIl_OUT("Invalid redirect back request:\n".$req->as_string);
        }
    }
    else {
        BAIL_OUT("Redirect back request error: ".$c->reason);
    }
    $c->close;
    undef($c);

    my ($access_token, $access_token_type, $auth_token) = $od->auth_by_code($code, $auth_url);
    ok($access_token, "auth_by_code(): Authorized");

    SKIP: {
        skip "Failed authorisation", 8 unless $access_token;

        my $patron = T::OverDrive::patron($od);

        $od = WebService::ILS::OverDrive::Patron->new({
            test => 1,
            client_id => $od_id,
            client_secret => $od_secret,
            library_id => $od_library_id,
            access_token => $access_token,
            access_token_type => $access_token_type,
        });
        $patron = T::OverDrive::patron($od);

        $od = WebService::ILS::OverDrive::Patron->new({
            test => 1,
            client_id => $od_id,
            client_secret => $od_secret,
            library_id => $od_library_id,
        });
        my $refreshed_auth_token;
        ($access_token, $access_token_type, $refreshed_auth_token) = $od->auth_by_token($auth_token);
        ok($access_token, "auth_by_token()");
        $patron = T::OverDrive::patron($od);

        sleep 5;
        $od = WebService::ILS::OverDrive::Patron->new({
            test => 1,
            client_id => $od_id,
            client_secret => $od_secret,
            library_id => $od_library_id,
        });
        if ( ok($od->auth_by_token($refreshed_auth_token), "auth_by_token() refreshed") ) {
            diag("Refreshed  token same as initial") if $auth_token eq $refreshed_auth_token;
        } else {
            diag("Initial token: $auth_token\nRefreshed  token: $refreshed_auth_token");
        }
        $patron = T::OverDrive::patron($od);

        my $bogus_access_token = "AA".$access_token."AA";
        $od->access_token($bogus_access_token);
        # should pick up auth_token
        $patron = T::OverDrive::patron($od);

        my $bogus_auth_token = "AA".$auth_token."AA";
        $od = WebService::ILS::OverDrive::Patron->new({
            test => 1,
            client_id => $od_id,
            client_secret => $od_secret,
            library_id => $od_library_id,
        });
        local $@;
        eval { $od->auth_by_token($bogus_auth_token) };
        ok($@ && $od->is_access_token_error($@), "Bad auth_token")
          or diag($@);
    }
}
