#!/usr/local/bin/perl

# Solaris::InstallDB
# Management of the /var/sadm/pkg directory
# And the contents file
#
# Chris Josephes 200001003
#

#
# Package Definition
#

package Solaris::InstallDB;

use strict;
use vars qw($VERSION $DefaultPkgDir);

$VERSION=0.9;

#
# Includes
#

use Solaris::Package;
use Solaris::Contents;

#
# Global Variables
#

$DefaultPkgDir="/var/sadm/pkg";

#
# Constructor Method
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

# Return the operating system release level (uname output)
sub release
{
my ($self)=@_;
return($self->{"os"}->{"release"});
}

# Return the commercial "Solaris XXX" release name
sub releaseAlias
{
my ($self)=@_;
return($self->{"os"}->{"alias"} || $self->{"os"}->{"release"});
}

# Return the hardware Instruction Set Architecture
sub isa
{
my ($self)=@_;
return($self->{"hw"}->{"isa"});
}

# Return the processor name
sub processor
{
my ($self)=@_;
return($self->{"hw"}->{"processor"});
}

# Return the hardware class
sub hardwareClass
{
my ($self)=@_;
return($self->{"hw"}->{"class"});
}

# Return the ISA and hardware class together
sub arch
{
my ($self)=@_;
return($self->{"hw"}->{"isa"}.".".$self->{"hw"}->{"class"});
}

# Return a list of packages
sub packages
{
my ($self)=@_;
return(keys(%{$self->{"db"}}));
}

# Return a list of supported architectures for a package
sub arches
{
my ($self,$pkg)=@_;
return(keys(%{$self->{"db"}->{$pkg}}));
}

# Return the contents file object
sub contents
{
my ($self)=@_;
return ($self->{"contents"} || undef);
}

sub pkgFile
{
my ($self,@args)=@_;
my ($x,$name,$arch);
while (@args)
{
	$x=shift(@args);
	if ($x eq "-name")
	{
		$name=shift(@args);
	} elsif ($x eq "-arch")
	{
		$arch=shift(@args);
	}
}
$arch=$self->arch() unless ($arch);
if ($name && $arch)
{
	return($self->{"db"}->{$name}->{$arch} || undef);
} else {
	return(undef);
}
}

sub package
{
my ($self,@args)=@_;
my ($x,$name,$arch,$debug,$object);
while (@args)
{
	($x)=shift(@args);
	if ($x eq "-name")
	{
		$name=shift(@args);
	} elsif ($x eq "-arch")
	{
		$arch=shift(@args);
	} elsif ($x eq "-debug")
	{
		$debug=1;
	}
}
unless ($name)
{
	print("No name specified\n") if ($debug);
	return(undef);
}
unless ($arch)
{
	my ($isa,$test);
	$isa=$self->isa();
	$test=$self->arch();
	if ($self->{"db"}->{$name}->{$test})
	{
		$arch=$test;
	} elsif ($self->{"db"}->{$name}->{$isa})
	{
		$arch=$isa;
	} else {
		print("Architecture must be specified") if ($debug);
		return(undef);
	}
} else {
	unless ($self->{"db"}->{$name}->{$arch})
	{
		print("Package $name, not found for arch $arch\n") 
		if ($debug);
		return(undef);
	}
}
$object=Solaris::Package::new(-directory => $self->{"pkgDir"}, 
	-file => $self->{"db"}->{$name}->{$arch},
	-installDB => $self); 
return($object);
}

sub directory
{
my ($self)=@_;
return($self->{"pkgDir"});
}

#
# Hidden Methods
#

# Parse the arguements passed to the constructor method
sub _init
{
my ($self,@args)=@_;
my ($a);
while (@args)
{
	$a=shift(@args);
	if ($a eq "-loadContents")
	{
		$self->{"contents"}=Solaris::Contents::new();
	} elsif ($a eq "-directory")
	{
		$self->{"pkgDir"}=shift(@args);
	}
}
$self->{"pkgDir"}=$DefaultPkgDir unless ($self->{"pkgDir"});
# Get the OS data
$self->_hostInfo();
# Find all of the installed packages
$self->_scanPkgDir();
return();
}

