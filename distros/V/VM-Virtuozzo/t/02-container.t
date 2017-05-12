#!/usr/bin/env perl

use v5.10;
use strict;
use warnings FATAL => "all";
use Test::More;
use XML::Compile::Tester;
use VM::Virtuozzo;

plan +( my $hostname = $ENV{VIRTUOZZO_HOSTNAME} )
	? ( tests => 18 )
	: ( skip_all => "Environment variable VIRTUOZZO_HOSTNAME not set." );

my $agent = VM::Virtuozzo->new(
	xsd_version => 4,
	use_ssl     => 0,
	hostname    => $hostname );
isa_ok($agent, "VM::Virtuozzo");
can_ok($agent, qw(envm));

my @operations = (
	{ create  => { config => { } } },
	{ suspend => { eid => "..." } },
	{ resume  => { eid => "..."  } },
	{ destroy => { eid => "..." } } );
foreach (@operations) {
	my ($function, $params) = %{$_};
	my $writer = writer_create(
		$agent->_schema,
		"env-$function writer",
		"{http://www.swsoft.com/webservices/vzl/4.0.0/envm}$function" );
	writer_test($writer, $params); }
