# Folder.pm - access to PVCS Folders for the Perl PVCS module
#
# Copyright (c) 1998  Bill Middleton
#

=head1 NAME

VCS::PVCS::Folder - Folder class for for VCS::PVCS. 


=head1 SYNOPSIS

  use VCS::PVCS::Project;

  $project = new VCS::PVCS::Project("ProjectName");

# return ref to array of all folders in the project with SCRIPTS in the name 

  $folds = $project->openFolders("SCRIPTS"); 
  foreach $folder (@$folds){
	$folder->checkout;  # Checkout all files in the folder to the WD
  }

=head1 DESCRIPTION

This class implements a set of methods for operating on the
directories, archive files, and workfiles which correspond to
PVCS folders.  It should not ordinarily be loaded directly, but
rather, is an ISA to the VCS::PVCS::Project class, as shown
above.

=head1 METHODS

=over 5


=item B<openFolders>

  $folds = $project->openFolders("FOO"); # folders with FOO in the name
  @folds = $project->openFolders(".*");   # ALL folders in the project
  $folds = $project->openFolders("New Folder");  # create the folder

Return a ref to array (or an array) of all folders in the project with 
FOO in the name.  If no match is found, the folder is created.  
The objects in this array are blessed into the
VCS::PVCS::Folder class.  openFolders() accepts partial name matches 
in the single argument. (Names are matched with grep(//))

=item B<members>

  @members = $folder->members("regexp");

Return an array (or ref to array) of blessed Archive objects which
reside within the folder, and match the regexp.  If no regexp is passed 
in, then return all of the archives in the project.  These objects 
can then call the methods in the VCS::PVCS::Archive class.

=item B<newArchive >

  $Folder->newArchive($file,$archivedir);

Create a new archive and place a copy into the folder.

=item B<getWD>

  $WorkingDir =  $folder->getWD;

Return the working directory for the folder.

=item B<getAttributes>

  $Folder->getAttributes([vcs opts])';

Populate the attributes object for each archive object member of the 
folder.

=item B<get>

  $Folder->get([get opts]);

Checkout all of the archive members in the folder
to the the folders' working directory.  Use opts to change 
default actions.

=item B<checkout>

  Convenience routine calls $folder->get()

=item B<co>

  Convenience routine calls $folder->get()

=item B<put>

  $Folder->put([put opts]);

Checkin all of the archive members of the folder.  Use opts to 
change default actions.

=item B<checkin>

  Convenience routine calls put()

=item B<ci>

  Convenience routine calls put()

=item B<vlog>

  $Folder->vlog([vlog opts]);

Takes a full vlog on all of the archive members in the folder.  
Use opts to change default actions.  Result in $PVCSOUTPUT.

=item B<log>

  Convenience routine calls vlog()

=item B<history>

  Convenience routine calls vlog()

=item B<lock>

  $Folder->lock($label|$version,[vcs opts]);

Locks the named revision (or rev spec'd by label) for all
archive members in the folder.  Use opts to change default action.

=item B<unlock>

  $Folder->unlock($label|$version,[vcs opts]);

unlocks the named revision (or rev spec'd by label) for all
archive members of the folder.  Use opts to change default action.

=item B<addVersionLabel>

  $Folder->addVersionLabel($label,[vcs opts]);

Create a new sticky version label for the all of the archive 
members of the folder (optionally with :<rev>).  Use opts
for additonal params.

=item B<deleteVersionLabel>

  $Folder->deleteVersionLabel($label,[vcs opts]);

Delete a version label from all of the archive members of the folder.

=item B<replaceVersionLabel>

  $Folder->replaceVersionLabel($newlabel,$oldlabel,[vcs opts]);

Rename a version label in all of the archive members of the folder.

=item B<addFloatingVersionLabel>

  $Folder->addFloatingVersionLabel($label,[vcs opts]);

Create a floating version label for all of the archive members
of the folder.

=item B<transformVersionLabel>

  $Folder->transformVersionLabel($label,[vcs opts])';

Transform a specified version label to a floating version label
for all of  the archive members of the folder.

=item B<deletePromoGroup>

  $Folder->deletePromoGroup($group,[vcs opts]);

Delete the promotion group from the archive for all archive
members in the folder.

=item B<addPromoGroup>

  $Folder->deletePromoGroup($group:$rev,[vcs opts])';

Add the archive, or promote it to, the named promotion group.
For all of the archive members in the folder.

Create a new archive

=item B<vcs>

  $Folder->vcs([opts][files]);

Run vcs in the folder's CWD, with opts.

=item B<getAttributes>

  $Folder->getAttributes(@_);

Populates and returns the archive object associated with the archive 
for all archives in the folder.

This object is blessed into the VCS::PVCS::Attributes class.

=back

=head1 COPYRIGHT

The PVCS module is Copyright (c) 1998 Bill Middleton.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 AUTHOR

Bill Middleton, wjm@metronet.com

=head1 SUPPORT / WARRANTY

The VCS::PVCS modules are free software.

B<THEY COME WITHOUT WARRANTY OF ANY KIND.>

Commercial support agreements for Perl can be arranged via
The Perl Clinic. See http://www.perl.co.uk/tpc for more details.

=head1 SEE ALSO

VCS::PVCS::Project

=cut

package VCS::PVCS::Folder;
use strict;
no strict qw(refs);
use vars qw($VERSION @EXPORT @EXPORT_OK @ISA);
use Carp;
use Cwd;
use VCS::PVCS;
require VCS::PVCS::Archive;
@ISA = qw(VCS::PVCS::Archive );
$VERSION = "0.01";


################################################
## Constructor
##

sub openFolders{
    my $type = shift;
    my $class = ref($type);
    ($class =~  /^VCS::PVCS::Project$/) or 
	croak "Must pass a Project object to new\n";
    (@_ >= 1) or croak "usage: new $class [Foldername]";
    my ($ret,$folder);
    my $foldernamematch = shift;
    my($args) = shift;
    (defined($args)) or ($args = {});
    my($ref) = $type->{'folders'};
    my($self) = [];
    my (@keys) = keys(%{$ref});
    my (@folders) = grep(/$foldernamematch/,@keys);
    if(@folders){
	foreach $folder (@folders){
	    $ret = VCS::PVCS::Folder::_parseFolder($type,$ref->{$folder},$folder)
		or return undef;
	    push(@{$self},$ret);
	}
    }
    else{
        warn "WARNING: Folder $foldernamematch does not exist, attempting to create" 
	    if $PVCSDEBUG;
        $ret = VCS::PVCS::Folder::_createFolder($type,$foldernamematch,$args)
            or return undef;
	push(@{$self},$ret);
    }
    (wantarray)?  @$self : $self;

}



sub _parseFolder{
my($self) = shift;
my $class = ref($self);
my($fref) = shift;
my($newfolder) = shift;
my($folder,$retval);
my($nextline,$tmp,$tmp2);
my($archdir,$archfile,$workdir,$workfile);

($class =~  /^VCS::PVCS::Project$/) or 
    croak "Must pass a Project object to openFolder\n";

$folder = $PVCSPROJ;
$folder .="/".$self->{'currentProject'}->{'DIR'};
$folder .="/".$fref->{'DIR'};
(open(FOLDER,"$folder/pvcsfold.pub"))
    or (croak "Cant open pvcsfold.pub for $newfolder\n");

while(<FOLDER>){
    if(/^\[DOCUMENT=(.*)\]/){
	$tmp2 = $1;
	($archdir,$archfile,$workdir,$workfile) = split(/;/,$1);
	my $tmp = "$workdir/$workfile";
	if(! defined($self->{'documents'}->{"$archdir\\$archfile"})){
	    warn "WARNING: No document in project\'s pvcsfold.pub for project $self->{'NAME'}:  $archdir\\$archfile in $folder/pvcsfold.pub\n" if($PVCSDEBUG);
	    $self->{'documents'}->{"$archdir\\$archfile"} = {};
	    bless($self->{'documents'}->{"$archdir\\$archfile"},"VCS::PVCS::Archive");
	    $self->{'documents'}->{"$archdir\\$archfile"}->{'arpath'} = "$archdir/$archfile";
	    $self->{'documents'}->{"$archdir\\$archfile"}->{'workfiles'}->{'MASTER'} = $tmp;
	}
	if($tmp ne $self->{'documents'}->{"$archdir\\$archfile"}->{'workfiles'}->{'MASTER'})
	{
	    warn "WARNING: Workfile $tmp differs from Master Workfile ".$self->{'documents'}->{"$archdir\\$archfile"}->{'workfiles'}->{'MASTER'}."\n" if $PVCSDEBUG;
	    $self->{'documents'}->{"$archdir\\$archfile"}->
		{'workfiles'}->{$self->{'NAME'}} = $tmp;

	}
	if($PVCSDEBUG){  # Check for existence of archive if debugging
	    $tmp = "$archdir\\$archfile";
	    ($^O ne "MSWin32") ? translatePath2Unix(\$tmp) : 
		translatePath2Win(\$tmp);
	    warn "$tmp does not exist!" unless (-e $tmp);
	}
	# push the hashref onto the members array
	# Another circular reference here
	push(@{$fref->{'members'}},
	    $self->{'documents'}->{"$archdir\\$archfile"});
	
    }
}
$retval = $fref;
$retval->{'PROJECT'} = $self->{'currentProject'};
bless($retval,"VCS::PVCS::Folder");

}

sub _createFolder{
my $type = shift;
my $class = ref($type);
($class =~  /^VCS::PVCS::Project$/) or 
    croak "Must pass a Project object to new\n";
(@_ >= 1) or croak "usage: _createFolder Foldername, [{WKDIR => workdir}]";
my($name) = shift;
my($args) = shift;
my($retval) = {};

my($ref,$shortname);
my($nomatch) = 1;
my($folder);

# Get a good name for the project config folder
($shortname = $name) =~ s/\s*//g;
if(length($shortname) > 8){
    $shortname = substr($shortname,0,8);
}
while($nomatch){
   if(-e "$PVCSPROJ/$type->{'DIR'}/$shortname.fld"){
        $shortname++;
        next;
   }
   $nomatch=0;
}
$folder = "$PVCSPROJ/$type->{'DIR'}/$shortname.fld";

unless($PVCSSHOWMODE){
    croak "cant create $folder for folder $name" unless 
	(mkdir("$folder",0755));
}


if(length($args->{'WKDIR'})){
    ($PVCSMULTIPLATFORM) && translatePath2Win(\$args->{'WKDIR'});
    $type->{'folders'}->{$name}->{'WKDIR'} = $args->{'WKDIR'};
}
else{
    $ref->{$name}->{'WKDIR'} = $type->{'WKDIR'}; 
}
$type->{'folders'}->{$name}->{'DIR'} = "$shortname.fld";

# Create folder config file 
unless($PVCSSHOWMODE){
    croak "cant open $folder/pvcsfold.pub for $name" unless 
	open(PVCSFOLD,">>$folder/pvcsfold.pub");
    print PVCSFOLD "[FORMAT=PVCS_GUI]\nVersion=5.2\n";
    close PVCSFOLD;
}
# Update the project master pvcsfold.pub
$folder = "$PVCSPROJ/$type->{'DIR'}";
unless($PVCSSHOWMODE){
    croak "cant open $folder/pvcsfold.pub for $name" unless 
	open(PVCSFOLD,">>$folder/pvcsfold.pub");
    print PVCSFOLD "\n[FOLDER=$name]\nDIR=$shortname.fld\n";
    print PVCSFOLD "WKDIR=".$type->{'folders'}->{$name}->{'WKDIR'}."\n";
    close PVCSFOLD;
}

$retval = $type->{'folders'}->{$name};
$retval->{'PROJECT'} = $type->{'currentProject'};
bless($retval,"VCS::PVCS::Folder");
}

#####################################################################
# newArchive - Create a new archive and add it to the folder
#####################################################################
sub newArchive {
my $type = shift;
my $class = ref($type);
my($newarchive,$folder);
my($fullapath,$fullwpath,$a,$b,$c,$d);
($class =~ /VCS::PVCS::Folder/) or 
    croak "must pass project object to newArchive\n";
(@_ >= 2) or croak 'usage: $Project->newArchive(workfile, archivedir, 
 [workingdir], [checkincomment], [workfilecomment]';
my($workfile,$archdir,$workingdir,$cicomment,$workcomment) = @_;

if(! $workingdir){
    $workingdir = $type->{'WKDIR'};
    (($^O ne "MSWin32") and ($PVCSMULTIPLATFORM)) and
	translatePath2Unix(\$workingdir);
    $workingdir = (-d $workingdir) ? $workingdir  : "./"; # revert to cwd()!
}
my($entry,$archive) = 
VCS::PVCS::Project::newArchive($type->{'PROJECT'},$workfile,$archdir,$workingdir,$cicomment,$workcomment);
if($entry and (! $PVCSSHOWMODE)){
    $folder = $PVCSPROJ."/".$type->{'PROJECT'}->{'DIR'}."/".$type->{'DIR'}."/pvcsfold.pub";
    open(FOLDER,">>$folder") ||
	croak "Cant open $folder for new archive\n";
    print FOLDER $entry;
    close FOLDER ;
    push(@{$type->{'members'}},$archive);
    return($entry);
}
return undef;    
}

###################################################################
# Return the members of the folder, names matched against parameter
###################################################################
sub members{
@_ >= 1 or croak 'usage: $Folder->members("regexp")';
my($type) = shift;
my($class) = ref($type);
my($match) = shift;
my($retval) = [];
my($member);

if($class eq "VCS::PVCS::Folder"){
    if($match){
	foreach $member (@{$type->{'members'}}){
	    if( grep(/$match/, (values %{$member->{'workfiles'}})) ){
		push(@{$retval},$member);
	    }
	}
	return (wantarray) ? @{$retval} : $retval;
    }
    else{
	return (wantarray) ? @{$type->{'members'}} : $type->{'members'};
    }
}

}

##############################################################################
# Folder utility methods
##############################################################################
sub getWD{
my($self) = shift;
my($WD);
$WD = $self->{'WKDIR'};
(($^O ne "MSWin32") && $PVCSMULTIPLATFORM) && translatePath2Unix(\$WD); 
return $WD;
}

##############################################################################
# Folder Checkout methods
##############################################################################

sub get{
@_ >= 1 or croak 'usage: $Folder->get([get opts])';
my($type) = shift;
my($class) = ref($type);
my($member,$error);
my($curdir) = cwd();
$error=1;
if($class eq "VCS::PVCS::Folder"){
    $PVCSOUTPUT = "";
    my($wkdir) = $type->{'WKDIR'};
    ($^O ne "MSWin32") ? translatePath2Unix(\$wkdir) : 
	translatePath2Win(\$wkdir);
    chdir($wkdir) or 
	(croak "Cant chdir to $wkdir to check out folder $type->{'NAME'}\n");
    foreach $member (@{$type->{'members'}}){
	unless($member->get(@_)){
	    (warn "GET error: $PVCSCURROUTPUT") if $PVCSDEBUG;
	    $error=0;
	}
    }
}
else{
    croak "Must invoke Folder::get passing folder object"; 
}
chdir($curdir);
$error;
}

sub checkout{
    get(@_);
}

sub co{
    get(@_);
}

##############################################################################
# Folder Checkin methods
##############################################################################

sub put{
@_ >= 1 or croak 'usage: $Folder->put([put opts])';
my($type) = shift;
my($class) = ref($type);
my($member,$error);
my($curdir) = cwd();
$error=1;
if($class eq "VCS::PVCS::Folder"){
    $PVCSOUTPUT = "";
    my($wkdir) = $type->{'WKDIR'};
    ($^O ne "MSWin32") ? translatePath2Unix(\$wkdir) : 
	translatePath2Win(\$wkdir);
    chdir($wkdir) or 
	(croak "Cant chdir to $wkdir to check in folder $type->{'NAME'}\n");
    foreach $member (@{$type->{'members'}}){
	unless($member->put(@_)){
	    (warn "PUT error: $PVCSCURROUTPUT") if $PVCSDEBUG;
	    $error=0;
	}
    }
}
else{
    croak "Must invoke Folder::put passing folder object"; 
}
$error;
}

# aliases
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
@_ >= 1 or croak 'usage: $Folder->vlog([vlog opts])';
my($type) = shift;
my($class) = ref($type);
my($member,$error);
my($curdir) = cwd();
$error=1;
if($class eq "VCS::PVCS::Folder"){
    $PVCSOUTPUT = "";
    my($wkdir) = $type->{'WKDIR'};
    ($^O ne "MSWin32") ? translatePath2Unix(\$wkdir) : 
	translatePath2Win(\$wkdir);
    chdir($wkdir) or 
	(croak "Cant chdir to $wkdir to vlog folder $type->{'NAME'}\n");
    foreach $member (@{$type->{'members'}}){
	unless($member->vlog(@_)){
	    (warn "VLOG error: $PVCSCURROUTPUT") if $PVCSDEBUG;
	    $error=0;
	}
    }
}
else{
    croak "Must invoke Folder::vlog passing folder object"; 
}
$error;
}

sub log{
    VCS::PVCS::Folder::vlog(@_);
}

sub history{
    VCS::PVCS::Folder::vlog(@_);
}

######################################################################
# locking methods
######################################################################

sub lock{
@_ >= 2 or croak 'usage: $Folder->lock($label|$version,[vcs opts])';
my($type) = shift;
my($version) = shift;

vcs($type,@_,"-L$version");
}

sub unlock{
@_ >= 2 or croak 'usage: $Folder->unlock($label|$version,[vcs opts])';
my($type) = shift;
my($version) = shift;

vcs($type,@_,"-U$version");
}

######################################################################
# Version label methods
######################################################################
sub addVersionLabel{
@_ >= 2 or croak 'usage: $Folder->addVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;

vcs($type,@_,"-V$label");
}

sub deleteVersionLabel{
@_ >= 2 or croak 'usage: $Folder->deleteVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;

($label .= ":delete") unless ($label =~ /:delete$/);
vcs($type,@_,"-V$label");
}

sub replaceVersionLabel{
@_ >= 3 or croak 'usage: $Folder->replaceVersionLabel($newlabel,$oldlabel,[vcs opts])';
my($type) = shift;
my($newlabel) = shift;
my($oldlabel) = shift;

vcs($type,@_,"-V$newlabel\:\:$oldlabel");  
}

sub addFloatingVersionLabel{
@_ >= 2 or croak 'usage: $Folder->addFloatingVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;
($label .= ":\\*") unless ($label =~ /:\*$/);
vcs($type,@_,"-V$label");
}

sub transformVersionLabel{
@_ >= 2 or croak 'usage: $Folder->transformVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;
($label .= ":\\*") unless ($label =~ /:\*$/);
vcs($type,@_,"-V$label","-Y");
}


######################################################################
# Promotion group methods
######################################################################

sub deletePromoGroup{
@_ >= 2 or croak 'usage: $Folder->deletePromoGroup($group,[vcs opts])';
my($type) = shift;
my($label) = shift;

($label .= ":delete") unless ($label =~ /:delete$/);
vcs($type,@_,"-G$label");

}

sub addPromoGroup{
@_ >= 2 or croak 'usage: $Folder->addPromoGroup($group:$rev,[vcs opts])';
my($type) = shift;
my($label) = shift;

vcs($type,@_,"-G$label");
}

sub createArchive{
@_ >= 2 or croak 'usage: $Folder->createArchive($archive,[vcs opts])';
my($type) = shift;
my($tmpopt) = $VCS::PVCS::Commands::vcsopts->{'I'};

vcs($type,@_,"-I");
}


##########################################################################
# The VCS utility command for augmentation for folder objects
##########################################################################
sub vcs{
@_ >= 1 or croak 'usage: vcs([opts][files])';
my($type) = shift;
my($class) = ref($type);
my($member,$error);
my($curdir) = cwd();
$error=1;
if($class eq "VCS::PVCS::Folder"){
    $PVCSOUTPUT = "";
    my($wkdir) = $type->{'WKDIR'};
    ($^O ne "MSWin32") ? translatePath2Unix(\$wkdir) : 
	translatePath2Win(\$wkdir);
    chdir($wkdir) or 
	(croak "Cant chdir to $wkdir to vlog folder $type->{'NAME'}\n");

# If we are not creating a new archive, then call for all members
    if(! $VCS::PVCS::Commands::vcsopts->{'I'}){
	foreach $member (@{$type->{'members'}}){
	    unless($member->vcs(@_)){
		(warn "VCS error: $PVCSCURROUTPUT") if $PVCSDEBUG;
		$error=0;
	    }
	}
    }
    else{
	unless(VCS::PVCS::Commands::vcs(@_)){
	    (warn "VCS error: $PVCSCURROUTPUT") if $PVCSDEBUG;
	    $error=0;
	}
	# TODO Add the new archive to this folder!
    }
}
else{
    croak "Must invoke Folder::vcs passing folder object"; 
}
$error;
}
##############################################################################
# attributes 
##############################################################################
sub getAttributes{
@_ >= 1 or croak 'usage: $Folder->getAttributes([vcs opts])';
my($type) = shift;
my($class) = ref($type);
my($member,$error);
my($curdir) = cwd();
$error=1;
if($class eq "VCS::PVCS::Folder"){
    $PVCSOUTPUT = "";
    foreach $member (@{$type->{'members'}}){
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



1;
__END__

