package Valiemon::Attributes::MinProperties;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);

sub attr_name { 'minProperties' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    return 1 unless ref $data eq 'HASH'; # ignore

    my $min_properties = $schema->{minProperties};
    $context->in_attr($class, sub {
        if (!$context->prims->is_integer($min_properties) || !(0 <= $min_properties)) {
            croak sprintf '`minProperties` must be an integer. This integer must be greater than, or equal to 0 at %s',
                $context->position;
        }
        scalar keys %$data >= $min_properties;
    });
}

1;
