package plenigo::AccessRightsManager;

=head1 NAME

 plenigo::AccessRightsManager - A utility class to get/add/remove access rights from/to a customer. 

=head1 SYNOPSIS

 use plenigo::AccessRightsManager;

 # Prepare configuration

 my $use_stage = 0; # set if stage system should be used
 my $configuration = plenigo::Configuration->new(access_token => 'ACCESS_TOKEN', use_stage => $use_stage);

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
use plenigo::Ex;
use plenigo::RestClient;

our $VERSION = '3.0002';

has configuration => (
    is       => 'ro',
    required => 1,
);

has _rest_client => (is => 'lazy',);

sub _build__rest_client {
    my $self = shift;
    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    return $rest_client;
}

=head1 METHODS

=cut

sub getAccessRights {
    my ($self, $customer_id) = @_;

    my %result = $self->_rest_client->get("accessRights/$customer_id");

    my @access_right_unique_ids = map {
        $_->{accessRightUniqueId}
    } @{$result{response_content}->{items}};

    return $self->hasAccess($customer_id, @access_right_unique_ids);
}

sub getGrantedAccessRightsItems {
    my ($self, $customer_id) = @_;

    my %access_rights = $self->getAccessRights($customer_id);

    return [
        grep {
            $_->{accessGranted}
        } @{$access_rights{items}}
    ];
}

=head2 hasAccess($customer_id, @product_ids)

 Test if a customer has access rights.

=cut

sub hasAccess {
    my ($self, $customer_id, @access_right_unique_ids) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->get(
        'accessRights/' . $customer_id . '/hasAccess',
        { accessRightUniqueIds => join(',', @access_right_unique_ids) }
    );
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
    my $result = $rest_client->post('access/' . $customer_id . '/addWithDetails', {}, %access_request);
    if (defined $result && $result->response_code == 404) {
       plenigo::Ex->throw({ code => 404, message => 'There is no customer for the customer id passed.' });
    }

    return 1;
}

=head2 removeAccess($customer_id, $access_right_unique_id)

 Remove access right from a customer.

=cut

sub removeAccess {
    my ($self, $customer_id, $access_right_unique_id) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    $rest_client->delete('accessRights/' . $customer_id . '/', $access_right_unique_id);

    return 1;
}

1;
