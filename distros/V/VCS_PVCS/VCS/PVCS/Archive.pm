# Archive.pm - access to PVCS Archives for the Perl PVCS module
#
# Copyright (c) 1998  Bill Middleton
#

=head1 NAME

VCS::PVCS::Archive - Archive class for for VCS::PVCS. 


=head1 SYNOPSIS

  use VCS::PVCS::Project;

  $project = new VCS::PVCS::Project("ProjectName");

# return ref to array of all folders in the project with SCRIPTS in the name 

  $folds = $project->openFolders("SCRIPTS"); 
  foreach $folder (@$folds){
	@archives = $folder->Members(); # array of blessed Archive objects
  	foreach $archive(@archives){
	    $archive->checkout;  # Checkout single archive to folder's WD
	}
  }

=head1 DESCRIPTION

This class provides methods for use by Archive objects in the
PVCS model.

Ordinarily, this class won't be included in your programs,
as it is part of the ISA for the master class VCS::PVCS::Project,
which should ordinarily be used, as shown above.  


=head1 METHODS

=over 5

=item B<new>

  VCS::PVCS::Archive::new(archivedir,
	workdir,workfile,"checkin comment","workfile comment");

Open an existing archive or create a new one.  

=item B<workfile>

  $workfile = $Archive->Workfile;

Return the default workfile for this archive object.  Use opts to 
change default actions.

=item B<get>

  $Archive->get([get opts]);

Checkout the archive to the CWD.  Use opts to change default
actions.

=item B<checkout>

  Convenience routine calls get()

=item B<co>

  Convenience routine calls get()

=item B<put>

  $Archive->put([put opts]);

Checkin the workfile in CWD to archive.  Use opts to change default
actions.

=item B<checkin>

  Convenience routine calls put()

=item B<ci>

  Convenience routine calls put()

=item B<vdiff>

  $Archive->vdiff([vdiff opts]);

Takes a diff on the archive and workfile.  Use opts to change default
actions.

=item B<vlog>

  $Archive->vlog([vlog opts]);

Takes a full vlog on the archive.  Use opts to change default
actions.

=item B<log>

  Convenience routine calls vlog()

=item B<history>

  Convenience routine calls vlog()

=item B<lock>

  $Archive->lock($label|$version,[vcs opts]);

