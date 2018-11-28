package plenigo::PurchasesManager;

=head1 NAME

 plenigo::PurchasesManager - A utility class to offer purchase information.

=head1 SYNOPSIS

 use plenigo::PurchasesManager;

 # Prepare configuration

 my $activate_testing = 0;
 my $configuration = plenigo::Configuration->new(company_id => 'YOUR_COMPANY_ID, secret => 'YOUR_SECRET', staging => $activate_testing);

 # Instantiate purchases manager

 my $purchases_manager = plenigo::PurchasesManager->new(configuration => $configuration);

 # Get all subscriptions of a customer

 my %subscriptions = $purchases_manager->getCustomerSubscriptions('CUSTOMER_ID');

=head1 DESCRIPTION

 plenigo::CustomerManPurchasesManagerager provides functionality to offer purchase information.

=cut

use Moo;
use Carp qw(confess);
use plenigo::Ex;
use plenigo::RestClient;

our $VERSION = '2.0006';

has configuration => (
    is       => 'ro',
    required => 1
);

=head2 getCustomerSubscriptions($customer_id)

Get all subscriptions that were purchased by a customer.

=cut

sub getCustomerSubscriptions {
    my ($self, $customer_id) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->get('user/' . $customer_id . "/subscriptions", {useExternalCustomerId => $self->configuration->use_external_customer_id});

    if ($result{'response_code'} == 404) {
        plenigo::Ex->throw({ code => 409, message => 'No customer can be found for the given customer id.' });
    }
    else {
        return %{$result{'response_content'}};
    }
}

1;
