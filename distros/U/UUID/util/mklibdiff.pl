#!perl -l

# make a diff between a patch level 1 file (usrcP)
# and a patch level 2 (ulib) file.
#
# e.g.:
#diff -au usrcP/uuid/uuidd.h ulib/uuid/uuidd.h
# or:
#perl util/mklibdiff uuid/uuidd.h

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
my $from = catfile( 'usrcP', $file );
my $to   = catfile( 'ulib', $file );

#print $from;
#print $to;

print diff($from,$to);
