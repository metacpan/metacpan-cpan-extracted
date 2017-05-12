#!/usr/local/bin/perl

#
# Solaris::Patchdiag
# Parses the Patchdiag.xref file into a parsable data structure
# Chris Josephes 20000929
#

#
# Package Definition
#

package Solaris::Patchdiag;

use strict;
use vars qw($VERSION);

#
# Global Variables
#

$VERSION=0.9;

#
# Constructor Methods
#

sub new 
{
my (@args)=@_;
my ($object)={};
bless ($object);
$object->_init(@args);
return($object);
}

sub version
{
return($VERSION);
}

#
# Object Methods
#

# Set the xref file to use
sub file
{
my ($self,$file)=@_;
if ($file)
{
	$self->{"file"}=$file;
	$self->_readFile();
}
return($self->{"file"});
}

# List all of the patches in the xref file
sub list
{
my ($self)=@_;
return(keys(%{$self->{"db"}}));
}

# Return a hash for a specific patch entry
sub entry
{
my ($self,$id)=@_;
return(%{$self->{"db"}->{$id}});
}

#
# The following methods return specific fields from within 
# the xref file for a given entry
#

# Patch Revision
sub rev
{
my ($self,$id)=@_;
return($self->{"db"}->{$id}->{"rev"});
}

# Patch release date
sub releaseDate
{
my ($self,$id)=@_;
return($self->{"db"}->{$id}->{"date"});
}

# Recommended flag
sub recommendedFlag
{
my ($self,$id)=@_;
return($self->{"db"}->{$id}->{"rf"});
}

# Security flag
sub securityFlag
{
my ($self,$id)=@_;
return($self->{"db"}->{$id}->{"sf"});
}

# Obsolete flag
sub obsoleteFlag
{
my ($self,$id)=@_;
return($self->{"db"}->{$id}->{"of"});
}

# Y2k flag
sub y2kFlag
{
my ($self,$id)=@_;
return($self->{"db"}->{$id}->{"yf"});
}

sub osRelease
{
my ($self,$id)=@_;
return($self->{"db"}->{$id}->{"osr"});
}

sub arch
{
my ($self,$id)=@_;
return($self->{"db"}->{$id}->{"arch"});
}

sub pkgs
{
my ($self,$id)=@_;
return($self->{"db"}->{$id}->{"pkgs"});
}

sub synopsis
{
my ($self,$id)=@_;
return($self->{"db"}->{$id}->{"synop"});
}

#
# The following methods return a list of patches
# if the requested flag is set
#

# Return a list of all recommended patches
sub recommendedList
{
my ($self)=@_;
my ($patch,@list);
foreach $patch (keys(%{$self->{"db"}}))
{
	if ($self->{"db"}->{$patch}->{"rf"})
	{
		push(@list,$patch);
	}
}
return(@list);
}

# Return a list of all security patches
sub securityList
{
my ($self)=@_;
my ($patch,@list);
foreach $patch (keys(%{$self->{"db"}}))
{
        if ($self->{"db"}->{$patch}->{"sf"})
        {
                push(@list,$patch);
        }
}
return(@list);
}

# Return a list of all obsolete patches
sub obsoleteList
{
my ($self)=@_;
my ($patch,@list);
foreach $patch (keys(%{$self->{"db"}}))
{
        if ($self->{"db"}->{$patch}->{"of"})
        {
                push(@list,$patch);
        }
}
return(@list);
}

# Return a list of all y2k patches
sub y2kList
{
my ($self)=@_;
my ($patch,@list);
foreach $patch (keys(%{$self->{"db"}}))
{
        if ($self->{"db"}->{$patch}->{"yf"})
        {
                push(@list,$patch);
        }
}
return(@list);
}

# Methods that are based on package name, not patch id
sub patchesFor
{
my ($self,$pkg,$osRelease)=@_;
return(keys(%{$self->{"pkgs"}->{$pkg}->{$osRelease}}))
}

#
# Hidden Methods
#

sub _init
{
my ($self,@args)=@_;
while (@args)
{
	my ($x);
	$x=shift(@args);
	if ($x eq "-file")
	{
		$self->{"file"}=shift(@args);
	}
} 
unless ($self->{"file"})
{
	if (-e "patchdiag.xref" )
	{
		$self->{"file"}="patchdiag.xref";
		$self->_readFile();
	}
}
$self->_readFile() if ($self->{"file"});
$self->_reverseMap();
return();
}

