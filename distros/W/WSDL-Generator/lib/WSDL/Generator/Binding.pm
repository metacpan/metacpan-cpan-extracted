=pod

=head1 NAME

WSDL::Generator::Binding - Generate wsdl messages and portType for WSDL::Generator

=head1 SYNOPSIS

  use WSDL::Generator::Binding;
  my $param = {	'services'     => 'AcmeTravelCompany',
				'service_name' => 'Book_a_Flight' };
  my $bind = WSDL::Generator::Binding->new($param);
  $bind->add_request('GetPrice');
  $bind->add_response('GetPrice');
  print $bind->get_message->to_string;
  print $bind->get_porttype->to_string;
  print $bind->get_binding->to_string;

=cut
package WSDL::Generator::Binding;

use strict;
use warnings::register;
use Carp;
use base	qw(WSDL::Generator::Base);

our $VERSION = '0.01';

=pod

=head1 CONSTRUCTOR

=head2 new($param)

  $param = {	'services'     => 'AcmeTravelCompany',
				'service_name' => 'Book_a_Flight' };
$param is optional.
Returns WSDL::Generator::Binding object

=cut
sub new {
	my ($class, $param) = @_;
	my $self = { 'services'     => $param->{services},
				 'service_name' => $param->{service_name},
	             'methods'      => {} };
	return bless $self => $class;
}

=pod

=head1 METHODS

=head2 add_request($method)

Adds a method with its request for binding

=cut
sub add_request : method {
	my ($self, $method) = @_;
	$self->{methods}->{$method}->{request} = $method.'Request';
}

=pod

=head2 add_reponse($method)

Adds a method with its response for binding

=cut
sub add_response : method {
	my ($self, $method) = @_;
	$self->{methods}->{$method}->{response} = $method.'Response';
}

=pod

=head2 generate($param)

  $param = {	'services'     => 'AcmeTravelCompany',
				'service_name' => 'Book_a_Flight' };
$param is optional.
Prepare a wsdl structure ready to be fetched

=cut
sub generate : method {
	my ($self, $param) = @_;
	my @message  = ();
	my @porttype = ();
	my @binding  = ();
	$self->{service_name}  = $param->{service_name}  if (exists $param->{service_name});
	$self->{services} = $param->{services} if (exists $param->{services});
	$self->{service_name}  or return carp 'No service defined';
	$self->{services} or return carp 'No services name defined';
	foreach my $method (sort keys %{$self->{methods}} ) {
		push @message, @{$self->get_wsdl_element( { wsdl_type => 'MESSAGE',
		                                            methodRe  => $method.'Request',
			                                        type      => $self->{methods}->{$method}->{request},
		                                        } ) if ($self->{methods}->{$method}->{request})};
		push @message, @{$self->get_wsdl_element( { wsdl_type => 'MESSAGE',
		                                            methodRe  => $method.'Response',
		                                            type      => $self->{methods}->{$method}->{response},
		                                        } ) if ($self->{methods}->{$method}->{response})};
		push @porttype, @{$self->get_wsdl_element( { wsdl_type => 'PORTTYPE_OPERATION',
		                                             method    => $method,
		                                             request   => $method.'Request',
		                                             response  => $method.'Response',
		                                        } )};
		push @binding, @{$self->get_wsdl_element( { wsdl_type        => 'BINDING_OPERATION',
		                                            method          => $method,
		                                            definition_name => $self->{service_name},
		                                        } )};
	}
	$self->{message}  = bless \@message => ref($self);
	$self->{binding}  = $self->get_wsdl_element( { wsdl_type         => 'BINDING',
						                           binding_operation => \@binding,
													%$self,
			                                        } );
	$self->{porttype} = $self->get_wsdl_element( { wsdl_type          => 'PORTTYPE',
						                           porttype_operation => \@porttype,
													%$self,
			                                        } );
	return $self;
}


=pod

=head2 get_message()

Returns WSDL message object

=cut
sub get_message : method {
	my $self = shift;
	exists $self->{message} or $self->generate;
	return $self->{message};
}


=pod

=head2 get_porttype()

Returns WSDL porttype object

=cut
sub get_porttype : method {
	my $self = shift;
	exists $self->{porttype} or $self->generate;
	return $self->{porttype};
}


=pod

=head2 get_binding()

Returns WSDL binding object

=cut
sub get_binding : method {
	my $self = shift;
	exists $self->{binding} or $self->generate;
	return $self->{binding};
}

1;

=pod

=head1 SEE ALSO

  WSDL::Generator

=head1 AUTHOR

"Pierre Denis" <pdenis@fotango.com>

=head1 COPYRIGHT

Copyright (C) 2001, Fotango Ltd - All rights reserved.
This is free software. This software may be modified and/or distributed under the same terms as Perl itself.

=cut
