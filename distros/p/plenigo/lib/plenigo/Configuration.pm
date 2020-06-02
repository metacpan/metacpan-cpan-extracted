package plenigo::Configuration;

=head1 NAME

 plenigo::Configuration - Contains all base configuration settings.

=head1 SYNOPSIS

 use plenigo::Configuration;

 # Prepare configuration

 my $use_stage = 0; # set if stage system should be used
 my $configuration = plenigo::Configuration->new(access_token => 'ACCESS_TOKEN', use_stage => $use_stage);

=head1 DESCRIPTION

 plenigo::Configuration contains all base configuration settings.

=cut

use Moo;
use Carp qw(confess);

our $VERSION = '3.0000';

has access_token => (
    is       => 'ro',
    required => 1
);

has use_stage => (
    is      => 'ro',
    default => 0
);

has api_host => (
    is      => 'rw',
    default => 'https://api.plenigo.com'
);

has api_host_stage => (
    is      => 'rw',
    default => 'https://api.plenigo-stage.com'
);

has api_url => (
    is      => 'rw',
    default => '/api/v3/'
);

1;
