package Zabbix7::API::TestUtils;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Zabbix7::API;
use Test::More;

sub canonical_username { $ENV{ZABBIX_API_USER} || 'Admin' }
sub canonical_password { $ENV{ZABBIX_API_PW} || 'zabbix' }

sub canonical_login {
    my $zabbix = Zabbix7::API->new(server => $ENV{ZABBIX_SERVER} || 'http://localhost/zabbix/api_jsonrpc.php');
    eval {
        # Prefer Bearer token if available, fallback to username/password
        if ($ENV{ZABBIX_API_TOKEN}) {
            $zabbix->set_bearer_token($ENV{ZABBIX_API_TOKEN});
            Log::Any->get_logger->debug("Authenticated using Bearer token for server: " . $zabbix->{server});
        } else {
            print "HERE ############## ";
            print canonical_username();
            print canonical_password();
            print  $ENV{ZABBIX_SERVER};
            $zabbix->login(user => canonical_username(), password => canonical_password());
            Log::Any->get_logger->debug("Authenticated using username: " . canonical_username() . " for server: " . $zabbix->{server});
        }
    };
    if (my $error = $@) {
        Log::Any->get_logger->error("Failed to authenticate: $error");
        BAIL_OUT($error);
    }
    return $zabbix;
}

1;
