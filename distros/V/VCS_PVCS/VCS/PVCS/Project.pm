# Project.pm - Primary class for Perl PVCS module
#
# Copyright (c) 1998  Bill Middleton
#
#

=head1 NAME

VCS::PVCS::Project - Standard PVCS Project class for for VCS::PVCS


=head1 SYNOPSIS

  use VCS::PVCS::Project;
  $project = new VCS::PVCS::Project("Project Name"); 

  $folds = $project->openFolders("SCRIPTS"); 
  foreach $folder (@$folds){
        $folder->checkout;  # Checkout all files in the folder to the WD
  }

=head1 DESCRIPTION

Inherit from VCS::PVCS::* to get all necessary methods to 
parse master config file, as well as the master pvcsproj.pub
to learn about all projects in the PVCSROOT.

Provides methods to operate on an entire project's files all\
at once.  You can checkout, checkin, get history, or use the
VCS command to perform many different archive operations on
all the files in the project.

=head1 METHODS

=over 5

=item B<new>

  new VCS::PVCS::Project("NAME", {'WKDIR' => $wdir });

Open an project in PVCS.  If the project doesn't exist,
an attempt is made to create it.  If an VCS::PVCS object
is not passed in, then the superclass routines from VCS::PVCS
are called to parse ISLVINI, PVCSPROJ files, and store global 
information, relevant to all projects, from MASTER.CFG. Then open 
and parse project-specific files (pvcsfold.pub) to learn about 
all folders and documents within the project.

Pass the hashref with WKDIR to specify a working directory for 
the entire project.  This method also creates the projects' 
control files, project.cfg, and control directory.

Returns a project object.

=item B<members>

  @members = $project->members("regexp");

Return an array (or ref to array) of blessed Archive objects which 
match the regexp.  If no regexp is passed in, then return all of 
the archives in the project.  These objects can then call the
methods in the VCS::PVCS::Archive class.

=item B<DESTROY>

When the Project object goes out of scope (e.g. when the program
finishes), the destroyer checks the list of archive directories
which have been added to the project, and saves a new config file
if appropriate.  

B<NOTE!  YOU SHOULD DISABLE THIS FEATURE IF YOU ARE USING CONDITIONAL
CONFIGURATION OPTIONS IN THE PROJECT CONFIG FILES AROUND VCSDIR.
THIS FEATURE MAY BE DISABLED BY TURNING ON $PVCSDONTSAVE in VCS::PVCS.pm.>

=item B<newArchive>

  $project->newArchive()

Create a new archive in the project. Normally, this method is called
by $Folder->newArchive, but if you, for some reason, dont use PVCS
folders, then you'll need to call this directly to create a new
archive.
 
=item B<copyProject>

Sorry, not copying projects in this release

=item B<deleteProject>

Sorry, not deleting projects in this release

=item B<lockProject>

Sorry, not locking projects in this release

=item B<get>

  $Project->get([get opts]);

Checkout all of the archive members in the project
to the the project's working directory, or CWD if
WD is not specified in pvcsproj.pub.  Use opts to change 
default actions.

=item B<checkout>

  Convenience routine calls $Project->get()

=item B<co>

  Convenience routine calls $Project->get()

=item B<put>

  $Project->put([put opts]);

Checkin all of the archive members of the project from the
projects' WD or CWD.  Use opts to change default actions.

=item B<checkin>

  Convenience routine calls put()

=item B<ci>

  Convenience routine calls put()

=item B<vlog>

  $Project->vlog([vlog opts]);

Takes a full vlog on all of the archive members in the project.  
Use opts to change default actions.  Result in $PVCSOUTPUT.

=item B<log>

  Convenience routine calls vlog()

=item B<history>

  Convenience routine calls vlog()

=item B<lock>

  $Project->lock($label|$version,[vcs opts]);

