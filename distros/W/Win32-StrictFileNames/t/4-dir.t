#!/usr/bin/perl -w
use strict;
use Test::More;
use Cwd;

plan tests => 13;

use Win32::StrictFileNames;
ok(1);  # load

ok ( opendir DIR, "./t/small/bigdirectoryname" );

ok ( opendir DIR, "./t/small/./bigdirectoryname" );

ok ( ! opendir DIR, "./t/smaLl/bigdirectoryname" );

ok ( ! opendir DIR, "./t/small/bigdirecToryname" );

my $cdir = cwd();

ok ( opendir DIR, "$cdir/t/small/bigdirectoryname" );

ok ( ! opendir DIR, "$cdir/t/smaLl/bigdirectoryname" );

ok ( ! opendir DIR, "$cdir/t/small/bigdirecToryname" );

$cdir = lc $cdir;
ok ( ! opendir DIR, "$cdir/t/small/bigdirectoryname" );

$cdir = cwd();
my $longpath = Win32::GetLongPathName("$cdir/t/small/bigdirectoryname");
my $shortpath = Win32::GetShortPathName($longpath);

ok ( opendir DIR, $longpath );

ok ( opendir DIR, $shortpath );

$longpath =~ s/StrictFileNames/StrictFiLeNames/;
ok ( ! opendir DIR, $longpath );

$shortpath =~ s/BIGDIR/BIgDIR/;
ok ( ! opendir DIR, $shortpath );
