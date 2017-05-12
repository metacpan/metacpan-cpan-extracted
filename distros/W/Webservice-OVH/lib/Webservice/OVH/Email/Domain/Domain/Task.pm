package Webservice::OVH::Email::Domain::Domain::Task;

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.3;

use Webservice::OVH::Email::Domain::Domain::Task::Account;
use Webservice::OVH::Email::Domain::Domain::Task::Mailinglist;
use Webservice::OVH::Email::Domain::Domain::Task::Redirection;

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing domain"  unless $params{domain};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $domain      = $params{domain};

    my $self = bless {
        _module            => $module,
        _wrapper       => $api_wrapper,
        _tasks_account     => {},
        _tasks_mailinglist => {},
        _tasks_redirection => {},
        _domain            => $domain,
    }, $class;

    return $self;
}

sub domain {

    my ($self) = @_;

    return $self->{_domain};
}

sub mailinglist_tasks {

    my ($self)      = @_;
    my $api         = $self->{_wrapper};
    my $domain_name = $self->domain->name;

    my $response = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/task/mailinglist", noSignature => 0 );
    croak $response->error if $response->error;

    my $ids     = $response->content;
    my $objects = [];

    foreach my $id (@$ids) {

        my $object = $self->{_tasks_mailinglist}{$id} = $self->{_tasks_mailinglist}{$id} || Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api, domain => $self->domain, id => $id, module => $self->{_module} );
        push @$objects, $object;
    }

    return $objects;
}

sub mailinglist_task_by_id {

    my ( $self, $id ) = @_;

    croak "Missing id" unless $id;

    my $api               = $self->{_wrapper};
    my $from_object_array = $self->{_tasks_mailinglist}{$id} if $self->{_tasks_mailinglist}{$id} && $self->{_tasks_mailinglist}{$id}->is_valid;
    my $account           = $self->{_tasks_mailinglist}{$id} = $from_object_array || Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api, domain => $self->domain, id => $id, module => $self->{_module} );

    return $account;
}

sub mailinglist_tasks_by_name {

    my ( $self, $mailinglist_name ) = @_;

    croak "Missing mailinglist_name" unless $mailinglist_name;

    my $domain_name = $self->domain->name;
    my $api         = $self->{_wrapper};

    my $response = $api->rawCall( method => 'get', path => sprintf( "/email/domain/$domain_name/task/mailinglist?account=%s", $mailinglist_name ), noSignature => 0 );
    croak $response->error if $response->error;

    my $ids     = $response->content;
    my $objects = [];

    foreach my $id (@$ids) {

        my $object = $self->{_tasks_mailinglist}{$id} = $self->{_tasks_mailinglist}{$id} || Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api, domain => $self->domain, id => $id, module => $self->{_module} );
        push @$objects, $object;
    }

    return unless scalar @$objects;

    return $objects;
}

sub account_tasks {

    my ($self) = @_;

    my $api         = $self->{_wrapper};
    my $domain_name = $self->domain->name;

    my $response = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/task/account", noSignature => 0 );
    croak $response->error if $response->error;

    my $ids     = $response->content;
    my $objects = [];

    foreach my $id (@$ids) {

        my $object = $self->{_tasks_account}{$id} = $self->{_tasks_account}{$id} || Webservice::OVH::Email::Domain::Domain::Task::Account->_new_existing( wrapper => $api, domain => $self->domain, id => $id, module => $self->{_module} );
        push @$objects, $object;
    }

    return $objects;
}

sub account_task_by_id {

    my ( $self, $id ) = @_;

    croak "Missing id" unless $id;

    my $api               = $self->{_wrapper};
    my $from_object_array = $self->{_tasks_account}{$id} if $self->{_tasks_account}{$id};
    my $account           = $self->{_tasks_account}{$id} = $from_object_array || Webservice::OVH::Email::Domain::Domain::Task::Account->_new_existing( wrapper => $api, domain => $self->domain, id => $id, module => $self->{_module} );

    return $account;
}

sub account_tasks_by_name {

    my ( $self, $account_name ) = @_;

    croak "Missing mailinglist_name" unless $account_name;

    my $domain_name = $self->domain->name;
    my $api         = $self->{_wrapper};

    my $response = $api->rawCall( method => 'get', path => sprintf( "/email/domain/$domain_name/task/account?name=%s", $account_name ), noSignature => 0 );
    croak $response->error if $response->error;

    my $ids     = $response->content;
    my $objects = [];

    foreach my $id (@$ids) {

        my $object = $self->{_tasks_account}{$id} = $self->{_tasks_account}{$id} || Webservice::OVH::Email::Domain::Domain::Task::Account->_new_existing( wrapper => $api, domain => $self->domain, id => $id, module => $self->{_module} );
        push @$objects, $object;
    }

    return unless scalar @$objects;

    return $objects;
}

sub redirection_tasks {

    my ($self) = @_;

    my $api         = $self->{_wrapper};
    my $domain_name = $self->domain->name;

    my $response = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/task/redirection", noSignature => 0 );
    croak $response->error if $response->error;

    my $ids     = $response->content;
    my $objects = [];

    foreach my $id (@$ids) {

        my $object = $self->{_tasks_redirection}{$id} = $self->{_tasks_redirection}{$id} || Webservice::OVH::Email::Domain::Domain::Task::Redirection->_new_existing( wrapper => $api, domain => $self->domain, id => $id, module => $self->{_module} );
        push @$objects, $object;
    }

    return $objects;
}

sub redirection_task_by_id {

    my ( $self, $id ) = @_;

    croak "Missing id" unless $id;

    my $api               = $self->{_wrapper};
    my $from_object_array = $self->{_tasks_redirection}{$id} if $self->{_tasks_redirection}{$id} && $self->{_tasks_redirection}{$id}->is_valid;
    my $account           = $self->{_tasks_redirection}{$id} = $from_object_array || Webservice::OVH::Email::Domain::Domain::Task::Redirection->_new_existing( wrapper => $api, domain => $self->domain, id => $id, module => $self->{_module} );

    return $account;
}

sub redirection_tasks_by_name {

    my ( $self, $redirection_id ) = @_;

    croak "Missing mailinglist_name" unless $redirection_id;

    my $domain_name = $self->domain->name;
    my $api         = $self->{_wrapper};

    my $response = $api->rawCall( method => 'get', path => sprintf( "/email/domain/$domain_name/task/redirection?account=%s", $redirection_id ), noSignature => 0 );
    croak $response->error if $response->error;

    my $ids     = $response->content;
    my $objects = [];

    foreach my $id (@$ids) {

        my $object = $self->{_tasks_redirection}{$id} = $self->{_tasks_redirection}{$id} || Webservice::OVH::Email::Domain::Domain::Task::Redirection->_new_existing( wrapper => $api, domain => $self->domain, id => $id, module => $self->{_module} );
        push @$objects, $object;
    }

    return unless scalar @$objects;

    return $objects;
}

1;
