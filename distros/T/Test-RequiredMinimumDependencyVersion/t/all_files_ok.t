#!perl

use 5.006;
use strict;
use warnings;

use Test::MockModule;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd;
use POSIX 'mkfifo';

use Test::RequiredMinimumDependencyVersion;

main();

sub main {
    my $class = 'Test::RequiredMinimumDependencyVersion';

    note('no file found in cwd');
    {
        my $cwd = cwd();
        _chdir( tempdir() );

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok,    1, 'all_files_ok returned 1' );
        is( $done_testing,         0, '... done_testing was not called' );
        is( $skip_all,             1, '... skip_all was called once' );
        is( scalar @skip_all_args, 2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found\n", '... and a message' );

        _chdir($cwd);
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

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok($tempdir), 1, 'all_files_ok returned 1' );
        is( $done_testing,                0, '... done_testing was not called' );
        is( $skip_all,                    1, '... skip_all was called once' );
        is( scalar @skip_all_args,        2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found in ($tempdir)\n", '... and a message' );
    }

    note('file passed as argument does not exist');
    {
        my $tempdir = tempdir();
        my $file    = "$tempdir/nonexisting_file";

        my $carp = 0;
        my @carp_args;
        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'carp', sub { @carp_args = @_; $carp++; return; } );
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok($file), 1, 'all_files_ok returned 1' );
        is( $done_testing,             0, '... done_testing was not called' );
        is( $skip_all,                 1, '... skip_all was called once' );
        is( scalar @skip_all_args,     2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found in ($file)\n", '... and a message' );
        is( $carp,             1,                             '... carp was called once' );
        is( scalar @carp_args, 2,                             '... with the correct number of arguments' );
        isa_ok( $carp_args[0], 'Test::Builder', '... a Test::Builder object' );
        like( $carp_args[1], "/\QFile '$file' does not exist\E/xsm", '... and a message' );
    }

    note('symlink passed as argument is ignored');
  SKIP: {
        skip 'The symlink function is unimplemented', 1 if !_symlink_supported();

        my $tempdir = tempdir();
        _touch("$tempdir/file.pm");
        _mkdir("$tempdir/lib");
        my $link = "$tempdir/lib/symlink.pm";
        _symlink( '../file.pm', $link );

        my $carp = 0;
        my @carp_args;
        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'carp', sub { @carp_args = @_; $carp++; return; } );
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok($link), 1, 'all_files_ok returned 1' );
        is( $done_testing,             0, '... done_testing was not called' );
        is( $skip_all,                 1, '... skip_all was called once' );
        is( scalar @skip_all_args,     2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found in ($link)\n", '... and a message' );
        is( $carp,             1,                             '... carp was called once' );
        is( scalar @carp_args, 2,                             '... with the correct number of arguments' );
        isa_ok( $carp_args[0], 'Test::Builder', '... a Test::Builder object' );
        like( $carp_args[1], "/\QIgnoring symlink '$link'\E/xsm", '... and a message' );
    }

    note('fifo passed as argument is ignored');
  SKIP: {
        skip 'The mkfifo function is unimplemented', 1 if !_fifo_supported();

        my $tempdir = tempdir();
        _mkdir("$tempdir/lib");
        my $fifo = "$tempdir/lib/symlink.pm";
        mkfifo $fifo, 0666;

        my $carp = 0;
        my @carp_args;
        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'carp', sub { @carp_args = @_; $carp++; return; } );
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok($fifo), 1, 'all_files_ok returned 1' );
        is( $done_testing,             0, '... done_testing was not called' );
        is( $skip_all,                 1, '... skip_all was called once' );
        is( scalar @skip_all_args,     2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found in ($fifo)\n", '... and a message' );
        is( $carp,             1,                             '... carp was called once' );
        is( scalar @carp_args, 2,                             '... with the correct number of arguments' );
        isa_ok( $carp_args[0], 'Test::Builder', '... a Test::Builder object' );
        like( $carp_args[1], "/\QFile '$fifo' is not a file nor a directory. Ignoring it.\E/xsm", '... and a message' );
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

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok( $tempdir, $tempdir2 ), 1, 'all_files_ok returned 1' );
        is( $done_testing,         0, '... done_testing was not called' );
        is( $skip_all,             1, '... skip_all was called once' );
        is( scalar @skip_all_args, 2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found in ($tempdir $tempdir2)\n", '... and a message' );
    }

    note('symlink to file in cwd');
  SKIP: {
        skip 'The symlink function is unimplemented', 1 if !_symlink_supported();

        my $cwd = cwd();
        _chdir( tempdir() );

        _mkdir('lib');
        _mkdir('tmp');
        _touch('tmp/file.pm');
        _symlink( '../tmp/file.pm', 'lib/file.pm' );

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok,    1, 'all_files_ok returned 1' );
        is( $done_testing,         0, '... done_testing was not called' );
        is( $skip_all,             1, '... skip_all was called once' );
        is( scalar @skip_all_args, 2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found in (lib)\n", '... and a message' );

        _chdir($cwd);
    }

    note('symlink to dir in cwd');
  SKIP: {
        skip 'The symlink function is unimplemented', 1 if !_symlink_supported();

        my $cwd = cwd();
        _chdir( tempdir() );

        _mkdir('lib');
        _mkdir('lib/a');
        _mkdir('tmp');
        _mkdir('tmp/a');
        _mkdir('tmp/a/b');
        _touch('tmp/a/b/file.pm');
        _symlink( '../../tmp/a/b', 'lib/a/b' );

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok,    1, 'all_files_ok returned 1' );
        is( $done_testing,         0, '... done_testing was not called' );
        is( $skip_all,             1, '... skip_all was called once' );
        is( scalar @skip_all_args, 2, '... with the correct number of arguments' );
        isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
        is( $skip_all_args[1], "No files found in (lib)\n", '... and a message' );

        _chdir($cwd);
    }

    note('one file in tempdir');
    {
        my $tempdir = tempdir();
        _mkdir("$tempdir/lib");
        my $file = "$tempdir/lib/my.pm";
        _touch($file);

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'file_ok', sub { my $self = shift; push @file_ok_args, [@_]; return 1; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok($tempdir), 1, 'all_files_ok returned 1' );
        is( $done_testing,                1, '... done_testing was called once' );
        is( $skip_all,                    0, '... skip_all was never called' );
        is( scalar @file_ok_args,         1, 'file_ok was called once' );
        is_deeply( [@file_ok_args], [ [$file] ], '... with the correct filename' );
    }

    note('one file in tempdir (passed as file and dir)');
    {
        my $tempdir = tempdir();
        _mkdir("$tempdir/lib");
        my $file = "$tempdir/lib/my.pm";
        _touch($file);

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'file_ok', sub { my $self = shift; push @file_ok_args, [@_]; return 1; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok( $file, $tempdir ), 1, 'all_files_ok returned 1' );
        is( $done_testing,        1, '... done_testing was called once' );
        is( $skip_all,            0, '... skip_all was never called' );
        is( scalar @file_ok_args, 2, 'file_ok was called twice' );
        is_deeply( [@file_ok_args], [ [$file], [$file] ], '... with the same filename twice' );
    }

    note('two file in tempdir');
    {
        my $tempdir = tempdir();
        _mkdir("$tempdir/lib");
        my @files = sort "$tempdir/lib/my_1.pm", "$tempdir/lib/my_2.pm";
        for my $file (@files) {
            _touch($file);
        }

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'file_ok', sub { my $self = shift; push @file_ok_args, [@_]; return 1; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok($tempdir), 1, 'all_files_ok returned 1' );
        is( $done_testing,                1, '... done_testing was called once' );
        is( $skip_all,                    0, '... skip_all was never called' );
        is( scalar @file_ok_args,         2, 'file_ok was called twice' );
        my @expected = map { [$_] } @files;
        is_deeply( [@file_ok_args], [@expected], '... with the correct filenames' );
    }

    note('two file in cwd');
    {
        my $cwd     = cwd();
        my $tempdir = tempdir();
        _mkdir("$tempdir/lib");
        my @files = sort "$tempdir/lib/my_1.pm", "$tempdir/lib/my_2.pm";
        for my $file (@files) {
            _touch($file);
        }

        _chdir($tempdir);

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'file_ok', sub { my $self = shift; push @file_ok_args, [@_]; return 1; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok($tempdir), 1, 'all_files_ok returned 1' );
        is( $done_testing,                1, '... done_testing was called once' );
        is( $skip_all,                    0, '... skip_all was never called' );
        is( scalar @file_ok_args,         2, 'file_ok was called twice' );
        my @expected = map { [$_] } @files;
        is_deeply( [@file_ok_args], [@expected], '... with the correct filenames' );

        _chdir($cwd);
    }

    note('one mismatched file');
    {
        my $cwd     = cwd();
        my $tempdir = tempdir();
        _mkdir("$tempdir/lib");
        my $file = "$tempdir/lib/mismatched.pm";
        _touch( $file, 'use Local::XYZ 0.001;' );

        _chdir($tempdir);

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'file_ok', sub { my $self = shift; push @file_ok_args, [@_]; return; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.002' } );
        is( $obj->all_files_ok($tempdir), undef, 'all_files_ok returned undef' );
        is( $done_testing,                1,     '... done_testing was called once' );
        is( $skip_all,                    0,     '... skip_all was never called' );
        is( scalar @file_ok_args,         1,     'file_ok was called once' );

        is_deeply( [@file_ok_args], [ [$file] ], '... with the correct filenames' );

        _chdir($cwd);
    }

    note('two file in tempdir (called with filenames)');
    {
        my $tempdir = tempdir();
        _mkdir("$tempdir/lib");
        my @files = sort "$tempdir/lib/my_1.pm", "$tempdir/lib/my_2.pm";
        for my $file (@files) {
            _touch($file);
        }

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'file_ok', sub { my $self = shift; push @file_ok_args, [@_]; return 1; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok(@files), 1, 'all_files_ok returned 1' );
        is( $done_testing,              1, '... done_testing was called once' );
        is( $skip_all,                  0, '... skip_all was never called' );
        is( scalar @file_ok_args,       2, 'file_ok was called twice' );
        my @expected = map { [$_] } @files;
        is_deeply( [@file_ok_args], [@expected], '... with the correct filenames' );
    }

    note('two file in project dir');
    {
        my $tempdir = tempdir();

        my $cwd = cwd();
        _chdir($tempdir);

        _mkdir("$tempdir/lib");
        my @files = sort 'lib/my_1.pm', 'lib/my_2.pm';
        for my $file (@files) {
            _touch($file);
        }

        my $done_testing = 0;
        my $skip_all     = 0;
        my @skip_all_args;
        my $module = Test::MockModule->new('Test::Builder');
        $module->mock( 'done_testing', sub { $done_testing++; return; } );
        $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

        my @file_ok_args;
        my $tpl = Test::MockModule->new($class);
        $tpl->mock( 'file_ok', sub { my $self = shift; push @file_ok_args, [@_]; return 1; } );

        my $obj = $class->new( module => { 'Local::XYZ' => '0.001' } );
        is( $obj->all_files_ok(), 1, 'all_files_ok returned 1' );
        is( $done_testing,        1, '... done_testing was called once' );
        is( $skip_all,            0, '... skip_all was never called' );
        is( scalar @file_ok_args, 2, 'file_ok was called twice' );
        my @expected = map { [$_] } @files;
        is_deeply( [@file_ok_args], [@expected], '... with the correct filenames' );

        _chdir($cwd);
    }

    #
    done_testing();

    exit 0;
}

