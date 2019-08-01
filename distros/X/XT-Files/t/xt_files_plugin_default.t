#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Fatal;
use Test::More 0.88;

use XT::Files;
use XT::Files::Plugin::Default;

use constant CLASS => 'XT::Files::Plugin::Default';

like( exception { CLASS()->new() }, q{/xtf attribute required/}, q{new throws an exception if 'xtf' argument is missing} );

is( XT::Files->_is_initialized, undef, 'singleton is not initialized' );

my $xtf = XT::Files->new( -config => undef );
is_deeply( $xtf->{_excludes}, [], 'no excludes are configured' );

my $obj = CLASS()->new( xtf => $xtf );
isa_ok( $obj, CLASS(), 'new returned object' );

is( $obj->run( [ [ dirs => 0 ], [ excludes => 0 ] ] ), undef, 'run returns undef' );
is_deeply( $xtf->{_excludes}, [], 'no excludes are configured' );
is_deeply( $xtf->{_file}, {},     'no files are found' );

my $expected_output = '[' . CLASS() . q{] Invalid configuration option 'hello = world' for plugin 'Default'};
test_out("# $expected_output");
my $output = exception { $obj->run( [ [ hello => 'world' ] ] ) };
test_test('correct error message');
like( $output, qr{\Q$expected_output\E}, 'run dies if an invalid argument is given' );

is_deeply( $xtf->{_excludes}, [], 'no excludes are configured' );
is_deeply( $xtf->{_file}, {},     'no files are found' );

is( $obj->run( [ [ dirs => 0 ] ] ), undef, 'run returns undef' );
is_deeply( $xtf->{_excludes}, [ q{[.]swp$}, q{[.]bak$}, q{~$} ], 'default excludes are configured' );
is_deeply( $xtf->{_file}, {}, 'no files are found' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
