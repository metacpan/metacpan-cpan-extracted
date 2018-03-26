# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::SettlementBatchSummaryGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';
use Carp qw(confess);

has 'gateway' => (is => 'ro');

use WebService::Braintree::_::SettlementBatchSummary;

sub generate {
    my ($self, $settlement_date, $group_by_custom_field) = @_;
    my $params = {
        settlement_date => $settlement_date
    };
    $params->{group_by_custom_field} = $group_by_custom_field if $group_by_custom_field;

    $self->_make_request("/settlement_batch_summary/", "post", {settlement_batch_summary => $params});
}

__PACKAGE__->meta->make_immutable;

1;
__END__
