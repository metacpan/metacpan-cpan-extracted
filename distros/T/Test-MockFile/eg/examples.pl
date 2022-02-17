#!perl

use strict;
use warnings;
use feature qw< say >;

use lib 'lib';

# This is straight from the SYNOPSIS

# strict mode by default
use Test::MockFile ();

# non-strict mode
# use Test::MockFile qw< nostrict >;

# Be sure to assign the output of mocks, they disappear when they go out of scope
my $foobar = Test::MockFile->file( "/foo/bar", "contents\ngo\nhere" );
open my $fh, '<', '/foo/bar' or die;    # Does not actually open the file on disk
say '/foo/bar exists' if -e $fh;
close $fh;

say '/foo/bar is a file' if -f '/foo/bar';
say '/foo/bar is THIS BIG: ' . -s '/foo/bar';

my $foobaz = Test::MockFile->file('/foo/baz');    # File starts out missing
my $opened = open my $baz_fh, '<', '/foo/baz';    # File reports as missing so fails
say '/foo/baz does not exist yet' if !-e '/foo/baz';

open $baz_fh, '>', '/foo/baz' or die;             # open for writing
print {$baz_fh} "first line\n";

open $baz_fh, '>>', '/foo/baz' or die;            # open for append.
print {$baz_fh} "second line";
close $baz_fh;

say "Contents of /foo/baz:\n>>" . $foobaz->contents() . '<<';

# Unmock your file.
# (same as the variable going out of scope
undef $foobaz;

# The file check will now happen on file system now the file is no longer mocked.
say '/foo/baz is missing again (no longer mocked)' if !-e '/foo/baz';

my $quux    = Test::MockFile->file( '/foo/bar/quux.txt', '' );
my @matches = </foo/bar/*.txt>;

# ( '/foo/bar/quux.txt' )
say "Contents of /foo/bar directory: " . join "\n", @matches;

@matches = glob('/foo/bar/*.txt');

# same as above
say "Contents of /foo/bar directory (using glob()): " . join "\n", @matches;
