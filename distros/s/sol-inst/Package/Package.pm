#!/usr/local/bin/perl

#
# Solaris::Package
# Obtain package information from a Solaris system
# Chris Josephes 20000929
#

#
# Package Definition
#

package Solaris::Package;

use strict;
use vars qw($VERSION);

$VERSION=0.9;

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
# Class Methods
#

sub pkg
{
my ($self)=@_;
return($self->{"params"}->{"PKG"});
}

sub name
{
my ($self)=@_;
return($self->{"params"}->{"NAME"});
}

sub desc
{
my ($self)=@_;
return($self->{"params"}->{"DESC"});
}

sub pkVersion
{
my ($self)=@_;
return($self->{"params"}->{"VERSION"});
}

sub arch
{
my ($self)=@_;
return($self->{"params"}->{"ARCH"});
}

sub email
{
my ($self)=@_;
return($self->{"params"}->{"EMAIL"});

}

sub hotline
{
my ($self)=@_;
return($self->{"params"}->{"HOTLINE"});
}

sub vendor
{
my ($self)=@_;
return($self->{"params"}->{"VENDOR"});
}

sub basedir
{
my ($self)=@_;
return($self->{"params"}->{"BASEDIR"});
}

sub pstamp
{
my ($self)=@_;
return($self->{"params"}->{"PSTAMP"});
}

sub instdate
{
my ($self)=@_;
return($self->{"params"}->{"INSTDATE"});
}

sub paramDump
{
my ($self)=@_;
return(%$self->{"params"});
}

sub pkgInfo
{
my ($self)=@_;
my ($param,$fmt);
$fmt="%10s:  %s\n";
foreach $param ("PKGINST","NAME","CATEGORY","ARCH","VERSION","BASEDIR",
		"VENDOR","DESC","PSTAMP","INSTDATE","HOTLINE")
{
	if ($self->{"params"}->{$param})
	{
		printf($fmt,$param,$self->{"params"}->{$param});
	}
}
return();
}

sub patchList
{
my ($self)=@_;
my (@list);
(@list)=split(/\s+/,$self->{"params"}->{"PATCHLIST"});
return(@list);
}

#
# Hidden Class Methods
#

# Solaris::Package currently only accepts a package name as an arguement
# however, that will change.
sub _init
{
my ($self,@args)=@_;
while (@args)
{
	my ($x);
	($x)=shift(@args);
	if ($x eq "-installDB")
	{
		$self->{"installDB"}=shift(@args);
	} elsif ($x eq "-directory")
	{
		$self->{"directory"}=shift(@args);
	} elsif ($x eq "-file")
	{
		$self->{"file"}=shift(@args);
	} 
}
unless ($self->_readPkgInfo())
{
	return(undef);
}
return();
}

sub _readPkgInfo
{
my ($self)=@_;
my ($pdir,$pfile,$x,$param,$value);
if ($self->{"directory"} && $self->{"file"})
{
	$pdir=$self->{"directory"};
	$pfile=$self->{"file"};
} else {
	print("Insufficient Info to find package $self->{name}\n");
}
open (F, $pdir."/".$pfile."/pkginfo") || return(undef);
while ($x=<F>)
{
	chop($x);
	($param,$value)=split(/=/,$x);
	$self->{"params"}->{$param}=$value;
}
close(F);
return(($self->{"params"}->{"PKG"}?1:undef));
}

#
# Exit Block
#
1;

#
# POD Block
#

=head1 NAME

Solaris::Package - Perl module to obtain basic Solaris Package Info

=head1 SYNOPSIS

  use Solaris::Package;

  $x=Solaris::Package::new(-directory => "/tmp/install", -file => "SUNWm64.u");

=head1 DESCRIPTION

Solaris::Package is a class module that reads in the information from a 
pkginfo file for a Solaris package.  It can be spawned from a 
Solaris::InstallDB object, or it can be used as a standalone object.

=head1 CONSTRUCTOR METHOD

=over 4

=item $pkg=Solaris::Package::new(-directory => $dir, -file => $pkgDir);

The -directory arguement specifies what package directory to search in, 
the -file directory points to the directory name the package is in.

Optionally, you can specify a pointer to a Solaris::InstallDB object by 
using the -installDB arguement.

Two points to clarify:

This object only works on Solaris packages in the directory format, not the 
data stream format, so the -file arguement is really specifying a 
filesystem directory.

The name of a package is not necessarily the same as the name of the file 
of the package.  The SUNWm64 example at the beginning of this documentation 
is an example of a package with a different directory name.

=back 

=head1 OBJECT METHODS

=over 4

=item pkg()

=item name()

=item desc()

=item pkVersion()

=item arch()

=item email()

=item hotline()

=item vendor()

=item basedir()

=item pstamp()

=item instdate()

=item patchList()

Each of these methods returns their corresponding pkginfo parameter.  Note 
that patchList() returns an array type, with each element listing a single 
patch. The pkVersion() method returns the package version, and should not 
be confused with the version() method.

=back

=over 4

=item pkgInfo()

Returns a simplified output similar to the "pkginfo" command, but does not 
report filesystem contents.  That can be achieved by using the 
Solaris::Contents object.

=back

=over 4

=item paramDump()

Returns a hash table with every parameter in the pkginfo file and every 
corresponding value

=back

=head1 AUTHOR

Chris Josephes, chrisj@onvoy.com

=head1 SEE ALSO

The pkginfo(4) manpage.
