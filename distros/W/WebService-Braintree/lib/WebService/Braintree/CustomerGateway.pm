package WebService::Braintree::CustomerGateway;
$WebService::Braintree::CustomerGateway::VERSION = '0.93';
use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);
use WebService::Braintree::Validations qw(verify_params customer_signature);
use WebService::Braintree::Util qw(validate_id);
use WebService::Braintree::Result;
use WebService::Braintree::Util;

has 'gateway' => (is => 'ro');

sub create {
    my ($self, $params) = @_;
    confess "ArgumentError" unless verify_params($params, customer_signature);
    $self->_make_request("/customers/", 'post', { customer => $params });
}

sub find {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    $self->_make_request("/customers/$id", 'get', undef)->customer;
}

sub delete {
    my ($self, $id) = @_;
    $self->_make_request("/customers/$id", "delete", undef);
}

sub update {
    my ($self, $id, $params) = @_;
    confess "ArgumentError" unless verify_params($params, customer_signature);
    $self->_make_request("/customers/$id", 'put', {customer => $params});
}

sub search {
    my ($self, $block) = @_;
    my $search = WebService::Braintree::CustomerSearch->new;
    my $params = $block->($search)->to_hash;
    my $response = $self->gateway->http->post("/customers/advanced_search_ids", {search => $params});
    return WebService::Braintree::ResourceCollection->new()->init($response, sub {
                                                                      $self->fetch_customers($search, shift);
                                                                  });
}

sub all {
    my $self = shift;
    my $response = $self->gateway->http->post("/customers/advanced_search_ids");
    return WebService::Braintree::ResourceCollection->new()->init($response, sub {
                                                                      $self->fetch_customers(WebService::Braintree::CustomerSearch->new, shift);
                                                                  });
}

sub fetch_customers {
    my ($self, $search, $ids) = @_;
    $search->ids->in($ids);
    my @result = ();
    return [] if scalar @{$ids} == 0;
    my $response = $self->gateway->http->post( "/customers/advanced_search/", {search => $search->to_hash});
    my $attrs = $response->{'customers'}->{'customer'};
    return to_instance_array($attrs, "WebService::Braintree::Customer");
}


__PACKAGE__->meta->make_immutable;
1;


