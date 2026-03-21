#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Errno qw/ENOENT/;

use File::Temp qw/tempfile/;

use Test::MockFile qw< nostrict >;    # Everything below this can have its open overridden.

my $test_string = "abcd\nefgh\n";
my ( $fh_real, $filename ) = tempfile();
print $fh_real $test_string;

note "-------------- REAL MODE --------------";
my $open_return = open( $fh_real, '<:stdio', $filename );
is( $open_return, 1,        "Open a real file bypassing PERLIO" );
is( <$fh_real>,   "abcd\n", " ... line 1" );
is( <$fh_real>,   "efgh\n", " ... line 2" );
is( <$fh_real>,   undef,    " ... EOF" );

close $fh_real;
undef $fh_real;
unlink $filename;

note "-------------- MOCK MODE --------------";
my $bar = Test::MockFile->file( $filename, $test_string );
$open_return = open( $fh_real, '<:stdio', $filename );
is( $open_return, 1,        "Open a mocked file bypassing PERLIO" );
is( <$fh_real>,   "abcd\n", " ... line 1" );
is( <$fh_real>,   "efgh\n", " ... line 2" );
is( <$fh_real>,   undef,    " ... EOF" );

close $fh_real;
ok( -e $filename, "Real file is there" );
undef $bar;

ok( !-e $filename, "Real file is not there" );

note "Following symlinks for open";
my $mock_file = Test::MockFile->file( $filename, $test_string );
my $mock_link = Test::MockFile->symlink( $filename, '/qwerty' );

{
    is( open( my $fh, '<', '/qwerty' ), 1,        "Open a mocked file via its symlink" );
    is( <$fh>,                          "abcd\n", " ... line 1" );
    is( <$fh>,                          "efgh\n", " ... line 2" );
    is( <$fh>,                          undef,    " ... EOF" );
    close $fh;
}

{
    $mock_file->unlink;
    is( open( my $fh, '<', '/qwerty' ), undef,  "Open a mocked file via its symlink when the file is missing fails." );
    is( $! + 0,                         ENOENT, '$! is ENOENT' );
}

subtest(
    'open modes' => sub {
        foreach my $write_mode (qw( > >> )) {
            my $open_str = $write_mode . '/debug.log';
            my $file     = Test::MockFile->file( '/debug.log', '' );
            my $fh;

            $! = 0;
            ok( open( $fh, $open_str ), "Two-arg $write_mode open works" );
            is( $! + 0, 0, 'No error' );

            $! = 0;
            ok( close($fh), 'Successfully closed open handle' );
            is( $! + 0, 0, 'No error' );
        }

        foreach my $read_mode ( '<', '' ) {
            my $open_str = $read_mode . '/debug.log';
            my $file     = Test::MockFile->file( '/debug.log', '' );
            my $fh;

            $! = 0;
            ok( open( $fh, $open_str ), "Two-arg $read_mode open works" );
            is( $open_str, "${read_mode}/debug.log", "arg not changed" );
            is( $! + 0,    0,                        'No error' );

            $! = 0;
            ok( close($fh), 'Successfully closed open handle' );
            is( $! + 0, 0, 'No error' );
        }

        foreach my $multi_mode (qw( +< +> )) {
            my $open_str = $multi_mode . '/debug.log';
            my $file     = Test::MockFile->file( '/debug.log', '' );
            my $fh;

            $! = 0;
            ok( open( $fh, $open_str ), "Two-arg $multi_mode open fails" );
            is( $! + 0, 0, 'No error' );

            $! = 0;
            ok( open( $fh, $multi_mode, '/debug.log' ), "Three-arg $multi_mode open fails" );
            is( $! + 0, 0, 'No error' );
        }

        # Pipe open pass-through
        my ( $fh, $tempfile ) = tempfile( 'CLEANUP' => 1 );
        my $pipefh;

        # Three-arg pipe write
        ok( open( $pipefh, '|-', "echo hello >> $tempfile" ), 'Succesful three-arg pipe open write' );

        # No point testing $! because it will correctly be set to ESPIPE (29, illegal seek)

        $! = 0;
        ok( close($pipefh), 'Successfully closed pipe' );
        is( $! + 0, 0, 'No error' );

        # Two-arg pipe write
        ok( open( $pipefh, "|echo world >> $tempfile" ), 'Succesful two-arg pipe open write' );

        # No point testing $! because it will correctly be set to ESPIPE (29, illegal seek)

        $! = 0;
        ok( close($pipefh), 'Successfully closed pipe' );
        is( $! + 0, 0, 'No error' );

        # Three-arg pipe write
        ok( open( $pipefh, '-|', "cat $tempfile" ), 'Succesful three-arg pipe open read' );

        # No point testing $! because it will correctly be set to ESPIPE (29, illegal seek)

        my $out = <$pipefh>;
        is( $out, "hello\n", 'Succesfully read from pipe with three-arg' );

        ok( close($pipefh), 'Successfully closed pipe' );

        # No point testing $! because it will correctly be set to ESPIPE (29, illegal seek)

        # Two-arg pipe write
        $out = '';
        ok( open( $pipefh, "cat $tempfile|" ), 'Succesful two-arg pipe open read' );

        # No point testing $! because it will correctly be set to ESPIPE (29, illegal seek)

        $out = <$pipefh>;
        $out .= <$pipefh>;
        is( $out, "hello\nworld\n", 'Succesfully read from pipe with two-arg' );

        $! = 0;
        ok( close($pipefh), 'Successfully closed pipe' );
        is( $! + 0, 0, 'No error' );
    }
);

note "-------------- BROKEN SYMLINK OPEN --------------";
{
    # Symlink to a path with no mock = broken symlink (target doesn't exist)
    my $link = Test::MockFile->symlink( '/nonexistent_target', '/broken_link' );

    # Opening a broken symlink should fail with ENOENT, not confess
    $! = 0;
    my $ret = open( my $fh, '<', '/broken_link' );
    ok( !$ret,              'open on broken symlink returns false' );
    is( $! + 0, ENOENT, 'open on broken symlink sets $! to ENOENT' );
}

done_testing();
exit;
