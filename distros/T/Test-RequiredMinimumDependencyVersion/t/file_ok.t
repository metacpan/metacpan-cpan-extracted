#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Fatal;
use Test::MockModule;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Test::RequiredMinimumDependencyVersion;

use FindBin qw($RealBin);
use lib "$RealBin/../corpus/lib";

main();

sub main {
    my $class = 'Test::RequiredMinimumDependencyVersion';

    {
        my $obj = $class->new( module => { 'XYZ' => '0.001' } );

        #
        like( exception { $obj->file_ok() },      qr{usage: file_ok[(]FILE[)]}, 'file_ok() throws an exception with too few arguments' );
        like( exception { $obj->file_ok(undef) }, qr{usage: file_ok[(]FILE[)]}, '... undef for a file name' );
        like( exception { $obj->file_ok( 'file', 'name', 'abc' ) }, qr{usage: file_ok[(]FILE[)]}, '... too many arguments' );

        #
        my $tmp               = tempdir();
        my $non_existing_file = "$tmp/no_such_file";

        #
        test_out("not ok 1 - Parse file ($non_existing_file)");
        test_fail(+3);
        test_diag(q{});
        test_diag("File $non_existing_file does not exist or is not a file");
        my $rc = $obj->file_ok($non_existing_file);
        test_test('file_ok fails on a non-existing file');

        is( $rc, undef, '... returns undef' );
    }

    {
        my $file = 'corpus/test1.pm';

        my $obj = $class->new( module => { 'Local::XYZ' => '0.002' } );

        test_out("ok 1 - Parse file ($file)");
        test_out('not ok 2 - Local::XYZ any >= 0.002');
        test_fail(+1);
        my $rc = $obj->file_ok($file);
        test_test('file_ok (no version in module)');

        is( $rc, undef, '... returns undef' );
    }

    {
        my $file = 'corpus/test1.pm';

        my $module = Test::MockModule->new('Perl::PrereqScanner');
        $module->mock( 'scan_file', sub { die 'simulating scan_file exception'; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.002' } );

        test_out("not ok 1 - Parse file ($file)");
        test_fail(+1);
        my $rc = $obj->file_ok($file);
        test_test('file_ok (Perl::PrereqScanner failed)');

        is( $rc, undef, '... returns undef' );
    }

    {
        my $file = 'corpus/test2.pm';

        my $obj = $class->new( module => { 'Local::XYZ' => '0.002' } );

        test_out("ok 1 - Parse file ($file)");
        test_out('not ok 2 - Local::XYZ 0.001 >= 0.002');
        test_fail(+1);
        my $rc = $obj->file_ok($file);
        test_test('file_ok (to low version in module)');

        is( $rc, undef, '... returns undef' );
    }

    {
        my $file = 'corpus/test3.pm';

        my $obj = $class->new( module => { 'Local::XYZ' => '0.002' } );

        test_out("ok 1 - Parse file ($file)");
        test_out('ok 2 - Local::XYZ 0.002 >= 0.002');
        my $rc = $obj->file_ok($file);
        test_test('file_ok (correct version in module)');

        is( $rc, 1, '... returns 1' );
    }

    {
        my $file = 'corpus/test4.pm';

        my $obj = $class->new( module => { 'Local::XYZ' => '0.002' } );

        test_out("ok 1 - Parse file ($file)");
        test_out('ok 2 - Local::XYZ v0.3.0 >= 0.002');
        my $rc = $obj->file_ok($file);
        test_test('file_ok (higher version in module)');

        is( $rc, 1, '... returns 1' );
    }

    {
        my $file = 'corpus/test2.pm';

        my $obj = $class->new( module => { 'Local::ABC' => '0.002' } );

        test_out("ok 1 - Parse file ($file)");
        my $rc = $obj->file_ok($file);
        test_test('file_ok (different module)');

        is( $rc, 1, '... returns 1' );
    }

    {
        my $file = 'corpus/test5.pm';

        my $obj = $class->new( module => { 'Local::ABC' => '0.002', 'Local::XYZ' => '0.002' } );

        test_out("ok 1 - Parse file ($file)");
        test_out('ok 2 - Local::ABC 0.002 >= 0.002');
        test_out('not ok 3 - Local::XYZ 0.001 >= 0.002');
        test_fail(+1);
        my $rc = $obj->file_ok($file);
        test_test('file_ok (two modules, one mismatch)');

        is( $rc, undef, '... returns undef' );
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
