#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::FileContents;

use strict;
use Carp;

use IO::File;

=head1 NAME

VCS::LibCVS::Datum::FileContents - File contents for use in CVS

=head1 SYNOPSIS

 $fc = VCS::LibCVS::Datum::FileContents->new("/cvs/dir/new.c");
 $rq = VCS::LibCVS::Client::Request::Modified->new(["new.c",$mode,$fc]);

=head1 DESCRIPTION

Datum::FileContents presents the contents of a file in a way which is suitable
for the various purposes of LibCVS.  Important aspects are the transmission of
the length of the file before the contents of the file itself, and the
conversion of line terminators.

A Datum::FileContents does not consist of a group of lines, so it is handled
differently from the others and it overrides most of the class routines.

=head1 SUPERCLASS

  VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Datum/FileContents.pm,v 1.11 2005/10/10 12:52:12 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Datum");

###############################################################################
# Private variables
###############################################################################

# $self->{Length}  The length of the contents
# $self->{Contents}  The contents of the file, right now just a big scalar

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$arg = Datum::FileContents->new($data)

=over 4

=item return type: Datum::FileContents

=item argument 1 type: ...

=over 2

=item E<32>E<32>option 1: IO::Handle

An IO::Handle object from which the file data will be read.  The file data
must arrive over the IO::Handle in the same manner as the CVS protocol, ie. a
file length in bytes followed by newline followed by the file transmission.

=item E<32>E<32>option 2: scalar

The name of a file in the local file system.  This file will not be read until
the Datum is accessed, so if it changes results may be unpredictable.

=item E<32>E<32>option 3: Datum::FileContents

If the argument is already a Datum::FileContents object, it will be
returned.  It will I<not> be copied.

=item E<32>E<32>option 4: \%hash ref

If the hash ref contains a parameter named 'scalar', it will be used as the
entire contents of the file.

=back

=back

Construct a new Datum::FileContents.  The IO::Handle option is generally used
when reading responses from the server, the others when constructing requests.

=cut

sub new {
  my ($class, $arg_data) = @_;

  # if the data is already of the right type, just return it
  return $arg_data if (UNIVERSAL::isa($arg_data, $class));

  my $that = bless {}, $class;

  if (!ref($arg_data)) {
    my $ioh = IO::File->new($arg_data, "r");
    $that->{Length} = (stat($arg_data))[7];
    $that->_read_from_ioh($ioh);
  } elsif (UNIVERSAL::isa($arg_data, "IO::Handle")) {
    $that->{Length} = $arg_data->getline();
    chomp $that->{Length};
    $that->_read_from_ioh($arg_data);
  } elsif ((ref($arg_data) eq "HASH") && (my $scalar = $arg_data->{'scalar'})) {
    $that->{Length} = length $scalar;
    $that->{Contents} = $scalar;
  } else {
    confess "Wrong type for data of Arg:" . ref($arg_data);
  }

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<as_string()>

$datum->as_string()

=over 4

=item return type: scalar string

=back

Returns the file contents as a scalar, which should not be modified.

=cut

sub as_string {
  my $self = shift;
  return $self->{Contents};
}

=head2 B<as_protocol_string()>

$file_contents = $datum->as_protocol_string()

=over 4

=item return type: string scalar

=back

Returns the Datum::FileContents as a string suitable for being sent to the
server: filelength, newline, filecontents.

=cut

sub as_protocol_string {
  my $self = shift;
  return $self->{Length} . "\n" . $self->{Contents};
}

###############################################################################
# Private routines
###############################################################################

# read data in from an io handle
# it expects to find the number of bytes to read in $self->{Length}
# the data is put in $self->{Contents}

# This doesn't handle network stuff very well.  read isn't properly documented,
# but I assume that it's going to block on network stuff, and I'll have to muck
# about with select and I don't want to do that.
sub _read_from_ioh {
  my ($self, $ioh) = @_;
  my $num_bytes_read = $ioh->read($self->{Contents}, $self->{Length});

  confess "Error on read." if (!defined ($num_bytes_read));
  confess "Wrong number of bytes" if ($num_bytes_read != $self->{Length});
}

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;
