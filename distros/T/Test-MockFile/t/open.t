#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Errno qw/ENOENT EBADF/;

use File::Temp qw/tempfile/;

use Test::MockFile;    # Everything below this can have its open overridden.

my $test_string = "abcd\nefgh\n";
my ( $fh_real, $filename ) = tempfile();
print $fh_real $test_string;

note "-------------- REAL MODE --------------";
is( open( $fh_real, '<:stdio', $filename ), 1, "Open a real file bypassing PERLIO" );
is( <$fh_real>, "abcd\n", " ... line 1" );
is( <$fh_real>, "efgh\n", " ... line 2" );
is( <$fh_real>, undef,    " ... EOF" );

close $fh_real;
undef $fh_real;
unlink $filename;

note "-------------- MOCK MODE --------------";
my $bar = Test::MockFile->file( $filename, $test_string );
is( open( $fh_real, '<:stdio', $filename ), 1, "Open a real file bypassing PERLIO" );
is( <$fh_real>, "abcd\n", " ... line 1" );
is( <$fh_real>, "efgh\n", " ... line 2" );
is( <$fh_real>, undef,    " ... EOF" );

close $fh_real;
ok( -e $filename, "Real file is there" );
undef $bar;

ok( !-e $filename, "Real file is not there" );
done_testing();

