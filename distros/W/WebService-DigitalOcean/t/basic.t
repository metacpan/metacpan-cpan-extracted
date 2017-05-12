#!/usr/bin/env perl
use Test::More;
use Test::Fatal;
use warnings;
use strict;
use utf8;
use WebService::DigitalOcean;

my $do;

# This is not a real token. We're not really hitting DigitalOcean's API here.
my $token = '855eed5572651530a92557f2426eb1f3b3b2120c6eda19d371c5b7d04c777aa0';

is(
    exception { $do = WebService::DigitalOcean->new(token => $token) },
    undef,
    '$do builds ok',
);

isa_ok( $do, 'WebService::DigitalOcean', '$do' );

my @domain_record_methods = qw/
  domain_record_create
  domain_record_list
  domain_record_get
  domain_record_delete
/;

my @domain_methods = qw/
  domain_create
  domain_list
  domain_get
  domain_delete
/;

my @droplet_action_methods = qw/
  droplet_resize
  droplet_change_kernel
  droplet_rebuild
  droplet_restore
  droplet_rename
  droplet_snapshot
  droplet_reboot
  droplet_power_cycle
  droplet_power_on
  droplet_power_off
  droplet_password_reset
  droplet_shutdown
  droplet_enable_ipv6
  droplet_disable_backups
  droplet_action_get
/;

my @key_methods = qw/
  key_get
  key_create
  key_delete
  key_list
/;

my @droplet_methods = qw/
  droplet_get
  droplet_list
  droplet_create
  droplet_delete
/;

my @region_methods = qw/
  region_list
/;

my @size_methods = qw/
  size_list
/;

my @ua_methods = qw/
  make_request
/;

for (
    @domain_record_methods, @domain_methods,  @droplet_action_methods,
    @key_methods,           @droplet_methods, @region_methods,
    @size_methods,          @ua_methods
  )
{
    ok( $do->can($_), '$do can ' . $_ );
}

like(
    exception { $do = WebService::DigitalOcean->new() },
    qr/missing required arguments.*token/i,
    '$do complains about `token` not being set',
);

done_testing;
