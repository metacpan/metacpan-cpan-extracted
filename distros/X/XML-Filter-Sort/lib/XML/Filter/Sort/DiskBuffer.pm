# $Id: DiskBuffer.pm,v 1.1.1.1 2002/06/14 20:40:05 grantm Exp $

package XML::Filter::Sort::DiskBuffer;

use strict;

require XML::Filter::Sort::Buffer;

use Storable;

##############################################################################
#                     G L O B A L   V A R I A B L E S
##############################################################################

use vars qw($VERSION @ISA);

$VERSION = '0.91';
@ISA     = qw(XML::Filter::Sort::Buffer);


##############################################################################
#                             M E T H O D S
##############################################################################

##############################################################################
# Method: freeze()
#
# Serialises a buffer and either writes it to a supplied file descriptor or
# returns it as a scalar. 
#
# If a list of sort key values is supplied (presumably a filtered version), it
# will replace any values currently stored in the object.
#

sub freeze {
  my $self = shift;
  my $fd   = shift;

  $self->{key_values} = [ @_ ] if(@_);

  my $data = Storable::freeze( [ $self->{key_values}, $self->{tree} ] );

  if($fd) {
    $fd->print(pack('L', length($data)));
    $fd->print($data);
    return;
  }

  return($data);
}


##############################################################################
# Constructor: thaw()
#
# Alternative constructor for reconstructing buffer objects serialised using
# Storable.pm.  Argument can be a scalar containing the raw serialised data, or
# a filehandle from which the next object will be read.
# Returns false on EOF.
# If called in a list context, returns the thawed object followed by an integer
# approximating the object's in-memory byte count.
#

sub thaw {
  my $class = shift;
  my $data  = shift;

  if(ref($data)) {        # Read the data from the file if required
    my $fd = $data;
    $fd->read($data, 4) || return;
    my($size) = unpack('L', $data);
    $fd->read($data, $size) || return;
  }

  my $ref = Storable::thaw($data);

  my $self = bless( { tree => $ref->[1], key_values => $ref->[0], }, $class);

  if(wantarray) {
    my $size = length($data) * 2;  # Approximation of in-memory size
    return($self, $size);
  }
  else {
    return($self);
  }
}


##############################################################################
# Method: close()
#
# Returns keys if this is a thawed buffer or calls base class method to get
# keys if buffer has never been frozen.
#

sub close {
  my $self = shift;

  unless($self->{key_values}) {
    $self->{key_values} = [ $self->SUPER::close() ];
  }
  return(@{$self->{key_values}});

}


##############################################################################
# Method: key_values()
#
# Returns the stored values for each of the sort keys.  In a scalar context, 
# returns a reference to an array of key values.
#

sub key_values {
  my $self = shift;

  return(@{$self->{key_values}}) if(wantarray);
  return($self->{key_values});
}


1;

__END__

=head1 NAME

XML::Filter::Sort::DiskBuffer - Implementation class used by XML::Filter::Sort


=head1 DESCRIPTION

The documentation is targetted at developers wishing to extend or replace
this class.  For user documentation, see L<XML::Filter::Sort>.

For an overview of the classes and methods used for buffering, see
L<XML::Filter::Sort::BufferMgr>.

=head1 METHODS

This class inherits from B<XML::Filter::Sort::Buffer> and adds the following
methods:

...


=head1 COPYRIGHT 

Copyright 2002 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

