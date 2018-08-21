package plenigo::AccessRightsManager;

=head1 NAME

 plenigo::AccessRightsManager - A utility class to get/add/remove access rights from/to a customer. 

=head1 SYNOPSIS

 use plenigo::AccessRightsManager;

 # Prepare configuration

 my $activate_testing = 0;
 my $configuration = plenigo::Configuration->new(company_id => 'YOUR_COMPANY_ID, secret => 'YOUR_SECRET', staging => $activate_testing);

 # Instantiate access rights manager

 my $access_rights = plenigo::AccessRightsManager->new(configuration => $configuration);

 # Checking access rights from a customer

 my %access_rights = $access_rights->hasAccess($plenigo_customer_id, ['ACCESS_RIGHT_ID']); 
 if ($access_rights{'accessGranted'}) {
     # customer has the right to access 
 }
 else {
     # customer is not allowed to access
 }

 # Adding access rights to a customer

 $access_rights->addAccess($plenigo_customer_id, (details => [{productId => 'ACCESS_RIGHT_ID'}]));

 # Removing access rights from a customer

 $access_rights->removeAccess($plenigo_customer_id, ['ACCESS_RIGHT_ID']);

=head1 DESCRIPTION

 plenigo::AccessRightsManager provides functionality to manage access rights of a customer.

=cut

use Moo;
use Carp qw(confess);
use Carp::Always;
use plenigo::Ex;
use plenigo::RestClient;

our $VERSION = '2.0003';

has configuration => (
    is       => 'ro',
    required => 1
);

=head1 METHODS

=cut

=head2 hasAccess($customer_id, @product_ids)

 Test if a customer has access rights.

=cut

sub hasAccess {
    my ($self, $customer_id, @product_ids) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->get('user/product/details', { customerId => $customer_id, productId => @product_ids, useExternalCustomerId => $self->configuration->use_external_customer_id, testMode => $self->configuration->staging });
    if ($result{'response_code'} == 403) {
        return('accessGranted' => 0)
    }
    else {
        return %{$result{'response_content'}};
    }
}

=head2 addAccess($customer_id, %access_request)

 Add access rights to a customer.

=cut

sub addAccess {
    my ($self, $customer_id, %access_request) = @_;
    
    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %additional_attributes = (testMode => $self->configuration->staging, useExternalCustomerId => $self->configuration->use_external_customer_id);
    %access_request = (%access_request, %additional_attributes);
    my $result = $rest_client->post('access/' . $customer_id . '/addWithDetails', {}, %access_request);
    if (defined $result && $result->response_code == 404) {
       plenigo::Ex->throw({ code => 404, message => 'There is no customer for the customer id passed.' });
    }

    return 1;
}

=head2 removeAccess($customer_id, @product_ids)

 Remove access rights from a customer.

=cut

sub removeAccess {
    my ($self, $customer_id, @product_ids) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    $rest_client->delete('access/' . $customer_id . '/remove', { customerId => $customer_id, productIds => @product_ids, useExternalCustomerId => $self->configuration->use_external_customer_id, testMode => $self->configuration->staging });

    return 1;
}

1;
