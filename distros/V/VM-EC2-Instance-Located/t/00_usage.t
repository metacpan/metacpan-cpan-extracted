#!perl
use warnings;
use strict;
use lib 'lib';

use Test::More tests => 2;

use_ok( 'VM::EC2::Instance::Located' );

my $result = VM::EC2::Instance::Located::at_ec2();

ok(defined($result), "Got a defined result");
