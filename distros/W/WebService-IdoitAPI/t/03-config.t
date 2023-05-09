#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use IO::ScalarArray;
use WebService::IdoitAPI;

my ($config, @data, $fh);

@data = (
	qq{'apikey' = "abcd "\n},
	qq{"key" : ' efgh'\n},
	qq{password=bla fasel \n},
	qq{ "url" : "http://example.com", \n},
	qq{ username = "adam"; \n},
);

$fh = new IO::ScalarArray \@data;

$config = WebService::IdoitAPI::_read_config_fh($fh);

is($config->{apikey},   "abcd ",    "Space at end with double quotation marks");
is($config->{key},      " efgh",    "Space at start with single quotation marks");
is($config->{password}, "bla fasel","Space in the middle and semicolon");
is($config->{url},      "http://example.com/src/jsonrpc.php", "Comma at end");
is($config->{username}, "adam",     "Semicolon at end");

$data[3] = qq{ "url" : "http://example.com/src/jsonrpc.php", \n};
$fh = new IO::ScalarArray \@data;
$config = WebService::IdoitAPI::_read_config_fh($fh);
is($config->{url},      "http://example.com/src/jsonrpc.php", "complete URL");

$data[3] = qq{ "url" : "http://example.com/", \n};
$fh = new IO::ScalarArray \@data;
$config = WebService::IdoitAPI::_read_config_fh($fh);
is($config->{url},      "http://example.com/src/jsonrpc.php", "URL ending in /");

done_testing;
