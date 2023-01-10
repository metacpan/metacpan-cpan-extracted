package Webservice::OVH::Me::Task;

=encoding utf-8

=head1 NAME

Webservice::OVH::Me::Task

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $task = $ovh->domain->service->change_contact(contact_billing => 'ovhaccount-ovh');
    
    $task->resend_email;

=head1 DESCRIPTION

Module only provides basic functionality for contact_change tasks.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.48;

=head2 _new

Internal Method to create the Task object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $type - intern type

=item * Return: L<Webservice::OVH::Me::Task>

=item * Synopsis: Webservice::OVH::Me::Task->_new($ovh_api_wrapper, $type, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"    unless $params{module};
    die "Missing wrapper"   unless $params{wrapper};
    die "Missing id"        unless $params{id};
    die "Missing task type" unless $params{type};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $task_id     = $params{id};
    my $type        = $params{type};

      die "Missing contact_id" unless $task_id;
    die "Missing type" unless $type;

    my $response = $api_wrapper->rawCall( method => 'get', path => "/me/task/contactChange/$task_id", noSignature => 0 );
    croak $response->error if $response->error;

    my $porperties = $response->content;
    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _id => $task_id, _type => $type, _properties => $porperties }, $class;

    return $self;
}

=head2 type

Returns intern type. At the moment only contact_change.

=over

=item * Return: VALUE

=item * Synopsis: my $type = $task->type;

=back

=cut

sub type {

    my ($self) = @_;

    return $self->{_type};
}

=head2 id

Returns the api id.

=over

=item * Return: VALUE

=item * Synopsis: my $id = $task->id;

=back

=cut

sub id {

    my ($self) = @_;

    return $self->{_id};
}

=head2 properties

Retrieves properties.
This method updates the intern property variable.

=over

=item * Return: HASH

=item * Synopsis: my $properties = $task->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $task_id  = $self->id;
    my $api      = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/me/task/contactChange/$task_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_properties} = $response->content;

    return $self->{_properties};
}

=head2 accept

Accepts a contact change.

=over

=item * Synopsis: $task->accept;

=back

=cut

sub accept {

    my ( $self, $token ) = @_;

    croak "Missing Token" unless $token;

    my $task_id  = $self->id;
    my $api      = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'post', path => "/me/task/contactChange/$task_id/accept", body => { token => $token }, noSignature => 0 );
    croak $response->error if $response->error;
}

=head2 refuse

Refuses a contact change.

=over

=item * Synopsis: $task->accept;

=back

=cut

sub refuse {

    my ( $self, $token ) = @_;

    croak "Missing Token" unless $token;

    my $task_id  = $self->id;
    my $api      = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'post', path => "/me/task/contactChange/$task_id/refuse", body => { token => $token }, noSignature => 0 );
    croak $response->error if $response->error;

}

=head2 resend_email

Resends the contact change request.

=over

=item * Synopsis: $task->resend_email;

=back

=cut

sub resend_email {

    my ($self) = @_;

    my $task_id  = $self->id;
    my $api      = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'post', path => "/me/task/contactChange/$task_id/resendEmail", body => {}, noSignature => 0 );
    croak $response->error if $response->error;

}

1;
