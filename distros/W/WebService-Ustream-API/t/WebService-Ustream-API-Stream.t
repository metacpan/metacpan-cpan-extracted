#!/usr/bin/env perl

use strict;
use warnings;
use version; our $VERSION = qv('0.03');

use Test::Base tests => 2;

use WebService::Ustream::API::Stream;

can_ok( 'WebService::Ustream::API::Stream', qw(new key ua) );
can_ok(
    'WebService::Ustream::API::Stream',
    qw(
	recent
	most_viewers
	random
	all_new
       )
);

