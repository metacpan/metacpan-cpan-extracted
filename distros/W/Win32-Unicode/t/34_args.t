use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw/tempdir/;
use Win32::Unicode::Constant qw/CYGWIN/;
use File::Copy qw/copy/;
use Encode;

my $tmpdir = tempdir CLEANUP => 1;
my $script = "$tmpdir/args.pl";
copy 't/34_args/args.pl', $script or die $!;

my $argv = 'test';
ok !system $^X, "$script", "$tmpdir/out", $argv;

open my $fh, '<', "$tmpdir/out" or die $!;
is <$fh>, $argv;
close $fh;

done_testing;
