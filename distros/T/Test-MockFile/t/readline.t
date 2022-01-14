#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT EBADF/;

use File::Temp qw/tempfile/;

use Test::MockFile;    # Everything below this can have its open overridden.

my ( $fh_real, $filename ) = tempfile();
print {$fh_real} "not\nmocked\n";
close $fh_real;

note "-------------- REAL MODE --------------";
is( -s $filename,                     11, "Temp file is on disk and right size" );
is( open( $fh_real, '<', $filename ), 1,  "Open a real file written by File::Temp" );
like( "$fh_real", qr/^GLOB\(0x[0-9a-f]+\)$/, '$fh2 stringifies to a GLOB' );
is( <$fh_real>, "not\n",    " ... line 1" );
is( <$fh_real>, "mocked\n", " ... line 2" );

{
    my $warn_msg;
    local $SIG{__WARN__} = sub { $warn_msg = shift };
    is( print( {$fh_real} "TEST" ), undef, "Fails to write to a read handle in mock mode." );
    is( $! + 0,                     EBADF, q{$! when the file is written to and it's a read file handle.} );
    like( $warn_msg, qr{^Filehandle \S+ opened only for input at t/readline.t line \d+}, "Warns about writing to a read file handle" );
}

close $fh_real;

note "-------------- MOCK MODE --------------";
my $bar = Test::MockFile->file( $filename, "abc\ndef\nghi\n" );

is( open( my $fh, '<', $filename ), 1, "Mocked temp file opens and returns true" );

isa_ok( $fh, ["IO::File"], '$fh is a IO::File' );
like( "$fh", qr/^IO::File=GLOB\(0x[0-9a-f]+\)$/, '$fh stringifies to a IO::File GLOB' );
is( <$fh>, "abc\n", '1st read on $fh is "abc\n"' );

is( <$fh>,          "def\n",           '2nd read on $fh is "def\n"' );
is( readline($fh),  "ghi\n",           '3rd read on $fh via readline is "ghi\n"' );
is( <$fh>,          undef,             '4th read on $fh undef at EOF' );
is( <$fh>,          undef,             '5th read on $fh undef at EOF' );
is( <$fh>,          undef,             '6th read on $fh undef at EOF' );
is( $bar->contents, "abc\ndef\nghi\n", '$foo->contents' );

$bar->contents( join( "\n", qw/abc def jkl mno pqr/ ) );
is( <$fh>, "mno\n", '7th read on $fh is "mno\n"' );
is( <$fh>, "pqr",   '7th read on $fh is "pqr"' );
is( <$fh>, undef,   '8th read on $fh undef at EOF' );
is( <$fh>, undef,   '9th read on $fh undef at EOF' );

{
    my $warn_msg;
    local $SIG{__WARN__} = sub { $warn_msg = shift };
    is( print( {$fh} "TEST" ), undef, "Fails to write to a read handle in mock mode." );
    is( $! + 0,                EBADF, q{$! when the file is written to and it's a read file handle.} );
    like( $warn_msg, qr{^Filehandle .+? opened only for input at .+? line \d+\.$}, "Warns about writing to a read file handle" );
}

close $fh;
ok( !exists $Test::MockFile::files_being_mocked{$filename}->{'fh'}, "file handle clears from files_being_mocked hash when it goes out of scope." );

undef $bar;
is( scalar %Test::MockFile::files_being_mocked, 0, "files_being_mocked empties when \$bar is cleared" );

note "-------------- REAL MODE --------------";
is( open( $fh_real, '<', $filename ), 1, "Once the mock file object is cleared, the next open reverts to the file on disk." );
like( "$fh_real", qr/^GLOB\(0x[0-9a-f]+\)$/, '$fh2 stringifies to a GLOB' );
is( <$fh_real>, "not\n",    " ... line 1" );
is( <$fh_real>, "mocked\n", " ... line 1" );
close $fh_real;

# Missing file handling
{
    local $!;
    unlink $filename;
}

undef $fh;
is( open( $fh, '<', $filename ), undef,  qq{Can't open a missing file "$filename"} );
is( $! + 0,                      ENOENT, 'What $! looks like when failing to open the missing file.' );

{
    note "-------------- MOCK MODE --------------";
    my $baz = Test::MockFile->file($filename);
    is( open( my $fh, '<', $filename ), undef,  qq{Can't open a missing file "$filename"} );
    is( $! + 0,                         ENOENT, 'What $! looks like when failing to open the missing file.' );
}

#### Slurp

my $multiline      = "abc\ndef\nghi\r\ndhdbhjdb\r";
my $mock_multiline = reverse "abc\ndef\nghi\r\ndhdbhjdb\r";
open( $fh, ">", $filename ) or die;
print $fh $multiline;
close $fh;

sub slurp {
    open( my $fh, '<', $filename ) or die("Failed to open slurp file: $!");
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

{
    note "---------------------------------------";
    is( slurp(), $multiline, "REAL multiline do slurp works" );
    my $baz = Test::MockFile->file( $filename, $mock_multiline );
    is( slurp(), $mock_multiline, "MOCK multiline do slurp works" );
}

{
    note "readline array.";
    my $baz = Test::MockFile->file( $filename, $multiline );
    open( my $fh, '<', $filename );
    my @read = <$fh>;
    is( \@read, [ "abc\n", "def\n", "ghi\r\n", "dhdbhjdb\r" ], "readline reads in an array of stuff." );
}

done_testing();
exit;
