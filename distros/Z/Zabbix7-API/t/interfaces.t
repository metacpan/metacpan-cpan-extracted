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

my $host = $zabber->fetch_single('Host', params => { host => 'Zabbix Server',
                                                      search => { host => 'Zabbix Server' } });

is(scalar(@{$host->interfaces}), 1,
   q{... and the host has one interface});

cmp_deeply($host->interfaces,
           array_each(isa('Zabbix7::API::HostInterface')),
           q{... and a host's interfaces accessor returns HostInterface objects});

my $interface = $host->interfaces->[0];

is($interface->name, '127.0.0.1',
   q{... and the interface's name is the IP});

my $fetched_host;

lives_ok(sub { $fetched_host = $interface->host },
         q{... and the interface can fetch its own host});

isa_ok($fetched_host, 'Zabbix7::API::Host');

is($fetched_host->id, $host->id,
   q{... and it's the original host});

my $new_interface = Zabbix7::API::HostInterface->new(
    root => $zabber,
    data => {
        dns => 'localhost',
        ip => '',
        useip => 0,
        main => 1,
        port => 10001,
        type => Zabbix7::API::HostInterface::INTERFACE_TYPE_SNMP,
        hostid => $host->id
    });

is($new_interface->name, 'localhost',
   q{... and the new interface's name is the hostname});

lives_ok(sub { $new_interface->create },
         q{... and we can create a new interface});

$host->pull;

is(scalar(@{$host->interfaces}), 2,
   q{... and the host has two interfaces now});

cmp_deeply($host->interfaces,
           array_each(isa('Zabbix7::API::HostInterface')),
           q{... and a host's interfaces accessor returns HostInterface objects});

cmp_deeply($host->interfaces,
           bag(methods(name => '127.0.0.1'),
               methods(name => 'localhost')),
           q{... and both interfaces are now tied to the host});

lives_ok(sub { $new_interface->delete },
         q{... and we can delete an interface});

$host->pull;

is(scalar(@{$host->interfaces}), 1,
   q{... and the host has only one interface now});

is($host->interfaces->[0]->name, '127.0.0.1',
   q{... and it's the one we did not delete});

# again, but create it via the host's interfaces attribute

$new_interface = Zabbix7::API::HostInterface->new(
    root => $zabber,
    data => {
        dns => 'localhost',
        ip => '',
        useip => 0,
        main => 1,
        port => 10001,
        type => Zabbix7::API::HostInterface::INTERFACE_TYPE_SNMP,
        hostid => $host->id
    });

push @{$host->interfaces}, $new_interface;
$host->update;

is(scalar(@{$host->interfaces}), 2,
   q{... and the host has two interfaces now});

cmp_deeply($host->interfaces,
           array_each(isa('Zabbix7::API::HostInterface')),
           q{... and a host's interfaces accessor returns HostInterface objects});

cmp_deeply($host->interfaces,
           bag(methods(name => '127.0.0.1'),
               methods(name => 'localhost')),
           q{... and both interfaces are now tied to the host});

$host->interfaces([ $interface ]);
lives_ok(sub { $host->update },
         q{... and we can delete it again});

$host->pull;

is(scalar(@{$host->interfaces}), 1,
   q{... and the host has only one interface now});

is($host->interfaces->[0]->name, '127.0.0.1',
   q{... and it's the one we did not delete});

eval { $zabber->logout };

done_testing;
