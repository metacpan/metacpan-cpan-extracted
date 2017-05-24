use strict;
use warnings;

use Test::More tests => 3;
use URI;

subtest 'amqp' => sub {
    my $uri = URI->new('amqp://user:pass@host.avast.com:1234/vhost?heartbeat=10&connection_timeout=60');

    is($uri->scheme, 'amqp',           'scheme');
    is($uri->host,   'host.avast.com', 'host');
    is($uri->port,   '1234',           'port');

    is($uri->path,  '/vhost', 'path');
    is($uri->vhost, 'vhost',  'vhost');

    is($uri->user,     'user', 'user');
    is($uri->password, 'pass', 'password');

    is($uri->query_param('heartbeat'),          10, 'query heartbeat');
    is($uri->query_param('connection_timeout'), 60, 'query heartbeat');

    ok(!$uri->secure, 'no SSL/TLS');
};

subtest 'amqps' => sub {
    my $uri = URI->new('amqps://user:pass@host.avast.com:1234/vhost');
    is($uri->scheme, 'amqps',          'scheme');
    is($uri->host,   'host.avast.com', 'host');
    is($uri->port,   '1234',           'port');

    ok($uri->secure, 'SSL/TLS');
};

subtest 'Appendix A: Examples' => sub {
    subtest 'amqp://user:pass@host:10000/vhost' => sub {
        plan tests => 5;

        my $uri = URI->new('amqp://user:pass@host:10000/vhost');
        is($uri->user,     'user',  'user');
        is($uri->password, 'pass',  'password');
        is($uri->host,     'host',  'host');
        is($uri->port,     10000,   'port');
        is($uri->vhost,    'vhost', 'vhost');
    };

    subtest 'amqp://user%61:%61pass@ho%61st:10000/v%2fhost' => sub {
        my $uri = URI->new('amqp://user%61:%61pass@ho%61st:10000/v%2fhost');
        is($uri->user,     'usera',  'user');
        is($uri->password, 'apass',  'password');
        is($uri->host,     'hoast',  'host');
        is($uri->port,     10000,    'port');
        is($uri->vhost,    'v/host', 'vhost');
    };

    subtest 'amqp://' => sub {
        my $uri = URI->new('amqp://');
        is($uri->user,     undef, 'user');
        is($uri->password, undef, 'password');
        is($uri->host,     '',    'host');
        is($uri->port,     5672,  'port');
        is($uri->vhost,    undef,    'vhost');
    };

    subtest 'amqp://:@/' => sub {
        my $uri = URI->new('amqp://:@/');
        is($uri->user,     '', 'user');
        is($uri->password, '', 'password');
        is($uri->host,     '',    'host');
        is($uri->port,     5672,  'port');
        is($uri->vhost,    undef,    'vhost');
    };

    subtest 'amqp://user@' => sub {
        my $uri = URI->new('amqp://user@');
        is($uri->user,     'user', 'user');
        is($uri->password, undef, 'password');
        is($uri->host,     '',    'host');
        is($uri->port,     5672,  'port');
        is($uri->vhost,    undef,    'vhost');
    };

    subtest 'amqp://user:pass@' => sub {
        my $uri = URI->new('amqp://user:pass@');
        is($uri->user,     'user', 'user');
        is($uri->password, 'pass', 'password');
        is($uri->host,     '',    'host');
        is($uri->port,     5672,  'port');
        is($uri->vhost,    undef ,   'vhost');
    };

    subtest 'amqp://host' => sub {
        my $uri = URI->new('amqp://host');
        is($uri->user,     undef, 'user');
        is($uri->password, undef, 'password');
        is($uri->host,     'host',    'host');
        is($uri->port,     5672,  'port');
        is($uri->vhost,    undef ,   'vhost');
    };

    subtest 'amqp://:10000' => sub {
        my $uri = URI->new('amqp://:10000');
        is($uri->user,     undef, 'user');
        is($uri->password, undef, 'password');
        is($uri->host,     '',    'host');
        is($uri->port,     10000,  'port');
        is($uri->vhost,    undef ,   'vhost');
    };

    subtest 'amqp:///vhost' => sub {
        my $uri = URI->new('amqp:///vhost');
        is($uri->user,     undef, 'user');
        is($uri->password, undef, 'password');
        is($uri->host,     '',    'host');
        is($uri->port,     5672,  'port');
        is($uri->vhost,    'vhost' ,   'vhost');
    };

    subtest 'amqp://host/' => sub {
        my $uri = URI->new('amqp://host/');
        is($uri->user,     undef, 'user');
        is($uri->password, undef, 'password');
        is($uri->host,     'host',    'host');
        is($uri->port,     5672,  'port');
        is($uri->vhost,    undef ,   'vhost');
    };

    subtest 'amqp://host/%2f' => sub {
        my $uri = URI->new('amqp://host/%2f');
        is($uri->user,     undef, 'user');
        is($uri->password, undef, 'password');
        is($uri->host,     'host',    'host');
        is($uri->port,     5672,  'port');
        is($uri->vhost,    '/' ,   'vhost');
    };

    subtest 'amqp://[::1]' => sub {
        my $uri = URI->new('amqp://[::1]');
        is($uri->user,     undef, 'user');
        is($uri->password, undef, 'password');
        is($uri->host,     '::1',    'host');
        is($uri->port,     5672,  'port');
        is($uri->vhost,    undef ,   'vhost');
    };

};
