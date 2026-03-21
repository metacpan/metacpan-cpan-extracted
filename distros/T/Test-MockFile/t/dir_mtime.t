use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw< nostrict >;

# GitHub issue #186: parent directory mtime should update when contents change.
#
# Note: Test::MockFile->dir() creates a mock placeholder that does NOT yet
# "exist" (stat returns empty). Use new_dir() to create an existing directory,
# or create a file with content inside it first.

# Helper: sleep 1 second to ensure mtime changes are detectable.
# Perl's time() has second-level granularity.
sub wait_for_time_change {
    sleep 1;
}

subtest 'file creation updates parent dir mtime' => sub {
    my $dir = Test::MockFile->new_dir('/mtime_test1');
    my $dir_mtime_before = ( stat '/mtime_test1' )[9];
    ok( defined $dir_mtime_before, 'directory has mtime' );

    wait_for_time_change();

    my $file = Test::MockFile->file( '/mtime_test1/newfile.txt', 'content' );
    my $dir_mtime_after = ( stat '/mtime_test1' )[9];
    ok( $dir_mtime_after > $dir_mtime_before, 'dir mtime updated after file creation' );
};

subtest 'file creation without content does not update parent dir mtime' => sub {
    my $dir = Test::MockFile->new_dir('/mtime_test2');
    my $dir_mtime_before = ( stat '/mtime_test2' )[9];

    wait_for_time_change();

    # File with undef contents = non-existent file, no directory entry added
    my $file = Test::MockFile->file('/mtime_test2/ghost.txt');
    my $dir_mtime_after = ( stat '/mtime_test2' )[9];
    is( $dir_mtime_after, $dir_mtime_before,
        'dir mtime NOT updated for file with undef contents' );
};

subtest 'unlink updates parent dir mtime' => sub {
    my $dir  = Test::MockFile->new_dir('/mtime_test3');
    my $file = Test::MockFile->file( '/mtime_test3/doomed.txt', 'bye' );

    wait_for_time_change();

    my $dir_mtime_before = ( stat '/mtime_test3' )[9];

    wait_for_time_change();

    unlink '/mtime_test3/doomed.txt';
    my $dir_mtime_after = ( stat '/mtime_test3' )[9];
    ok( $dir_mtime_after > $dir_mtime_before, 'dir mtime updated after unlink' );
};

subtest 'mkdir updates parent dir mtime' => sub {
    my $parent = Test::MockFile->new_dir('/mtime_test4');
    my $child  = Test::MockFile->dir('/mtime_test4/subdir');

    wait_for_time_change();

    my $parent_mtime_before = ( stat '/mtime_test4' )[9];

    wait_for_time_change();

    mkdir '/mtime_test4/subdir';
    my $parent_mtime_after = ( stat '/mtime_test4' )[9];
    ok( $parent_mtime_after > $parent_mtime_before,
        'parent dir mtime updated after mkdir' );
};

subtest 'rmdir updates parent dir mtime' => sub {
    my $parent = Test::MockFile->new_dir('/mtime_test5');
    my $child  = Test::MockFile->new_dir('/mtime_test5/subdir');

    wait_for_time_change();

    my $parent_mtime_before = ( stat '/mtime_test5' )[9];

    wait_for_time_change();

    rmdir '/mtime_test5/subdir';
    my $parent_mtime_after = ( stat '/mtime_test5' )[9];
    ok( $parent_mtime_after > $parent_mtime_before,
        'parent dir mtime updated after rmdir' );
};

subtest 'open for write creates file and updates parent dir mtime' => sub {
    my $dir  = Test::MockFile->new_dir('/mtime_test6');
    my $mock = Test::MockFile->file('/mtime_test6/new.txt');    # undef contents

    wait_for_time_change();

    my $dir_mtime_before = ( stat '/mtime_test6' )[9];

    wait_for_time_change();

    open( my $fh, '>', '/mtime_test6/new.txt' ) or die "open: $!";
    print {$fh} "hello";
    close $fh;

    my $dir_mtime_after = ( stat '/mtime_test6' )[9];
    ok( $dir_mtime_after > $dir_mtime_before,
        'dir mtime updated when open creates new file' );
};

subtest 'open existing file for write does NOT update parent dir mtime' => sub {
    my $dir  = Test::MockFile->new_dir('/mtime_test7');
    my $mock = Test::MockFile->file( '/mtime_test7/exists.txt', 'old content' );

    wait_for_time_change();

    my $dir_mtime_before = ( stat '/mtime_test7' )[9];

    # Opening an existing file for write (truncate) should NOT update parent mtime
    # Only creating new directory entries updates parent mtime.
    open( my $fh, '>', '/mtime_test7/exists.txt' ) or die "open: $!";
    print {$fh} "new content";
    close $fh;

    my $dir_mtime_after = ( stat '/mtime_test7' )[9];
    is( $dir_mtime_after, $dir_mtime_before,
        'dir mtime NOT updated when opening existing file for write' );
};

subtest 'symlink creation updates parent dir mtime' => sub {
    my $dir     = Test::MockFile->new_dir('/mtime_test8');
    my $target  = Test::MockFile->file( '/mtime_test8/target.txt', 'content' );

    wait_for_time_change();

    my $dir_mtime_before = ( stat '/mtime_test8' )[9];

    wait_for_time_change();

    my $link = Test::MockFile->symlink( '/mtime_test8/target.txt', '/mtime_test8/link.txt' );
    my $dir_mtime_after = ( stat '/mtime_test8' )[9];
    ok( $dir_mtime_after > $dir_mtime_before,
        'dir mtime updated after symlink creation' );
};

subtest 'ctime also updates alongside mtime' => sub {
    my $dir = Test::MockFile->new_dir('/mtime_test9');
    my $dir_ctime_before = ( stat '/mtime_test9' )[10];
    ok( defined $dir_ctime_before, 'directory has ctime' );

    wait_for_time_change();

    my $file = Test::MockFile->file( '/mtime_test9/file.txt', 'data' );
    my $dir_ctime_after = ( stat '/mtime_test9' )[10];
    ok( $dir_ctime_after > $dir_ctime_before, 'dir ctime also updated' );
};

subtest 'no parent dir mocked means no crash' => sub {
    # File without a mocked parent directory — should not crash
    my $file = Test::MockFile->file( '/orphan/file.txt', 'content' );
    ok( $file, 'file created without mocked parent dir (no crash)' );
};

done_testing();