sub _chdir {
    my ($dir) = @_;

    my $rc = chdir $dir;
    BAIL_OUT("chdir $dir: $!") if !$rc;
    return $rc;
}

{
    my $_fifo_supported;

    sub _fifo_supported {
        if ( !defined $_fifo_supported ) {
            $_fifo_supported = 0;

            ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
            eval {
                mkfifo q{}, 0666;
                $_fifo_supported = 1;
            };
            ## use critic
        }

        return $_fifo_supported;
    }
}

sub _mkdir {
    my ($dir) = @_;

    my $rc = mkdir $dir;
    BAIL_OUT("mkdir $dir: $!") if !$rc;
    return $rc;
}

sub _symlink {
    my ( $old_name, $new_name ) = @_;

    my $rc = symlink $old_name, $new_name;
    BAIL_OUT("symlink $old_name, $new_name: $!") if !$rc;
    return $rc;
}

{
    my $_symlink_supported;

    sub _symlink_supported {
        if ( !defined $_symlink_supported ) {
            $_symlink_supported = 0;

            ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
            eval {
                symlink q{}, q{};    ## no critic (InputOutput::RequireCheckedSyscalls)
                $_symlink_supported = 1;
            };
            ## use critic
        }

        return $_symlink_supported;
    }
}

sub _touch {
    my ( $file, @content ) = @_;

    if ( open my $fh, '>', $file ) {
        if ( print {$fh} @content ) {
            return if close $fh;
        }
    }

    BAIL_OUT("Cannot write file '$file': $!");
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
