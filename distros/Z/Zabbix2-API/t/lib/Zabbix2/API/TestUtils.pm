package Zabbix2::API::TestUtils;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Zabbix2::API;
use Test::More;

sub canonical_username { $ENV{ZABBIX_API_USER} || 'Admin' }
sub canonical_password { $ENV{ZABBIX_API_PW} || 'zabbix' }

sub canonical_login {
    my $zabber = Zabbix2::API->new(server => $ENV{ZABBIX_SERVER} || 'http://localhost/zabbix/api_jsonrpc.php');
    eval { $zabber->login(user => canonical_username(),
                          password => canonical_password()) };
    if (my $error = $@) {
        BAIL_OUT($error);
    }
    return $zabber;
}

1;
