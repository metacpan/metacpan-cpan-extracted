#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Errno qw/ENOENT/;

use File::Temp qw/tempfile/;

use Test::MockFile;    # Everything below this can have its open overridden.

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
    is( open( my $fh, '<', '/qwerty' ), 1, "Open a mocked file via its symlink" );
    is( <$fh>, "abcd\n", " ... line 1" );
    is( <$fh>, "efgh\n", " ... line 2" );
    is( <$fh>, undef,    " ... EOF" );
    close $fh;
}

{
    $mock_file->unlink;
    is( open( my $fh, '<', '/qwerty' ), undef, "Open a mocked file via its symlink when the file is missing fails." );
    is( $! + 0, ENOENT, '$! is ENOENT' );
}

done_testing();
exit;
