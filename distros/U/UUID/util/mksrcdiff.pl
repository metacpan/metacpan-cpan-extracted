#!perl -l

# make a diff between a usrc file
# and a patch level 1 (usrcP) file.
#
# e.g.:
#diff -au usrc/uuid/uuidd.h usrcP/uuid/uuidd.h
# or:
#perl util/mkdiff uuid/uuidd.h

use strict;
use warnings;
use Text::Diff;
use File::Spec::Functions qw(
    abs2rel
    catfile
    file_name_is_absolute
    rel2abs
);

my $file = $ARGV[0];

unless ( file_name_is_absolute($file) ) {
    $file = rel2abs($file);
}

$file    = abs2rel($file);
my $from = catfile( 'usrc', $file );
my $to   = catfile( 'usrcP', $file );

#print $from;
#print $to;

print diff($from,$to);
