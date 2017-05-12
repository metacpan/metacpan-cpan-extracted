package Valiemon::Attributes::MaxProperties;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);

sub attr_name { 'maxProperties' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    return 1 unless ref $data eq 'HASH'; # ignore

    my $max_properties = $schema->{maxProperties};
    $context->in_attr($class, sub {
        if (!$context->prims->is_integer($max_properties) || !(0 <= $max_properties)) {
            croak sprintf '`maxProperties` must be an integer. This integer must be greater than, or equal to 0 at %s',
                $context->position;
        }
        scalar keys %$data <= $max_properties;
    });
}

1;
