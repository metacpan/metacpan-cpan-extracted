#!perl
use warnings;
use strict;
use lib 'lib';

use Test::More tests => 1;

use_ok( 'VM::EC2::Security::CredentialCache' );
