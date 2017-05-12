BEGIN{
$ENV{'ISLVINI'} = "./PVCSPROJ/islvrc";
}
use strict;
#$VCS::PVCS::PVCSDEBUG= 1;
use Cwd;
use VCS::PVCS;
use VCS::PVCS::Commands qw(:all);
$VCS::PVCS::PVCSMASTERCFG = "../../MASTER.CFG";
$VCS::PVCS::PVCSCURRPROJCFG = "../../examples.cfg";
#$PVCSSHOWMODE = 1;

print "1..38\n";

my($i) = 1;
my($arch);
my($vers,$label,$file,$curdir);
$curdir = cwd();

chdir("t/PVCSPROJ/PVCSWORK/src") && (print "ok $i\n");
$i++;

my %files = (
	"foo.c_v" => "foo.c",
	"bar.c_v" => "bar.c",
	"baz.c_v" => "baz.c",
	"blech.h_v" => "blech.h"
);

foreach $file (keys %files){
    $arch = "../../archives/src/".$file;
    checkout("-l", "-R1.2",$arch);
    (! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
    if(open(F,">>$files{$file}")){
	print "ok $i\n";
    }
    else{
	print "not ok $i\n";
    }
    print F "foobaz\n";
    close F;
    $i++;
    checkin('-M"Checked in from test"',$arch);
    (! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;

    # Add a version label 
    addVersionLabel("foobar",$arch);
    (! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;

    # Convert a version label to floating
    transformVersionLabel("foobar",$arch);
    (! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
    
    # delete a version label
    deleteVersionLabel("foobar",$arch);
    (! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
    
    # REname a version label
    replaceVersionLabel("blah","blahblek",$arch);
    (! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
    
    # Promote all of the 1.0 revisions to the Production group (from Prodtest)
    addPromoGroup("Prodtest:1.3","-Y",$arch);
    (! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
    vdiff("-D -R1.2 -R1.3",$arch); # -D gives a simple delta script output
    ($PVCSOUTPUT =~ /foobaz/) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
}
chdir($curdir) && (print "ok $i\n");

