#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Main module
use_ok('WWW::Hetzner');

# Role
use_ok('WWW::Hetzner::Role::HTTP');
use_ok('WWW::Hetzner::Role::IO');

# HTTP abstraction
use_ok('WWW::Hetzner::HTTPRequest');
use_ok('WWW::Hetzner::HTTPResponse');
use_ok('WWW::Hetzner::LWPIO');

# Cloud API
use_ok('WWW::Hetzner::Cloud');
use_ok('WWW::Hetzner::Cloud::API::Servers');
use_ok('WWW::Hetzner::Cloud::API::SSHKeys');
use_ok('WWW::Hetzner::Cloud::API::ServerTypes');
use_ok('WWW::Hetzner::Cloud::API::Images');
use_ok('WWW::Hetzner::Cloud::API::ISOs');
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
use_ok('WWW::Hetzner::Cloud::API::LoadBalancerTypes');
use_ok('WWW::Hetzner::Cloud::API::Pricing');

# Cloud entities
use_ok('WWW::Hetzner::Cloud::Server');
use_ok('WWW::Hetzner::Cloud::SSHKey');
use_ok('WWW::Hetzner::Cloud::ServerType');
use_ok('WWW::Hetzner::Cloud::Image');
use_ok('WWW::Hetzner::Cloud::ISO');
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
use_ok('WWW::Hetzner::Cloud::LoadBalancerType');
use_ok('WWW::Hetzner::Cloud::Pricing');

# Robot API
use_ok('WWW::Hetzner::Robot');
use_ok('WWW::Hetzner::Robot::API::Servers');
use_ok('WWW::Hetzner::Robot::API::Keys');
use_ok('WWW::Hetzner::Robot::API::IPs');
use_ok('WWW::Hetzner::Robot::API::Reset');
use_ok('WWW::Hetzner::Robot::API::Traffic');
use_ok('WWW::Hetzner::Robot::API::Boot');
use_ok('WWW::Hetzner::Robot::API::RDNS');
use_ok('WWW::Hetzner::Robot::API::Failover');

# Robot entities
use_ok('WWW::Hetzner::Robot::Server');
use_ok('WWW::Hetzner::Robot::Key');
use_ok('WWW::Hetzner::Robot::IP');
use_ok('WWW::Hetzner::Robot::RDNS');
use_ok('WWW::Hetzner::Robot::Failover');

# Test Cloud instantiation
my $cloud = WWW::Hetzner::Cloud->new(token => 'test-token');
isa_ok($cloud, 'WWW::Hetzner::Cloud');
is($cloud->token, 'test-token', 'Cloud token set correctly');

# Test Robot instantiation
my $robot = WWW::Hetzner::Robot->new(user => 'test-user', password => 'test-pass');
isa_ok($robot, 'WWW::Hetzner::Robot');
is($robot->user, 'test-user', 'Robot user set correctly');

done_testing;
