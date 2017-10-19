package WebService::Braintree::TransactionGateway;
$WebService::Braintree::TransactionGateway::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';
use Carp qw(confess);
use WebService::Braintree::Util qw(validate_id to_instance_array);
use WebService::Braintree::Validations qw(verify_params transaction_signature clone_transaction_signature transaction_search_results_signature);

has 'gateway' => (is => 'ro');

sub create {
    my ($self, $params) = @_;
    confess "ArgumentError" unless verify_params($params, transaction_signature);
    $self->_make_request("/transactions/", "post", {transaction => $params});
}

sub find {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    $self->_make_request("/transactions/$id", "get", undef);
}

sub retry_subscription_charge {
    my ($self, $subscription_id, $amount) = @_;
    my $params = {
        subscription_id => $subscription_id,
        amount => $amount,
        type => "sale"
    };

    $self->create($params);
}

sub submit_for_settlement {
    my ($self, $id, $params) = @_;
    $self->_make_request("/transactions/$id/submit_for_settlement", "put", {transaction => $params});
}

sub void {
    my ($self, $id) = @_;
    $self->_make_request("/transactions/$id/void", "put", undef);
}

sub refund {
    my ($self, $id, $params) = @_;
    $self->_make_request("/transactions/$id/refund", "post", {transaction => $params});
}

sub clone_transaction {
    my ($self, $id, $params) = @_;
    confess "ArgumentError" unless verify_params($params, clone_transaction_signature);
    $self->_make_request("/transactions/$id/clone", "post", {transaction_clone => $params});
}

sub search {
    my ($self, $block) = @_;
    my $search = WebService::Braintree::TransactionSearch->new;
    my $params = $block->($search)->to_hash;
    my $response = $self->gateway->http->post("/transactions/advanced_search_ids", {search => $params});
    confess "DownForMaintenanceError" unless (verify_params($response, transaction_search_results_signature));
    return WebService::Braintree::ResourceCollection->new()->init($response, sub {
        $self->fetch_transactions($search, shift);
    });
}

sub hold_in_escrow {
    my ($self, $id) = @_;
    $self->_make_request("/transactions/$id/hold_in_escrow", "put", undef);
}

sub release_from_escrow {
    my ($self, $id) = @_;
    $self->_make_request("/transactions/$id/release_from_escrow", "put", undef);
}

sub cancel_release {
    my ($self, $id) = @_;
    $self->_make_request("/transactions/$id/cancel_release", "put", undef);
}

sub all {
    my $self = shift;
    my $response = $self->gateway->http->post("/transactions/advanced_search_ids");
    return WebService::Braintree::ResourceCollection->new->init($response, sub {
        $self->fetch_transactions(WebService::Braintree::TransactionSearch->new, shift);
    });
}

sub fetch_transactions {
    my ($self, $search, $ids) = @_;

    return [] if scalar @{$ids} == 0;

    $search->ids->in($ids);

    my $response = $self->gateway->http->post("/transactions/advanced_search/", {search => $search->to_hash});
    my $attrs = $response->{'credit_card_transactions'}->{'transaction'};
    return to_instance_array($attrs, "WebService::Braintree::Transaction");
}

__PACKAGE__->meta->make_immutable;

1;
__END__
