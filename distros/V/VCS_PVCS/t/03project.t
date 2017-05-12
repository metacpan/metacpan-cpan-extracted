# This test file shows how to use the project interface
# to PVCS by itself.  It's not a clean as using folders, but if
# your project doesn't use folders, then it's better
# than using just the Command line interface by itself.

BEGIN{
$ENV{'ISLVINI'} = "t/PVCSPROJ/islvrc.txt";
}

use VCS::PVCS::Project;
use Cwd;
my($curdir) = cwd();
#$PVCSDEBUG = 1;
#$PVCSSHOWMODE =1;

$|=1;

print "1..50\n";
print STDERR "This might take a minute or two on Windows especially...\n";
my($i) = 1;

my $proj = new VCS::PVCS::Project("examples");  # created in 02folder.t

# Get all of the files in the project
@members = $proj->members('\.c$');  # note the quoted $ to get all .c files
$proj->getAttributes;  # Initially populate the attribute object for each 
foreach $f (@members){
    $attrs = $f->attributes;
    ($attrs->Last_trunk_rev =~ /1.1/) ? (print "ok $i\n"):(print "not ok $i\n");
    $i++;
    ($attrs->Version_labels =~ /blahblek/) ? (print "ok $i\n"):(print "not ok $i\n");
    $i++;
}

# We must be in the desired location when issuing a 
# $project->checkout and friends, since documents
# are stored with only "." as the working directory
# in the master pvcsfold.pub for each project.
# 
# This interface is only designed for projects which
# don't use folders, and have all their files in a
# single directory.

# Checkout the entire project to the right place
chdir("t/PVCSPROJ/PVCSWORK/src") && (print "ok $i\n");
$i++;
$proj->checkout("-l");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;

my(@files) = qw(foo.c bar.c baz.c blech.h);  # Created in 00setup.t

# make a small change to all files

my($j);
foreach $j (@files){
    if(open(F,">>$j")){
	print "ok $i\n";
    }
    else{
	print "not ok $i\n";
    }
    print F "foobaz\n";
    close F;
    $i++;
}

# Checkin the entire project
$proj->checkin('-M"Checked in from test"');  # Checkin all archives 
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;

my($vers,$label);
# Reload the attributes for all files (force with 1 as argument)
$proj->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes object
    ($attributes->Locks) ? (print "not ok $i\n") : (print "ok $i\n");
    $i++;
    $vers = $attributes->Last_trunk_rev;
    ($vers =~ /1.2/) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
}

# Add/change/delete some version labels

# add foobar to 1.2 (tip default)
$proj->addVersionLabel("foobar");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
$proj->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes object
     $label = $attributes->Version_labels;
     ($label =~ /foobar/) ? (print "ok $i\n") : (print "not ok $i\n");
     $i++;
}

# Add a version label to an earlier version
$proj->addVersionLabel("bazbar:1.0");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;

$proj->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes object
     $label = $attributes->Version_labels;
     ($label =~ /bazbar/) ? (print "ok $i\n") : (print "not ok $i\n");
     $i++;
}

# Convert a version label to floating
$proj->transformVersionLabel("foobar");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
$proj->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes hash
     $label = $attributes->Version_labels;
     ($label =~ /1.\*/) ? (print "ok $i\n") : (print "not ok $i\n");
     $i++;
}

# delete a version label
$proj->deleteVersionLabel("foobar");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
$proj->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes hash
     $label = $attributes->Version_labels;
     ($label =~ /foobar/) ? (print "not ok $i\n") : (print "ok $i\n");
     $i++;
}

# REname a version label
$proj->replaceVersionLabel("blahbleck","bazbar");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
$proj->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes hash
     $label = $attributes->Version_labels;
     ($label =~ /bazbar/) ? (print "not ok $i\n") : (print "ok $i\n");
     $i++;
     ($label =~ /blahblek/) ? (print "ok $i\n") : (print "not ok $i\n");
     $i++;
}

# Promote all of the 1.0 revisions to the Production group (from Prodtest)
$proj->addPromoGroup("Production:1.0");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
$proj->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes hash
    $label = $attributes->Groups;
    ($label =~ /Production/) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
}


# take a diff on all members against the two versions 
foreach $member (@members){
    $member->vdiff("-D -R1.1 -R1.2"); # -D gives a simple delta script output
    ($PVCSOUTPUT =~ /foobaz/) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
}
chdir($curdir) && (print "ok $i\n");
