package WebService::Braintree::SettlementBatchSummaryGateway;
$WebService::Braintree::SettlementBatchSummaryGateway::VERSION = '0.93';
use Moose;
with 'WebService::Braintree::Role::MakeRequest';
use Carp qw(confess);

has 'gateway' => (is => 'ro');

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

