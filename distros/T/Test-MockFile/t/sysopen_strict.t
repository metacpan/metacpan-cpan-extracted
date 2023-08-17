#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;

my $can_run;
BEGIN {
    $can_run = ($^V ge 5.28.0);
}

use Test::MockFile ($can_run ? ( plugin => 'FileTemp' ) : ());

use Fcntl;
use File::Temp;

plan skip_all => 'Needs FileTemp plugin' if !$can_run;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my ($separator) = $dir =~ m<([\\/])> or die "No separator in $dir!";

Test::MockFile::add_strict_rule(
    'open',
    qr<\Q$dir$separator\E>,
    1,
);

my $path = "$dir${separator}file";
sysopen my $fh, $path, Fcntl::O_WRONLY | Fcntl::O_CREAT or die "sysopen($path): $!";

my $fh_str = "$fh";

my $err = dies { sysopen my $fh2, $fh, Fcntl::O_RDONLY };
like(
    $err,
    qr<\Q$fh_str\E>,
    'sysopen() to read a filehandle fails',
);

done_testing;

1;
