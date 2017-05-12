package WebSource::Soap;

use strict;
use SOAP::Lite;
use WebSource::Module;
use Carp;

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Soap;
Module allowing to handle input data with a WebService  

=head1 DESCRIPTION

A Soap operator makes a SOAP call to a WebService for each input.

The description of a Soap operator is as follows :

  <ws:soap name="opname" forward-to="ops">
    <parameters>
      <param name="service" value="http://somehost/someservices.wsdl" />
      <param name="method"  value="serviceMethodName" />
      <param name="parameters"
                            value="parameter names ordered for method call" />
      <param name="p1" value="v1" />
    </parameters>
  </ws:soap>                                                                                                 

=head1 SYNOPSIS

  $service = WebSource::Soap->new(wsnode => $node);

=head1 METHODS

  See WebSource::Module

=over 2

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;
  $self->{service} or craak("No service defined");
  $self->{serv} = SOAP::Lite->service($self->{service});
  $self->{serv}->outputxml(1);
  $self->{method} or croak("No method to call");
  if($self->{parameters}) {
    $self->{params} = [ split / /, $self->{parameters} ];
  } else {
    $self->{params} = [ "data" ];
  }
  $self->log(5,"End setup params : ",$self->{params});
}

=item B<< $service->handle($env); >>

=cut

sub handle {
  my $self = shift;
  my $env = shift;

  my %data = ( %$self, %$env );
  $self->log(6,"parameter selection is '",join(",",@{$self->{params}}),"'");
  my @params = map { $data{$_} } @{$self->{params}};
  $self->log(6,"Available keys ",join(",",keys(%data)));
  my $method = $self->{method};
  $self->log(3,"Calling $method with params : ",join(",",@params));
  my $result = $self->{serv}->$method(@params);
  my %meta = %$env;
  return WebSource::Envelope->new(%meta,
    type => 'text/xml',
    data => $result
   );
}

=back

=head1 SEE ALSO

WebSource::Module

=cut

1;
