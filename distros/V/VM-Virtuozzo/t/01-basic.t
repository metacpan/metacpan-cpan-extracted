#!/usr/bin/env perl

use v5.10;
use strict;
use warnings FATAL => "all";
use Test::More;
use XML::Compile::Tester;
use VM::Virtuozzo;

plan +( my $hostname = $ENV{VIRTUOZZO_HOSTNAME} )
	? ( tests => 6 )
	: ( skip_all => "Environment variable VIRTUOZZO_HOSTNAME not set." );

my $agent = VM::Virtuozzo->new(
	xsd_version => 4,
	use_ssl     => 0,
	hostname    => $hostname );
isa_ok($agent, "VM::Virtuozzo");
can_ok($agent, qw(new _client _schema));

my $writer = writer_create(
	$agent->_schema,
	"vzl_writer",
	"{http://www.swsoft.com/webservices/vzl/4.0.0/system}login" );
my $xml = writer_test( $writer, {
	name     => "root",
	realm    => "00000000-0000-0000-0000-000000000000",
	password => "mysecret123" } );
