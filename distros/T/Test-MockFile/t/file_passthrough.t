#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

# Create temp dir BEFORE loading Test::MockFile to avoid
# File::Temp's internal stat/chmod hitting our overrides.
my $dir;
BEGIN {
    $dir = "/tmp/tmf_passthrough_$$";
    CORE::mkdir( $dir, 0700 ) or die "Cannot create $dir: $!";
}

# Strict mode is the default — file_passthrough must work with it.
use Test::MockFile;

subtest(
    'file_passthrough returns a mock object' => sub {
        my $file = "$dir/basic.txt";

        my $mock = Test::MockFile->file_passthrough($file);
        isa_ok( $mock, ['Test::MockFile'], 'returns a Test::MockFile object' );
    }
);

subtest(
    'file_passthrough delegates to real filesystem' => sub {
        my $file = "$dir/delegate.txt";
        my $mock = Test::MockFile->file_passthrough($file);

        # File doesn't exist yet on real FS
        ok( !-e $file, 'file does not exist yet on real FS' );

        # Create the real file via Perl open (goes through CORE::GLOBAL::open override)
        ok( open( my $fh, '>', $file ), 'can open file for writing via override' );
        print {$fh} "hello world\n";
        close $fh;

        # Perl-level checks should see the real file
        ok( -e $file,  '-e sees the real file' );
        ok( -f $file,  '-f sees the real file' );
        ok( !-d $file, '-d correctly returns false' );

        my $size = -s $file;
        is( $size, 12, '-s returns correct size' );

        # Can read back via Perl open
        ok( open( my $fh2, '<', $file ), 'can open file for reading via override' );
        my $content = <$fh2>;
        close $fh2;
        is( $content, "hello world\n", 'content matches what was written' );

        # stat works
        my @stat = stat($file);
        ok( scalar @stat, 'stat returns data' );
        is( $stat[7], 12, 'stat size is correct' );

        # unlink works
        ok( unlink($file), 'can unlink via override' );
        ok( !-e $file, 'file is gone after unlink' );
    }
);

subtest(
    'file_passthrough coexists with regular mocks' => sub {
        my $mocked_file = "$dir/regular.txt";
        my $pass_file   = "$dir/pass.txt";

        my $regular_mock = Test::MockFile->file( $mocked_file, "mocked content" );
        my $pass_mock    = Test::MockFile->file_passthrough($pass_file);

        # Regular mock works as expected
        ok( -f $mocked_file, 'regular mock file exists in mock world' );
        ok( open( my $fh, '<', $mocked_file ), 'can open regular mock' );
        my $content = <$fh>;
        close $fh;
        is( $content, "mocked content", 'regular mock has mocked content' );

        # Passthrough falls through to real FS
        ok( !-e $pass_file, 'passthrough file does not exist on disk yet' );

        # Create real file for passthrough
        ok( open( my $fh2, '>', $pass_file ), 'can write to passthrough path' );
        print {$fh2} "real content\n";
        close $fh2;

        ok( -f $pass_file, 'passthrough file now exists on disk' );
    }
);

subtest(
    'file_passthrough strict rule cleanup on scope exit' => sub {
        my $file = "$dir/scoped.txt";

        {
            my $mock = Test::MockFile->file_passthrough($file);

            # Should be able to access the file without strict mode dying
            ok( !-e $file, 'file does not exist (no strict violation)' );

            # Create it
            ok( open( my $fh, '>', $file ), 'can create file in passthrough scope' );
            print {$fh} "temporary\n";
            close $fh;
            ok( -f $file, 'file exists while passthrough is alive' );

            # Clean up the real file before mock goes out of scope
            CORE::unlink($file);
        }

        # After scope exit, accessing the unmocked file in strict mode should die
        like(
            dies { -e $file },
            qr/unmocked file/,
            'strict mode violation after passthrough goes out of scope',
        );
    }
);

subtest(
    'file_passthrough with glob pattern matches multiple files' => sub {
        my $base = "$dir/mydb.sqlite";

        # Register all SQLite auxiliary files with a single glob
        my $mock = Test::MockFile->file_passthrough("$dir/mydb.sqlite*");

        # Create real files via CORE:: (simulating what XS code like DBD::SQLite does)
        CORE::open( my $fh1, '>', $base )         or die "Cannot create $base: $!";
        print {$fh1} "db\n";
        CORE::close($fh1);

        CORE::open( my $fh2, '>', "$base-wal" )   or die "Cannot create $base-wal: $!";
        print {$fh2} "wal\n";
        CORE::close($fh2);

        CORE::open( my $fh3, '>', "$base-shm" )   or die "Cannot create $base-shm: $!";
        print {$fh3} "shm\n";
        CORE::close($fh3);

        # Perl-level checks should all pass through to real FS without strict violation
        ok( -f $base,         'main db file visible via -f' );
        ok( -f "$base-wal",   'wal file visible via -f' );
        ok( -f "$base-shm",   'shm file visible via -f' );

        my @st = stat($base);
        ok( scalar @st, 'stat works on main db file' );

        CORE::unlink $base, "$base-wal", "$base-shm";
    }
);

subtest(
    'file_passthrough rejects undefined path' => sub {
        like(
            dies { Test::MockFile->file_passthrough(undef) },
            qr/No file provided/,
            'dies with undef path',
        );

        like(
            dies { Test::MockFile->file_passthrough('') },
            qr/No file provided/,
            'dies with empty path',
        );
    }
);

done_testing();

# Cleanup — use CORE:: to bypass Test::MockFile strict mode
END {
    if ( defined $dir ) {
        CORE::unlink "$dir/$_" for qw(basic.txt delegate.txt regular.txt pass.txt scoped.txt
            mydb.sqlite mydb.sqlite-wal mydb.sqlite-shm);
        CORE::rmdir $dir;
    }
}
