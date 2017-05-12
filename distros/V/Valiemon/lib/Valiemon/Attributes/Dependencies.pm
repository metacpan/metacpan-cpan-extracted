package Valiemon::Attributes::Dependencies;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use List::MoreUtils qw(all any);

sub attr_name { 'dependencies' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;
    $context->in_attr($class, sub {
        return 1 unless ref $data eq 'HASH'; # ignore

        my $dependencies = $schema->{dependencies};
        unless (ref $dependencies eq 'HASH') {
            croak sprintf '`dependencies` must be an object at %s', $context->position
        }

        for my $name (keys %$dependencies) {
            my $subschema_or_propertyset = $dependencies->{$name};

            if (ref $subschema_or_propertyset eq 'HASH') {
                # schema dependencies
                my $sub_v = $context->sub_validator($subschema_or_propertyset);
                next unless exists $data->{$name};
                next if $sub_v->validate($data);
                return 0;
            } elsif (ref $subschema_or_propertyset eq 'ARRAY') {
                # property dependencies
                unless ( scalar @$subschema_or_propertyset > 0 ) {
                    croak sprintf 'In case value of `dependencies` is an array, it must have at least one element at %s', $context->position;
                }
                # assume all values are string
                unless ( all { $context->prims->is_string($_) } @$subschema_or_propertyset ) {
                    croak sprintf 'All elements of value of `dependencies` must be a string at %s', $context->position;
                }
                # assume are values are unique
                unless ( $class->check_all_uniqueness($context, $subschema_or_propertyset) ) {
                    croak sprintf 'All elements of value of `dependencies` must be unique at %s', $context->position;
                }
                next unless exists $data->{$name};
                next if all { exists $data->{$_} } @$subschema_or_propertyset;
                return 0;
            } elsif ( $context->prims->is_string($subschema_or_propertyset) ) {
                # In draft 3, string was allowed (as a singly value of propertyset)
                croak sprintf '`dependencies` member values can no longer be single strings at %s', $context->position;
            } else {
                croak sprintf 'Invalid value of `dependencies` at %s', $context->position;
            }
        }
        return 1;
    });
}

sub check_all_uniqueness {
    my ($class, $context, $elements) = @_;

    my $unique_elements = [];
    for my $elem (@$elements) {
        return 0 if any { $context->prims->is_equal($_, $elem) } @$unique_elements;
        push @$unique_elements, $elem;
    }
    return 1;
}

1;
