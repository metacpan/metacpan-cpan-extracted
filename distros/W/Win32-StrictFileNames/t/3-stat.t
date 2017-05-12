#!/usr/bin/perl -w
use strict;
use Test::More;
use Cwd;

plan tests => 15;

use Win32::StrictFileNames;
ok(1);  # load

ok ( stat "./t/small/bigdirectoryname/test.txt" );

ok ( stat "./t/small/./bigdirectoryname/test.txt" );

ok ( ! stat "./t/smaLl/bigdirectoryname/test.txt" );

ok ( ! stat "./t/small/bigdirecToryname/test.txt" );

ok ( ! stat "./t/small/bigdirecToryname/test.tXt" );

my $cdir = cwd();

ok ( stat "$cdir/t/small/bigdirectoryname/test.txt" );

ok ( ! stat "$cdir/t/smaLl/bigdirectoryname/test.txt" );

ok ( ! stat "$cdir/t/small/bigdirecToryname/test.txt" );

ok ( ! stat "$cdir/t/small/bigdirecToryname/test.tXt" );

$cdir = lc $cdir;
ok ( ! stat "$cdir/t/small/bigdirectoryname/test.txt" );

$cdir = cwd();
my $longpath = Win32::GetLongPathName("$cdir/t/small/bigdirectoryname/test.txt");
my $shortpath = Win32::GetShortPathName($longpath);

ok ( stat $longpath );

ok ( stat $shortpath );

$longpath =~ s/StrictFileNames/StrictFiLeNames/;
ok ( ! stat $longpath );

$shortpath =~ s/BIGDIR/BIgDIR/;
ok ( ! stat $shortpath );
