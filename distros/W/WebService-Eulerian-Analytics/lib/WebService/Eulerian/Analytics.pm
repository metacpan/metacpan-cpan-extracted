package WebService::Eulerian::Analytics;

# $Id: Analytics.pm,v 1.4 2008-09-21 23:30:08 cvscore Exp $

our $VERSION	= 0.8;

use strict;
use SOAP::Lite;

=pod

=head1	NAME 

WebService::Eulerian::Analytics - Eulerian Analytics API

=head1 DESCRIPTION

This module handles the calls and responses sent to the different services
provided by the WebService::Eulerian::Analytics modules. It's the parent class
for all other modules and should not be used directly.

=head1 METHODS

=head2 new : constructor called by other modules

=head3 input

=over 4

=item * hash reference with the following options

o apikey : API key allowing you to request the API, mandatory (provided by Eulerian Technologies), must be sent with each requests in the SOAP Enveloppe.

o host : the host on which you have to send your API requests, mandatory (provided by Eulerian Analytics)

o timeout : in seconds the timeout after which a request is aborted, defaults to 60.

o debug : set to 1 if you want to check the raw SOAP requets, defaults to 0.

o version : indicate the version of the API you are requesting, defaults to the newest version.

=back

=head3 output

=over 4

=item * a Perl object corresponding to the service you instantiated

=back

=cut

sub new {
 my $proto      = shift;
 my $class      = ref($proto) || $proto;
 my %h_p        = @_;
 if ( $h_p{debug} ) {
  SOAP::Lite->import(+trace => 'debug');
 }
 return         bless({
   _APIKEY	=> $h_p{apikey},
   _HOST	=> $h_p{host} 		|| 'api.ea.eulerian.com',
   _VERSION	=> $h_p{version} 	|| 'v1',
   _SERVICE	=> $h_p{service},
   _DEBUG	=> $h_p{debug}		|| 0,
   _TIMEOUT	=> $h_p{timeout}	|| 60 * 15, # 15 minutes
   _FAULT	=> 0,
   _FAULTDETAILS=> {},
   }, $class);
}

sub _endpoint {
 my ($self, $host, $version) = @_;
 return 'http://'.join('/', $host, 'ea', $version);
}

sub _faultclear {
 my $self	= shift;
 $self->{_FAULT}	= 0;
 $self->{_FAULTDETAILS}	= {};
 return		1;
}

sub _faultadd {
 my ($self, $r_h) = @_;
 $self->{_FAULT}	= 1;
 $self->{_FAULTDETAILS}	= $r_h;
 return		1;
}

=pod

=head2 fault : indicates if the last call generated a fault on the server

=head3 input

=over 4

=item * none

=back

=head3 output

=over 4

=item * 1 if a fault was generated, 0 otherwise

=back

=cut

sub fault 		{ return shift()->{_FAULT}; 			}

=pod

=head2 faultdetails : returns a hash reference containing the details on the last generated fault

=head3 input

=over 4

=item * none

=back

=head3 output

=over 4

=item * hash reference

o code : fault code

o string : fault string

=back

=cut

sub faultdetails	{ return shift()->{_FAULTDETAILS};		}

=pod

=head2 faultcode : returns the faultcode of the last generated fault

=head3 input

=over 4

=item * none

=back

=head3 output

=over 4

=item * code describing the fault

=back

=cut

sub faultcode 		{ return shift()->_faultdetails_k('code'); 	}

=pod

=head2 faultstring : returns the faultstring of the last generated fault

=head3 input

=over 4

=item * none

=back

=head3 output

=over 4

=item * text describing the fault

=back

=cut

sub faultstring		{ return shift()->_faultdetails_k('string');	}

sub _faultdetails_k {
 my ($self, $k) = @_; 
 return	$self->{_FAULTDETAILS}->{ $k };
}

=pod

=head2 call : generic SOAP call method (private)

This method should not be called directly, use the main classes.

=head3 input

=over 4

=item * name of the method to be called

=item * array of parameters sent to the method call

=back

=head3 output

=over 4

=item * if no error : returns the value of the Response part of the SOAP call

=item * if error : returns undef and set the fault flag to 1 and faultdetails with fault information

=back

=head3 sample

	my $rh_return = $service->call('MyMethodName', 'param1', { hash => 'param2' }, [ 'param3' ]);
	#
	# test if the server generated a fault
	if ( $service->fault ) {
	 # die on fault and display the faultstring
	 die $service->faultstring();
	}
	#
	# no fault : process the returned structure
	use Data::Dumper;
	print Dumper($rh_return);

=cut

sub call {
 my ($self, $method, @a_p) = @_;

 # reset fault methods
 $self->_faultclear();

 # build soap header with auth
 my @a_header   = (
  SOAP::Header->name("apikey")->value($self->{_APIKEY} )->type('')
 );

 # send SOAP request to API host
 my $soap       = SOAP::Lite->proxy(
   $self->_endpoint($self->{_HOST}, $self->{_VERSION}).'/'.$self->{_SERVICE},
   timeout       => $self->{_TIMEOUT}
   );
 my $result	= $soap->call(
   SOAP::Data->name($method)->uri($self->{_SERVICE}) => @a_header, @a_p);

 # check for a fault and return hash detailling fault if any
 if ( $result->fault ) {
  $self->_faultadd({
   code		=> $result->faultcode 	|| 0, 
   string	=> $result->faultstring	|| '', 
  });
  return	undef;
 }
 # no fault : return the generated structure
 return		$result->valueof('//'.$method.'Response/'.$method.'Return');
}

=pod

=head1 SEE ALSO

L<SOAP::Lite>

=head1 AUTHOR

Mathieu Jondet <mathieu@eulerian.com>

=head1 COPYRIGHT

Copyright (c) 2008 Eulerian Technologies Ltd L<http://www.eulerian.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

1;
__END__
