use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Test::More;
use Test::Exception;
use Test::Deep;

use Zabbix7::API;
use Zabbix7::API::Host;
use Zabbix7::API::HostInterface;

use lib 't/lib';
use Zabbix7::API::TestUtils;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix7::API::TestUtils::canonical_login;

my $hosts = $zabber->fetch('Host', params => { host => 'Zabbix Server',
                                               search => { host => 'Zabbix Server' } });

is(@{$hosts}, 1, '... and a host known to exist can be fetched');

my $zabhost = $hosts->[0];

isa_ok($zabhost, 'Zabbix7::API::Host',
       '... and that host');

ok($zabhost->exists,
   '... and it returns true to existence tests');

cmp_deeply($zabhost->interfaces,
           array_each(isa('Zabbix7::API::HostInterface')),
           q{... and it has a bunch of HostInterface objects});

cmp_deeply($zabhost->graphs,
           array_each(isa('Zabbix7::API::Graph')),
           q{... and it has a bunch of Graph objects});

cmp_deeply($zabhost->items,
           array_each(isa('Zabbix7::API::Item')),
           q{... and it has a bunch of Item objects});

my $oldname = $zabhost->data->{name};

$zabhost->data->{name} = 'Spongebob Squarepants';

$zabhost->update;

$zabhost->pull;

is($zabhost->data->{name}, 'Spongebob Squarepants',
   '... and updated data can be pushed back to the server');

$zabhost->data->{name} = $oldname;
$zabhost->update;

my $new_host = Zabbix7::API::Host->new(root => $zabber,
                                       data => { host => 'Another Server',
                                                 groups => [ { groupid => 4 } ],
                                                 interfaces => [
                                                     {
                                                         dns => 'localhost',
                                                         ip => '',
                                                         main => 1,
                                                         port => 10000,
                                                         type => Zabbix7::API::HostInterface::INTERFACE_TYPE_AGENT,
                                                         useip => 0,
                                                     } ] });
eval { $new_host->create };

if ($@) { diag "Caught exception: $@" };

ok($new_host->exists,
   '... and pushing it to the server creates a new host');

$new_host->pull;

is(scalar(@{$new_host->interfaces}), 1,
   q{... and the host interfaces survived});

cmp_deeply($new_host->interfaces->[0]->data, superhashof({
    dns => 'localhost',
    interfaceid => re(qr/\d+/),
    hostid => $new_host->id,
    ip => '',
    main => 1,
    port => 10000,
    type => Zabbix7::API::HostInterface::INTERFACE_TYPE_AGENT,
    useip => 0, }),
           q{... and they have some new data});

eval { $new_host->delete };

if ($@) { diag "Caught exception: $@" };

ok(!$new_host->exists,
   '... and calling its delete method removes it from the server');

ok(!$new_host->interfaces->[0]->exists,
   '... and it removes the host interfaces also');

eval { $zabber->logout };

done_testing;
