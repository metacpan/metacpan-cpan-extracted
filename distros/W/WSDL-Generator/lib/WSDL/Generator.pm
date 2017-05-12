=pod

=head1 NAME

WSDL::Generator - Generate wsdl file automagically

=head1 SYNOPSIS

  use WSDL::Generator;
  my $wsdl = WSDL::Generator->new($init);
  Foo->a_method($param);
  print $wsdl->get('Foo');

=head1 DESCRIPTION

You know folks out there who use another language than Perl (huh?) and you want to release a SOAP server for them

  1/ that's very kind of you
  2/ you need to generate a wsdl file
  3/ this module can help
Because Perl is dynamically typed, it is a fantastic language to write SOAP clients,
but that makes perl not-so-easy to use as SOAP server queried by statically typed languages
such as Delphi, Java, C++, VB...
These languages need a WSDL file to communicate with your server.
The WSDL file contains all the data structure definition necessary to interact with the server.
It contains also the namespace and URL as well.

=cut
package WSDL::Generator;

use strict;
use warnings::register;
use Carp;
use Class::Hook;
use WSDL::Generator::Schema;
use WSDL::Generator::Binding;
use base    qw(WSDL::Generator::Base);
use 5.6.0;

our $VERSION = '0.04';

=pod

=head1 CONSTRUCTOR

=head2 new($init)

  $init = {   'schema_namesp' => 'http://www.acmetravel.com/AcmeTravelServices.xsd',
              'services'      => 'AcmeTravel',
              'service_name'  => 'BookFlight',
              'target_namesp' => 'http://www.acmetravel.com/SOAP/',
              'documentation' => 'Service to book tickets online',
              'location'      => 'http://www.acmetravel.com/SOAP/BookFlight' };
Install a spy which captures all the methods and subs calls to other classes

=cut
sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = { calls   => {},
                 %$param };
    bless $self => $class;
    Class::Hook->before(\&_before, $self);
    Class::Hook->after(\&_after, $self);
    Class::Hook->activate();
    return $self;
}

=pod

=head1 METHODS

=head2 get($class)

Returns the WSDL code for a specific class

=cut
sub get : method {
    my $self  = shift;
    my $class = shift;
    unless (exists $self->{calls}{$class} and $self->{calls}{$class}) {
        carp "Class $class not called";
        return undef;
    }
    my $schema  = WSDL::Generator::Schema->new( $self->{schema_namesp} );
    my $binding = WSDL::Generator::Binding->new( { service_name => $self->{service_name},
                                                   services     => $self->{services} } );
    foreach my $method ( keys %{$self->{calls}{$class}} ) {
        my $before = $self->{calls}{$class}->{$method}->{before};
        my $after  = $self->{calls}{$class}->{$method}->{after};
        $schema->add($before, $method.'Request');
        $schema->add($after, $method.'Response');
        $binding->add_request($method);
        $binding->add_response($method);
    }
    $self->{schema}      = $schema->get;
    $self->{message}     = $binding->get_message;
    $self->{porttype}    = $binding->get_porttype;
    $self->{binding}     = $binding->get_binding;
    $self->{service}     = $self->get_wsdl_element( { wsdl_type => 'SERVICE',
                                            %$self,
                                             } );
    $self->{definitions} = $self->get_wsdl_element( { wsdl_type => 'DEFINITIONS',
                                            %$self,
                                             } );
    my $wsdl = $self->get_wsdl_element( { wsdl_type => 'WSDL',
                                            %$self,
                                            } );
    Class::Hook->deactivate();
    return $wsdl->to_string;
}


=pod

=head2 get_all()

Returns all classes available for a WSDL generation

=cut
sub get_all : method {
    my $self = shift;
    return sort keys %{$self->{calls}};
}


=pod

=head2 schema_namesp($value)

Get or Set schema name space value

=cut
sub schema_namesp {
    my $self = shift;
    my $value = shift or return $self->{schema_namesp};
    $self->{schema_namesp} = $value;
}

=pod

=head2 service($value)

Get or Set service name value

=cut
sub service {
    my $self = shift;
    my $value = shift or return $self->{service};
    $self->{service} = $value;
}

=pod

=head2 services($value)

Get or Set services name value

=cut
sub services {
    my $self = shift;
    my $value = shift or return $self->{services};
    $self->{services} = $value;
}


sub _before {
    my ($self, $param) = @_;
    my $class  = $param->{class};
    my $method = $param->{method};
    $self->{calls}{$class}{$method}{before} = $param->{param}->[0];
}

sub _after {
    my ($self, $param) = @_;
    my $class  = $param->{class};
    my $method = $param->{method};
    $self->{calls}{$class}{$method}{after} = $param->{'return'};
}



1;

=pod

=head1 CAVEATS

WSDL doesn't works only on perl 5.6 and not 5.8. UNIVERSAL::AUTOLOAD is broken in perl 5.8 and it is used by Class::Hook upon wich WSDL::Generator depends.

WSDL is very flexible since it can describe any kind of data structure in a language non dependant description.
But that flexibility makes certain things difficult, such as array of inconsistant data types.
So, here is the current limitation of WSDL::Generator :

Rule - "An array must contain elements of the same perl type".
Understand perl type as "scalar", "arrayref" or "hashref".
So, if you send this:

  [
      {
        key1 => 'Hello',
        key2 => 'world',
      },
      {
        key1 => 'Hi',
        key3 => 'there',
      },
      {
        key1 => 'Hi',
      },
  ]
That will do, but if you send:

  [
      {
        key1 => 'Hello',
        key2 => 'world',
      },
      {
        key1 => 'Hi',
        key3 => 'there',
      },
      'a string instead of a hash ref',
  ]
That won't work, since your structure is not "consistent", your array cannot contain both hashref and string.

Another situation, if you send this:

  [
      {
        key1 => 'Hello',
        key2 => 'world',
      },
      {
        key1 => 'Hi',
        key3 => 'there',
      },
      {
        key1 => 'Hi',
      },
  ]
That will do, but if you send:

  [
      {
        key1 => 'Hello',
        key2 => 'world',
      },
      {
        key1 => [1,2,3],
        key3 => 'there',
      },
  ]
That won't work either, since your key1 can have two complete different types of value (a string or an arrayref)
Finally, if you call several times a method, only the last call will be scanned to produce the WSDL file.
I hope these limitations will be lifted in the future.

=head1 BUGS

  This is till n alpha release, so don't expect miracles and don't use it without caution - you've been warned!
  Feel free to send me your bug reports, contribution and comments about this project.

=head1 SEE ALSO

  SOAP::Lite, Class::Hook
  http://www.w3.org/TR/SOAP/
  http://www.w3.org/TR/wsdl

=head1 ACKNOWLEDGEMENT

A lot of thanks to:

  Paul Kulchenko for his fantastic SOAP::Lite module and his help
  Patrick Morris, a Delphi wizard, for testing the wsdl generated and investing weird things
  Joe Breeden for his excellent documentation
  Yuval Mazor for his patch to make it compatible with .net wsdl compiler
  Leon Brocard for his code review
  James Duncan for his support

=head1 AUTHOR

Pierre Denis, C<< <pierre@itrelease.net> >>.

=head1 COPYRIGHT

Copyright 2009, Pierre Denis, All Rights Reserved.

You may use, modify, and distribute this package under the
same terms as Perl itself.

=cut
