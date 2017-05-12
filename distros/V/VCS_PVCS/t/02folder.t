BEGIN{
    use Cwd;
    my($wd) = cwd;
    $ENV{'ISLVINI'} = "$wd/t/PVCSPROJ/islvrc.txt";
}

use VCS::PVCS::Project;

my($wd) = cwd;

# Self configure
my($wdir) = $wd;
my($adir) = $wd;
$wdir .= "/t/PVCSPROJ/PVCSWORK/src";
$adir .= "/t/PVCSPROJ/archives/src";

#$PVCSDEBUG = 1;
$|=1;
print "1..64\n";
print STDERR "This might take a minute or two on Windows especially...\n";

# Create new project
# Pass ref to hash for WKDIR for project, if desired.
my($i) =1;
my($proj) = new VCS::PVCS::Project("examples", {'WKDIR' => $wdir });
($proj) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;

# Create a new folder called example in the examples project
# Same argument for working dir

my ($folder) = $proj->openFolders("docs" , {'WKDIR' => $wdir});
($folder) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
my($wd2) = $folder->getWD();  # utility routine returns the folder's working dir
($wd2) ? (print "ok $i\n") : (print "not ok $i\n");

$i++;

my(@files) = qw(foo.c bar.c baz.c blech.h);  # Created in 00setup.t
my($file);
foreach $file (@files){
    $folder->newArchive($file,$adir);
    (!($PVCSERR) && $folder) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
}

# Checkout all files in the folder
$folder->checkout("-l");  # Checkout all archives with lock
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;

# Populate the attributes object for each file in the folder
$folder->getAttributes;
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;

# i = 10

# Get a list of archive object members of the folder and ck for locks
my(@members) = $folder->members;
my($member,$attributes);

foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes object
    ($attributes->Locks) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++
}
# Now make a small change
my($j);
foreach $j (@files){
    if(open(F,">t/PVCSPROJ/PVCSWORK/src/$j")){
	print "ok $i\n";
    }
    else{
	print "not ok $i\n";
    }
    print F "foobaz\n";
    close F;
    $i++;
}

$folder->checkin('-M"Checked in from test"');  # Checkin all archives 
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;

my($vers,$label);
# Reload the attributes for all files (force with 1 as argument)
$folder->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes object
    ($attributes->Locks) ? (print "not ok $i\n") : (print "ok $i\n");
    $i++;
    $vers = $attributes->Last_trunk_rev;
    ($vers =~ /1.1/) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
}

# Add/change/delete some version labels

# add foobar to 1.1 (tip default)
$folder->addVersionLabel("foobar");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
$folder->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes object
     $label = $attributes->Version_labels;
     ($label =~ /foobar/) ? (print "ok $i\n") : (print "not ok $i\n");
     $i++;
}

# Add a version label to an earlier version
$folder->addVersionLabel("bazbar:1.0");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;

$folder->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes object
     $label = $attributes->Version_labels;
     ($label =~ /bazbar/) ? (print "ok $i\n") : (print "not ok $i\n");
     $i++;
}

# Convert a version label to floating
$folder->transformVersionLabel("foobar");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
$folder->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes hash
     $label = $attributes->Version_labels;
     ($label =~ /1.\*/) ? (print "ok $i\n") : (print "not ok $i\n");
     $i++;
}

# delete a version label
$folder->deleteVersionLabel("foobar");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
$folder->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes hash
     $label = $attributes->Version_labels;
     ($label =~ /foobar/) ? (print "not ok $i\n") : (print "ok $i\n");
     $i++;
}

# REname a version label
$folder->replaceVersionLabel("blahblek","bazbar");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
$folder->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes hash
     $label = $attributes->Version_labels;
     ($label =~ /bazbar/) ? (print "not ok $i\n") : (print "ok $i\n");
     $i++;
     ($label =~ /blahblek/) ? (print "ok $i\n") : (print "not ok $i\n");
     $i++;
}

# Promote all of the 1.0 revisions to the Prodtest group
$folder->addPromoGroup("Prodtest:1.0");
(! $PVCSERR) ? (print "ok $i\n") : (print "not ok $i\n");
$i++;
$folder->getAttributes(1);
foreach $member (@members){
    $attributes = $member->attributes;  # Get the attributes hash
    $label = $attributes->Groups;
    ($label =~ /Prodtest/) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
}


# take a diff on all members against the two versions (default)
foreach $member (@members){
    $member->vdiff("-D -R1.0 -R1.1");
    ($PVCSOUTPUT =~ /foobaz/) ? (print "ok $i\n") : (print "not ok $i\n");
    $i++;
}
