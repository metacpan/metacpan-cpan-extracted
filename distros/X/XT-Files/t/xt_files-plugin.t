#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Fatal;
use Test::More 0.88;

use File::stat;
use File::Temp;
use lib ();

use XT::Files;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files';

chdir 'corpus/dist1' or die "chdir failed: $!";

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );

#
test_out(q{# [XT::Files] '/tmp/abc' is not a valid plugin name});
my $output = exception { $obj->plugin('/tmp/abc') };
test_test('correct error message');
like( $output, qr{'\/tmp\/abc' is not a valid plugin name}, 'plugin() dies if an invalid plugin name is given' );

# Note: We load the test plugin in this section and it'll stay loaded
lib->import('xt/lib');

# don't test the exception message because it's from Module::Load
isnt( exception { $obj->plugin('=Local::No::Such::Plugin::Exists') }, undef, 'plugin() dies if it cannot load the plugin' );

#
test_out(q{# [XT::Files] Not a valid version 'hello world'});
$output = exception { $obj->plugin( '=Local::Test', 'hello world' ) };
test_test('correct error message');
like( $output, q{/Not a valid version 'hello world'/}, q{plugin() dies if it's version is gibberish} );

#
test_out(q{# [XT::Files] Local::Test version 2 required--this is only version 0.001});
$output = exception { $obj->plugin( '=Local::Test', 2 ) };
test_test('correct error message');
like( $output, '/Local::Test version 2 required--this is only version 0.001/', q{plugin() dies if it's version is to low} );

test_out(q{# [XT::Files] Local::Bad1 doesn't have a run method});
$output = exception { $obj->plugin('=Local::Bad1') };
test_test('correct error message');
like( $output, q{/Local::Bad1 doesn't have a run method/}, q{plugin() dies if plugin doesn't have a 'run' method} );

test_out(q{# [XT::Files] Local::Bad2 doesn't have a new method});
$output = exception { $obj->plugin('=Local::Bad2') };
test_test('correct error message');
like( $output, q{/Local::Bad2 doesn't have a new method/}, q{plugin() dies if plugin doesn't have a 'new' method} );

my $tempdir = File::Temp->newdir();

note('no arguments to run');
my $report_file_base = "$tempdir/report_" . __LINE__;
local $ENV{REPORT_FILE_BASE} = $report_file_base;

is( $obj->plugin( '=Local::Test', '0.001' ), undef, 'plugin returns undef' );

my $st = stat "${report_file_base}.new";
ok( defined $st, '... new was run' );
if ( defined $st ) {
    is( $st->size, 0, '... without arguments' );
}

$st = stat "${report_file_base}.run";
ok( defined $st, '... run was run' );
if ( defined $st ) {
    is( $st->size, 0, '... without arguments' );
}

note('arguments to run');
$report_file_base = "$tempdir/report_" . __LINE__;
local $ENV{REPORT_FILE_BASE} = $report_file_base;

is( $obj->plugin( '=Local::Test', undef, [ [ 'hello' => 'WORLD' ], [ hello => 'WORLD2' ], [ 'abc' => 'a b c' ] ] ), undef, 'plugin returns undef' );

$st = stat "${report_file_base}.new";
ok( defined $st, '... new was run' );
if ( defined $st ) {
    is( $st->size, 0, '... without arguments' );
}

my $rc = open my $fh, '<', "${report_file_base}.run";
ok( $rc, '... run was run' );
if ($rc) {
    my @lines = <$fh>;
    close $fh or die "read failed: $!";
    chomp @lines;
    is_deeply( \@lines, [ 'hello=WORLD', 'hello=WORLD2', 'abc=a b c', ], '... with the correct arguments' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