# Read the file into the "db" data structure
sub _readFile
{
my ($self)=@_;
my ($line,$id,$field,$value,@flds);
# Delete any old patchref data we may have
delete ($self->{"db"});
open (F, $self->{"file"}) || return(undef);
while ($line=<F>)
{
	next if ($line=~/^#/);
	(@flds)=split(/\|/,$line);
	$id=shift(@flds);
	foreach $field ("rev","date","rf","sf","of","yf",
		"osr","arch","pkgs","synop")
	{
		$value=shift(@flds);
		$value=undef if ($value=~/^\s+$/);
		$self->{"db"}->{$id}->{$field}=$value;
	}
}
close(F);
return();
}

# Build a reverse lookup map based on packages
sub _reverseMap
{
my ($self)=@_;
my ($patch,$pkgBlock,$os,$p,$pname,@pkgs);
foreach $patch ($self->list())
{
	($pkgBlock)=$self->pkgs($patch);
	($os)=$self->osRelease($patch);
	(@pkgs)=split(/;/,$pkgBlock);
	while (@pkgs)
	{
		$p=shift(@pkgs);
		($pname)=split(/:/,$p);
		$self->{"pkgs"}->{$pname}->{$os}->{$patch}=1;
	}
}
return();
}

#
# Exit Block
#
1;

#
# POD Block
#

=head1 NAME

Solaris::Patchdiag - Patchdiag class file

=head1 SYNOPSIS

use Solaris::Patchdiag;
$pd=Solaris::Patchdiag::new(-file => $filename);

=head1 DESCRIPTION

Solaris::Patchdiag is a class for accessing the content of the patchdiag.xref 
file, which is a file Sun puts out to list patches available for the Solaris 
operating system.

An instance method of the class reads in the file, and accessor methods 
allow programs to obtain information about the patches, such as what OS 
version the patch is for, and what packages the patch is applied to.

=head1 CONSTRUCTOR METHOD

$pd=Solaris::Patchdiag::new(-file => $filename);

The new method can accept a file paramter to specify what patchdiag.xref file 
it should read.  If no file is specified, the object will look for a 
patchdiag.xref file in the current directory.

=head1 OBJECT METHODS

=over 4

=item rev($id)

=item releaseDate($id)

=item recommendedFlag($id)

=item securityFlag($id)

=item obsoleteFlag($id)

=item y2kFlag($id)

=item osRelease($id)

=item arch($id)

=item pkgs($id)

=item synopsis($id)

Each of the above methods access fields within the file for a specified patch.  
To find out what operating system release patch ID 108832 is for, you would use

 $os=$pd->osRelease(108832);

=back

=over 4

=item file()

Returns the name of the patchdiag.xref file being referenced

=back

=over 4

=item list()

Returns a list of all patches in the patchdiag.xref file

=back

=over 4

=item entry($id)

Returns a hash table with all of the data for a particular patch

=back

=over 4

=item recommendedList()

=item securityList()

=item obsoleteList()

=item y2kList()

Each of the above methods returns an array list of patches with the 
appropriate flag set.  For example, to get a list of all of the security 
classified patches, use

 (@secpatches)=$pd->securityList();

=back

=over 4

=item patchesFor($pkg,$osRelease)

Returns an array of all the patches that modify a package in a specific OS 
Release

=back

=head1 NOTES

The patchdiag.xref file is a REALLY awkward file format, and the fact that 
it isn't really documented doesn't help much.  I'm only interpreting it 
based on the source code of the patchdiag.pl program and from 
observation.

The "arch" field apparantly lists architectures supported by the patch, AND 
prerequisite patches that need to be installed beforehand.  

The "flag" fields contain a space when empty, which technically wastes 
space.  

The "y2k" field can contain either a "Y" or a "B", and the original 
patchdiag.pl program checks for the possibility of a "YB" value as well.  
I have no idea what the differences are, so I just report the flag as set 
if either character is present.

The "osRelease" field specifies the Solaris OS release name, which involves 
some munging, and it makes no sense at times.  Why report "7_x86" in one 
field, when you already report the platform architecture in another?  Maybe 
it's really a Solaris naming convention issue.

=head1 AUTHOR

Chris Josephes, chrisj@onvoy.com

=head1 SEE ALSO

The patchdiag(1m) manpage.
