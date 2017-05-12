#!/usr/bin/perl

use strict;
use Test::More tests => 4;

use WWW::Metaweb;

our $original_query;
our ($callback1, $callback2) = (0, 0);

$original_query = qq({
	"query":{
		"creator":true,
		"id":"/user/hds/default_domain/www_metaweb_test"
	}
});

sub callback1  {
	my $json = shift;

	$main::callback1 = 1;

	$main::callback1 = 2 if $json =~ /"id":"\/user\/hds\/default_domain\/www_metaweb_test"/;

	return $json;
} # &callback1

sub callback2  {
	my $json = shift;
	
	$main::callback2 = 1;
	
	$json =~ s/"creator":true/"creator":null/;

	return $json;
} # &callback2

my $mh = WWW::Metaweb->connect( server => 'www.freebase.com',
				read_uri => '/api/service/mqlread',
				json_preprocessor => [ \&callback1, \&callback2 ]
			      );

my $result = $mh->read($original_query, 'perl');

cmp_ok($callback1, '>', 0, 'First callback called.');

cmp_ok($callback1, '>', 1, 'JSON sent to callback correctly.');

cmp_ok($callback2, '>', 0, 'Second callback called.');

ok($mh->result_is_ok('query0'), 'Callback altered JSON.');

exit;
