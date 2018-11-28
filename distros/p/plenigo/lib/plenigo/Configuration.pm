package plenigo::Configuration;

=head1 NAME

 plenigo::Configuration - Contains all base configuration settings.

=head1 SYNOPSIS

 use plenigo::Configuration;

 # Prepare configuration

 my $activate_testing = 0; # set if testing mode should be enabled
 my $use_external_customer_id = 0; # set if you use your own customer id instead of the one provided by plenigo
 my $configuration = plenigo::Configuration->new(company_id => 'YOUR_COMPANY_ID, secret => 'YOUR_SECRET', staging => $activate_testing, use_external_customer_id => $use_external_customer_id);

=head1 DESCRIPTION

 plenigo::Configuration contains all base configuration settings.

=cut

use Moo;
use Carp qw(confess);

our $VERSION = '2.0006';

has company_id => (
    is       => 'ro',
    required => 1
);

has secret => (
    is       => 'ro',
    required => 1
);

has staging => (
    is      => 'ro',
    default => 0
);

has use_external_customer_id => (
    is      => 'ro',
    default => 0
);

has api_host => (
    is      => 'rw',
    default => 'https://api.plenigo.com'
);

has api_url => (
    is      => 'rw',
    default => '/api/v2/'
);

1;
