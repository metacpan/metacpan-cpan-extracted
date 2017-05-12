#---------------------------------------------------------------------
package WebService::NFSN::Object;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  3 Apr 2007
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Base class for NFSN API objects
#---------------------------------------------------------------------

use 5.006;
use Carp;
use strict;
use warnings;
use HTTP::Request::Common qw(GET POST PUT);
use URI 1.00 ();
use WebService::NFSN 0.10 qw(_eval_or_die);

#=====================================================================
# Package Global Variables:

our $VERSION = '1.03'; # VERSION

#=====================================================================
sub get_converter # ($function)
{
  my $convert = ($_[0] =~ s/:JSON$//
                 ? 'WebService::NFSN::decode_json'
                 : '');

  return $convert;
} # end get_converter

#---------------------------------------------------------------------
# Generate the code for an API module:

sub _define
{
  my ($class, %p) = @_;

  #...................................................................
  # Create the object_type method for classifying objects:

  my $code = "package $class;\nsub object_type { '$p{type}' }\n";

  #...................................................................
  # Create an accessor method for each property:

  foreach my $propType (qw(rw ro wo)) {
    my $properties = $p{$propType};

    next unless $properties;

    foreach my $property (@$properties) {
      my $convert = get_converter($property);

      $code .= <<"END PROPERTY";
sub $property
{
  $convert shift->${propType}_property('$property' => \@_);
}
END PROPERTY
    } # end foreach $property
  } # end foreach $propType

  #...................................................................
  # Create an object method for each API method:

  if (my $methods = $p{methods}) {
    while (my ($method, $params) = each %$methods) {
      my $convert = get_converter($method);

      # Process method prototype:
      my (%accepted, @required);
      foreach (@$params) {
        push @required, $_ unless s/\?$//;
        $accepted{$_} = 1;
      } # end foreach parameter declaration

      # Store method prototype into package variable:
      { no strict 'refs'; ## no critic ProhibitNoStrict
        @{ sprintf '%s::_%s_prototype', $class, $method }
            = ($method, \%accepted, \@required) }

      # Define the method:
      $code .= <<"END METHOD";
our \@_${method}_prototype;
sub $method
{
  $convert shift->POST_request(\@_${method}_prototype, \@_);
}
END METHOD
    } # end while each method
  } # end if methods

  _eval_or_die $code;
} # end _define

#=====================================================================
sub new
{
  my ($class, $manager, $id) = @_;

  return bless { manager => $manager,
                 id      => $id,
               }, $class;
} # end new

#---------------------------------------------------------------------
sub GET_request
{
  my ($self, $property) = @_;

  return $self->make_request(GET $self->make_uri($property));
} # end GET_request

#---------------------------------------------------------------------
sub PUT_request
{
  my ($self, $property, $value) = @_;

  return $self->make_request(PUT $self->make_uri($property),
                             Content => $value);
} # end PUT_request

#---------------------------------------------------------------------
sub POST_request
{
  my ($self, $method, $accepted, $required, %param) = @_;

  foreach my $key (@$required) {
    croak(qq'Missing required "$key" parameter for $method')
        unless defined $param{$key};
  }

  foreach my $key (keys %param) {
    carp(qq'"$key" is not a parameter of $method') unless $accepted->{$key};
  }

  return $self->make_request(POST $self->make_uri($method), \%param);
} # end POST_request

#---------------------------------------------------------------------
sub make_request
{
  my $self = shift @_;

  my $res = $self->{manager}->make_request(@_);

  return $res->content;
} # end make_request

#---------------------------------------------------------------------
sub make_uri
{
  my ($self, $name) = @_;

  URI->new(join('/', $self->{manager}->root_url, $self->object_type,
                $self->{id}, $name));
} # end make_url

#---------------------------------------------------------------------
sub ro_property
{
  my ($self, $property) = @_;

  croak "$property is read-only" if @_ > 2;

  return $self->GET_request($property);
} # end ro_property

#---------------------------------------------------------------------
sub rw_property
{
  my ($self, $property, $value) = @_;

  if (@_ > 2) {
    return $self->PUT_request($property, $value);
  } else {
    return $self->GET_request($property);
  }
} # end rw_property

#---------------------------------------------------------------------
sub wo_property
{
  my ($self, $property, $value) = @_;

  croak "$property is write-only" if @_ < 3;

  return $self->PUT_request($property, $value);
} # end wo_property

#=====================================================================
# Package Return Value:

1;

__END__

