# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ClientToken;
$WebService::Braintree::ClientToken::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ClientToken

=head1 PURPOSE

This class generates the client token needed by client-side SDKs, such as
Mobile and Javascript.

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

use constant DEFAULT_VERSION => "2";

=head1 CLASS METHODS

=head2 generate()

This takes a hashref of parameters and returns the client token created by
Braintree. Unlike all other interfaces, this one does B<NOT> return an object.
Instead, just the token string is returned.

    WebService::Braintree::ClientToken->generate({
        key1 => 'value1',
        key2 => 'value2',
    });

=head3 Default values

=over 4

=item version

This will default to the DEFAULT_VERSION of 2.

=back

=cut

sub generate {
    my ($class, $params) = @_;
    $params->{version} //= DEFAULT_VERSION;

    $class->gateway->client_token->generate($params);
}

1;
__END__
