#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test::MockFile qw< strict >;

subtest(
    '-x after unlink' => sub {
        my $filename = '/bin/mine';
        my $mocked   = Test::MockFile->file( $filename => '#!/bin/true' );

        chmod 0755, $filename;

        ok( -e $filename, 'File should exist' );
        ok( -x $filename, 'File should be executable' );

        unlink $filename;

        ok( !-e $filename, 'File should not exist' );
        ok( !-x $filename, 'File should not be executable' );
    }
);

subtest(
    '-x with multiple files' => sub {
        my $filename1 = q[/bin/one];
        my $filename2 = q[/bin/two];

        my $mock1 = Test::MockFile->file($filename1);
        my $mock2 = Test::MockFile->file($filename2);

        ok( !-x $filename1, 'First filename should not be executable' );
        ok( !-x $filename2, 'Second filename should not be executable' );

        $mock1->touch;
        chmod 0755, $filename1;

        ok( -e $filename1,  'First filename should now exist' );
        ok( -x $filename1,  'First filename should now be executable' );
        ok( !-e $filename2, 'Second filename should still not exist' );
        ok( !-x $filename2, 'Second filename should still not be executable' );
    }
);

subtest(
    'rmdir works for mocked directories' => sub {
        my $dir    = q[/some/where];
        my $mocked = Test::MockFile->dir($dir);

        ok( mkdir($dir), 'Created directory successfully' );
        ok( -d $dir,     'Directory now exists' );

        is( $! + 0, 0, 'No errors yet' );
        ok( rmdir($dir), 'Successfully rmdir directory' );
        is( $! + 0, 0, 'Still no errors' );
        ok( !-d $dir, 'Directory no longer exists' );
    }
);

done_testing();
exit;
