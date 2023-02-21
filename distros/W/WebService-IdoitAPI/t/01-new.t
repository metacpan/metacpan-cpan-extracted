#!perl

use 5.006;
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok( 'WebService::IdoitAPI' );

dies_ok { WebService::IdoitAPI->new( {} ) }
	"expected to die with empty configuration";

print $@, "\n";

throws_ok { WebService::IdoitAPI->new( { apikey => "abc" } ) }
        qr/^configuration is missing the URL/,
	"expected to die without URL";

print $@, "\n";

throws_ok { WebService::IdoitAPI->new( { url => "https://test.i-doit.com/" } ) }
        qr/^configuration is missing the API key/,
	"expected to die without API key";

print $@, "\n";

lives_ok { WebService::IdoitAPI->new( {
			apikey => "abc",
			url => "https://test.i-doit.com/",
		} ) }
	"this shouldn't die";

done_testing();
