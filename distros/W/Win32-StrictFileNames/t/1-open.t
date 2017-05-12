#!/usr/bin/perl -w
use strict;
use Test::More;
use Cwd;

plan tests => 15;

use Win32::StrictFileNames;
ok(1);  # load

ok ( open TXT, "./t/small/bigdirectoryname/test.txt" );
close TXT;

ok ( open TXT, "./t/small/./bigdirectoryname/test.txt" );
close TXT;

ok ( !open TXT, "./t/smaLl/bigdirectoryname/test.txt" );
close TXT;

ok ( !open TXT, "./t/small/bigdirecToryname/test.txt" );
close TXT;

ok ( !open TXT, "./t/small/bigdirecToryname/test.tXt" );
close TXT;

my $cdir = cwd();

ok ( open TXT, "$cdir/t/small/bigdirectoryname/test.txt" );
close TXT;

ok ( !open TXT, "$cdir/t/smaLl/bigdirectoryname/test.txt" );
close TXT;

ok ( !open TXT, "$cdir/t/small/bigdirecToryname/test.txt" );
close TXT;

ok ( !open TXT, "$cdir/t/small/bigdirecToryname/test.tXt" );
close TXT;

$cdir = lc $cdir;
ok ( !open TXT, "$cdir/t/small/bigdirectoryname/test.txt" );
close TXT;

$cdir = cwd();
my $longpath = Win32::GetLongPathName("$cdir/t/small/bigdirectoryname/test.txt");
my $shortpath = Win32::GetShortPathName($longpath);

ok ( open TXT, $longpath );
close TXT;

ok ( open TXT, $shortpath );
close TXT;

$longpath =~ s/StrictFileNames/StrictFiLeNames/;
ok ( !open TXT, $longpath );
close TXT;

$shortpath =~ s/BIGDIR/BIgDIR/;
ok ( !open TXT, $shortpath );
close TXT;
