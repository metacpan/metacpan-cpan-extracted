package plenigo::CompanySettingsManager;

=head1 NAME

 plenigo::CompanySettingsManager - A utility class to handle company settings manager.

=head1 SYNOPSIS

 use plenigo::CompanySettingsManager;

 # Prepare configuration

 my $activate_testing = 0;
 my $configuration = plenigo::Configuration->new(company_id => 'YOUR_COMPANY_ID, secret => 'YOUR_SECRET', staging => $activate_testing);

 # Instantiate company settings

 my $company_settings = plenigo::CompanySettingsManager->new(configuration => $configuration);

 # Check if payment is enabled

 my $is_payment_active = $company_settings->isPaymentEnabled;
 if (not $is_payment_active) {
     // e.g. indicate all devices to play out all content
 }

=head1 DESCRIPTION

 plenigo::CompanySettingsManager provides functionality to manage company settings.

=cut

use Moo;
use Carp qw(confess);
use plenigo::RestClient;

our $VERSION = '2.0006';

has configuration => (
    is       => 'ro',
    required => 1
);

=head2 isPaymentEnabled()

 Check if payment is currently enabled.

=cut

sub isPaymentEnabled {
    my ($self) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->get('paywall/state');
    return $result{'response_content'}{'enabled'};
}

1;
