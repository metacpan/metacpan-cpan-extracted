package VMS::FlatFile;

use strict;
use vars qw($VERSION);

$VERSION    = "0.01";

# use the IndexedFile module
use VMS::IndexedFile;
use Data::FixedFormat;

1;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
    my $self = shift;
    $self->{FileName} = shift;
    $self->{Access} = shift;
    my $fmt = shift;
    $self->{KeyNum} = shift || 0;
    $self->{Handle} = tie(%{$self->{File}}, 'VMS::IndexedFile',
			  $self->{FileName}, $self->{KeyNum},
			  $self->{Access} ? O_RDWR : O_RDONLY)
	|| die "Unable to tie to file $self->{FileName}\n$!\n";
    $self->{Formatter} = Data::FixedFormat->new($fmt);
    1;
}

sub get {
    my $self = shift;
    my $key = shift;
    my $frec = ${$self->{File}}{$key};
    return undef unless $frec;
    $self->{Formatter}->unformat($frec);
}

sub put {
    my $self = shift;
    my $frec = $self->{Formatter}->format(@_);
    $self->{Handle}->store($frec);
}

sub delete {
    my $self = shift;
    my $key = shift;
    delete(${$self->{File}}{$key});
}

=head1 NAME

VMS::FlatFile - read and write hashes with VMS::IndexedFile.

=head1 SYNOPSIS

=head2 Standalone

    # Load the module
    use VMS::FlatFile;

    # Create an instance
    # args - file name, access (ro=0, rw=1), format, key number
    my $file = new VMS::FlatFile 'disk$user01:[user]file.dat', 0,
			    [ 'field1:a10', 'field2:a16' ], 0;

    # Read a hash
    my $hashref = $file->get($key);
    # Write a hash
    my $sts = $file->put($hashref);
    # Delete a record
    $sts = $file->delete($key);

=head2 As a Base Class

    # name your derived class
    package MyFile;

    # Load the module and derive
    use VMS::FlatFile;
    use var qw(@ISA);
    @ISA = qw(VMS::FlatFile);
    1;

    # override new
    sub new {
        my $class = shift;
	my $self = {};
	bless $self,$class;
	# default to read only
	my $access = shift || 0;
	# use key 0
	my $krf = shift || 0;
	$self->_initialize('disk:[dir]filename.type', $access,
		[ 'field1:a10', 'field2:a16' ], $krf);
	return $self;
    }

    package main;

    # create an instance
    my $file = new MyFile;
    my $hashref = $file->get('keyvalue');

=head1 DESCRIPTION

VMS::FlatFile combines VMS::IndexedFile and Data::FixedFormat to make
it possible to read and write hashes to VMS indexed files.

First, load the module:

    use VMS::FlatFile;

Next, create an instance:

    my $file = new VMS::FlatFile 'disk$user01:[user]file.dat', 0,
			    [ 'field1:a10', 'field2:a16' ], 0;

The B<new> method accepts four arguments:

=over 4

=item filename

The filename argument is passed directly to VMS::IndexedFile.

=item access

If access is true, the file is opened read/write.  If false the file
is opened read only.

=item format

The format argument is used to construct a Data::FixedFormat instance
for the file.  This argument is passed directly to
Data::FixedFormat::new.

=item key of reference

This argument is passed to VMS::IndexedFile to select a key of
reference.  If not specified or if specified as 0, the file's primary
key is used.  Specify 1 for the first alternate key, etc.

=back

To read records, use the B<get> method:

    my $hashref = $file->get($key);

B<get> returns a reference to a hash created by
Data::FixedFormat::unformat.

B<get> accepts one argument which is the key of the record to be read.
If specified as the null string, the next sequential record is read
from the file.

To write records, use the B<put> method:

    my $sts = $file->put($hashref);

The status returned by B<put> comes from VMS::IndexedFile::store.  The
lone argument is a reference to a hash which is converted into a file
buffer with Data::FixedFormat::format and written to the file.

To delete records, use the B<delete> method:

    my $sts = $file->delete($key);

The record with the specified key value will be deleted from the file.

The easiest way to use VMS::FlatFile as a base class would be to write a
derived module that provides the filename and format arguments for
each file you need to access.  To do this, override the B<new> method
with a routine like the following:

    package MyFile;
    use VMS::FlatFile;
    use vars qw(@ISA);
    @ISA = qw(VMS::FlatFile);

    sub new {
        my $class = shift;
	my $self = {};
	bless $self,$class;
	# default to read only
	my $access = shift || 0;
	# use key 0
	my $krf = shift || 0;
	$self->_initialize('disk:[dir]filename.type', $access,
		[ 'field1:a10', 'field2:a16' ], $krf);
	return $self;
    }

The B<_initialize> routine takes the same arguments as B<new>.  This
new constructor takes two arguments; the access mode (true for
read/write) and the key of reference.

VMS::FlatFile instances contain the attributes:

=over 4

=item File

This is the hash bound to the file with B<tie>.  Records are read from
the file by reading attributes (i.e., file keys) from this hash.

=item Handle

This attribute receives the result from the call to B<tie> which
connects the VMS file to the hash.

=item Formatter

The Formatter attribute is an instance of a Data::FixedFormat which is
used for converting between file records and hashes.

=back

=head1 AUTHOR

VMS::FlatFile was written by Thomas Pfau <pfau@eclipse.net>
http://www.eclipse.net/~pfau/.

=head1 COPYRIGHT

Copyright (C) 2000 Thomas Pfau.  All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU General Public License
along with this progam; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
