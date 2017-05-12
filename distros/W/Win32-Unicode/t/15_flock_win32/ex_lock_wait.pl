use strict;
use warnings;
use blib;
use Win32::Unicode;

my $tmpdir = shift;

my $lock_file = "$tmpdir/ex_lock_wait";

my $fh = Win32::Unicode::File->new;
$fh->open(w => $lock_file) or die $!;
$fh->flock(2);
$fh->write('test');
sleep 2;
$fh->unlock;
$fh->close;
