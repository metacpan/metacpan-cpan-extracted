#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Fatal;
use Test::More 0.88;

use XT::Files;
use XT::Files::Plugin::Dirs;

use constant CLASS => 'XT::Files::Plugin::Dirs';

like( exception { CLASS()->new() }, q{/xtf attribute required/}, q{new throws an exception if 'xtf' argument is missing} );

like( exception { CLASS()->new( xtf => 'hello world' ) }, q{/'xtf' is not of class 'XT::Files'/}, q{new throws an exception if 'xtf' argument is not an XT::Files object} );

chdir 'corpus/dist1' or die "chdir failed: $!";

is( XT::Files->_is_initialized, undef, 'singleton is not initialized' );

my $xtf = XT::Files->new( -config => undef );
is_deeply( [ $xtf->files ], [], 'no files are configured' );

my $obj = CLASS()->new( xtf => $xtf );
isa_ok( $obj, CLASS(), 'new returned object' );

is( $obj->run(), undef, 'run returns undef' );
is_deeply( [ $xtf->files ], [], 'no files are configured' );

my $expected_output = '[' . CLASS() . q{] Invalid configuration option 'hello = world' for plugin 'Dirs'};
test_out("# $expected_output");
my $output = exception { $obj->run( [ [ hello => 'world' ] ] ) };
test_test('correct error message');
like( $output, qr{\Q$expected_output\E}, 'run dies if an invalid argument is given' );
is_deeply( [ $xtf->files ], [], 'no files are configured' );

is( $obj->run( [ [ bin => 'bin' ] ] ), undef, 'run returns undef' );

my @files = $xtf->files;
is( scalar @files, 2, '... found 2 files' );

my %expected_file;
for my $name (qw(bin/hello.txt bin/world.txt)) {
    $expected_file{$name} = _check_bin_file($name);
}

for my $name ( sort keys %expected_file ) {
    if ( !@files ) {
        ok( 0, "expected file not found: $name" );
    }
    else {
        my $file = shift @files;
        $expected_file{$name}->($file);
    }
}

for my $file (@files) {
    ok( 0, 'file found but not expected: ' . $file->name() );
}

#
chdir '../dist4' or die "chdir failed: $!";

is( XT::Files->_is_initialized, undef, 'singleton is not initialized' );

$xtf = XT::Files->new( -config => undef );
is_deeply( [ $xtf->files ], [], 'no files are configured' );

$obj = CLASS()->new( xtf => $xtf );
isa_ok( $obj, CLASS(), 'new returned object' );

is(
    $obj->run(
        [
            [ bin    => 'bin' ],
            [ module => 'bin/lib' ],
            [ module => 'lib' ],
            [ test   => 't' ],
            [ test   => 'xt' ],
        ],
    ),
    undef,
    'run returns undef',
);

@files = $xtf->files;
is( scalar @files, 7, '... found 7 files' );

undef %expected_file;
$expected_file{'bin/hello.txt'}           = _check_bin_file('bin/hello.txt');
$expected_file{'bin/lib/module.pm'}       = _check_module_file('bin/lib/module.pm');
$expected_file{'bin/lib/not_a_module.pl'} = _check_bin_file('bin/lib/not_a_module.pl');
$expected_file{'bin/world.txt'}           = _check_bin_file('bin/world.txt');
$expected_file{'lib/world.pm'}            = _check_module_file('lib/world.pm');
$expected_file{'lib/world.pod'}           = _check_pod_file('lib/world.pod');
$expected_file{'t/test.t'}                = _check_test_file('t/test.t');

for my $name ( sort keys %expected_file ) {
    if ( !@files ) {
        ok( 0, "expected file not found: $name" );
    }
    else {
        my $file = shift @files;
        $expected_file{$name}->($file);
    }
}

for my $file (@files) {
    ok( 0, 'file found but not expected: ' . $file->name() );
}

#
done_testing();

exit 0;

sub _check_bin_file {
    my ($name) = @_;

    return sub {
        my ($file) = @_;

        is( $file->name, $name, "$name - correct name" );
        ok( !$file->is_module, "$name - !is_module" );
        ok( !$file->is_pod,    "$name - !is_pod" );
        ok( $file->is_script,  "$name - is_script" );
        ok( !$file->is_test,   "$name - !is_test" );

        return;
    };
}

sub _check_module_file {
    my ($name) = @_;

    return sub {
        my ($file) = @_;

        is( $file->name, $name, "$name - correct name" );
        ok( $file->is_module,  "$name - is_module" );
        ok( !$file->is_pod,    "$name - !is_pod" );
        ok( !$file->is_script, "$name - !is_script" );
        ok( !$file->is_test,   "$name - !is_test" );

        return;
    };
}

sub _check_pod_file {
    my ($name) = @_;

    return sub {
        my ($file) = @_;

        is( $file->name, $name, "$name - correct name" );
        ok( !$file->is_module, "$name - !is_module" );
        ok( $file->is_pod,     "$name - is_pod" );
        ok( !$file->is_script, "$name - !is_script" );
        ok( !$file->is_test,   "$name - !is_test" );

        return;
    };
}

sub _check_test_file {
    my ($name) = @_;

    return sub {
        my ($file) = @_;

        is( $file->name, $name, "$name - correct name" );
        ok( !$file->is_module, "$name - !is_module" );
        ok( !$file->is_pod,    "$name - !is_pod" );
        ok( $file->is_script,  "$name - is_script" );
        ok( $file->is_test,    "$name - is_test" );

        return;
    };
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
