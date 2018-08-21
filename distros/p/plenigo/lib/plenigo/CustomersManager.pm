package plenigo::CustomersManager;

=head1 NAME

 plenigo::CustomersManager - A utility class to handle customers.

=head1 SYNOPSIS

 use plenigo::CustomersManager;

 # Prepare configuration

 my $activate_testing = 0;
 my $configuration = plenigo::Configuration->new(company_id => 'YOUR_COMPANY_ID, secret => 'YOUR_SECRET', staging => $activate_testing);

 # Instantiate access rights manager

 my $access_rights = plenigo::AccessRightsManager->new(configuration => $configuration);

 # Register a new external customer

 my $customersManager = plenigo::CustomersManager->new(configuration => $configuration);
 my %customerDetails = $customersManager->registerCustomer('newuser@example.com', 'DE', '123456789', 'MALE', 'Mike', 'Miller', 0, 0);

 # Change email address of an exiting customer

 $customersManager->editCustomer('CUSTOMER_ID', 'newmail@example.com')

=head1 DESCRIPTION

 plenigo::CustomerManager provides functionality to manage customers.

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

=head2 registerCustomer($email, $language, $external_customer_id, $salutation, $first_name, $surname, $with_password_reset, $fail_by_existing_email)

Register a new customer in the plenigo system.

=cut

sub registerCustomer {
    my ($self, $email, $language, $external_customer_id, $salutation, $first_name, $surname, $with_password_reset, $fail_by_existing_email) = @_;
    $with_password_reset //= 0;
    $fail_by_existing_email //= 0;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->post('externalUser/register', {}, (
        email               => $email,
        language            => $language,
        externalUserId      => $external_customer_id,
        gender              => $salutation,
        firstName           => $first_name,
        surname             => $surname,
        withPasswordReset   => $with_password_reset,
        failByExistingEmail => $fail_by_existing_email
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
    my %result = $rest_client->put('externalUser/' . $customer_id . '/changeEmail', { useExternalCustomerId => $self->configuration->use_external_customer_id }, (email => $email));
    if ($result{'response_code'} == 404) {
        plenigo::Ex->throw({ code => 404, message => 'There is no customer for the customer id passed.' });
    }

    return 1;
}

1;
