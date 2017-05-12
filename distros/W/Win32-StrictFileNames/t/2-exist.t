#!/usr/bin/perl -w
use strict;
use Test::More;
use Cwd;

plan tests => 15;

use Win32::StrictFileNames;
ok(1);  # load

ok ( -e "./t/small/bigdirectoryname/test.txt" );

ok ( -e "./t/small/./bigdirectoryname/test.txt" );

ok ( ! -e "./t/smaLl/bigdirectoryname/test.txt" );

ok ( ! -e "./t/small/bigdirecToryname/test.txt" );

ok ( ! -e "./t/small/bigdirecToryname/test.tXt" );

my $cdir = cwd();

ok ( -e "$cdir/t/small/bigdirectoryname/test.txt" );

ok ( ! -e "$cdir/t/smaLl/bigdirectoryname/test.txt" );

ok ( ! -e "$cdir/t/small/bigdirecToryname/test.txt" );

ok ( ! -e "$cdir/t/small/bigdirecToryname/test.tXt" );

$cdir = lc $cdir;
ok ( ! -e "$cdir/t/small/bigdirectoryname/test.txt" );

$cdir = cwd();
my $longpath = Win32::GetLongPathName("$cdir/t/small/bigdirectoryname/test.txt");
my $shortpath = Win32::GetShortPathName($longpath);

ok ( -e $longpath );

ok ( -e $shortpath );

$longpath =~ s/StrictFileNames/StrictFiLeNames/;
ok ( ! -e $longpath );

$shortpath =~ s/BIGDIR/BIgDIR/;
ok ( ! -e $shortpath );
