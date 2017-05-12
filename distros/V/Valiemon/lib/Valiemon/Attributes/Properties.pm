package Valiemon::Attributes::Properties;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use Clone qw(clone);
use List::MoreUtils qw(all);
use Valiemon;

sub attr_name { 'properties' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;
    $context->in_attr($class, sub {
        return 1 unless ref $data eq 'HASH'; # ignore

        my $properties = $schema->{properties};
        unless (ref $properties eq 'HASH') {
            croak sprintf '`properties` must be an object at %s', $context->position
        }

        my $is_valid = 1;
        for my $prop (keys %$properties) {
            unless (exists $data->{$prop}) {
                my $definition = $properties->{$prop}->{'$ref'} # resolve ref TODO refactor
                    ? $context->rv->resolve_ref($properties->{$prop}->{'$ref'})
                    : $properties->{$prop};
                if (my $default = $definition->{default}) {
                    # fill in default
                    $data->{$prop} = clone($default);
                    # in case default value applied, skip validation for default value
                    next;
                } elsif ($definition->{required}) {
                    # if required specified and default not exists, it's invalid
                    # TODO check definition. Is it valid existing "default" and "required" in same property???
                    $is_valid=0;
                    last;
                } else {
                    next; # skip on no-required empty
                }
            }

            my $sub_data = $data->{$prop};
            my $sub_schema = $properties->{$prop};
            my $res = $context->in($prop, sub {
                $context->sub_validator($sub_schema)->validate($sub_data, $context);
            });

            if (!$res) {
                $is_valid = 0;
                last;
            }
        }

        $is_valid;
    });
}

1;
