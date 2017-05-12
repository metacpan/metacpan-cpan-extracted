#!/usr/bin/perl -w
use strict;
use Test::More;
use Cwd;

plan tests => 14;

use Win32::StrictFileNames;
ok(1);  # load

mkdir "./t/small/bigdirectoryname/TestDir";

ok( !rmdir "./t/smaLl/bigdirectoryname/TestDir" );

ok( !rmdir "./t/small/bigdirecToryname/TestDir" );

ok( !rmdir "./t/small/bigdirectoryname/Testdir" );

ok( rmdir "./t/small/bigdirectoryname/TestDir" );

ok( !rmdir "./t/small/bigdirectoryname/TestDir" );

mkdir "./t/small/bigdirectoryname/TestDir";
my $cdir = cwd();

ok ( !rmdir "$cdir/t/small/bigdirecToryname/TestDir" );

ok ( !rmdir "$cdir/t/small/bigdirecToryname/Testdir" );

ok (  rmdir "$cdir/t/small/bigdirectoryname/TestDir" );

mkdir "./t/small/bigdirectoryname/TestDir";
mkdir "./t/bigdirectoryname/small/TestDir";
$cdir = lc $cdir;

ok ( !rmdir "$cdir/t/small/bigdirectoryname/TestDir" );

$cdir = cwd();
my $longpath = Win32::GetLongPathName("$cdir/t/small/bigdirectoryname/TestDir");
my $shortpath = Win32::GetShortPathName("$cdir/t/bigdirectoryname/small/TestDir");

$longpath =~ s/StrictFileNames/StrictFiLeNames/;
ok ( !rmdir $longpath );

$shortpath =~ s/BIGDIR/BIgDIR/;
ok ( !rmdir $shortpath );

$longpath = Win32::GetLongPathName("$cdir/t/small/bigdirectoryname/TestDir");
$shortpath = Win32::GetShortPathName("$cdir/t/bigdirectoryname/small/TestDir");

ok ( rmdir $longpath );

ok ( rmdir $shortpath );
