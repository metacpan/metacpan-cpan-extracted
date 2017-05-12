
use Test;
BEGIN { plan tests => 7 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use base 'Waft';

my $obj = __PACKAGE__->new;

$ENV{SERVER_NAME} = 'localhost';
$ENV{SERVER_PORT} = 80;
$ENV{REQUEST_METHOD} = 'GET';
$ENV{SCRIPT_NAME} = '/test.cgi';

ok( $obj->absolute_url eq 'http://localhost/test.cgi' );

$obj->{foo} = 'bar';
$obj->set_values( baz => qw( foo bar ) );
ok( $obj->absolute_url('foo.html', 'ALL_VALUES')
    eq 'http://localhost/test.cgi?p=foo.html&v=baz-foo-bar+foo-bar' );

$ENV{REQUEST_URI} = '/test.cgi/foo/bar';
ok( $obj->absolute_url eq 'http://localhost/test.cgi/foo/bar' );

$ENV{SERVER_PORT} = 81;
ok( $obj->absolute_url eq 'http://localhost:81/test.cgi/foo/bar' );

$ENV{HTTPS} = 'on';
ok( $obj->absolute_url eq 'https://localhost:81/test.cgi/foo/bar' );

$ENV{SERVER_PORT} = 443;
ok( $obj->absolute_url eq 'https://localhost/test.cgi/foo/bar' );

$ENV{HTTP_HOST} = 'localhost.localdomain:444';
ok( $obj->absolute_url
    eq 'https://localhost.localdomain:444/test.cgi/foo/bar' );
