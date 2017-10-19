package WebService::Braintree::SubscriptionGateway;
$WebService::Braintree::SubscriptionGateway::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use WebService::Braintree::Util qw(to_instance_array validate_id);
use Carp qw(confess);

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

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
    my $search = WebService::Braintree::SubscriptionSearch->new;
    my $params = $block->($search)->to_hash;
    my $response = $self->gateway->http->post("/subscriptions/advanced_search_ids", {search => $params});
    return WebService::Braintree::ResourceCollection->new()->init($response, sub {
                                                                      $self->fetch_subscriptions($search, shift);
                                                                  });
}

sub all {
    my $self = shift;
    my $response = $self->gateway->http->post("/subscriptions/advanced_search_ids");
    return WebService::Braintree::ResourceCollection->new->init($response, sub {
        $self->fetch_subscriptions(WebService::Braintree::SubscriptionSearch->new, shift);
    });
}

sub fetch_subscriptions {
    my ($self, $search, $ids) = @_;
    $search->ids->in($ids);
    return [] if scalar @{$ids} == 0;
    my $response = $self->gateway->http->post("/subscriptions/advanced_search/", {search => $search->to_hash});
    my $attrs = $response->{'subscriptions'}->{'subscription'};
    return to_instance_array($attrs, "WebService::Braintree::Subscription");
}

__PACKAGE__->meta->make_immutable;

1;
__END__
