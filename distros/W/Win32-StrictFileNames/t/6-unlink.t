#!/usr/bin/perl -w
use strict;
use Test::More;
use Cwd;

sub CreateTestFiles {
  open TXT, "> ./t/small/bigdirectoryname/todel.txt" or die $!;
  print TXT "test file\n";
  close TXT;
  open TXT, "> ./t/bigdirectoryname/small/todel.txt" or die $!;
  print TXT "test file\n";
  close TXT;
}

plan tests => 15;

use Win32::StrictFileNames;
ok(1);  # load

CreateTestFiles();

ok ( unlink "./t/small/bigdirectoryname/todel.txt" );

ok ( open TXT, "./t/bigdirectoryname/small/test.txt" );

CreateTestFiles();

ok ( !unlink "./t/smaLl/bigdirectoryname/todel.txt" );

ok ( !unlink "./t/small/bigdirecToryname/todel.txt" );

ok ( !unlink "./t/small/bigdirectoryname/todel.tXt" );

my $cdir = cwd();

ok ( unlink "$cdir/t/small/bigdirectoryname/todel.txt" );

ok ( unlink "$cdir/t/bigdirectoryname/small/todel.txt" );

CreateTestFiles();

ok ( !unlink "$cdir/t/small/bigdirecToryname/todel.txt" );

ok ( !unlink "$cdir/t/small/bigdirecToryname/todel.tXt" );

$cdir = lc $cdir;
ok ( !unlink "$cdir/t/small/bigdirectoryname/todel.txt" );

$cdir = cwd();
my $longpath = Win32::GetLongPathName("$cdir/t/small/bigdirectoryname/todel.txt");
my $shortpath = Win32::GetShortPathName("$cdir/t/bigdirectoryname/small/todel.txt");

CreateTestFiles();

$longpath =~ s/StrictFileNames/StrictFiLeNames/;
ok ( !unlink $longpath );

$shortpath =~ s/BIGDIR/BIgDIR/;
ok ( !unlink $shortpath );

$longpath = Win32::GetLongPathName("$cdir/t/small/bigdirectoryname/todel.txt");
$shortpath = Win32::GetShortPathName("$cdir/t/bigdirectoryname/small/todel.txt");

ok ( unlink $longpath );

ok ( unlink $shortpath );
