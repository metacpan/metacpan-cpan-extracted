#

package Tie::Dir;

=head1 NAME

Tie::Dir - class definition for reading directories via a tied hash

=head1 SYNOPSIS

	use Tie::Dir qw(DIR_UNLINK);
	
	# Both of these produce identical results
	#(ie %hash is tied)
	tie %hash, Tie::Dir, ".", DIR_UNLINK;
	new Tie::Dir \%hash, ".", DIR_UNLINK;
	
	# This creates a reference to a hash, which is tied.
	$hash = new Tie::Dir ".";
	
	# All these examples assume that %hash is tied (ie one of the
	# first two tie methods was used
	
	# itterate through the directory
	foreach $file ( keys %hash ) {
		...
	}
	
	# Set the access and modification times (touch :-)
	$hash{SomeFile} = time;
	
	# Obtain stat information of a file
	@stat = @{$hash{SomeFile}};
	
	# Check if entry exists
	if(exists $hash{SomeFile}) {
		...
	}
	
	# Delete an entry, only if DIR_UNLINK specified
	delete $hash{SomeFile};

=head1 DESCRIPTION

This module provides a method of reading directories using a hash.

The keys of the hash are the directory entries and the values are a
reference to an array which holds the result of C<stat> being called
on the entry.

The access and modification times of an entry can be changed by assigning
to an element of the hash. If a single number is assigned then the access
and modification times will both be set to the same value, alternatively
the access and modification times may be set separetly by passing a 
reference to an array with 2 entries, the first being the access time
and the second being the modification time.

=over

=item new [hashref,] dirname [, options]

This method ties the hash referenced by C<hashref> to the directory C<dirname>.
If C<hashref> is omitted then C<new> returns a reference to a hash which
hash been tied, otherwise it returns the result of C<tie>

The possible options are:

=over

=item DIR_UNLINK

Delete operations on the hash will cause C<unlink> to be called on the
corresponding file 

=back

=back

=head1 AUTHOR

Graham Barr <bodg@tiuk.ti.com>, from a quick hack posted by 
Kenneth Albanowski <kjahds@kjahds.com>  to the perl5-porters mailing list
based on a neat idea by Ilya Zakharevich.

=cut

use Symbol;
use Carp;
use Tie::Hash;
use strict;
use vars qw(@ISA $VERSION @EXPORT_OK);
require Exporter;

@ISA = qw(Tie::Hash Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
@EXPORT_OK = qw(DIR_UNLINK);

sub DIR_UNLINK { 1 }

sub new {
    my $pkg = shift;
    my $h;

    if(@_ && ref($_[0])) {
	$h = shift;
	return tie %$h, $pkg, @_;
    }

    $h = {};
    tie %$h, $pkg, @_;
    return $h;
}

sub TIEHASH {
    my($class,$dir,$unlink) = @_;
    $unlink ||= 0;
    bless [$dir,undef,$unlink], $class;
}

sub FIRSTKEY {
    my($this) = @_;
    if($this->[1]) {
	eval { rewinddir($this->[1]) } or
	    opendir($this->[1],$this->[0]) or
	    croak "Can't read ".$this->[0].": $!";
    }
    else {
	$this->[1] =  gensym();
	opendir($this->[1],$this->[0]) or
		croak "Can't read ".$this->[0].": $!";
    }
    readdir($this->[1]);
}

sub NEXTKEY {
    my($this,$last) = @_;
    readdir($this->[1]);
}

sub EXISTS {
    my($this,$key) = @_;
    -e $this->[0] . "/" . $key;
}

sub DESTROY {
    my($this) = @_;
    closedir($this->[1])
	if($this->[1]);
}

sub FETCH {
    my($this,$key) = @_;
    [stat($this->[0] . "/" . $key)];
}

sub STORE {
    my($this,$key,$data) = @_;
    my($atime,$mtime) = ref($data) ? @$data : ($data,$data);
    utime($atime,$mtime, $this->[0] . "/" . $key);
}

sub DELETE {
    my($this,$key) = @_;
    # Only unlink if unlink-ing is enabled
    unlink($this->[0] . "/" . $key)
	if($this->[2] & DIR_UNLINK);
}

1;

