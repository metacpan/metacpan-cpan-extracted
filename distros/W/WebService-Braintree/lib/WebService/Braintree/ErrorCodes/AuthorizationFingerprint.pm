# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::AuthorizationFingerprint;
$WebService::Braintree::ErrorCodes::AuthorizationFingerprint::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::AuthorizationFingerprint

=head1 PURPOSE

This class contains error codes that might be returned if an authorization
fingerprint is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item InvalidCreatedAt

=cut

use constant InvalidCreatedAt => '93204';

=item InvalidFormat

=cut

use constant InvalidFormat => '93202';

=item InvalidPublicKey

=cut

use constant InvalidPublicKey => '93205';

=item InvalidSignature

=cut

use constant InvalidSignature => '93206';

=item MissingFingerprint

=cut

use constant MissingFingerprint => '93201';

=item OptionsNotAllowedWithoutCustomer

=cut

use constant OptionsNotAllowedWithoutCustomer => '93207';

=item SignatureRevoked

=cut

use constant SignatureRevoked => '93203';

=back

=cut

1;
__END__
