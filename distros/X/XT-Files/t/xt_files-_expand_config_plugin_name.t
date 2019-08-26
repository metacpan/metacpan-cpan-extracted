#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Fatal;
use Test::More 0.88;

use XT::Files;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files';

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );

is( $obj->_expand_config_plugin_name('XaYbZc'), 'XT::Files::Plugin::XaYbZc', 'package name is correctly created' );
is( $obj->_expand_config_plugin_name('=XaYbZcd'), 'XaYbZcd', 'package name is correctly created' );

test_out(q{# [XT::Files] '/tmp/abc' is not a valid plugin name});
my $output = exception { $obj->_expand_config_plugin_name('/tmp/abc') };
test_test('correct error message');

like( $output, qr{'\/tmp\/abc' is not a valid plugin name}, 'invalid plugin name throws an exception' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
