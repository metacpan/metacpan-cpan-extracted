# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::DocumentUpload;
$WebService::Braintree::ErrorCodes::DocumentUpload::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::DocumentUpload

=head1 PURPOSE

This class contains error codes that might be returned if a document upload
is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item KindIsInvalid

=cut

use constant KindIsInvalid => '84901';

=item FileIsTooLarge

=cut

use constant FileIsTooLarge => '84902';

=item FileTypeIsInvalid

=cut

use constant FileTypeIsInvalid => '84903';

=item FileIsMalformedOrEncrypted

=cut

use constant FileIsMalformedOrEncrypted => '84904';

=back

=cut

1;
__END__
