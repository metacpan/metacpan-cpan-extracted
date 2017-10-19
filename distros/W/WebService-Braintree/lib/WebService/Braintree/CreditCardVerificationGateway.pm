package WebService::Braintree::CreditCardVerificationGateway;
$WebService::Braintree::CreditCardVerificationGateway::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use Moose;
use WebService::Braintree::CreditCardVerificationSearch;
use WebService::Braintree::Util qw(validate_id to_instance_array);
use Carp qw(confess);

has 'gateway' => (is => 'ro');

sub find {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    my $response = $self->gateway->http->get("/verifications/$id");
    return WebService::Braintree::CreditCardVerification->new($response->{'verification'});
}

sub search {
    my ($self, $block) = @_;
    my $search = WebService::Braintree::CreditCardVerificationSearch->new;
    my $params = $block->($search)->to_hash;
    my $response = $self->gateway->http->post("/verifications/advanced_search_ids", {search => $params});
    return WebService::Braintree::ResourceCollection->new()->init($response, sub {
                                                                      $self->fetch_verifications($search, shift);
                                                                  });
}

sub all {
    my $self = shift;
    my $response = $self->gateway->http->post("/verifications/advanced_search_ids");
    return WebService::Braintree::ResourceCollection->new->init($response, sub {
        $self->fetch_verifications(
            WebService::Braintree::CreditCardVerificationSearch->new, shift,
        );
    });
}

sub fetch_verifications {
    my ($self, $search, $ids) = @_;

    return [] if scalar @{$ids} == 0;

    $search->ids->in($ids);
    my $response = $self->gateway->http->post("/verifications/advanced_search/", {search => $search->to_hash});

    my $attrs = $response->{'credit_card_verifications'}->{'verification'};
    return to_instance_array($attrs, "WebService::Braintree::CreditCardVerification");
}

__PACKAGE__->meta->make_immutable;

1;
__END__
