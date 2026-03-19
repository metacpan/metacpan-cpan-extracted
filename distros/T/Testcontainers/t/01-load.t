use strict;
use warnings;
use Test::More;

# Unit tests for core module loading and basic functionality
# These tests do NOT require Docker

use_ok('Testcontainers');
use_ok('Testcontainers::Container');
use_ok('Testcontainers::ContainerRequest');
use_ok('Testcontainers::DockerClient');
use_ok('Testcontainers::Wait');
use_ok('Testcontainers::Wait::Base');
use_ok('Testcontainers::Labels');
use_ok('Testcontainers::Wait::HostPort');
use_ok('Testcontainers::Wait::HTTP');
use_ok('Testcontainers::Wait::Log');
use_ok('Testcontainers::Wait::HealthCheck');
use_ok('Testcontainers::Wait::Multi');
use_ok('Testcontainers::Module::PostgreSQL');
use_ok('Testcontainers::Module::MySQL');
use_ok('Testcontainers::Module::Redis');
use_ok('Testcontainers::Module::Nginx');

done_testing;