Locks the named revision (or rev spec'd by label).  Use opts
to change default action.

=item B<unlock>

  $Archive->unlock($label|$version,[vcs opts]);

unlocks the named revision (or rev spec'd by label).  Use opts
to change default action.

=item B<addVersionLabel>

  $Archive->addVersionLabel($label,[vcs opts]);

Create a new sticky version label for the archive (optionally with :<rev>.

=item B<deleteVersionLabel>

  $Archive->deleteVersionLabel($label,[vcs opts]);

Delete a version label from the archive.

=item B<replaceVersionLabel>

  $Archive->replaceVersionLabel($newlabel,$oldlabel,[vcs opts]);

Rename a version label in the archive

=item B<addFloatingVersionLabel>

  $Archive->addFloatingVersionLabel($label,[vcs opts]);

Create a floating version label for the archive.

=item B<transformVersionLabel>

  $Archive->transformVersionLabel($label,[vcs opts])';

Transform a specified version label to a floating version label.

=item B<deletePromoGroup>

  $Archive->deletePromoGroup($group,[vcs opts]);

Delete the promotion group from the archive.

=item B<addPromoGroup>

  $Archive->deletePromoGroup($group:$rev,[vcs opts])';

Add the archive, or promote it to, the named promotion group.

Create a new archive

=item B<vcs>

  $archive->vcs([opts][files]);

Runs the VCS command against the archive, with opts as specified.

=item B<getAttributes>

  $archive->getAttributes(@_);

Populates and returns the archive object associated with the archive.
This object is blessed into the VCS::PVCS::Attributes class.

=item B<attributes>

 $archive->attributes;

Returns the attributes object associated with the archive

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

package VCS::PVCS::Archive;
use strict;
no strict qw(refs);
use vars qw($VERSION @EXPORT @EXPORT_OK @ISA);
use Carp;
use Cwd;
use VCS::PVCS;
use VCS::PVCS::Commands;
require VCS::PVCS::Attributes;
@ISA = qw(VCS::PVCS::Commands VCS::PVCS::Attributes);
$VERSION = "0.01";


################################################
## Constructor
################################################
sub new{
@_ == 5 or croak 'usage: VCS::PVCS::Archive::new(archivedir,workdir,workfile,"checkin comment","workfile comment")';
my($workfile,$arpath,$workdir,$cicomment,$workfilecomment)=@_;
my(@args,$output,$newarchive);
my($new) = {};
my($tmpdir) = cwd;

# Check things for sanity
if(! (-d $arpath)){
    print "ls is ".`ls $arpath`;
    croak "archivepath $arpath is not a directory\n";
 
}
if(! (-d $workdir)){
    croak "workingdir $workdir is not a directory\n";
}

chdir($workdir) or croak "Cant change dir to $workdir\n";

if(! -e "$workfile"){
    croak "workfile $workdir/$workfile does not exist!\n";
}

if($^O !~ "^MSWin32"){
  @args = ("-U", "-M\"$cicomment\"", "-T\"$workfilecomment\"","$arpath\\($workfile\\)");
}
else{
  @args = ( "-N","-U","-M\"$cicomment\"", "-T\"$workfilecomment\"","$arpath($workfile)");
}

VCS::PVCS::Commands::put(@args);

if(!$PVCSERR){
    $output = $PVCSOUTPUT;
    $output =~ /$workfile\s+->\s+([^\r\n]+)/;
    $newarchive = $1;
    if((! -e "$newarchive") && (! $PVCSSHOWMODE)){
	croak "Something went wrong creating $arpath\($workfile\)\n";
    }
}
else{
    return undef;
}

if($PVCSMULTIPLATFORM){
($^O ne "MSWin32") and translatePath2Win(\$newarchive);
($^O ne "MSWin32") and translatePath2Win(\$workfile);
($^O ne "MSWin32") and translatePath2Win(\$workdir);
}

$new->{'arpath'} = $newarchive;
$new->{'workfiles'}->{'MASTER'} = ".\\$workfile";
bless($new,"VCS::PVCS::Archive");
chdir($tmpdir);
return $new;
}
 

################################################
## Member access methods
################################################

sub Archive{
my($self) = shift;
    return $self->{'arpath'};
}
sub archive{
my($self) = shift;
    return $self->{'arpath'};
}
sub workfile{
my($self) = shift;
    return $self->{'workfiles'}->{'MASTER'};
}
sub Workfile{
my($self) = shift;
    return $self->{'workfiles'}->{'MASTER'};
}



##############################################################################
# Archive Checkout methods
##############################################################################

sub get{
@_ >= 1 or croak 'usage: $Archive->get([get opts])';
my($type) = shift;
my($class) = ref($type);

if($class eq "VCS::PVCS::Archive"){
    (caller =~ /VCS::PVCS::(Folder|Archive)/) or ($PVCSOUTPUT = "");
    my($archive) = $type->archive();
    ($^O ne "MSWin32") and translatePath2Unix(\$archive);
    return VCS::PVCS::Commands::get(@_,$archive);
}
else{
    croak "Must invoke Archive::get passing archive object"; 
}

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
@_ >= 1 or croak 'usage: $Archive->put([get opts])';
my($type) = shift;
my($class) = ref($type);

if($class eq "VCS::PVCS::Archive"){
    (caller =~ /VCS::PVCS::(Folder|Archive)/) or ($PVCSOUTPUT = "");
    my($archive) = $type->archive();
    ($^O ne "MSWin32") and translatePath2Unix(\$archive);
    return VCS::PVCS::Commands::put(@_,$archive);
}
else{
    croak "Must invoke Archive::put passing archive object"; 
}

}

sub checkin{
    put(@_);
}

sub ci{
    put(@_);
}

##############################################################################
# diff method
##############################################################################
sub vdiff{
@_ >= 1 or croak 'usage: $Archive->vdiff([vlog opts])';
my($type) = shift;
my($class) = ref($type);

# The default here is to diff the workfile against the tip
# if we have additional arguments, then assume only the archive

if($class eq "VCS::PVCS::Archive"){
    (caller =~ /VCS::PVCS::(Folder|Archive)/) or ($PVCSOUTPUT = "");
    my($archive) = $type->archive();
    my($workfile) = $type->workfile();
    ($^O ne "MSWin32") and translatePath2Unix(\$archive);
    ($^O ne "MSWin32") and translatePath2Unix(\$workfile);
    if(@_ == 0){
        return VCS::PVCS::Commands::vdiff(@_,$workfile,$archive);
    }
    else{
        return VCS::PVCS::Commands::vdiff(@_,$archive);
    }
}
else{
    croak "Must invoke Archive::vdiff passing archive object"; 
}
}
##############################################################################
# history methods
##############################################################################
sub vlog{
@_ >= 1 or croak 'usage: $Archive->vlog([vlog opts])';
my($type) = shift;
my($class) = ref($type);

if($class eq "VCS::PVCS::Archive"){
    (caller =~ /VCS::PVCS::(Folder|Archive)/) or ($PVCSOUTPUT = "");
    my($archive) = $type->archive();
    ($^O ne "MSWin32") and translatePath2Unix(\$archive);
    return VCS::PVCS::Commands::vlog(@_,$archive);
}
else{
    croak "Must invoke Archive::vlog passing archive object"; 
}
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
@_ >= 2 or croak 'usage: $Archive->lock($label|$version,[vcs opts])';
my($type) = shift;
my($tmptype) = $VCS::PVCS::Commands::vcsopts->{'L'};
my($version) = shift;

$VCS::PVCS::Commands::vcsopts->{'L'} = $version;
vcs($type,@_);
$VCS::PVCS::Commands::vcsopts->{'L'} = $tmptype;

}

sub unlock{
@_ >= 2 or croak 'usage: $Archive->unlock($label|$version,[vcs opts])';
my($type) = shift;
my($tmptype) = $VCS::PVCS::Commands::vcsopts->{'U'};
my($version) = shift;

$VCS::PVCS::Commands::vcsopts->{'U'} = $version;
vcs($type,@_);
$VCS::PVCS::Commands::vcsopts->{'U'} = $tmptype;

}

######################################################################
# Version label methods
######################################################################
sub addVersionLabel{
@_ >= 2 or croak 'usage: $Archive->addVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;

vcs($type,@_,"-V$label");
}

sub deleteVersionLabel{
@_ >= 2 or croak 'usage: $Archive->deleteVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;

($label .= ":delete") unless ($label =~ /:delete$/);
vcs($type,@_,"-V$label");
}

sub replaceVersionLabel{
@_ >= 3 or croak 'usage: $Archive->replaceVersionLabel($newlabel,$oldlabel,[vcs opts])';
my($type) = shift;
my($newlabel) = shift;
my($oldlabel) = shift;

vcs($type,@_,"-V$newlabel\:\:$oldlabel");
}

sub addFloatingVersionLabel{
@_ >= 2 or croak 'usage: $Archive->addFloatingVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;

($label .= ":\*") unless ($label =~ /:\*$/);
vcs($type,@_,"-V$label");
}

sub transformVersionLabel{
@_ >= 2 or croak 'usage: $Archive->transformVersionLabel($label,[vcs opts])';
my($type) = shift;
my($label) = shift;

($label .= ":\\*") unless ($label =~ /:\*$/);
vcs($type,@_,"-V$label","-Y");
}

######################################################################
# Promotion group methods
######################################################################

sub deletePromoGroup{
@_ >= 2 or croak 'usage: $Archive->deletePromoGroup($group,[vcs opts])';
my($type) = shift;
my($label) = shift;

($label .= ":delete") unless ($label =~ /:delete$/);
vcs($type,@_,"-G$label");

}

sub addPromoGroup{
@_ >= 2 or croak 'usage: $Archive->deletePromoGroup($group:$rev,[vcs opts])';
my($type) = shift;
my($label) = shift;

vcs($type,@_,"-G$label");
}

sub createArchive{
@_ >= 2 or croak 'usage: $Folder->createArchive($archive,[vcs opts])';
my($type) = shift;
my($class) = ref($type);

vcs($type,@_,"-I");
}


##########################################################################
# The all-seeing, all-knowing VCS utility command
##########################################################################
sub vcs{
@_ >= 1 or croak 'usage: vcs([opts][files])';
my($type) = shift;
my($class) = ref($type);
my($member);
if($class eq "VCS::PVCS::Archive"){
    (caller =~ /VCS::PVCS::(Folder|Archive)/) or ($PVCSOUTPUT = "");
    my($archive) = $type->archive();
    ($^O ne "MSWin32") and translatePath2Unix(\$archive);
    return VCS::PVCS::Commands::vcs(@_,$archive);
}
else{
    croak "Must invoke Archive::vcs passing archive object"; 
}

}

sub getAttributes{
return VCS::PVCS::Attributes::getAttributes(@_);
}

sub attributes{
my($self) = shift;
return $self->{'Attributes'};
}

1;
__END__

