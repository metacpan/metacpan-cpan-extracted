use strict;
use warnings;
use blib;
use Win32::Unicode;

my $tmpdir = shift;

my $lock_file = "$tmpdir/shared_lock_wait";

my $fh = Win32::Unicode::File->new;
$fh->open(w => "$tmpdir/shared_lock_wait") or die $!;
print $fh "test";
$fh->close;

$fh->open(r => $lock_file) or die $!;
$fh->flock(1) or die $!;
sleep 2;
$fh->unlock or die $!;
$fh->close;
