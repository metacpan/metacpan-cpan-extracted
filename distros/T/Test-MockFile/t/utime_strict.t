#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< dies lives >;

use Test::MockFile;

subtest(
    'utime on unmocked file in strict mode dies' => sub {
        like(
            dies( sub { utime 1000, 2000, '/unmocked/strict_test.txt' } ),
            qr/\Qutime\E/,
            'utime on unmocked file in strict mode triggers violation',
        );
    }
);

subtest(
    'utime on mocked file in strict mode succeeds' => sub {
        my $file = Test::MockFile->file( '/strict/test', 'content' );

        ok(
            lives( sub { utime 1000, 2000, '/strict/test' } ),
            'utime on mocked file in strict mode works',
        ) or note $@;

        my @stat = stat('/strict/test');
        is( $stat[8], 1000, 'atime set correctly in strict mode' );
        is( $stat[9], 2000, 'mtime set correctly in strict mode' );
    }
);

done_testing();
exit;
