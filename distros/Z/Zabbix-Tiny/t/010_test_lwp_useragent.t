#!/usr/bin/env perl
use strict;
use warnings;
use Test::LWP::UserAgent;
use JSON;

use Test::Most;
use Test::Exception;

use_ok('Zabbix::Tiny');

my $url      = 'http://zabbix.domain.com/zabbix/api_jsonrpc.php';
my $username = 'username';
my $badpass  = 'badpass';
my $goodpass = 'goodpass';

my $useragent = Test::LWP::UserAgent->new;

# Create a new Zabbix::Tiny object
my $zabbix = new_ok(
    'Zabbix::Tiny',
    [
        server   => $url,
        password => $goodpass,
        user     => $username,
        ua       => $useragent,
    ],
    '$zabbix'
);

my $authstring = '0424bd59b807674191e7d77572075f33';
my $authID;
my $id;

#### Define responses from the Test::LWP::UserAgent.
## valid user.login:
$useragent->map_response(
    sub {
        my $req     = shift;
        my $content = decode_json( $req->{_content} );
        $id = $content->{id};
        return 1
          if (  $content->{method} eq 'user.login'
            and $content->{params}->{password} eq $goodpass );
    },
    sub {
        $authID = $authstring;
        return HTTP::Response->new(
            '200', 'OK',
            HTTP::Headers->new( 'content-type' => 'application/json' ),
            encode_json(
                {
                    jsonrpc => '2.0',
                    result  => $authID,
                    id      => $id,
                }
            ),
        );
    }
);

## invalid user.login:
$useragent->map_response(
    sub {
        my $req     = shift;
        my $content = decode_json( $req->{_content} );
        $id = $content->{id};
        return 1
          if (  $content->{method} eq 'user.login'
            and $content->{params}->{password} ne $goodpass );
    },
    sub {
        return HTTP::Response->new(
            '200', 'OK',
            HTTP::Headers->new( 'content-type' => 'application/json' ),
            encode_json(
                {
                    jsonrpc => '2.0',
                    id      => $id,
                    error   => {
                        code    => -32602,
                        message => 'Invalid params.',
                        data    => 'Login name or password is incorrect.'
                    },
                }
            ),
        );
    }
);

$useragent->map_response(
    sub {
        my $req     = shift;
        my $content = decode_json( $req->{_content} );
        return 1
          if (  $content->{method} eq 'host.get'
            and $content->{params}->{id} == 10001
            and defined($authID) );
    },
    sub {
        return HTTP::Response->new(
            '200', 'OK',
            HTTP::Headers->new( 'content-type' => 'application/json' ),
            encode_json(
                {
                    jsonrpc => '2.0',
                    result  => [
                        {
                            hostid => 10001,
                            host   => 'ZABBIX-SERVER'
                        }
                    ],
                    id => $id
                }
            )
        );
    }
);

$useragent->map_response(
    sub {
        my $req     = shift;
        my $content = decode_json( $req->{_content} );
        return 1 if ( $content->{method} eq 'user.logout' );
    },
    sub {
        undef $authID;
        return HTTP::Response->new(
            '200', 'OK',
            HTTP::Headers->new( 'content-type' => 'application/json' ),
            encode_json(
                {
                    jsonrpc => '2.0',
                    result  => JSON::true,
                    id      => $id
                }
            )
        );
    }
);

$useragent->map_response(
    sub {
        my $req     = shift;
        my $content = decode_json( $req->{_content} );
        return 1
          if (  $content->{method} eq 'host.get'
            and $content->{params}->{id} == 10001
            and !defined($authID) );
    },
    sub {
        return HTTP::Response->new(
            '200', 'OK',
            HTTP::Headers->new( 'content-type' => 'application/json' ),
            encode_json(
                {
                    jsonrpc => '2.0',
                    id      => $id,
                    error   => {
                        code    => -32602,
                        message => 'Invalid params.',
                        data    => 'Session terminated, re-login, please.'
                    },
                }
            )
        );
    }
);

ok( my $auth = $zabbix->login, 'Login attempted' );
is( $auth,       $authID, 'AuthID is correct' );
is( $zabbix->id, 1,       'ID is 1' );
ok( my $prepare = $zabbix->prepare( 'host.get', { id => 10001 } ),
    'host.get prepared' );
is( $zabbix->request->{id}, 2, 'ID is updated to 2 in the prepared request' );
is( $zabbix->id, $zabbix->request->{id}, '$zabbix->id also updated to 2' );
$id = 3;
ok( my $host = $zabbix->do(), 'Executed previously prepared host.get' );

throws_ok(
    sub { badpass( $url, $badpass, $username, $useragent ) },
    qr/Error.*-32602.* Login name or password is incorrect/,
    'Correct handling of a bad user password.'
);

is( my $logout = $zabbix->do( 'user.logout', ), JSON::true, 'User log out' );
is( $authID, undef, 'Server side auth invalid after logout.' );
ok( $host = $zabbix->do( 'host.get', { id => 10001 } ), 'Automatic re-login' );
is( $zabbix->auth, $authID, 'Confirm re-login (auth is set.)' );

done_testing();

sub badpass {
    my $url  = shift;
    my $user = shift;
    my $pass = shift;
    $pass = substr( $pass, 0, -1 );

    my $zabbix_bad_pass = Zabbix::Tiny->new(
        server   => $url,
        user     => $user,
        password => $pass,
        ua       => $useragent,
    );
    $zabbix_bad_pass->login;
}