sub _hostInfo
{
my ($self)=@_;
my ($und,$test);
# Get the OS data
open (UN, "/usr/bin/uname -rpim |");
$und=<UN>;
chop($und);
close(UN);
($self->{"os"}->{"release"},$self->{"hw"}->{"class"},
        $self->{"hw"}->{"isa"},$self->{"hw"}->{"processor"})=split(/\s/,$und);
# Determine an alias for our operating system release
$test=chop($self->{"os"}->{"release"});
if ($test >= 7)
{
	$self->{"os"}->{"alias"}=$test;
}
if ($self->{"hw"}->{"arch"} eq "i386")
{
	if ($self->{"os"}->{"alias"})
	{
		$self->{"os"}->{"alias"}.="_x86";
	} else {
		$self->{"os"}->{"alias"}=$self->{"os"}->{"release"}."_x86";
	}
}
return();
}

# Scan the package directory, and find the name of every package
# in it.
sub _scanPkgDir
{
my ($self)=@_;
my ($dir,$entry,$ecount);
$dir=$self->{"pkgDir"};
$self->{"db"}={};
opendir (D, $dir) || return(undef);
while ($entry=readdir(D))
{
	if (-d $dir."/".$entry)
	{
		next if ($entry eq "." || $entry eq "..");
		if (-e $dir."/".$entry."/pkginfo")
		{
			$self->_getPkgName($dir,$entry);
			$ecount++;
		}
	}
}
closedir(D);
return();
}

# Read a pkginfo file to determine the package name
sub _getPkgName
{
my ($self,$dir,$entry)=@_;
my ($param,$value,$x,$pkg,$arch);
open (F, $dir."/".$entry."/pkginfo");
while ($x=<F>)
{
	($param,$value)=split(/=/,$x);
	if ($param eq "PKG")
	{
		chop($value);
		$pkg=$value;
	} elsif ($param eq "ARCH")
	{
		chop($value);
		$arch=$value;
	} 
	last if ($pkg && $arch);
}
close(F);
$self->{"db"}->{$pkg}->{$arch}=$entry;
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

Solaris::InstallDB - Manages Solaris package information

=head1 SYNOPSIS

use Solaris::InstallDB
$instdb=Solaris::InstallDB::new(-directory => $dir, -loadContents);

=head1 DESCRIPTION

The Solaris::InstallDB class manages a directory of Solaris packages. It 
searches for all of the packages in a directory, and then records them in 
a hash table by name and architecture.  It is also capable of spawning a 
Solaris::Contents object.

With this class, you can get a list of all packages available, and all 
architectures it supports.  It can also report some basic system about the 
hardware it is running on.

=head1 CONSTRUCTOR METHOD

$instdb=Solaris::InstallDB::new(-directory => $dir, -loadContents);

The new method creates a Solaris::InstallDB object.  By default, it will 
search for objects in the /var/sadm/pkg directory, but you can change that 
by using the -directory parameter.

If you want to create a Solaris::Contents object automatically, add the 
-loadContents flag.

=head1 OBJECT METHODS

=over 4

=item release()

Returns the operating system release number in uname format.  For example, 
if you were running a script on a Solaris 7 system, it would return 5.7.

=back

=over 4 

=item releaseAlias()

Returns the commercial name of the operating system.  For example, if you 
were running a script on an Intel system running Solaris 7, it would 
return 7_x86.

=back

=over 4

=item isa()

Returns the Instruction Set Architecture of the hardware.

=back

=over 4

=item processor()

Returns the processor type.

=back

=over 4

=item hardwareClass()

Returns the hardware class.

=back

=over 4

=item arch()

Returns a combination of the ISA and hardware class.

=back

=over 4

=item packages()

Returns a list of the packages found in the specified directory

=back

=over 4

=item arches($pkg)

Returns a list of architectures supported by a given package.

=back

=over 4

=item contents()

Returns the Solaris::Contents object that was created when the object 
was initialized.

=back

=over 4

=item package(-name => $pkg, -arch => $arch, -debug)

Returns a Solaris::Package object.

If -arch isn't specified, the object will search the database for a suitable 
match based on the system the script is running on.

If -debug is specified and the method fails to return a package object, 
an error message to STDOUT will explain why the method failed.

=back

=over 4

=item pkgFile(-name => $name, -arch => $arch)

Returns the filename of a particular package for the specified architecture

=back

=over 4

=item directory()

Returns the directory the object is looking for packages in

=back

=head1 NOTES

This object only works on packages in the directory format, not the data 
stream format.

The code may seem a bit complex, but it's due to the fact that there are 
different package directories for the same package, but with different 
architectures.

Since I have a lot of code that gives hardware information, I may work on the 
idea of a Solaris::Hardware package during a later code revision.

=head1 AUTHOR

Chris Josephes, chrisj@onvoy.com
