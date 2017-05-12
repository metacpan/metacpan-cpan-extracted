package Webservice::OVH::Email::Domain::Domain::Task::Account;

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.3;

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing id"      unless $params{id};
    die "Missing domain"  unless $params{domain};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $id          = $params{id};
    my $domain      = $params{domain};
    my $domain_name = $domain->name;

    my $self = bless { _module => $module, _valid => 1, _wrapper => $api_wrapper, _id => $id, _properties => undef, _domain => $domain }, $class;

    return $self;
}

sub is_valid {

    my ($self) = @_;

    $self->properties;

    return $self->{_valid},;
}

sub properties {

    my ($self) = @_;

    croak "Invalid" unless $self->{_valid};

    my $domain_name = $self->{_domain}->name;
    my $id          = $self->{_id};
    my $api_wrapper = $self->{_wrapper};

    my $response = $api_wrapper->rawCall( method => 'get', path => "/email/domain/$domain_name/task/account/$id", noSignature => 0 );
    carp $response->error if $response->error;

    if ( !$response->error ) {

        my $porperties = $response->content;
        $self->{_properties} = $porperties;

    } else {
        
        $self->{_properties} = undef;
        $self->{_valid} = 0;
    }

}

sub name {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}{name};
}

sub id {

    my ($self) = @_;

    return $self->{_id};
}

sub domain {

    my ($self) = @_;

    return $self->{_domain};
}

sub date {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}{date};
}

sub action {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}{action};
}

1;
