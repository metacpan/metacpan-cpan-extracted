#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Fatal;
use Test::More 0.88;

use XT::Files;

use constant CLASS => 'XT::Files';

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );
isa_ok( $obj, CLASS(), 'new(-config => undef) returned object' );

test_out(q{# [XT::Files] Invalid entry 'invalid = entry'});
my $output = exception { $obj->_global_keyval( 'invalid', 'entry' ) };
test_test('correct error message');
like( $output, q{/Invalid entry 'invalid = entry'/}, '_global_keyval dies on unknown entries' );

is( $obj->_global_keyval( ':version', '0' ), undef, '... returns undef if the :version is ok' );

test_out(q{# [XT::Files] Not a valid version 'hello world'});
$output = exception { $obj->_global_keyval( ':version', 'hello world' ) };
test_test('correct error message');
like( $output, q{/Not a valid version 'hello world'/}, '... dies if the specified version does not pass version->is_lax' );

test_out('# [XT::Files] XT::Files version 99999999 required--this is only version 0.001');
$output = exception { $obj->_global_keyval( ':version', '99999999' ) };
test_test('correct error message');
like( $output, '/XT::Files version 99999999 required--this is only version /', '... dies if the :version is not ok' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
