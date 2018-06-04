# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::BinData;
$WebService::Braintree::_::BinData::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::BinData

=head1 PURPOSE

This class represents a bin data.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 commercial()

This represents if this bin data is commercial.

=cut

has commercial => (
    is => 'ro',
);

=head2 country_of_issuance()

This is the country of issuance for this bin data.

=cut

has country_of_issuance => (
    is => 'ro',
);

=head2 debit()

This represents if this bin data is debit.

=cut

has debit => (
    is => 'ro',
);

=head2 durbin_regulated()

This represents if this bin data is Durbin-regulated.

=cut

has durbin_regulated => (
    is => 'ro',
);

=head2 healthcare()

This represents if this bin data is healthcare.

=cut

has healthcare => (
    is => 'ro',
);

=head2 issuing_bank()

This is the issuing bank for this bin data.

=cut

has issuing_bank => (
    is => 'ro',
);

=head2 payroll()

This represents if this bin data is payroll.

=cut

has payroll => (
    is => 'ro',
);

=head2 prepaid()

This represents if this bin data is prepaid.

=cut

has prepaid => (
    is => 'ro',
);

=head2 product_id()

This is the product ID for this bin data.

=cut

has product_id => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
