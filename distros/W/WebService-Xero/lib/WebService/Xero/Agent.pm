package WebService::Xero::Agent;


use 5.006;
use strict;
use warnings;
use Carp;

use LWP::UserAgent;
use HTTP::Request;
use Mozilla::CA;
use Config::Tiny;
use JSON;
use XML::Simple;
use Digest::MD5 qw( md5_base64 );
use URI::Encode qw(uri_encode uri_decode );
use Data::Random qw( rand_chars );
use Net::OAuth 0.20;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

use WebService::Xero::Organisation;


=head1 NAME

WebService::Xero::Agent - Base Class for API Connections

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS

This is the base class for the Xero API agents that integrate with the Xero Web Application APIs.

You should not need to use this directly but should use one of the derived classes.

see the following for usage examples:

  perldoc WebService::Xero::Agent::PrivateApplication
  perldoc WebService::Xero::Agent::PublicApplication



=head1 METHODS

=head2 new()

  default base constructor - includes properties used by child classes.

=cut

sub new 
{
  my ( $class, %params ) = @_;

    my $self = bless 
    {
      NAME           => $params{NAME} || 'Unnamed Application',
      CONSUMER_KEY   => $params{CONSUMER_KEY} || '',
      CONSUMER_SECRET => $params{CONSUMER_SECRET} || "",
      PRIVATE_KEY     => $params{PRIVATE_KEY} || '',
      keystring       => $params{keystring} || undef,
      internal_consumer_key    => $params{internal_consumer_key}    || "",
      internal_token           => $params{internal_token}           || "",
      internal_token_secret    => $params{internal_token_secret}    || "",  
      pko             => $params{pko} || undef,
      ua              => LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 },),
      _status           => undef,
    }, $class;
    return $self->_validate_agent(); ## derived classes to validate required properties
}


=head2 _validate_agent()

  To be implemented in derived classes to validate the configuration of the agent.

=cut

sub _validate_agent 
{
  my ( $self  ) = @_;
  return $self->_error('base class not meant for instantiation');
}



=head2 get_all_xero_products_from_xero()

  Experimental: a shortcut to do_xero_api_call

