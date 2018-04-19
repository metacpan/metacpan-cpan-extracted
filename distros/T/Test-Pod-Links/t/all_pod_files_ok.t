#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::MockModule;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd;

use Test::Pod::Links;

main();

sub main {
    my $class = 'Test::Pod::Links';

    note('no file found in cwd');
    {
        my $cwd = cwd();
        chdir tempdir();

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my $obj = $class->new;
        is( $obj->all_pod_files_ok, 1, 'all_pod_files_ok returned 1' );
        is( $done_testing,          0, '... done_testing was not called' );
        is( $skip_all,              1, '... skip_all was called once' );
        is( scalar @skip_all_args,  2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found\n", '... and a message' );

        chdir $cwd;
    }

    note('no file found in tempdir');
    {
        my $tempdir = tempdir();

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my $obj = $class->new;
        is( $obj->all_pod_files_ok($tempdir), 1, 'all_pod_files_ok returned 1' );
        is( $done_testing,                    0, '... done_testing was not called' );
        is( $skip_all,                        1, '... skip_all was called once' );
        is( scalar @skip_all_args,            2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found in ($tempdir)\n", '... and a message' );
    }

    note('no file found in multiple tempdir');
    {
        my $tempdir  = tempdir();
        my $tempdir2 = tempdir();

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my $obj = $class->new;
        is( $obj->all_pod_files_ok( $tempdir, $tempdir2 ), 1, 'all_pod_files_ok returned 1' );
        is( $done_testing,         0, '... done_testing was not called' );
        is( $skip_all,             1, '... skip_all was called once' );
        is( scalar @skip_all_args, 2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found in ($tempdir $tempdir2)\n", '... and a message' );
    }

    note('one file in tempdir');
    {
        my $tempdir = tempdir();
        mkdir "$tempdir/lib";
        my $pod_file = "$tempdir/lib/my.pod";
        _touch($pod_file);

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @pod_file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'pod_file_ok', sub { my $self = shift; push @pod_file_ok_args, [@_]; return 1; } );

        my $obj = $class->new;
        is( $obj->all_pod_files_ok($tempdir), 1, 'all_pod_files_ok returned 1' );
        is( $done_testing,                    1, '... done_testing was called once' );
        is( $skip_all,                        0, '... skip_all was never called' );
        is( scalar @pod_file_ok_args,         1, 'pod_file_ok was called once' );
        is_deeply( [@pod_file_ok_args], [ [$pod_file] ], '... with the correct filename' );
    }

    note('two file in tempdir');
    {
        my $tempdir = tempdir();
        mkdir "$tempdir/lib";
        my @pod_files = sort "$tempdir/lib/my_1.pod", "$tempdir/lib/my_2.pod";
        for my $file (@pod_files) {
            _touch($file);
        }

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @pod_file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'pod_file_ok', sub { my $self = shift; push @pod_file_ok_args, [@_]; return 1; } );

        my $obj = $class->new;
        is( $obj->all_pod_files_ok($tempdir), 1, 'all_pod_files_ok returned 1' );
        is( $done_testing,                    1, '... done_testing was called once' );
        is( $skip_all,                        0, '... skip_all was never called' );
        is( scalar @pod_file_ok_args,         2, 'pod_file_ok was called twice' );
        my @expected = map { [$_] } @pod_files;
        is_deeply( [@pod_file_ok_args], [@expected], '... with the correct filenames' );
    }

    note('two file in cwd');
    {
        my $cwd     = cwd();
        my $tempdir = tempdir();
        mkdir "$tempdir/lib";
        my @pod_files = sort "$tempdir/lib/my_1.pod", "$tempdir/lib/my_2.pod";
        for my $file (@pod_files) {
            _touch($file);
        }

        chdir $tempdir;

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @pod_file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'pod_file_ok', sub { my $self = shift; push @pod_file_ok_args, [@_]; return 1; } );

        my $obj = $class->new;
        is( $obj->all_pod_files_ok($tempdir), 1, 'all_pod_files_ok returned 1' );
        is( $done_testing,                    1, '... done_testing was called once' );
        is( $skip_all,                        0, '... skip_all was never called' );
        is( scalar @pod_file_ok_args,         2, 'pod_file_ok was called twice' );
        my @expected = map { [$_] } @pod_files;
        is_deeply( [@pod_file_ok_args], [@expected], '... with the correct filenames' );

        chdir $cwd;
    }

    note('one malformed file');
    {
        my $cwd     = cwd();
        my $tempdir = tempdir();
        mkdir "$tempdir/lib";
        my $pod_file = "$tempdir/lib/malformed.pod";
        _touch($pod_file);

        chdir $tempdir;

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @pod_file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'pod_file_ok', sub { my $self = shift; push @pod_file_ok_args, [@_]; return; } );

        my $obj = $class->new;
        is( $obj->all_pod_files_ok($tempdir), undef, 'all_pod_files_ok returned undef' );
        is( $done_testing,                    1,     '... done_testing was called once' );
        is( $skip_all,                        0,     '... skip_all was never called' );
        is( scalar @pod_file_ok_args,         1,     'pod_file_ok was called once' );

        is_deeply( [@pod_file_ok_args], [ [$pod_file] ], '... with the correct filenames' );

        chdir $cwd;
    }

    note('two file in tempdir (called with filenames)');
    {
        my $tempdir = tempdir();
        mkdir "$tempdir/lib";
        my @pod_files = sort "$tempdir/lib/my_1.pod", "$tempdir/lib/my_2.pod";
        for my $file (@pod_files) {
            _touch($file);
        }

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @pod_file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'pod_file_ok', sub { my $self = shift; push @pod_file_ok_args, [@_]; return 1; } );

        my $obj = $class->new;
        is( $obj->all_pod_files_ok(@pod_files), 1, 'all_pod_files_ok returned 1' );
        is( $done_testing,                      1, '... done_testing was called once' );
        is( $skip_all,                          0, '... skip_all was never called' );
        is( scalar @pod_file_ok_args,           2, 'pod_file_ok was called twice' );
        my @expected = map { [$_] } @pod_files;
        is_deeply( [@pod_file_ok_args], [@expected], '... with the correct filenames' );
    }

    note('two file in project dir');
    {
        my $tempdir = tempdir();

        my $cwd = cwd();
        chdir $tempdir;

        mkdir "$tempdir/lib";
        my @pod_files = sort 'lib/my_1.pod', 'lib/my_2.pod';
        for my $file (@pod_files) {
            _touch($file);
        }

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @pod_file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'pod_file_ok', sub { my $self = shift; push @pod_file_ok_args, [@_]; return 1; } );

        my $obj = $class->new;
        is( $obj->all_pod_files_ok(), 1, 'all_pod_files_ok returned 1' );
        is( $done_testing,            1, '... done_testing was called once' );
        is( $skip_all,                0, '... skip_all was never called' );
        is( scalar @pod_file_ok_args, 2, 'pod_file_ok was called twice' );
        my @expected = map { [$_] } @pod_files;
        is_deeply( [@pod_file_ok_args], [@expected], '... with the correct filenames' );

        chdir $cwd;
    }

    #
    done_testing();

    exit 0;
}

sub _touch {
    my ($file) = @_;

    open my $fh, '>>', $file;
    close $fh;

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
