package plenigo::LoginManager;

=head1 NAME

 plenigo::LoginManager - Handles log ins of a customer.

=head1 SYNOPSIS

 use plenigo::LoginManager;

 # Prepare configuration

 my $activate_testing = 0; # set if testing mode should be enabled
 my $configuration = plenigo::Configuration->new(company_id => 'YOUR_COMPANY_ID, secret => 'YOUR_SECRET', staging => $activate_testing);

 # verify a customers log in data 

 my $login_manager = plenigo::LoginManager->new(configuration => $configuration);
 my %customer_details = $login_manager->verifyLoginData($customer_email, $customer_password);
 my $customer_id = $customer_details{'userId'};

 # create one or more login tokens for the checkout process or customer snippets

 my %loginTokens = $login_manager->createLoginTokens($customer_id);

=head1 DESCRIPTION

 plenigo::LoginManager offers functionality to log in a customer.

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

=head2 addAccess($customer_id, $amount)

 Create login tokens for a customer to use during the checkout process or showing the customer snippets.

=cut

sub createLoginTokens {
    my ($self, $customer_id, $amount) = @_;
    $amount //= 1;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->post('externalUser/' . $customer_id . '/createMultipleLoginTokens', {useExternalCustomerId => $self->configuration->use_external_customer_id, amount => $amount}, ());
    if ($result{'response_code'} == 404) {
        plenigo::Ex->throw({ code => 404, message => 'There is no customer for the customer id passed.' });
    }
    else {
        return %{$result{'response_content'}};
    }
}

=head2 verifyLoginData($email, $password, $browser, $os, $source)

 Verify a customer's login data.

=cut

sub verifyLoginData {
    my ($self, $email, $password, $browser, $os, $source) = @_;

    my %login_data = (email => $email, password => $password);
    if (defined $browser) {
        $login_data{'browser'} = $browser;
    }
    if (defined $os) {
        $login_data{'os'} = $os;
    }
    if (defined $source) {
        $login_data{'source'} = $source;
    }

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->post('user/verifyLogin', {}, %login_data);
    if ($result{'response_code'} == 403) {
        plenigo::Ex->throw({ code => 403, message => 'The customer\'s login credentials are not correct.' });
    }
    elsif ($result{'response_code'} == 406) {
        plenigo::Ex->throw({ code => 406, message => 'The customer is blocked because of too many login attempts with an incorrect password.' });
    }
    elsif ($result{'response_code'} == 423) {
        plenigo::Ex->throw({ code => 423, message => 'The customer is currently blocked by a support agent.' });
    }
    else {
        return %{$result{'response_content'}};
    }
}

1;
