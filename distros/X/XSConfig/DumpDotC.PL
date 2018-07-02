#!/usr/bin/perl
# this file compresses and binary encodes Config.c and prints it to console
# so it can be reviewed on CPANTesters from the build log
use strict;
use warnings;
use MIME::Base64;
use IO::Compress::Bzip2 qw(bzip2 $Bzip2Error);

open my $fh, '<', 'Config.c' or die "Can't open Config.c: $!";
my $data;
{
    local $/ = undef;
    $data = <$fh>;
}
close $fh;
my $out;
bzip2(\$data => \$out) or die "bzip2 failed: $Bzip2Error\n";
$out = encode_base64($out);
print $out;
