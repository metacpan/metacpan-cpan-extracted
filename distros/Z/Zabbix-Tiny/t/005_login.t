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


## apiinfo.version request:
$useragent->map_response(
    sub {
        my $req     = shift;
        my $content = decode_json( $req->{_content} );
        $id         = $content->{id};

        if (  $content->{method} eq 'apiinfo.version' ) {
            return 1;
        }
    },
    sub {
        return HTTP::Response->new(
            '200', 'OK',
            HTTP::Headers->new( 'content-type' => 'application/json' ),
            encode_json(
                {
                    jsonrpc => '2.0',
                    result  => '6.4',
                    id      => $id,
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
done_testing();
exit;
