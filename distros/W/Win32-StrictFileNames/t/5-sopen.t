#!/usr/bin/perl -w
use strict;
use Test::More;
use Cwd;
use Fcntl;

plan tests => 15;

use Win32::StrictFileNames;
ok(1);  # load

ok ( sysopen TXT, "./t/small/bigdirectoryname/test.txt", O_RDONLY  );
close TXT;

ok ( sysopen TXT, "./t/small/./bigdirectoryname/test.txt", O_RDONLY );
close TXT;

ok ( !sysopen TXT, "./t/smaLl/bigdirectoryname/test.txt", O_RDONLY );
close TXT;

ok ( !sysopen TXT, "./t/small/bigdirecToryname/test.txt", O_RDONLY );
close TXT;

ok ( !sysopen TXT, "./t/small/bigdirecToryname/test.tXt", O_RDONLY );
close TXT;

my $cdir = cwd();

ok ( sysopen TXT, "$cdir/t/small/bigdirectoryname/test.txt", O_RDONLY );
close TXT;

ok ( !sysopen TXT, "$cdir/t/smaLl/bigdirectoryname/test.txt", O_RDONLY );
close TXT;

ok ( !sysopen TXT, "$cdir/t/small/bigdirecToryname/test.txt", O_RDONLY );
close TXT;

ok ( !sysopen TXT, "$cdir/t/small/bigdirecToryname/test.tXt", O_RDONLY );
close TXT;

$cdir = lc $cdir;
ok ( !sysopen TXT, "$cdir/t/small/bigdirectoryname/test.txt", O_RDONLY );
close TXT;

$cdir = cwd();
my $longpath = Win32::GetLongPathName("$cdir/t/small/bigdirectoryname/test.txt");
my $shortpath = Win32::GetShortPathName($longpath);

ok ( sysopen TXT, $longpath, O_RDONLY );
close TXT;

ok ( sysopen TXT, $shortpath, O_RDONLY );
close TXT;

$longpath =~ s/StrictFileNames/StrictFiLeNames/;
ok ( !sysopen TXT, $longpath, O_RDONLY );
close TXT;

$shortpath =~ s/BIGDIR/BIgDIR/;
ok ( !sysopen TXT, $shortpath, O_RDONLY );
close TXT;
