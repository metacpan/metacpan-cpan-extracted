#!/usr/bin/perl

use strict;
use Test::More tests => 7;

use WWW::Metaweb;

	
my $mh = WWW::Metaweb->connect( server => 'www.freebase.com',
				auth_uri => '/api/account/login',
				read_uri => '/api/service/mqlread',
				write_uri => '/api/service/mqlwrite',
				trans_uri => '/api/trans',
				pretty_json => 1 );
ok(defined $mh, 'Can connect to Freebase. '.$WWW::Metaweb::errstr);

# Since the only thing I can control on Freebase is my own account - and
# my own types, I'm using them for testing read queries.
my $query = '{
  "query":{
    "creator":null,
    "guid":null,
    "id":"/user/hds/default_domain/www_metaweb_test",
    "name":null,
    "properties":[],
    "type":"/type/type"
  }
} 
';
ok($mh->add_read_query($query), 'Can add query. '.$WWW::Metaweb::errstr); # Can add query

ok($mh->send_read_envelope, 'Can send envelope. '.$WWW::Metaweb::errstr); # Send envelope

ok($mh->result_is_ok, 'Result is okay. '.$WWW::Metaweb::errstr); # Result is valid

my $result;
ok($result = $mh->result, 'Result can be fetched as JSON. '.$WWW::Metaweb::errstr); # Result can be fetched as default (JSON)

ok($result = $mh->result('netmetawebquery', 'perl'), 'Result can be fetched as a Perl structure. '.$WWW::Metaweb::errstr); # Result can be fetched as a perl structure

my $expected = {
	  creator => '/user/hds',
	  name => 'WWW::Metaweb Test',
	  type => '/type/type',
	  guid => '#9202a8c04000641f8000000005c81c61',
	  id => '/user/hds/default_domain/www_metaweb_test',
	  properties => [
	  		  '/user/hds/default_domain/www_metaweb_test/install_time',
			  '/user/hds/default_domain/www_metaweb_test/metaweb_version'
			  ]
};
is_deeply($result, $expected, 'Structure of test query is correct.');


exit;
