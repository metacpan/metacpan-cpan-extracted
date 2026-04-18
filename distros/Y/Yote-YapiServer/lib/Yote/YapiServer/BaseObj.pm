package Yote::YapiServer::BaseObj;

use strict;
use warnings;
use base 'Yote::SQLObjectStore::SQLite::Obj', 'Yote::SQLObjectStore::MariaDB::Obj';

#----------------------------------------------------------------------
# Class data accessors — look up %HASH in the calling class
# Named to avoid colliding with get_foo/set_foo instance accessors
#----------------------------------------------------------------------

sub field_access {
    my ($self) = @_;
    my $class = ref($self) || $self;
    no strict 'refs';
    return \%{"${class}::FIELD_ACCESS"};
}

sub method_defs {
    my ($self) = @_;
    my $class = ref($self) || $self;
    no strict 'refs';
    return \%{"${class}::METHODS"};
}

#----------------------------------------------------------------------
# Client class name — strips Yote::YapiServer:: prefix
#----------------------------------------------------------------------

sub _client_class_name {
    my ($self) = @_;
    my $class = ref($self) || $self;
    $class =~ s/^Yote::YapiServer::App:://;
    $class =~ s/^Yote::YapiServer:://;
    return $class;
}

#----------------------------------------------------------------------
# Default serialization — filters fields by %FIELD_ACCESS rules
#----------------------------------------------------------------------

sub to_client_hash {
    my ($self, $session, $viewer) = @_;
    my %result;

    my $field_access = $self->field_access;
    my $cols = $self->cols;
    my $owner = eval { $self->get_owner };
    my $is_owner = $viewer && $owner && $owner->id eq $viewer->id;
    my $is_admin = $viewer && $viewer->get_is_admin;

    for my $field (keys %$field_access) {
        my $rule = $field_access->{$field};

        next if $rule->{never};
        next if $rule->{owner_only} && !$is_owner && !$is_admin;
        next if $rule->{admin_only} && !$is_admin;

        # Use get() directly — AUTOLOAD-generated getters aren't seen by can()
        next unless exists $cols->{$field};
        $result{$field} = $self->get($field);
    }

    return \%result;
}

1;

__END__

=head1 NAME

Yote::YapiServer::BaseObj - Base class for all yapi-server persisted objects

=head1 DESCRIPTION

Provides default serialization (to_client_hash), class data accessors
(field_access, method_defs), and client class naming for all yapi objects.

Subclasses define C<%FIELD_ACCESS> and C<%METHODS> package variables.
Override C<to_client_hash> for custom serialization.

=cut
