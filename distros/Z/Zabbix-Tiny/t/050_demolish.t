#!/usr/bin/env perl
use strict;
use warnings;
use Test::LWP::UserAgent;
use JSON;

use Test::Most;
use Test::Exception;

use Zabbix::Tiny;

my $url      = 'http://zabbix.domain.com/zabbix/api_jsonrpc.php';
my $username = 'username';
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
    'Creating new Zabbix::Tiny object.'
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


ok( my $auth = $zabbix->login, 'Login attempted' );

## Ugly wayto force ua to be undefined to simulate problem in iss26.
is( $zabbix->{ua} = undef, undef, 'Setting $zabbix->ua to undef.' );
is( $zabbix->ua, undef, 'Confirming that $zabbix->ua is undef.' );
ok( !defined($zabbix->DEMOLISH), 'Clean demolish of Zabbix::Tiny object' );


done_testing();



