#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum;

use strict;
use Carp;

use VCS::LibCVS::Datum::DirectoryName;
use VCS::LibCVS::Datum::Entry;
use VCS::LibCVS::Datum::FileContents;
use VCS::LibCVS::Datum::FileMode;
use VCS::LibCVS::Datum::FileName;
use VCS::LibCVS::Datum::LogMessage;
use VCS::LibCVS::Datum::PathName;
use VCS::LibCVS::Datum::RevisionNumber;
use VCS::LibCVS::Datum::Root;
use VCS::LibCVS::Datum::String;
use VCS::LibCVS::Datum::TagSpec;
use VCS::LibCVS::Datum::Time;

=head1 NAME

VCS::LibCVS::Datum - a piece of CVS data

=head1 SYNOPSIS

 $mode = VCS::LibCVS::Datum::Mode->new("u=rw,g=rw,o=r");
 $rq = VCS::LibCVS::Client::Request::Modified->new(["file",$mode,$file]);

=head1 DESCRIPTION

Datum represents a single piece of CVS data, such as an entries line, a file
mode or a tag spec.  It has subclasses for each type of CVS data.  Datum should
not to be instantiated, instead its subclasses should be instantiated.

To access the contained data see the accessors for each subclass.

=cut

# Datum provides some generic facilities to help the implementation of its
# simpler subclasses; those which consist of a predetermined number of lines
# which can be named.  To use these facilities a subclass of Datum overrides
# the _data_names() routine, which returns a list of names used as keys into
# the private hash.  All the routines defined in Datum use this facility.

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Datum.pm,v 1.14 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# Private variables
###############################################################################

# These are specified by _data_names().
# Each of them is a single line of text, without a terminating newline.

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$data = Datum::Subclass->new($data)

Only call this on subclasses of Datum.  Some subclasses override this
constructor.

=over 4

=item return type: Datum::Subclass

=item argument 1 type: . . .

=over 2

=item E<32>E<32>option 1: IO::Handle

An IO::Handle object from which the Datum will be read.  Most Datum are line
oriented, so they will read one or more lines from the IO::handle.

=item E<32>E<32>option 2: scalar

If the Datum consists of a single line, it can be passed as a scalar.

=item E<32>E<32>option 3: \@array ref

If the Datum consists of one or more lines, they can be passed as an array ref.

=item E<32>E<32>option 4: Datum::Subclass

If the argument is an object of the type which is being constructed, the
argument itself will be returned.  It will I<not> be copied.

This is used by the Client::Request constructor which blindly passes its
args to the Datum constructor.  That way the user has the freedom to
construct their own Datum and pass it to the Client::Request constructor.

=back

=back

Construct a new Datum.  The IO::Handle option is used for reading a Datum
from the server, the others when constructing it locally.

=cut

sub new {
  my ($class, $arg_data) = @_;

  # if the argument is already an object of the right type, just return it
  return $arg_data if (UNIVERSAL::isa($arg_data, $class));

  my $that = bless {}, $class;

  # if the argument is an iohandle, read in the right number of lines, and
  # overwrite $arg_data with that.
  if (UNIVERSAL::isa($arg_data, "IO::Handle")) {
    my @arg_data = map { $arg_data->getline(); } $that->_data_names();
    $arg_data = \@arg_data;
  }

  # a scalar is good if one line is needed, otherwise expect an array ref
  if (!ref($arg_data)) {
    confess "Datum needs multiple lines" if (@{[$that->_data_names]} != 1);
    $that->_add_line(($that->_data_names)[0], $arg_data);

  } elsif (ref($arg_data) eq "ARRAY") {
    confess "Wrong number of lines" if (@{[$that->_data_names]} != @$arg_data);
    foreach my $n ($that->_data_names) {$that->_add_line($n, shift @$arg_data)}

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

$datum_string = $datum->as_string()

=over 4

=item return type: string scalar

=back

Returns the Datum as a string.

=cut

sub as_string {
  my $self = shift;
  my $as_string = $self->as_protocol_string();
  chomp $as_string;
  return $as_string;
}

=head2 B<protocol_print()>

$datum->protocol_print($file_handle)

=over 4

=item return type: undef

=item argument 1 type: IO::Handle

=back

Prints the Datum to the IO::Handle.  The output will be formatted for
sending to the cvs server, including the placement of newlines.

=cut

sub protocol_print {
  my ($self, $ioh) = @_;
  $ioh->print($self->as_protocol_string());
}

=head2 B<as_protocol_string()>

$datum_string = $datum->as_protocol_string()

=over 4

=item return type: string scalar

=back

Returns the Datum as a string suitable for being sent to the server,
including the placement of newlines.

=cut

sub as_protocol_string {
  my $self = shift;
  my $p_string = "";
  foreach my $name ($self->_data_names) { $p_string .= $self->{$name} . "\n"; }
  return $p_string;
}

=head2 B<equals()>

if ($datum1->equals($datum2)) {

=over 4

=item return type: boolean

=item argument 1 type: VCS::LibCVS::Datum

=back

Returns true if the data contain the same information (and are of the same
type)

=cut

sub equals {
  my $self = shift;
  my $other = shift;
  return 0 if ref($self) ne ref($other);
  foreach my $key ($self->_data_names()) {
    return 0 if $self->{$key} ne $other->{$key};
  }
  return 1;
}

###############################################################################
# Private routines
###############################################################################

# Returns a list of strings, which are names of the keys in the $self hash
# which hold the lines of the Datum.  If the Datum is something other than a
# list of lines, the empty list will be returned.
sub _data_names {
  return ();
}

# Add a single named line to the internal hash, ensuring that it contains no
# newlines
sub _add_line {
  my ($self, $name, $line) = @_;
  chomp($line);
  confess "Embedded newline in Datum line: $name: $line" if $line =~ /\n/;
  return $self->{$name} = $line;
}

=head1 SEE ALSO

  VCS::LibCVS::Datum::DirectoryName
  VCS::LibCVS::Datum::Entry
  VCS::LibCVS::Datum::FileContents
  VCS::LibCVS::Datum::FileMode
  VCS::LibCVS::Datum::FileName
  VCS::LibCVS::Datum::PathName
  VCS::LibCVS::Datum::Root
  VCS::LibCVS::Datum::String
  VCS::LibCVS::Datum::TagSpec
  VCS::LibCVS::Datum::Time

=cut

1;
