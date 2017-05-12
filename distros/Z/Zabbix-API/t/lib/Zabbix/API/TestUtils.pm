package Zabbix::API::TestUtils;

use Zabbix::API;
use Test::More;

sub canonical_login {

    my $zabber = Zabbix::API->new(server => $ENV{ZABBIX_SERVER} || 'http://localhost/zabbix/api_jsonrpc.php',
                                  verbosity => $ENV{ZABBIX_VERBOSITY} || 0);

    eval { $zabber->login(user => $ENV{ZABBIX_API_USER} || 'api_access',
                          password => $ENV{ZABBIX_API_PW} || 'api') };

    if ($@) {

        my $error = $@;
        BAIL_OUT($error);

    }

    return $zabber;

}

1;
