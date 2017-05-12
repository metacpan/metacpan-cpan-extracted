#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Try::Tiny;
use Test::More 'no_plan';

use FindBin qw($Bin);
use lib "$Bin/../lib";

use_ok( 'WebService::SendGrid::Profile' );
require_ok( 'WebService::SendGrid::Profile' );

my $profile = WebService::SendGrid::Profile->new(
  api_user => 'jlloyd',
  api_key => 'abcdefg123456789',
  test_mode => 1,  
);
isa_ok($profile, 'WebService::SendGrid::Profile');
can_ok($profile, qw(set setUsername setPassword setEmail));

for (qw(username email)) {
  ok(defined $profile->$_, "Parameter $_ is defined");
}

