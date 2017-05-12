#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;

use Test::Mock::LWP;

isa_ok $Mock_ua,   'Test::MockObject';
isa_ok $Mock_req,  'Test::MockObject';
isa_ok $Mock_resp, 'Test::MockObject';
