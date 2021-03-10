package Webservice::Shipment;

use Mojo::Base -base;

our $VERSION = '0.06';
$VERSION = eval $VERSION;

use Scalar::Util 'blessed';

has carriers => sub { [] };
has defaults => sub { {} };

use Carp;

sub AUTOLOAD {
  my $self = shift;
  my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  return $self->delegate($method, @_);
}

sub add_carrier {
  my ($self, $carrier, $conf) = @_;
  $conf ||= {};
  $conf = { %{$self->defaults}, %$conf };

  if (blessed $carrier and $carrier->isa('Webservice::Shipment::Carrier')) {
    push @{$self->carriers}, $carrier;
    return $self;
  }

  for my $class ("Webservice::Shipment::Carrier::$carrier", $carrier) {
    next unless eval "require $class; 1";
    next unless $class->isa('Webservice::Shipment::Carrier');
    next unless my $inst = $class->new($conf);
    push @{$self->carriers}, $inst;
    return $self;
  }

  croak "Unable to add carrier $carrier";
}

sub delegate {
  my ($self, $method) = (shift, shift);
  my $id = $_[0];

  croak "No added carrier can handle $id"
    unless my $carrier = $self->detect($id);

  return $carrier->$method(@_);
}

sub detect {
  my ($self, $id) = @_;
  my $carriers = $self->carriers;
  for my $carrier (@$carriers) {
    return $carrier if $carrier->validate($id);
  }

  return undef;
}

1;

=head1 NAME

Webservice::Shipment - Get common shipping information from supported carriers

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Webservice::Shipment;

  my $ship = Webservice::Shipment->new(defaults => {date_format => '%m/%d/%y'});
  $ship->add_carrier(UPS => {
    api_key  => 'MYAPIKEY_12345',
    username => 'some_user',
    password => 'passw0rd',
  });
  $ship->add_carrier(USPS => {
    username => 'my_username',
    password => 'p@ssword',
  });

  use Data::Dumper;

  print Dumper $ship->track('9400105901096094290500'); # usps
  print Dumper $ship->track('1Z584056NW00605000'); # ups

  # non-blocking with callback
  $ship->track('1Z584056NW00605000', sub {
    my ($carrier, $err, $info) = @_;
    warn $err if $err;
    print Dumper $info
  });

  __END__
  # sample output

  {
    'status' => {
      'description' => 'DELIVERED',
      'date' => '12/24/14',
      'delivered' => 1,
    },
    'destination' => {
      'address1' => '',
      'address2' => '',
      'city' => 'BEVERLY HILLS',
      'state' => 'CA',
      'country' => '',
      'postal_code' => '90210',
    },
    'weight' => '0.70 LBS',
    'service' => 'UPS NEXT DAY AIR',
    'human_url' => 'http://wwwapps.ups.com/WebTracking/track?trackNums=1Z584056NW00605000&track.x=Track',
  }

=head1 DESCRIPTION

L<Webservice::Shipment> is a central module for obtaining shipping information from supported carriers.
It is very lightweight, built on the L<Mojolicious> toolkit.
The fact that it is built on L<Mojolicious> does not restrict its utility in non-Mojolicious apps.

L<Webservice::Shipment::Carrier> subclasses request information from that carrier's api and extract information from it.
The information is then returned in a standardized format for ease of use.
Futher, L<Webservice::Shipment> itself tries to deduce which carrier to use based on the id number.
This makes it very easy to use, but also implies that it will only ever report common information.
More detailed API interfaces already exist and are mentioned L<below|/"SEE ALSO">.

Note that this is a very early release and will likely have bugs that need to be worked out.
It should be used for informative puposes only.
Please do not rely on this for mission critical code until this message is removed.

=head1 ATTTRIBUTES

L<Webservice::Shipment> inherits all of the attributes from L<Mojo::Base> and implements the following new ones.

=head2 carriers

An array refence of added L<Webservice::Shipment::Carrier> objects.
You probably want to use L</add_carrier> instead.

=head2 defaults

A hash reference of default values to be merged with per-carrier constructor arguments when using L</add_carrier>.
This defaults can be overridden by passing in an explicity parameter of the same name to L</add_carrier>.
This is especially useful for C<date_format> parameters and possibly for C<username> and/or C<password> if those are consistent between carriers.

=head1 METHODS

L<Webservice::Shipment> inherits all of the methods from L<Mojo::Base> and implements the following new ones.

=head2 add_carrier

  $ship = $ship->add_carrier(UPS => { username => '...', password => '...', api_key => '...', ... });
  $ship = $ship->add_carrier($carrier_object);

Adds an instance of L<Webservice::Shipment::Carrier> to L</carriers>.
If passed an object, the object is verified to be a subclass of that module and added.
Otherwise, the first argument is assumed to be a class name, first attempted relative to C<Webservice::Shipment::Carrier> then as absolute.
If the class can be loaded, its parentage is checked as before and then an instace is created, using an optional hash as constructor arguments.
If provided, those arguments should conform to the documented constructor arguments for that class.

If these conditions fail, and no carrier is added, the method throws an exception.

=head2 delegate

  $ship->delegate('method_name', $id, @addl_args);

Attempts to call C<method_name> on an carrier instance in L</carriers> which corresponds to the given C<$id>.
This is done via the L</detect> method.
In the above example if the detected instance was C<$carrier> it would then be called as:

  $carrier->method_name($id, @addl_args);

Clearly this only is only useful for carrier methods that take an id as a leading argument.
If no carrier is detected, an exception is thrown.

This method is used to implement C<AUTOLOAD> for this class.
This allows the very simple usage:

  $ship->add_carrier($c1)->add_carrier($c2);
  $info = $ship->track($id);

=head2 detect

  $carrier = $ship->detect($id);

Returns the first carrier in L</carriers> that validates the given id as something that it can handle, via L<Webservice::Shipment::Carrier/validate>.
Returns undef if no carrier matches.

=head1 SEE ALSO

=over

=item L<Shipment>

=item L<Parcel::Track>

=item L<Net::Async::Webservice::UPS>

=item L<Business::Shipping>

=back

=head1 SPECIAL THANKS

Pharmetika Software, L<http://pharmetika.com>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

Ryan Perry

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by L</AUTHOR> and L</CONTRIBUTORS>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

