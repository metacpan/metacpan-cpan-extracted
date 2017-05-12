# Configuration Class for Validation Classes

# Validation::Class::Configuration provides a default configuration profile used
# by validation classes and many class prototype methods.

package Validation::Class::Configuration;

use strict;
use warnings;

use Validation::Class::Directives;
use Validation::Class::Listing;
use Validation::Class::Mapping;
use Validation::Class::Fields;
use Validation::Class::Mixins;
use Validation::Class::Util;

use Module::Find 'usesub';

our $VERSION = '7.900057'; # VERSION

sub attributes {

    my ($self) = @_;

    return $self->profile->{ATTRIBUTES};

}

sub builders {

    my ($self) = @_;

    return $self->profile->{BUILDERS};

}

sub configure_profile {

    my ($self) = @_;

    $self->configure_profile_register_directives;
    $self->configure_profile_register_filters;
    $self->configure_profile_register_events;

    return $self;

}

sub configure_profile_register_directives {

    my ($self) = @_;

    # automatically attach discovered directive classes

    my $directives = Validation::Class::Directives->new;

    foreach my $directive ($directives->values) {

        my $name = $directive->name;

        $self->directives->add($name => $directive);

    }

    return $self;

}

sub configure_profile_register_filters {

    my ($self) = @_;

    # automatically attach filters registered on in the filters directive

    my $directives = $self->directives;

    my $filters = $directives->get('filters');

    return unless $filters;

    $self->filters->add($filters->registry);

    return $self;

}

sub configure_profile_register_events {

    my ($self) = @_;

    # inspect the directives for event subscriptions

    if (my @directives = ($self->directives->values)) {

        my $events = {
            # hookable events list, keyed by directive name
            'on_after_validation'   => {},
            'on_before_validation'  => {},
            'on_normalize'          => {},
            'on_validate'           => {}
        };

        while (my($name, $container) = each(%{$events})) {

            ($name) = $name =~ /^on_(\w+)/;

            foreach my $directive (@directives) {
                next if defined $container->{$name};
                if (my $routine = $directive->can($name)) {
                    $container->{$directive->name} = $routine;
                }
            }

        }

        $self->events->add($events);

    }

    return $self;

}

sub default_profile {

    my %default_mixins = (

        ':flg' => Validation::Class::Mixin->new(
            required    => 1,
            min_length  => 1,
            filters     => [qw/trim strip numeric/],
            between     => [0, 1],
            name        => ':flg',
        ),

        ':num' => Validation::Class::Mixin->new(
            required    => 1,
            min_length  => 1,
            filters     => [qw/trim strip numeric/],
            name        => ':num',
        ),

        ':str'  => Validation::Class::Mixin->new(
            required    => 1,
            min_length  => 1,
            filters     => [qw/trim strip/],
            name        => ':str',
        )

    );

    return Validation::Class::Mapping->new({

        ATTRIBUTES  => Validation::Class::Mapping->new,

        BUILDERS    => Validation::Class::Listing->new,

        DIRECTIVES  => Validation::Class::Mapping->new,

        DOCUMENTS   => Validation::Class::Mapping->new,

        EVENTS     => Validation::Class::Mapping->new,

        FIELDS     => Validation::Class::Fields->new,

        FILTERS    => Validation::Class::Mapping->new,

        METHODS    => Validation::Class::Mapping->new,

        MIXINS     => Validation::Class::Mixins->new(%default_mixins),

        PROFILES   => Validation::Class::Mapping->new,

        SETTINGS   => Validation::Class::Mapping->new,

    });

}

sub directives {

    my ($self) = @_;

    return $self->profile->{DIRECTIVES};

}

sub documents {

    my ($self) = @_;

    return $self->profile->{DOCUMENTS};

}

sub events {

    my ($self) = @_;

    return $self->profile->{EVENTS};

}

sub fields {

    my ($self) = @_;

    return $self->profile->{FIELDS};

}

sub filters {

    my ($self) = @_;

    return $self->profile->{FILTERS};

}

sub methods {

    my ($self) = @_;

    return $self->profile->{METHODS};

}

sub mixins {

    my ($self) = @_;

    return $self->profile->{MIXINS};

}

sub new {

    my $self = bless {}, shift;

    $self->configure_profile;

    return $self;

}

sub profile {

    my ($self) = @_;

    return $self->{profile} ||= $self->default_profile;

}

sub profiles {

    my ($self) = @_;

    return $self->profile->{PROFILES};

}

sub settings {

    my ($self) = @_;

    return $self->profile->{SETTINGS};

}

1;
