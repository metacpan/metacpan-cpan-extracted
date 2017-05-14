use strict;
use warnings;
package iTransact::Lite;

use XML::Hash::LX;
use Digest::HMAC_SHA1;
use LWP::UserAgent;
use Any::Moose;
use Ouch;

has gateway_id => (
    is      => 'ro',
    required=> 1,
);

has api_key => (
    is      => 'ro',
    required=> 1,
);

has api_username => (
    is      => 'ro',
    required=> 1,
);

sub submit {
    my ($self, $payload) = @_;
    my $xml = hash2xml $payload;
    $xml = (split(/\n/, $xml))[1]; # strip the <xml> tag before calculating the PayloadSignature
    my $hmac = Digest::HMAC_SHA1->new($self->api_key);
    $hmac->add($xml);
    my %request = (
        GatewayInterface    => {
            APICredentials  => {
                Username            => $self->api_username,
                TargetGateway       => $self->gateway_id,
                PayloadSignature    => $hmac->b64digest . '=',
            },
            %{$payload},
        },
    );
    $xml = hash2xml \%request;
    my $response = LWP::UserAgent->new->post(
        'https://secure.itransact.com/cgi-bin/rc/xmltrans2.cgi',
        Content_Type    => 'text/xml',
        Content         => $xml,
        Accept          => 'text/xml',
    );
    if ($response->is_success) {
        return xml2hash $response->decoded_content;
    }
    else {
        ouch 504, 'Could not connect to the credit card processor.', \%request;
    }
}


no Any::Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

iTransact::Lite - A simple interface to the iTransact payment gateway.

=head1 SYNOPSIS

 use iTransact::Lite;
 
 my $itransact = iTransact::Lite->new(
    gateway_id      => 99999,
    api_key         => 'xxxxxxx',
    api_username    => 'mycoolsite',
 );
 
 my $response = $itransact->submit({
        AuthTransaction => {
            CustomerData    => {
                Email           => 'user@example.com',
                BillingAddress  => {
                    Address1        => '123 Main St',
                    FirstName       => 'John',
                    LastName        => 'Doe',
                    City            => 'Anytown',
                    State           => 'WI',
                    Zip             => '00000',
                    Country         => 'US',
                    Phone           => '608-555-1212',
                },
                CustId          => $customer_id,
            },
            Total               => sprintf('%.2f', $amount),
            Description         => 'Space Sneakers',
            AccountInfo         => {
                CardAccount => {
                    AccountNumber   => $credit_card_number,
                    ExpirationMonth => '07',
                    ExpirationYear  => '2019',
                    CVVNumber       => '999',
                },
            },
            TransactionControl  => {
                SendCustomerEmail   => 'FALSE',
                SendMerchantEmail   => 'FALSE',
                TestMode            => 'TRUE',
            },
        },
 });

 if ($response->{GatewayInterface}{TransactionResponse}{TransactionResult}{Status} eq 'ok') {
     say "Success! Transaction ID: ". $response->{GatewayInterface}{TransactionResponse}{TransactionResult}{XID};
 }
 else {
     die $response->{GatewayInterface}{TransactionResponse}{TransactionResult}{ErrorMessage};
 }

=head1 DESCRIPTION

This module provides a simple wrapper around the iTransact XML Connection API (L<http://www.itransact.com/support/toolkit/xml-connection/api/>). It does the hard work of signing, serializing, and submitting the request for you, but you still have to give it the data the web service API is expecting.

=head1 METHODS

=head2 new

Constructor.

=over

=item gateway_id

The gateway id number supplied by iTransact for your account.

=item api_key

The API Key supplied by iTransact for your account after you enable web services.

=item api_username

The API Username suppplied by iTransact for your account after you enable web services.

=back

=head2 submit

Use this method to submit your requests. You may use this method multipled times on the same object with new payloads each time.

=over

=item payload

A hash reference of the data you wish to submit. This should not include the outer C<GatewayInterface> wrapper or the C<APICredentials> section as those will be auto generated.

=back

=head1 EXCEPTIONS

If this module is unable to connect to iTransact for any reason it will throw an L<Ouch> exception with the exception code of C<504>.

=head1 PREREQS

The following modules are required:

L<Ouch>
L<LWP>
L<LWP::Protocol::https>
L<XML::Hash::LX>
L<Digest::HMAC_SHA1>
L<Any::Moose>

=head1 TODO

Someday I should probably make a full featured version of this module that hides all of the web service's data structures, and does some more advanced response handling.

=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/iTransact-Lite>

=item Bug Reports

L<http://github.com/rizen/iTransact-Lite/issues>

=back

=head1 AUTHOR

JT Smith <rizen@cpan.org>

=head1 LEGAL

iTransact::Lite is Copyright 2012 Plain Black Corporation (L<http://www.plainblack.com>) and is licensed under the same terms as Perl itself.

=cut

