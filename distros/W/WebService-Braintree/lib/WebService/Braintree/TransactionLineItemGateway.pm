# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::TransactionLineItemGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);
use Scalar::Util qw(blessed);
use WebService::Braintree::Util qw(validate_id);

has 'gateway' => (is => 'ro');

use WebService::Braintree::_::TransactionLineItem;

sub find_all {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    my $response = $self->_make_raw_request(
        "/transactions/${id}/line_items", 'get', undef,
    );
    return $response if blessed($response);
    return (
        map {
            WebService::Braintree::_::TransactionLineItem->new($_);
        } @{$response->{line_items} // []}
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
