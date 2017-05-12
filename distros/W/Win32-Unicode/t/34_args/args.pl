use strict;
use warnings;
use utf8;
use blib;
use Win32::Unicode::Native;
open my $fh, '>:utf8', $ARGV[0] or die $!;
print $fh $ARGV[1];
close $fh;
