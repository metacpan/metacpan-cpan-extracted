use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix::API;

use lib 't/lib';
use Zabbix::API::TestUtils;

if ($ENV{ZABBIX_SERVER}) {

    plan tests => 9;

} else {

    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';

}

use_ok('Zabbix::API::Host');

my $zabber = Zabbix::API::TestUtils::canonical_login;

my $hosts = $zabber->fetch('Host', params => { host => 'Zabbix Server',
                                               search => { host => 'Zabbix Server' } });

is(@{$hosts}, 1, '... and a host known to exist can be fetched');

my $zabhost = $hosts->[0];

isa_ok($zabhost, 'Zabbix::API::Host',
       '... and that host');

ok($zabhost->created,
   '... and it returns true to existence tests');

my $oldip = $zabhost->data->{ip};

$zabhost->data->{ip} = '255.255.255.255';

$zabhost->push;

$zabhost->pull;

is($zabhost->data->{ip}, '255.255.255.255',
   '... and updated data can be pushed back to the server');

$zabhost->data->{ip} = $oldip;
$zabhost->push;

my $new_host = Zabbix::API::Host->new(root => $zabber,
                                      data => { host => 'Another Server',
                                                ip => '255.255.255.255',
                                                useip => 1,
                                                groups => [ { groupid => 4 } ] });

isa_ok($new_host, 'Zabbix::API::Host',
       '... and a host created manually');

eval { $new_host->push };

if ($@) { diag "Caught exception: $@" };

ok($new_host->created,
   '... and pushing it to the server creates a new host');

TODO: {

    local $TODO = 'Merging fetched objects does not work';

    my $existing = Zabbix::API::Host->new(root => $zabber,
                                          data => { host => 'Another Server' });

    $existing->push;

    is($existing, $new_host, '... and trying to push an existing host as new merges both objects');

}

eval { $new_host->delete };

if ($@) { diag "Caught exception: $@" };

ok(!$new_host->created,
   '... and calling its delete method removes it from the server');

eval { $zabber->logout };
