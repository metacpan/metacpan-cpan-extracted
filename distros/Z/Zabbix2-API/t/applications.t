use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Test::More;
use Test::Exception;
use Test::Deep;

use Zabbix2::API;
use Zabbix2::API::Application;

use lib 't/lib';
use Zabbix2::API::TestUtils;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix2::API::TestUtils::canonical_login;

my $host = $zabber->fetch_single('Host', params => { host => 'Zabbix Server',
                                                     search => { host => 'Zabbix Server' } });

ok(my $app = $zabber->fetch_single('Application',
                                   params => { filter => { name => 'CPU' },
                                               hostids => [ $host->id ] }),
   '... and an app known to exist can be fetched');

isa_ok($app, 'Zabbix2::API::Application',
       '... and that app');

ok($app->exists,
   '... and it returns true to existence tests');

cmp_deeply($app->items,
           array_each(isa('Zabbix2::API::Item')),
           q{... and it has a bunch of HostInterface objects});

isa_ok($app->host, 'Zabbix2::API::Host',
       q{... and it has a single Host object});

my $new_app = Zabbix2::API::Application->new(root => $zabber,
                                             data => { hostid => $app->host->id,
                                                       name => 'Some Application' });

isa_ok($new_app, 'Zabbix2::API::Application',
       '... and an app created manually');

eval { $new_app->create };

if ($@) { diag "Caught exception: $@" };

ok($new_app->exists,
   '... and pushing it to the server creates a new app');

$new_app->pull;

cmp_deeply($new_app->host,
           $app->host,
           q{... and its host is correctly set});

$new_app->data->{name} = 'Spongebob Squarepants';

$new_app->update;

$new_app->pull;

is($new_app->data->{name}, 'Spongebob Squarepants',
   '... and updated data can be pushed back to the server');

eval { $new_app->delete };

if ($@) { diag "Caught exception: $@" };

ok(!$new_app->exists,
   '... and calling its delete method removes it from the server');

eval { $zabber->logout };

done_testing;
