#!/usr/bin/perl
use warnings;
use strict;
use lib 'lib';
use Test::More;

use_ok( "LWP" );
use_ok( "JSON" );
use_ok( "Moose" );
use_ok( "WebService::VaultPress::Partner" );
use_ok( "WebService::VaultPress::Partner::Response" );
use_ok( "WebService::VaultPress::Partner::Request::GoldenTicket" );
use_ok( "WebService::VaultPress::Partner::Request::History" );
use_ok( "WebService::VaultPress::Partner::Request::Usage" );

done_testing;
