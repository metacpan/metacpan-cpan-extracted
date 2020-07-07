package plenigo::CustomersManager;

=head1 NAME

 plenigo::CustomersManager - A utility class to handle customers.

=head1 SYNOPSIS

 use plenigo::CustomersManager;

 # Prepare configuration

 my $use_stage = 0; # set if stage system should be used
 my $configuration = plenigo::Configuration->new(access_token => 'ACCESS_TOKEN', use_stage => $use_stage);

 # Instantiate customers manager

 my $customers_manager = plenigo::CustomersManager->new(configuration => $configuration);

 # Register a new external customer

 my %customer_details = $customers_manager->registerCustomer('newuser@example.com', 'DE', '123456789', 'MR', 'Mike', 'Miller');

 # Change email address of an exiting customer

 $customers_manager->editCustomer('CUSTOMER_ID', 'newmail@example.com')

=head1 DESCRIPTION

 plenigo::CustomersManager provides functionality to manage customers.

=cut

use Moo;
use Carp qw(confess);
use plenigo::Ex;
use plenigo::RestClient;

our $VERSION = '3.0002';

has configuration => (
    is       => 'ro',
    required => 1
);

=head2 registerCustomer($email, $language, $customer_id, $salutation, $first_name, $last_name)

Register a new customer in the plenigo system.

=cut

sub registerCustomer {
    my ($self, $email, $language, $customer_id, $salutation, $first_name, $last_name) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->post('customers', {}, (
        customerId => $customer_id,
        email      => $email,
        language   => $language,
        gender     => $salutation,
        addresses  => (
            "type"      => "INVOICE",
            "preferred" => 1,
            firstName   => $first_name,
            lastName    => $last_name,
        )
    ));
    if ($result{'response_code'} == 409) {
        plenigo::Ex->throw({ code => 409, message => 'A customer with the given email already exists. If you want to avoid this error, set the fail_by_existing_email flag to false.' });
    }
    if ($result{'response_code'} == 429) {
        plenigo::Ex->throw({ code => 429, message => 'A customer registration with the same email address can only be done once every 5 seconds.' });
    }
    else {
        return %{$result{'response_content'}};
    }
}

=head2 editCustomer($customer_id, $email)

Edit a customer in the plenigo system.

=cut

sub editCustomer {
    my ($self, $customer_id, $email) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->put('customers/' . $customer_id, (email => $email));
    if ($result{'response_code'} == 404) {
        plenigo::Ex->throw({ code => 404, message => 'There is no customer for the customer id passed.' });
    }

    return 1;
}

1;
