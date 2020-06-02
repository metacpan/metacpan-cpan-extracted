package plenigo::LoginManager;

=head1 NAME

 plenigo::LoginManager - Handles log ins of a customer.

=head1 SYNOPSIS

 use plenigo::LoginManager;

 # Prepare configuration

 my $use_stage = 0; # set if stage system should be used
 my $configuration = plenigo::Configuration->new(access_token => 'ACCESS_TOKEN', use_stage => $use_stage);
 
 # create one or more login tokens for a customer to show the customer snippets

 my %loginTokens = $login_manager->createLoginTokens($customer_id);

=head1 DESCRIPTION

 plenigo::LoginManager offers functionality to log in a customer.

=cut

use Moo;
use Carp qw(confess);
use plenigo::Ex;
use plenigo::RestClient;

our $VERSION = '3.0000';

has configuration => (
    is       => 'ro',
    required => 1
);

=head2 createLoginTokens($customer_id, $amount)

 Create login tokens for a customer to show the customer snippets.

=cut

sub createLoginTokens {
    my ($self, $customer_id, $amount) = @_;
    $amount //= 1;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->post('customers/' . $customer_id . '/logInTokens', (amount => $amount));
    if ($result{'response_code'} == 404) {
        plenigo::Ex->throw({ code => 404, message => 'There is no customer for the customer id passed.' });
    }
    else {
        return %{$result{'response_content'}};
    }
}
