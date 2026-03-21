use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Fcntl qw( :flock O_RDWR O_CREAT );
use File::Temp ();

# Create a real tempfile before loading Test::MockFile
my $real_tempfile;
BEGIN {
    $real_tempfile = File::Temp->new( UNLINK => 1 );
}

use Test::MockFile qw< nostrict >;

# GitHub issue #112: flock on mocked files should work.

subtest 'flock LOCK_EX on mocked file succeeds' => sub {
    my $mock = Test::MockFile->file( '/fake/lockfile', 'data' );
    open( my $fh, '>', '/fake/lockfile' ) or die "open: $!";

    ok( flock( $fh, LOCK_EX ), 'LOCK_EX succeeds on mocked file' );

    close $fh;
};

subtest 'flock LOCK_SH on mocked file succeeds' => sub {
    my $mock = Test::MockFile->file( '/fake/shared', 'data' );
    open( my $fh, '<', '/fake/shared' ) or die "open: $!";

    ok( flock( $fh, LOCK_SH ), 'LOCK_SH succeeds on mocked file' );

    close $fh;
};

subtest 'flock LOCK_UN on mocked file succeeds' => sub {
    my $mock = Test::MockFile->file( '/fake/unlock', 'data' );
    open( my $fh, '>', '/fake/unlock' ) or die "open: $!";

    ok( flock( $fh, LOCK_EX ),    'LOCK_EX succeeds' );
    ok( flock( $fh, LOCK_UN ),    'LOCK_UN succeeds' );

    close $fh;
};

subtest 'flock LOCK_EX|LOCK_NB on mocked file succeeds' => sub {
    my $mock = Test::MockFile->file( '/fake/nonblock', 'data' );
    open( my $fh, '>', '/fake/nonblock' ) or die "open: $!";

    ok( flock( $fh, LOCK_EX | LOCK_NB ), 'LOCK_EX|LOCK_NB succeeds' );

    close $fh;
};

subtest 'flock with sysopen on mocked file succeeds' => sub {
    my $mock = Test::MockFile->file( '/fake/syslock', 'data' );
    sysopen( my $fh, '/fake/syslock', O_RDWR | O_CREAT ) or die "sysopen: $!";

    ok( flock( $fh, LOCK_EX | LOCK_NB ), 'LOCK_EX|LOCK_NB via sysopen' );
    ok( flock( $fh, LOCK_UN ),           'LOCK_UN via sysopen' );

    close $fh;
};

subtest 'flock on real file falls through to CORE::flock' => sub {
    my $path = $real_tempfile->filename;
    open( my $fh, '>', $path ) or die "Cannot open $path: $!";

    ok( flock( $fh, LOCK_EX | LOCK_NB ), 'LOCK_EX|LOCK_NB on real file succeeds' );
    ok( flock( $fh, LOCK_UN ),           'LOCK_UN on real file succeeds' );

    close $fh;
};

subtest 'reproducer from issue #112' => sub {
    my $f      = '/tmp/myfile';
    my $mocked = Test::MockFile->file( $f => 'content' );

    open( my $fh, '>', $f ) or die;
    ok( flock( $fh, LOCK_EX | LOCK_NB ), 'flock succeeds (issue #112 reproducer)' );

    close $fh;
};

done_testing();
