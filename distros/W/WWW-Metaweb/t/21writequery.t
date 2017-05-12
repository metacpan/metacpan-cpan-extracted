#!/usr/bin/perl

use strict;
use Test::More tests => 8;

use WWW::Metaweb;

my $auth_present = 0;
my $test_name = '21writequery.t';

if (defined $ENV{FREEBASE_USER} && defined $ENV{FREEBASE_PASS})  {
	$auth_present = 1;
}

SKIP:  {
	skip 'No Freebase credentials provided', 8 unless $auth_present;

	my $mh = WWW::Metaweb->connect( username => $ENV{FREEBASE_USER},
					password => $ENV{FREEBASE_PASS},
					server => 'sandbox.freebase.com',
					auth_uri => '/api/account/login',
					read_uri => '/api/service/mqlread',
					write_uri => '/api/service/mqlwrite',
					trans_uri => '/api/trans',
					pretty_json => 1 );
	ok(defined $mh, 'Can authenticate to Freebase. '.$WWW::Metaweb::errstr)
	  or BAIL_OUT('Without being able to authenticate to Freebase we can\'t run any more tests.');


	my $t = time;
	my $query = qq({
		"query":{
			"create":"unless_exists",
			"type":"/user/hds/default_domain/www_metaweb_test",
			"name":"$test_name",
			"install_time":"$t",
			"metaweb_version":"$WWW::Metaweb::VERSION",
			"id":null
		}
	});
	
	ok($mh->add_write_query(test_write => $query), 'Can add write query. '.$WWW::Metaweb::errstr);

	ok($mh->send_write_envelope, 'Can send write envelope. '.$WWW::Metaweb::errstr);

	# If we get a timeout here we're in trouble - bail out.
	if ($WWW::Metaweb::errstr =~ /^HTTP response: 500/)  {
		BAIL_OUT('Connection timeout to sandbox.freebase.com - unable to continue tests');
	}
	
	ok($mh->result_is_ok('test_write'), 'Result from write query okay. '.$WWW::Metaweb::errstr);

	my $result;
	ok($result = $mh->result('test_write', 'perl'), 'Result of write can be fetched. '.$WWW::Metaweb::errstr);

	ok($result->{create} eq 'created', 'New object can be created (id='.$result->{id}.'). '.$WWW::Metaweb::errstr);

	$query = qq({
	"query":{
		"id":"$result->{id}",
		"install_time":{
			"connect":"update",
			"lang":"/lang/en",
			"value":"$t+1"
		},
		"type":"/user/hds/default_domain/www_metaweb_test"
	}
});
	$query = {
		query => {
			id => "$result->{id}",
			install_time => {
				connect => 'update',
				lang => '/lang/en',
				'value' => "$t+1"
			},
			type => '/user/hds/default_domain/www_metaweb_test'
		}
	};
	
	$result = $mh->write($query);

	ok(defined $result, 'Can use \'easy\' write method. '.$WWW::Metaweb::errstr);

	ok($result->{install_time}->{connect} eq 'updated', 'Can update existing object. ');

} # SKIP if no auth
