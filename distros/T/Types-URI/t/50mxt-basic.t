use strict;
use warnings;

use Test::More;
use Test::Requires { 'Moose' => '2.0000' };

use Types::URI -all;

use URI;
use URI::WithBase;

{
	package Foo;
	use Moose;
	package Bar;
	use Moose;
	extends qw(URI);
}

ok( defined &Uri, "Uri" );
ok( defined &FileUri, "FileUri" );
ok( defined &DataUri, "DataUri" );

ok( my $uri = Uri, "find Uri" );

my $http = URI->new("http://www.google.com");
my $file = URI->new("file:///tmp/foo");
my $rel  = URI->new("foo");
my $data = URI->new("data:"); $data->data("stuff");
my $base_http = URI::WithBase->new("foo", $http );
my $base_file = URI::WithBase->new("foo", $file );
my $base_rel  = URI::WithBase->new("foo", $rel );

my $http_str = "http://www.google.com";

ok( $uri->check($http), "http uri" );
ok( $uri->check($file), "file uri" );
ok( $uri->check($rel),  "rel uri" );
ok( $uri->check($data), "data uri" );
ok( $uri->check(Bar->new),   "subclass" );
ok( $uri->check($base_http), "http with base" );
ok( $uri->check($base_file), "file with base" );
ok( $uri->check($base_rel),  "rel with base" );

ok( !$uri->check($http_str), "not for string" );
ok( !$uri->check(undef), "not for undef" );
ok( !$uri->check(Foo->new), "not for object" );

ok( my $furi = FileUri, "find FileUri" );

ok( $furi->check($file), "file uri" );

ok( !$furi->check($http), "http uri" );
ok( !$furi->check($rel),  "rel uri" );
ok( !$furi->check($data), "data uri" );
ok( !$furi->check(Bar->new),   "subclass" );
ok( !$furi->check($base_http), "http with base" );
ok( !$furi->check($base_file), "file with base" );
ok( !$furi->check($base_rel),  "rel with base" );

ok( !$furi->check($http_str), "not for string" );
ok( !$furi->check(undef), "not for undef" );
ok( !$furi->check(Foo->new), "not for object" );

ok( my $duri = DataUri, "find DataUri" );

ok( $duri->check($data), "data uri" );

ok( !$duri->check($http), "http uri" );
ok( !$duri->check($file), "file uri" );
ok( !$duri->check($rel),  "rel uri" );
ok( !$duri->check(Bar->new),   "subclass" );
ok( !$duri->check($base_http), "http with base" );
ok( !$duri->check($base_file), "file with base" );
ok( !$duri->check($base_rel),  "rel with base" );

ok( !$duri->check($http_str), "not for string" );
ok( !$duri->check(undef), "not for undef" );
ok( !$duri->check(Foo->new), "not for object" );

my $uri_http_str = to_Uri($http_str);
isa_ok( $uri_http_str, "URI" );
is( $uri_http_str->scheme, "http", "scheme" );

my $uri_str = to_Uri("foo");
isa_ok( $uri_str, "URI" );
is( $uri_str->path, "foo", "URI" );
is( $uri_str->scheme, undef, "URI" );

my $uri_hash = to_Uri({path => "foo"});
isa_ok( $uri_hash, "URI" );
is( $uri_hash->path, "foo", "URI from HashRef" );
is( $uri_hash->scheme, undef, "URI from HashRef" );

my $uri_file = to_FileUri("foo");
isa_ok( $uri_file, "URI::file" );
is( $uri_file->file, "foo", "filename" );

my $uri_data = to_DataUri("foo");
isa_ok( $uri_data, "URI::data" );
is( $uri_data->data, "foo", "foo as data" );

my $uri_data_ref = to_DataUri(\"foo");
isa_ok( $uri_data_ref, "URI::data" );
is( $uri_data_ref->data, "foo", "scalar ref foo as data" );

done_testing;
