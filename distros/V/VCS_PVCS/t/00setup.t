use Cwd;
use ExtUtils::Command;
my($dir) = cwd;
$| = 1;
use strict;

my($sep) = ($^O eq "MSWin32") ? "\\" : "/";

print "1..8\n";
my($i)=1;

# Cleanup before we start
chdir ("t/PVCSPROJ") && (print "ok $i\n");
$i++;
my ($files) = "islvrc.txt examples.cfg examples.cfg.old examples.prj PVCSWORK/src/*.c PVCSWORK/src/*.h archives/src/*.h_v archives/src/*.c_v archives/src/journal.vcs pvcsproj.pub nfsmap";

@ARGV = split(' ',$files);
rm_rf();
chdir($dir) && (print "ok $i\n");
$i++;
# Create the islvrc.txt file
my($islvrc) = $dir.$sep."t/PVCSPROJ".$sep."islvrc.txt";
open(ISLVRC,">$islvrc") && (print "ok $i\n");
print ISLVRC "PVCSPROJ=$dir$sep"."t/PVCSPROJ\n";
print ISLVRC "PVCSPRIV=$dir$sep"."t/PVCSPROJ\n";
print ISLVRC "NFSMAP=$dir$sep"."t/PVCSPROJ\n";
$i++;

# Create the pvcsproj.pub file
$islvrc = $dir.$sep."t/PVCSPROJ/pvcsproj.pub";
open(ISLVRC,">$islvrc") && (print "ok $i\n");
print ISLVRC "CFG=$dir$sep"."MASTER.CFG\n";
print ISLVRC "DIR=MstrPrjc.prj\n";
print ISLVRC "ARDIR=\n";
print ISLVRC "WKDIR=$dir$sep"."t".$sep."\n";

$i++;

# figure out the base dir to emulate nfsmap if running on UNIX
if($^O ne "MSWin32"){
    my($base);
    $dir =~ m#^(/[^/]*)#;
    $base = $1;

# Create the nfsmap file
    $islvrc = $dir.$sep."t/PVCSPROJ/nfsmap";
    open(ISLVRC,">$islvrc"); 
    print ISLVRC "N	$base\n";
    close ISLVRC;
}

# Create the sample files for testing 
my @files = qw(foo.c bar.c baz.c blech.h);
my($j);
foreach $j (@files){
    (open(F,">t/PVCSPROJ/PVCSWORK/src/$j")) || 
	(print "not ok $i\n" && die "cant open $j\n");
    print "ok $i\n";
    print F "foobar\n";
    close F;
    $i++;
}







