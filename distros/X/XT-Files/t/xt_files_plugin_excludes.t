#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Fatal;
use Test::More 0.88;

use XT::Files;
use XT::Files::Plugin::Excludes;

use constant CLASS => 'XT::Files::Plugin::Excludes';

like( exception { CLASS()->new() }, q{/xtf attribute required/}, q{new throws an exception if 'xtf' argument is missing} );

like( exception { CLASS()->new( xtf => 'hello world' ) }, q{/'xtf' is not of class 'XT::Files'/}, q{new throws an exception if 'xtf' argument is not an XT::Files object} );

my $xtf = XT::Files->new( -config => undef );
is_deeply( $xtf->{_excludes}, [], 'no excludes are configured' );

my $obj = CLASS()->new( xtf => $xtf );
isa_ok( $obj, CLASS(), 'new returned object' );

is( $obj->run(), undef, 'run returns undef' );
is_deeply( $xtf->{_excludes}, [], 'no excludes are configured' );

my $expected_output = '[' . CLASS() . q{] Invalid configuration option 'hello = world' for plugin 'Excludes'};
test_out("# $expected_output");
my $output = exception { $obj->run( [ [ hello => 'world' ] ] ) };
test_test('correct error message');
like( $output, qr{\Q$expected_output\E}, 'run dies if an invalid argument is given' );
is_deeply( $xtf->{_excludes}, [], 'no excludes are configured' );

is( $obj->run( [ [ exclude => 'hello' ], [ exclude => '.*world$' ] ] ), undef, 'run returns undef' );
is_deeply( $xtf->{_excludes}, [ 'hello', '.*world$' ], 'correct excludes are configured' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