=cut
#####################################
sub get_all_xero_products_from_xero
{
  my ( $self ) = @_;
  #my $data = $self->_do_xero_get( q{https://api.xero.com/api.xro/2.0/Items} );
  my $data = $self->do_xero_api_call( q{https://api.xero.com/api.xro/2.0/Items} ) || return $self->_error('get_all_xero_products_from_xero() failed');
  return $data;
}
#####################################


=head2 get_all_customer_invoices_from_xero()

    Experimental: a shortcut to do_xero_api_call

=cut 

#####################################
sub get_all_customer_invoices_from_xero
{
  my ( $self, $xero_cref ) = @_;  
  my $ret = [];
  my $ext = uri_encode(qq{Contact.ContactID = Guid("$xero_cref")});
  my $page = 1; my $page_count=100;
  while ( $page_count >= 100 and my $data = $self->do_xero_api_call( qq{https://api.xero.com/api.xro/2.0/Invoices?where=$ext&page=$page} ) ) ## continue querying until we have a non-full page ( ie $page_count < 100 )
  {
    foreach my $inv ( @{ $data->{Invoices}{Invoice}} )
    {
      push @$ret, $inv;
      $page_count--;
    }
    if ($page_count  == 0)
    {
      $page_count=100; $page++;
    }
  }
  $self->{status} = 'OK get_all_customer_invoices_from_xero()';
  return $ret;
}
#####################################



=head2 do_xero_api_call()

  INPUT PARAMETERS AS A LIST ( NOT NAMED )

* $uri (required)    - the API endpoint URI ( eg 'https://api.xero.com/api.xro/2.0/Contacts/')
* $method (optional) - 'POST' or 'GET' .. PUT not currently supported
* $xml (optional)    - the payload for POST updates as XML

  RETURNS

    The response is requested in JSON format which is then processed into a Perl structure that
    is returned to the caller.


=cut 

sub do_xero_api_call
{
  my ( $self, $uri, $method, $xml ) = @_;
  $method = 'GET' unless $method;

  my $data = undef;
  my $encryption = 'RSA-SHA1';
  $encryption = 'HMAC-SHA1' if (defined $self->{TOKEN} and $self->{TOKEN} ne $self->{CONSUMER_KEY} ); 
  $self->{TOKEN}        = $self->{CONSUMER_KEY}    unless  $self->{TOKEN};
  $self->{TOKEN_SECRET} = $self->{CONSUMER_SECRET} unless  $self->{TOKEN_SECRET};

  my %opts = (
    consumer_key     => $self->{CONSUMER_KEY},
    consumer_secret  => $self->{CONSUMER_SECRET},
    token            => $self->{TOKEN},
    token_secret     => $self->{TOKEN_SECRET},
    request_url      => $uri,
    request_method   => $method,
    signature_method => $encryption,
    timestamp        => time,
    nonce => 'ccp' . md5_base64( join('', rand_chars(size => 8, set => 'alphanumeric')) . time ), 
  );
  $opts{verifier} = $self->{verifier} if defined $self->{verifier};
  $opts{extra_params} = { xml => $xml}  if ( $method eq 'POST' and defined $xml );


  my $access = Net::OAuth->request("protected resource")->new( %opts );
  
  if ( $self->{TOKEN} eq $self->{CONSUMER_KEY} ) 
  {
    $access->sign( $self->{pko} );
  }
  else
  {
    $access->sign(); ## HMAC-SHA1 is self signed
  }
  my $req = HTTP::Request->new( $method,  $uri );
  
  if ( $method eq 'POST' )
  {
    $req->header(  'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8');
    $req->header( 'Accept' => 'application/json');
    $req->content( $access->to_post_body ) if defined $xml;
  }
  elsif ( $method eq 'GET' )
  {
    $req->header(Authorization => $access->to_authorization_header);
    $req->header( 'Accept' => 'application/json');
  } 
  else 
  {
    return $self->_error('ONLY POST AND GET CURRENT SUPPORTED BY WebService::Xero Library');
  }
  my $res = $self->{ua}->request($req);
  if ($res->is_success)
  {
    $self->{status} = 'GOT RESPONSE FROM XERO API CALL';
    $data = from_json($res->content) || return $self->api_error( $res->content );  
  } 
  else 
  {
    return $self->api_error($res->content);
  }
  return $data;
}


=head2 api_error

    Experimental: place to catch known API errors - TODO

=cut 
sub api_error
{
  my ( $self, $msg ) = @_;
  #return $self->_error("SERVER ERROR: CONSUMER_KEY was not recognised - check your credentials") if ( $msg eq 'oauth_problem=consumer_key_unknown&oauth_problem_advice=Consumer%20key%20was%20not%20recognised');
  return $self->_error("UNRECOGNISED API ERROR '$msg'");
}



=head2 api_account_organisation()
  
  Experimental: a shortcut to dp_xero_api_call that returns 
  a WebService::Xero::Organisation object describing the organisation that provides the API.

=cut 

sub api_account_organisation
{
  my ( $self ) = @_;
  return WebService::Xero::Organisation->new_from_api_data( $self->do_xero_api_call( 'https://api.xero.com/api.xro/2.0/organisation' ) ) || $self->_error('FAILED TO CREATE ORGANISATION OBJECT FROM AGENT');
}


sub _error 
{
  my ( $self, $msg ) = @_;
  carp( $self->{_status} = $msg);
  return $self->{_ERROR_VAL}; ##undef
}


=head2 as_text

  just a quick debugging method.

=cut 

sub as_text
{
  my ( $self ) = @_;
  return qq{    NAME              => $self->{NAME}\nCONSUMER_KEY      => $self->{CONSUMER_KEY}\nCONSUMER_SECRET   => $self->{CONSUMER_SECRET} \n};
}

=head2 get_status

  return a text description of the last communication with the Xero API

=cut 

sub get_status
{
  my ( $self ) = @_;
  return $self->{_status} || 'STATUS NOT SET';
}





=head1 AUTHOR

Peter Scott, C<< <peter at computerpros.com.au> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ccp-xero at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CCP-Xero>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Xero


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CCP-Xero>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CCP-Xero>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CCP-Xero>

=item * Search CPAN

L<http://search.cpan.org/dist/CCP-Xero/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Peter Scott.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::Xero
