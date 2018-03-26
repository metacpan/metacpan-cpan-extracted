#!/usr/bin/env perl
use strict;
use warnings;
use Test::LWP::UserAgent;
use JSON;

use Test::Most;
use Test::Exception;

use_ok('Zabbix::Tiny');

my $url      = 'http://zabbix.domain.com/zabbix/bad_jsonrpc.php';
my $username = 'username';
my $goodpass = 'goodpass';

my $useragent = Test::LWP::UserAgent->new;

# Create a new Zabbix::Tiny object
my $zabbix = new_ok(
    'Zabbix::Tiny', [
      server   => $url,
      password => $goodpass,
      user     => $username,
      ua       => $useragent,
    ],
    '$zabbix'
);

my $authID = '0424bd59b807674191e7d77572075f33';
my $id;

#### Define responses from the Test::LWP::UserAgent.
## valid user.login:
$useragent->map_response(sub {
        #my $req = shift;
        return 1;
    },
    sub{
        return HTTP::Response->new( '404', 'Not Found',
            undef,
            "Page not found",
        );
    }
);


throws_ok(
    sub{ my $auth = $zabbix->login } ,
    qr/HTTP error/,
    'Croak on non-200 HTTP response.'
);
#throws_ok(
#    sub { my $events = $zabbix->do('event.get', {output => 'extended'}); },
#    qr/Empty response received from the Zabbix API. This can indicate an error on the API side like running out of memory./,
#    'empty string in response croaks with more informative error.'
#);
#is( $zabbix->request->{id}, 2, 'ID is updated to 2 in the prepared request' );
#is( $zabbix->id, $zabbix->request->{id}, '$zabbix->id also updated to 2');
#$id = 3;
#ok( my $host = $zabbix->do(), 'Executed previously prepared host.get' );

#throws_ok(
#   sub{badpass( $url, $badpass, $username, $useragent )},
#    qr/Error.*-32602.* Login name or password is incorrect/,
#    'Correct handling of a bad user password.'
#);



done_testing();




sub badpass {
    my $url = shift;
    my $user = shift;
    my $pass = shift;
    $pass    = substr( $pass, 0, -1 );

    my $zabbix_bad_pass = Zabbix::Tiny->new(
        server   => $url,
        user     => $user,
        password => $pass,
        ua       => $useragent,
    );
    $zabbix_bad_pass->login;
}
