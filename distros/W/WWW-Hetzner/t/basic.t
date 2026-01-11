#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Main module
use_ok('WWW::Hetzner');

# Role
use_ok('WWW::Hetzner::Role::HTTP');

# Cloud API
use_ok('WWW::Hetzner::Cloud');
use_ok('WWW::Hetzner::Cloud::API::Servers');
use_ok('WWW::Hetzner::Cloud::API::SSHKeys');
use_ok('WWW::Hetzner::Cloud::API::ServerTypes');
use_ok('WWW::Hetzner::Cloud::API::Images');
use_ok('WWW::Hetzner::Cloud::API::Locations');
use_ok('WWW::Hetzner::Cloud::API::Datacenters');
use_ok('WWW::Hetzner::Cloud::API::Zones');
use_ok('WWW::Hetzner::Cloud::API::RRSets');
use_ok('WWW::Hetzner::Cloud::API::Volumes');
use_ok('WWW::Hetzner::Cloud::API::Networks');
use_ok('WWW::Hetzner::Cloud::API::Firewalls');
use_ok('WWW::Hetzner::Cloud::API::FloatingIPs');
use_ok('WWW::Hetzner::Cloud::API::PrimaryIPs');
use_ok('WWW::Hetzner::Cloud::API::LoadBalancers');
use_ok('WWW::Hetzner::Cloud::API::Certificates');
use_ok('WWW::Hetzner::Cloud::API::PlacementGroups');

# Cloud entities
use_ok('WWW::Hetzner::Cloud::Server');
use_ok('WWW::Hetzner::Cloud::SSHKey');
use_ok('WWW::Hetzner::Cloud::ServerType');
use_ok('WWW::Hetzner::Cloud::Image');
use_ok('WWW::Hetzner::Cloud::Location');
use_ok('WWW::Hetzner::Cloud::Datacenter');
use_ok('WWW::Hetzner::Cloud::Zone');
use_ok('WWW::Hetzner::Cloud::RRSet');
use_ok('WWW::Hetzner::Cloud::Volume');
use_ok('WWW::Hetzner::Cloud::Network');
use_ok('WWW::Hetzner::Cloud::Firewall');
use_ok('WWW::Hetzner::Cloud::FloatingIP');
use_ok('WWW::Hetzner::Cloud::PrimaryIP');
use_ok('WWW::Hetzner::Cloud::LoadBalancer');
use_ok('WWW::Hetzner::Cloud::Certificate');
use_ok('WWW::Hetzner::Cloud::PlacementGroup');

# Robot API
use_ok('WWW::Hetzner::Robot');
use_ok('WWW::Hetzner::Robot::API::Servers');
use_ok('WWW::Hetzner::Robot::API::Keys');
use_ok('WWW::Hetzner::Robot::API::IPs');
use_ok('WWW::Hetzner::Robot::API::Reset');
use_ok('WWW::Hetzner::Robot::API::Traffic');

# Robot entities
use_ok('WWW::Hetzner::Robot::Server');
use_ok('WWW::Hetzner::Robot::Key');
use_ok('WWW::Hetzner::Robot::IP');

# Test Cloud instantiation
my $cloud = WWW::Hetzner::Cloud->new(token => 'test-token');
isa_ok($cloud, 'WWW::Hetzner::Cloud');
is($cloud->token, 'test-token', 'Cloud token set correctly');

# Test Robot instantiation
my $robot = WWW::Hetzner::Robot->new(user => 'test-user', password => 'test-pass');
isa_ok($robot, 'WWW::Hetzner::Robot');
is($robot->user, 'test-user', 'Robot user set correctly');

done_testing;
