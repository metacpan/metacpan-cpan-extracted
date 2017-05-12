package WebService::Xero::Agent::PrivateApplication;


use 5.006;
use strict;
use warnings;
use Carp;
use base ('WebService::Xero::Agent');
use Crypt::OpenSSL::RSA;

=head1 NAME

WebService::Xero::Agent::PrivateApplication - Connects to a Xero Private Application API 

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS



Xero API Applications have a limit of 1,000/day and 60/minute request per organisation.


    use WebService::Xero::Agent::PrivateApplication;

    my $xero = WebService::Xero::Agent::PrivateApplication->new( CONSUMER_KEY    => 'YOUR_OAUTH_CONSUMER_KEY', 
                                                          CONSUMER_SECRET => 'YOUR_OAUTH_CONSUMER_SECRET', 
                                                          #KEYFILE         => "/path/to/privatekey.pem" 
                                                          PRIVATE_KEY      => '-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQCu2PMZrIHPiFmZujY0s7dz8atk1TofVSTVqhWg5h/fn8tYbwgg
koTqpAigxAUCAZ63prtj9LQhIqe3TRNtCDMsxxriyN3O/cxkVD52LwCKAgEoaNmr
Vvt97UgxglKyQ6taNO/c6V8FCKvPC945GKd/b7BoIYZcJsrpo+E+8Ek9IQIDAQAB
AoGAbbPC+0XIAI0dIp256uEjZkSn89Dw8b27Ka/YeCZKs0UQEYFAiSdE6+9VVoEG
X1bi3XloM3PSHMQglJpwaMVvTUwZfdxCFIM0mpgXtdK8Xuh3QTZpgH9S0a2HoXrB
uXFEqvwMcT43ig2FCfVQU86RQZAxrb1YfyFSauEayrVtbT0CQQDe8HEXSkbxjUwj
I2TdCDA7yOW7rWQPAk3REZ33SqBUdo45qofpkH7vWSx+W6q65uyRYfF4N1JKmW8V
OhMxBpFPAkEAyMbGZ2VX6gW37g03OGSoUG6mvXe+CKRqv8hV4UoGeQIUYJTFlt2O
ukD2jKyHqWIdU/3tM3iP1b8CY6JyVyhOjwJBAJ/NmDMKohnJn9bcKxOpJ/HiypIh
8sQzcZY4W5QEYTLKHJ7HV08brXFh6VvV12bL2q1HmLAEb69bll2P2Gve+k8CQQC3
1Pi4lxwl1FKSjlsvMUrDSm01Mbw34YM0UlP/0W2XwoWx4MYB2p7ifrTAHQCh4IoF
64wSAqOADEI9w/F5SBiVAkBJVt3jNObeieMfxVU/NOtajXX51sDUj3XCIWPPui8i
IKzzVn7G0kH+/TqtTPdizrDJkg/rsnrTpvHi8eeMZlAy
-----END RSA PRIVATE KEY-----',
                                                          );
    my $contact_struct = $xero->do_xero_api_call( 'https://api.xero.com/api.xro/2.0/Contacts' );  


=head2 XERO PRIVATE APPLICATION API CONFIGURATION

Private applications use a 2-legged authorisation process. When you register your application, you will select the organisation that is authorised to your application. This cannot be changed afterwards, although you can register another private application if you have multiple organisations.

Private applications require a private RSA keypair which is used to sign each request to the API. You can generate this keypair on Mac OSX or Linux with OpenSSL. For example:

    openssl genrsa -out privatekey.pem 1024
    openssl req -newkey rsa:1024 -x509 -key privatekey.pem -out publickey.cer -days 365
    openssl pkcs12 -export -out public_privatekey.pfx -inkey privatekey.pem -in publickey.cer

You need to upload this public_privatekey.pfx file to your private application in http://api.xero.com.

https://app.xero.com/Application

=head1 METHODS

=cut 

=head2 as_text()

  returns 'WebService::Xero::Agent::PrivateApplication'

=cut 

sub as_text
{
    my ( $self ) = @_;
    my $txt = 'WebService::Xero::Agent::PrivateApplication';
    $txt .= "\nSTATUS = " . $self->get_status();

}


sub _validate_agent 
{
  my ( $self  ) = @_;
  return $self->_error('CONSUMER_KEY not valid')     unless ( $self->{CONSUMER_KEY}    =~ /.{20,}/m ); ## min 20 chars - 30 is typical
  return $self->_error('CONSUMER_SECRET not valid')  unless ( $self->{CONSUMER_SECRET} =~ /.{20,}/m ); ## min 20 chars - 30 is typical
   #     KEYFILE 
   #     PRIVATE_KEY
  if ( not defined $self->{pko} and $self->{PRIVATE_KEY} =~ /BEGIN RSA PRIVATE KEY/smg )
  {
    $self->{pko} = Crypt::OpenSSL::RSA->new_private_key(  $self->{PRIVATE_KEY} ) || return $self->_error('PRIVATE_KEY not valid'); 
    ## TODO - sort out catching error - currently crashes if fails not return undef
    ##  could try to catch the error .. eg. RSA.xs:178: OpenSSL error: too long
    ## FROM Crypt::OpenSSL::RSA docs
#       NOTE: Many of the methods in this package can croak, so use eval, or
#       Error.pm's try/catch mechanism to capture errors.  Also, while some
#       methods from earlier versions of this package return true on success,
#       this (never documented) behavior is no longer the case.
  }
  $self->{_status} = 'RSA KEY SET';
  return $self->_error('PRIVATE_KEY unable to create a valid RSA:' . ref($self->{pko}) ) unless ( ref($self->{pko}) eq 'Crypt::OpenSSL::RSA' );
  return $self;
}


=head2 do_xero_api_call()

  INPUT PARAMETERS AS A LIST ( NOT NAMED )

* $uri (required)    - the API endpoint URI ( eg 'https://api.xero.com/api.xro/2.0/Contacts/')
* $method (optional) - 'POST' or 'GET' .. PUT not currently supported
* $xml (optional)    - the payload for POST updates as XML

  RETURNS

    The response is requested in JSON format which is then processed into a Perl structure that
    is returned to the caller.


=cut 


=head1 AUTHOR

Peter Scott, C<< <peter at computerpros.com.au> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-xero at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Xero>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Xero


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Xero>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Xero>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Xero>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Xero/>

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
