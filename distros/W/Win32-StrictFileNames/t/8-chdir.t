#!/usr/bin/perl -w
use strict;
use Test::More;
use Cwd;

plan tests => 11;

use Win32::StrictFileNames;
ok(1);  # load

mkdir "./t/small/bigdirectoryname/TestDir";

ok( !chdir "./t/smaLl/bigdirectoryname/TestDir" );

ok( !chdir "./t/small/bigdirecToryname/TestDir" );

ok( !chdir "./t/small/bigdirectoryname/Testdir" );

ok( chdir "./t/small/bigdirectoryname/TestDir" );

my $cdir = cwd();

ok ( chdir "$cdir" );

$cdir = lc $cdir;
ok ( !chdir "$cdir" );

$cdir = cwd();
my $longpath = Win32::GetLongPathName("$cdir");
my $shortpath = Win32::GetShortPathName("$cdir");

ok ( chdir $longpath );

ok ( chdir $shortpath );

$longpath =~ s/StrictFileNames/StrictFiLeNames/;
ok ( !chdir $longpath );

$shortpath =~ s/BIGDIR/BIgDIR/;
ok ( !chdir $shortpath );



