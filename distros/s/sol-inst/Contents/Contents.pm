#!/usr/local/bin/perl

# Solaris::Contents
# Object for the Solaris contents file
#
# Chris Josephes 200001003
#

#
# Package Definition
#

package Solaris::Contents;

use strict;
use vars qw($VERSION $Contents);

$VERSION=0.9;
$Contents="/var/sadm/install/contents";

#
# Global Variables
#

#
# Constructor Method
#

sub new
{
my ($object)={};
bless ($object);
$object->{"file"}=$Contents;
$object->_read();
$object->_reverseMap();
return($object);
}

sub version
{
return($VERSION);
}

#
# Object Methods
#

# Return an array of all files in the contentsDB (very long)
sub entries
{
my ($self)=@_;
return(keys(%{$self->{"db"}}));
}

# Return an array of all files associated with one package
sub entriesForPkg
{
my ($self,$pkg)=@_;
return(keys(%{$self->{"rev"}->{$pkg}}));
}

# Return a hash with all of the data for a particular entry
sub entry
{
my ($self,$file)=@_;
return(%{$self->{"db"}->{$file}});
}

# Return the file's ftype
sub ftype
{
my ($self,$file)=@_;
return($self->{"db"}->{$file}->{"ftype"});
}

sub class
{
my ($self,$file)=@_;
return($self->{"db"}->{$file}->{"class"});
}

sub major
{
my ($self,$file)=@_;
return($self->{"db"}->{$file}->{"major"});
}

sub minor
{
my ($self,$file)=@_;
return($self->{"db"}->{$file}->{"minor"});
}

sub mode
{
my ($self,$file)=@_;
return($self->{"db"}->{$file}->{"mode"});
}

sub user
{
my ($self,$file)=@_;
return($self->{"db"}->{$file}->{"user"});
}

sub group
{
my ($self,$file)=@_;
return($self->{"db"}->{$file}->{"group"});
}

sub size
{
my ($self,$file)=@_;
return($self->{"db"}->{$file}->{"size"});
}

sub cksum
{
my ($self,$file)=@_;
return($self->{"db"}->{$file}->{"cksum"});
}

sub modified
{
my ($self,$file)=@_;
return($self->{"db"}->{$file}->{"modified"});
}

sub pkgs
{
my ($self,$file)=@_;
return(@{$self->{"db"}->{$file}->{"pkgs"}});
}

#
# Hidden Methods
#

sub _read
{
my ($self)=@_;
my ($ln,$file,$ftype,$class,$fld,$flds,@rest,@rf,@lines);
open (F, $self->{"file"}) || return(undef);
(@lines)=<F>;
close(F);
while (@lines)
{
	$ln=shift(@lines);
	next if ($ln=~/^#/);
	($file,$ftype,$class,@rest)=split(/\s/,$ln);
	$self->{"db"}->{$file}->{"file"}=$file;
	$self->{"db"}->{$file}->{"ftype"}=$ftype;
	$self->{"db"}->{$file}->{"class"}=$class;
	# print("Ftype $ftype - File $file\n");
	# The rest of the fields in the contents file
	# are dependent on what the ftype is
	if ($ftype eq "s" || $ftype eq "l")
	{
		(@rf)=();
	} elsif ($ftype eq "b" || $ftype eq "c")
	{
		(@rf)=("major","minor","mode","user","group");
	} elsif ($ftype eq "d")
	{
		(@rf)=("mode","user","group","pkgs");
	} elsif ($ftype eq "e" || $ftype eq "f" || $ftype eq "v")
	{
		(@rf)=("mode","user","group","size","cksum","modified");
	} else {
		# Unknown ftype, we shouldn't reach this part
		# Best to delete the strange entry and move on
		$self->{"db"}->{$file}={};
		next;
	}
	while (@rf)
	{
		$fld=shift(@rf);
		# print("Assigning $fld to $file\n");
		$self->{"db"}->{$file}->{$fld}=shift(@rest);
	}
	$self->{"db"}->{$file}->{"pkgs"}= [ @rest ];
}
return();
}

# Build a reverse contents map based on pacakge
sub _reverseMap
{
my ($self)=@_;
my ($file,$p,@pkgs);
foreach $file ($self->entries())
{
	(@pkgs)=$self->pkgs($file);
	while (@pkgs)
	{
		$p=shift(@pkgs);
		$self->{"rev"}->{$p}->{$file}=1;
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

Solaris::Contents - Read /var/sadm/install/contents file

=head1 SYNOPSIS

$c=Solaris::Contents::new();

=head1 DESCRIPTION

Solaris::Contents is an object oriented interface into the 
/var/sadm/install/contents file which Solaris uses to keep track of all 
the files installed on a system, and their corresponding packages.

=head1 CONSTRUCTOR METHOD

$c=Solaris::Contents::new();

No arguements are required.  By default, the object always believes the 
contents file is /var/sadm/install/contents.  The ability to change this 
could change with a future release.

=head1 OBJECT METHODS

=over 4

=item entries()

Returns an array of every file record in the contents file.  Very long.

=back

=over 4

=item entriesForPkg()

Returns an array of every file record for a specified package.

=back

=over 4

=item entry($file)

Returns a hash table of every element for a specified file.

=back

=over 4

=item ftype($file)

=item class($file)

=item major($file)

=item minor($file)

=item mode($file)

=item user($file)

=item group($file)

=item size($file)

=item cksum($file)

=item modified($file)

=item pkgs($file)

Each of the above methods returns the specific data for a specified file 
entry from the contents file.  Not all entries will have data specific to 
every method.  Check the Solaris prototype man page for more information.  
The pkgs() method returns an array of packages related to that specific file.

=back

=head1 NOTES

The initialization time of Contents objects could take a few seconds 
depending on the size of the contents file.

I may add more methods to this class later on.  It would be kind of neat to 
do more with the link entries.

=head1 AUTHOR

Chris Josephes, chrisj@onvoy.com