Locks the named revision (or rev spec'd by label) for all
archive members in the project.  Use opts to change default action.

=item B<unlock>

  $Project->unlock($label|$version,[vcs opts]);

unlocks the named revision (or rev spec'd by label) for all
archive members of the project.  Use opts to change default action.

=item B<addVersionLabel>

  $Project->addVersionLabel($label,[vcs opts]);

Create a new sticky version label for the all of the archive 
members of the project (optionally with :<rev>).  Use opts
for additonal params.

=item B<deleteVersionLabel>

  $Project->deleteVersionLabel($label,[vcs opts]);

Delete a version label from all of the archive members of the project.

=item B<replaceVersionLabel>

  $Project->replaceVersionLabel($newlabel,$oldlabel,[vcs opts]);

Rename a version label in all of the archive members of the project.

=item B<addFloatingVersionLabel>

  $Project->addFloatingVersionLabel($label,[vcs opts]);

Create a floating version label for all of the archive members
of the project.

=item B<transformVersionLabel>

  $Project->transformVersionLabel($label,[vcs opts])';

Transform a specified version label to a floating version label
for all of  the archive members of the project.

=item B<deletePromoGroup>

  $Project->deletePromoGroup($group,[vcs opts]);

Delete the promotion group from the archive for all archive
members in the project.

=item B<addPromoGroup>

  $Project->deletePromoGroup($group:$rev,[vcs opts])';

Add the archive, or promote it to, the named promotion group,
for all of the archive members in the project.

Create a new archive

=item B<vcs>

  $Project->vcs([opts][files]);

Run vcs in the project's WD, with opts.

=item B<getAttributes>

  $Project->getAttributes(@_);

Populates and returns the archive object associated with the archive 
for all archives in the project.

This object is blessed into the VCS::PVCS::Attributes class.

=back

=head1 AUTHOR

Bill Middleton, wjm@metronet.com

=head1 COPYRIGHT

The PVCS module is Copyright (c) 1998 Bill Middleton.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SUPPORT / WARRANTY

The VCS::PVCS modules are free software.

B<THEY COME WITHOUT WARRANTY OF ANY KIND.>

Commercial support agreements for Perl can be arranged via
The Perl Clinic. See http://www.perl.co.uk/tpc for more details.

=head1 SEE ALSO

perl(1).

=cut

package VCS::PVCS::Project;
use strict;
no strict qw(refs);
use vars qw($VERSION @ISA @EXPORT);
use Carp;
use Cwd;
use VCS::PVCS;
require VCS::PVCS::Folder; 
require Exporter;
@ISA = qw(VCS::PVCS::Folder);
$VERSION = "0.01";
@EXPORT = ("\$PVCSSHOWMODE","\$PVCSERR","\$PVCSOUTPUT","\$PVCSDEBUG");

################################################
## Constructor
##

sub new {
    my $type = shift;
    my($self);
    my $class = ref($type) || $type || "VCS::PVCS::Project";
    (@_ >= 1) or croak "usage: new $class [PROJECTNAME]";
    my($name) = shift;
    my($args) = shift;
    my $config = ($class =~  /^VCS::PVCS$/) ? $type : VCS::PVCS::new();
    
    if(defined($config->{'projects'}->{$name})){
        $self = openProject($config,$name,$args)
            or return undef;
    }
    else{
	warn "Project $_[0] does not exist, attempting to create" if
	    $PVCSDEBUG;
        $self = createProject($config,$name)
            or return undef;
    }
    $self->{'DIR'} = $config->{'projects'}->{$name}->{'DIR'};
    $self->{'CFG'} = $config->{'projects'}->{$name}->{'CFG'};
    $self->{'WKDIR'} = $config->{'projects'}->{$name}->{'WKDIR'};
    $self->{'NAME'} = $config->{'projects'}->{$name}->{'NAME'};
    $self->{'config'} = $config;  # Master.cfg info
    readProjectConfigFile($self);
# circular?  Probably need a DESTROY...
    $self->{'currentProject'} = $config->{'projects'}->{$name};
    bless($self->{'currentProject'},"VCS::PVCS::Project");
    ($^O ne "MSWin32") ?
	translatePath2Unix(\$self->{'currentProject'}->{'CFG'}):
	translatePath2Win(\$self->{'currentProject'}->{'CFG'});
    $PVCSCURRPROJCFG = $self->{'currentProject'}->{'CFG'};
    
    bless($self,$class);
}

sub readProjectConfigFile{
my($self) = shift;
my($key,$value);
my($tmpcfg);
# Eventually, this'll be replaced with API call
# Right now the only thing we're interested in is VCSDIR,
# since the command line tools will read them for themselves.
$tmpcfg = $self->{'CFG'};
(($^O ne "MSWin32") and $PVCSMULTIPLATFORM) and
    translatePath2Unix(\$tmpcfg);
(croak "Cant find your Project Config file, $tmpcfg")
    unless (-e "$tmpcfg");
    open(MASTER, "$tmpcfg") || 
	croak "cant open $tmpcfg\n";
    while(<MASTER>){
	chop;chop; # icky but ok
	($key,$value) = split(/\s+[= 	]+\s*/,$_);
	next unless ($key =~ s/.*(VCSDIR).*/$1/);
	$self->{'VCSDIR'} =  $value;
	$value =~s/^\s*\"//;
	$value =~s/\"\s*$//;
	@{$self->{'VCSDIRS'}} =  split(/\"\;\"/,$value);
	last;
    }
}

sub DESTROY{
my($self) = shift;
my($tmpcfg);
my($key,$value,$dir,$found);
my(@tmp,@new);
$tmpcfg = $self->{'CFG'};
return unless defined($self->{'NEWVCSDIRS'}); # Nothing to do
return if $VCS::PVCS::PVCSDONTSAVE;
(($^O ne "MSWin32") and $PVCSMULTIPLATFORM) and
    translatePath2Unix(\$tmpcfg);
(croak "Cant find your Project Config file, $tmpcfg")
    unless (-e "$tmpcfg");
open(MASTER, "$tmpcfg") || 
    (warn "cant open $tmpcfg\n" && return);
open(NEWCFG,">$PVCSPROJ/$$.NEW") ||
    croak "Could not open tmpfile\n";
while(<MASTER>){
    if(/^\s*VCSDIR/){
	($key,$value) = split(/\s+[= 	]+\s*/,$_);
	if($value ne $self->{'VCSDIR'}){  # Something has changed
	    $value =~s/^\s*\"//;
	    $value =~s/\"\s*$//;
	    @{$self->{'VCSDIRS'}}=  split(/\"\;\"/,$value);
	}
	foreach $dir (@{$self->{'NEWVCSDIRS'}}){
	    push(@{$self->{'VCSDIRS'}},$dir);
	}
	my($newvcs) = 'VCSDIR = "'.join('";"',@{$self->{'VCSDIRS'}}).'"'."\n";
	print NEWCFG $newvcs;
	$found = 1;
    }
    else{
	print NEWCFG $_;
    }
}
if(!$found){  # New project has no VCSDIRS yet
    my($newvcs) = 'VCSDIR = "'.join('";"',@{$self->{'NEWVCSDIRS'}}).'"'."\n";
    print NEWCFG $newvcs;
}
close MASTER;
close NEWCFG;
rename("$tmpcfg","$tmpcfg.old");
rename("$PVCSPROJ/$$.NEW","$tmpcfg");

(warn "Saved your new configuration file $tmpcfg, and renamed your old configuration file $tmpcfg to $tmpcfg.old\n") if $PVCSDEBUG;

}



sub newArchive {
my $type = shift;
my $class = ref($type);
my($newarchive,$folder);
my($fullapath,$fullwpath,$a,$b,$c,$d);

($class =~ /VCS::PVCS::Project/) or 
    croak "Must pass project ref to newArchive\n";

(@_ >= 2) or croak 'usage: $Project->newArchive(workfile, archivedir, 
 [workingdir], [checkincomment], [workfilecomment]';

my($workfile,$archdir,$workingdir,$cicomment,$workcomment) = @_;

if(! $workingdir){
    $workingdir = (-d $type->{'WKDIR'}) ? $type->{'WKDIR'} : "./";
}
if((! defined($cicomment)) || (! length($cicomment))){
    $cicomment = "Checked in from Perl VCS::PVCS module";
}
if((! defined($workcomment)) || (! length($workcomment))){
    $workcomment = "Checked in from Perl VCS::PVCS module";
}

($^O ne "MSWin32") ?
    translatePath2Unix(\$archdir):
    translatePath2Win(\$archdir);

($^O ne "MSWin32") ?
    translatePath2Unix(\$workingdir):
    translatePath2Win(\$workingdir);


$newarchive = VCS::PVCS::Archive::new( $workfile,$archdir,$workingdir,$cicomment,$workcomment);

if($newarchive and (! $PVCSSHOWMODE)){
    $folder = $PVCSPROJ."/".$type->{'DIR'}."/pvcsfold.pub";
    ($fullapath = $newarchive->archive()) =~ m/(.*)[\\\/](.*)/;
    ($a,$b) = ($1,$2);
    ($fullwpath = $newarchive->{'workfiles'}->{'MASTER'}) =~ m/(.*)[\\\/](.*)/;
    ($c,$d) = ($1,$2);
    open(PROJECT,">>$folder") ||
	croak "Cant open pvcsfold.pub for new archive\n";
    print PROJECT "[DOCUMENT=$a;$b;$c;$d]\n";
    close PROJECT;
    $type->{'documents'}->{$fullapath}= $newarchive;
# Add the new archive to the Config file on DESTROY, if it's not there already
    if((! grep('$a',@{$type->{'VCSDIRS'}})) && 
	(! grep('$a',@{$type->{'NEWVCSDIRS'}})) ){
	push(@{$type->{'NEWVCSDIRS'}},$a);
    }
    return ("[DOCUMENT=$a;$b;$c;$d]\n",$newarchive);
}
return undef;    
}
###############################################################################
sub openProject{  # opens an existing project
###############################################################################
my($self) = shift;
my($projname) = shift;
my $project = {};
my($newfolder,$folder);
my($nextline);
my($archdir,$archfile,$workdir,$workfile,$tmp);

croak "No such project: $projname" unless 
    (defined($self->{'projects'}->{$projname}));

$folder = $PVCSPROJ."/".$self->{'projects'}->{$projname}->{'DIR'};

croak "No pvcsfold.pub in $folder for $projname" unless 
    (-e "$folder/pvcsfold.pub");

open(MASTER,"<$folder/pvcsfold.pub") or 
    (croak "Cant open $folder/pvcsfold.pub\n");

while (<MASTER>){
    chomp;
    if(/^\[FOLDER=(.*)\]/){
	$newfolder = $1;
	for(1 .. 2){
	    chomp($nextline = <MASTER>);
	    if($nextline =~ m/^(DIR|WKDIR)=([^\015]*)/){
		$project->{'folders'}->{$newfolder}->{$1} = $2;
	    }
        }
	$project->{'folders'}->{$newfolder}->{'NAME'} = $newfolder;
	    
    }
    elsif(/^\[DOCUMENT=(.*)\]/){
	    $tmp = $1;
	    ($archdir,$archfile,$workdir,$workfile) = split(/;/,$1);
	    $project->{'documents'}->{"$archdir\\$archfile"} = {};
	    bless($project->{'documents'}->{"$archdir\\$archfile"},"VCS::PVCS::Archive");
	    $project->{'documents'}->{"$archdir\\$archfile"}->{'workfiles'}->{'MASTER'} = "$workdir/$workfile";
	    if($VCS::PVCS::USESQL){
		# Insert SQL lookup for archiveID here
	    }
	    $project->{'documents'}->{"$archdir\\$archfile"}->{'arpath'} = "$archdir\\$archfile";
    }
}
$project;
}

sub createProject{
my($self) = shift;
my($projname) = shift;
my $project = {};
my($folder,$shortname,$tmp);
my($args) = shift;

(ref($args)) or ($args = {});

$shortname = _name2Eight($self,$projname);
$folder = "$PVCSPROJ/$shortname.prj";

# Create project folder
unless($PVCSSHOWMODE){
    croak "cant create $folder for $projname" unless 
	(mkdir("$folder",0755));

# Create project master pvcsfold.pub
    croak "cant open $folder/pvcsfold.pub for $projname" unless 
	open(PVCSFOLD,">$folder/pvcsfold.pub");
    print PVCSFOLD "[FORMAT=PVCS_GUI]\nVersion=5.2\n";
    close(PVCSFOLD);

# Create project project.cfg
    croak "cant open $PVCSPROJ/$shortname.cfg for $projname" unless 
	open(PVCSFOLD,">>$PVCSPROJ/$shortname.cfg");
    print PVCSFOLD "# VERSION PVCS VM_5.3.00\n";
    close(PVCSFOLD);

# Create project config file and set up the config object
    croak "cant open $PVCSPROJ/pvcsproj.pub for $projname" unless 
	open(PVCSFOLD,">>$PVCSPROJ/pvcsproj.pub");

    print PVCSFOLD "\n[Project=$projname]\n";
}
$self->{'projects'}->{$projname}->{'NAME'} = $projname;
$tmp = $PVCSPROJ."/$shortname.cfg";

($PVCSMULTIPLATFORM) && translatePath2Win(\$tmp);

$self->{'projects'}->{$projname}->{'CFG'} = $tmp;

unless($PVCSSHOWMODE){
    print PVCSFOLD "CFG=$tmp\n";
    print PVCSFOLD "DIR=$shortname.prj\n";
}
$self->{'projects'}->{$projname}->{'DIR'} = "$shortname.prj";

unless($PVCSSHOWMODE){
    if(defined($args->{'ARDIR'})){
	print PVCSFOLD "ARDIR=".$args->{'ARDIR'}."\n";
    }
    else{
	print PVCSFOLD "ARDIR=\n";
    }
}
$self->{'projects'}->{$projname}->{'ARDIR'} = $args->{'ARDIR'};

unless($PVCSSHOWMODE){
    if($args->{'WKDIR'}){
	$tmp = $args->{'WKDIR'};
    }else{
	$tmp = $PVCSPROJ."/PVCSWORK";
    }
    ($PVCSMULTIPLATFORM) && translatePath2Win(\$tmp);
    print PVCSFOLD "WKDIR=$tmp\n";
}

$self->{'projects'}->{$projname}->{'WKDIR'} = $tmp;

unless($PVCSSHOWMODE){
    close(PVCSFOLD);
}

if($PVCSSHOWMODE){
    print "Would have created Project: $shortname.prj\n";
}
return $project;

}

sub copyProject{
croak "Sorry, not copying projects in this release\n";
}

sub deleteProject{
croak "Sorry, not deleting projects in this release\n";
}

sub lockProject{
croak "Sorry, not locking projects in this release\n";
}

sub _name2Eight{
my($type,$name) = @_;
my($nomatch) = 1;

if(length($name) > 8){
    $name = substr($name,0,8);
}
while($nomatch){
   if(-e "$PVCSPROJ/$name.cfg"){
	$name++;
	next;
   }
   $nomatch=0;
}
$name;
}  

sub Members{
members(@_);
}

sub members{
@_ >= 1 or croak 'usage: $Project->members("regexp")';
my($type) = shift;
my($class) = ref($type);
my($match) = shift;
my($retval) = [];
my($member);

if($class eq "VCS::PVCS::Project"){
    if($match){
        foreach $member (values %{$type->{'documents'}}){
            if( grep(/$match/, (values %{$member->{'workfiles'}})) ){
                push(@{$retval},$member);
            }
        }
        return (wantarray) ? @{$retval} : $retval;
    }
    else{
        return (wantarray) ? @{$type->{'documents'}} : $type->{'documents'};
    }
}

}


sub getAttributes{
@_ >= 1 or croak 'usage: $Project->getAttributes([vcs opts])';
my($type) = shift;
my($class) = ref($type);
my($member,$error);
my($curdir) = cwd();
$error=1;
if($class eq "VCS::PVCS::Project"){
    $PVCSOUTPUT = "";
    foreach $member (values %{$type->{'documents'}}){
	unless($member->getAttributes(@_)){
	    (warn "getAttributes error: $PVCSCURROUTPUT") if $PVCSDEBUG;
	    $error=0;
	}
    }
}
else{
    croak "Must invoke Folder::getAttributes passing folder object"; 
}
$error;
}


##############################################################################
# Project Checkout methods
##############################################################################
sub get{
@_ >= 1 or croak 'usage: $Project->get([$label|$version],[vcs opts])';
my($type) = shift;
my($class) = ref($type);
my($document,$error);
$error=1;
if($class eq "VCS::PVCS::Project"){ 
    $PVCSOUTPUT = "";
    foreach $document (values %{$type->{'documents'}}){
	unless($document->get(@_)){
	    (warn "GET error: $PVCSCURROUTPUT") if $PVCSDEBUG;
	    $error = 0;
	}
    }
}
else{
    croak 'Must pass Project object to VCS::PVS::Project::get()';
}
$error
}

sub checkout{
    get(@_);
}

sub co{
    get(@_);
}

##############################################################################
# Checkin methods
##############################################################################

sub put{
@_ >= 1 or croak 'usage: $Project->vlog([vlog opts])';
my($type) = shift;
my($class) = ref($type);
my($document,$error);
$error=1;
if($class eq "VCS::PVCS::Project"){ 
    $PVCSOUTPUT = "";
    foreach $document (values %{$type->{'documents'}}){
	unless($document->put(@_)){
	    (warn "PUT error: $PVCSCURROUTPUT") if $PVCSDEBUG;
	    $error=0;
	}
    }
}
else{
    croak 'Must pass Project object to VCS::PVS::Project::put()';
}
$error;
}

sub checkin{
    put(@_);
}

sub ci{
    put(@_);
}


##############################################################################
# history methods
##############################################################################
sub vlog{
@_ >= 1 or croak 'usage: $Project->vlog([vlog opts])';
my($type) = shift;
my($class) = ref($type);
my($document,$error);
$error=1;
if($class eq "VCS::PVCS::Project"){ 
    $PVCSOUTPUT = "";
    foreach $document (values %{$type->{'documents'}}){
	unless($document->vlog(@_)){
	    (warn "VLOG error: $PVCSCURROUTPUT") if $PVCSDEBUG;
	    $error=0;
	}
    }
}
else{
    croak 'Must pass Project object to VCS::PVS::Project::vlog()';
}
$error;
}

sub log{
    vlog(@_);
}

sub history{
    vlog(@_);
}

######################################################################
# locking methods
######################################################################

sub lock{
@_ >= 1 or croak 'usage: $Project->lock([$label|$version],[vcs opts])';
my($type) = shift;
my($class) = ref($type);
my($tmptype) = $VCS::PVCS::Commands::vcsopts->{'L'};
my($version) = shift;

$VCS::PVCS::Commands::vcsopts->{'L'} = ($version) ? $version : 1;
vcs($type,@_);
$VCS::PVCS::Commands::vcsopts->{'L'} = $tmptype;

}

sub unlock{

@_ >= 1 or croak 'usage: $Project->unlock($label|$version,[vcs opts])';
my($type) = shift;
my($tmptype) = $VCS::PVCS::Commands::vcsopts->{'U'};
my($version) = shift;

$VCS::PVCS::Commands::vcsopts->{'U'} = ($version) ? $version : 1;
vcs($type,@_);
$VCS::PVCS::Commands::vcsopts->{'U'} = $tmptype;

}

######################################################################
# Project Version label methods
######################################################################

sub addVersionLabel{
@_ >= 2 or croak 'usage: $Project->addVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;
vcs($type,@_,"-V$label");
}

sub deleteVersionLabel{
@_ >= 2 or croak 'usage: $Project->deleteVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;

($label .= ":delete") unless ($label =~ /:delete$/);
vcs($type,@_,"-V$label");
}

sub replaceVersionLabel{
@_ >= 3 or 
   croak 'usage: $Project->replaceVersionLabel($newlabel,$oldlabel,[vcs opts])';
my($type) = shift;
my($newlabel) = shift;
my($oldlabel) = shift;

vcs($type,@_,"-V$newlabel\:\:$oldlabel");
}

sub addFloatingVersionLabel{
@_ >= 2 or croak 'usage: $Project->addFloatingVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;

($label .= ":\\*") unless ($label =~ /:\*$/);
vcs($type,@_,"-V$label");
}

sub transformVersionLabel{
@_ >= 2 or croak 'usage: $Project->transformVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;

($label .= ":\\*") unless ($label =~ /:\*$/);
vcs($type,@_,"-V$label","-Y");
}


######################################################################
# Promotion group methods
######################################################################

sub deletePromoGroup{
@_ >= 2 or croak 'usage: $Project->deletePromoGroup($group,[vcs opts])';
my($type) = shift;
my($label) = shift;

($label .= ":delete") unless ($label =~ /:delete$/);
vcs($type,@_,"-G$label");
}

sub addPromoGroup{
@_ >= 2 or croak 'usage: $Project->deletePromoGroup($group:$rev,[vcs opts])';
my($type) = shift;
my($label) = shift;

vcs($type,@_,"-G$label");
}

sub createArchive{
@_ >= 1 or croak 'usage: createArchive($archive,[vcs opts])';
my($type) = shift;
my($class) = ref($type);

vcs($type,@_,"-I");
}

##########################################################################
# The Project VCS utility command
##########################################################################
sub vcs{
@_ >= 1 or croak 'usage: $Project->vcs([opts][files])';
my($type) = shift;
my($class) = ref($type);
my($document,$error);
$error=1;
if($class eq "VCS::PVCS::Project"){ 
    $PVCSOUTPUT = "";
    foreach $document (values %{$type->{'documents'}}){
	unless($document->vcs(@_)){
	    (warn "VCS error: $PVCSCURROUTPUT") if $PVCSDEBUG;
	    $error = 0;
	}
    }
}
else{
    croak 'Must pass Project object to VCS::PVS::Project::vcs()';
}
$error;
}


1;

__END__

