use strict;
use warnings;
use Test::More;

# Basic module loading and construction tests for WWW::Docker.
# These tests do NOT require Docker.

use_ok('WWW::Docker');
use_ok('WWW::Docker::Role::HTTP');
use_ok('WWW::Docker::API::System');
use_ok('WWW::Docker::API::Containers');
use_ok('WWW::Docker::API::Images');
use_ok('WWW::Docker::API::Networks');
use_ok('WWW::Docker::API::Volumes');
use_ok('WWW::Docker::API::Exec');
use_ok('WWW::Docker::Container');
use_ok('WWW::Docker::Image');
use_ok('WWW::Docker::Network');
use_ok('WWW::Docker::Volume');

# Default construction
my $docker = WWW::Docker->new(api_version => '1.47');
isa_ok($docker, 'WWW::Docker');
is($docker->host,        'unix:///var/run/docker.sock', 'default host is Unix socket');
is($docker->api_version, '1.47',                        'api_version is stored');
is($docker->tls,         0,                             'TLS is off by default');

# Custom TCP host
my $docker_tcp = WWW::Docker->new(
    host        => 'tcp://remote:2375',
    api_version => '1.47',
);
is($docker_tcp->host, 'tcp://remote:2375', 'custom TCP host is stored');

# API accessor existence
can_ok($docker, qw(system containers images networks volumes exec));

# API accessor types
isa_ok($docker->system,     'WWW::Docker::API::System');
isa_ok($docker->containers, 'WWW::Docker::API::Containers');
isa_ok($docker->images,     'WWW::Docker::API::Images');
isa_ok($docker->networks,   'WWW::Docker::API::Networks');
isa_ok($docker->volumes,    'WWW::Docker::API::Volumes');
isa_ok($docker->exec,       'WWW::Docker::API::Exec');

done_testing;
