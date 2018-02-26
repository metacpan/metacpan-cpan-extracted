package WebService::Braintree::SubscriptionGateway;
$WebService::Braintree::SubscriptionGateway::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use WebService::Braintree::Util qw(validate_id);
use Carp qw(confess);

use Moose;
with 'WebService::Braintree::Role::MakeRequest';
with 'WebService::Braintree::Role::CollectionBuilder';

has 'gateway' => (is => 'ro');

sub create {
    my ($self, $params) = @_;
    my $result = $self->_make_request("/subscriptions/", "post", {subscription => $params});
    return $result;
}

sub find {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    my $result = $self->_make_request("/subscriptions/$id", "get", undef)->subscription;
}

sub update {
    my ($self, $id, $params) = @_;
    my $result = $self->_make_request("/subscriptions/$id", "put", {subscription => $params});
}

sub cancel {
    my ($self, $id) = @_;
    my $result = $self->_make_request("/subscriptions/$id/cancel", "put", undef);
}

sub search {
    my ($self, $block) = @_;

    return $self->resource_collection({
        ids_url => "/subscriptions/advanced_search_ids",
        obj_url => "/subscriptions/advanced_search",
        inflate => [qw/subscriptions subscription Subscription/],
        search => $block->(WebService::Braintree::SubscriptionSearch->new),
    });
}

sub all {
    my $self = shift;

    return $self->resource_collection({
        ids_url => "/subscriptions/advanced_search_ids",
        obj_url => "/subscriptions/advanced_search",
        inflate => [qw/subscriptions subscription Subscription/],
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
