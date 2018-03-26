#!/usr/bin/env perl
use strict;
use warnings;
use Zabbix::Tiny;
use Test::LWP::UserAgent;
use JSON;

use Test::More tests => 4;
use Test::Exception;

my $url      = 'http://zabbix.domain.com/zabbix/api_jsonrpc.php';
my $username = 'username';
my $password = 'P@ssword4ever';

my $useragent = Test::LWP::UserAgent->new;

# Create a new Zabbix::Tiny object
my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
    ## Use of ua here allows for the Test::LWP::UserAgent, rather than the
    ## real LWP::UserAgent.  This should only be done in tests.
    ua => $useragent,
);

## An auth ID that can be retuned by the Test::LWP::UserAgent
my $auth_id  = '0424bd59b807674191e7d77572075f33';
my $zversion = '3.2.1';
my $id;

## Zabbix API method is 'apiinfo.version', and an auth string is included.
## Zabbix will reject this with a error lie $message below.
my $apiinfo_err =
  'The "apiinfo.version" method must be called without the "auth" parameter.';
my $api_message = encode_json(
    {
        jsonrpc => '2.0',
        id      => $id,
        error   => {
            code    => 32602,
            message => "Invalid params.",
            data    => $apiinfo_err,
        },
    }
);
$useragent->map_response(
    sub {
        my $req     = shift;
        my $content = decode_json( $req->content );
        $id = $content->{id};
        return 0 if ( $content->{method} ne 'apiinfo.version' );
        return 1 if ( $content->{auth} );
    },
    sub {
        my $message = encode_json(
            {
                jsonrpc => '2.0',
                id      => $id,
                error   => {
                    code    => 32602,
                    message => "Invalid params.",
                    data    => $apiinfo_err,
                },
            }
        );
        return my200($message);
    }
);

## Zabbix method is 'apiinfo.version', but no auth is sent (this is correct).
$useragent->map_response(
    sub {
        my $req     = shift;
        my $content = decode_json( $req->content );
        $id = $content->{id};
        return 0 if ( $content->{method} ne 'apiinfo.version' );
        return 1 if ( !( $content->{auth} ) );
    },
    sub {
        my $message = qq({"jsonrpc":"2.0","result":"3.2.1","id":$id});
        return my200($message);
    }
);

## Handle a user login method (older versions of Zabbix::Tiny will exit before
## sending the apiinfo.version method, so this is for handling this test
## against older versions.  Of course these will fail with the apiinfo.version
## call, though.
$useragent->map_response(
    sub {
        my $req     = shift;
        my $content = decode_json( $req->{_content} );
        $id = $content->{id};
        if ( $content->{method} ne 'user.login' ) {
            return 0;
        }
        if ( $content->{params}->{password} eq $password ) {
            return 1;
        }
    },
    sub {
        my $req     = shift;
        my $message = qq({"jsonrpc":"2.0","result":"$auth_id","id":"$id"});
        return my200($message);
    }
);

#is($zversion, $version, qq{Version number "$zversion" retrievd correctly});
my $version;
lives_ok(
    sub {
        $version = $zabbix->do('apiinfo.version'), $zversion;
    },
    "version should be $zversion"
);
is( $zabbix->auth, undef, "Do not need to be logged into get the version." );

$zabbix->login;
is( $zabbix->auth, $auth_id, "Login after getting version is ok." );
lives_ok(
    sub {
        $version = $zabbix->do('apiinfo.version'), $zversion;
    },
    "Still able to retrieve version after login. (No auth parameter sent)"
);

#"'apiinfo.version' method should not contain an auth argument";
#is( $version, $zversion, "version should be $zversion");

sub my200 {
    my $message = shift;
    my $return =
      HTTP::Response->new( '200', 'OK',
        HTTP::Headers->new( 'content-type' => 'application/json' ), $message, );
    return $return;
}
