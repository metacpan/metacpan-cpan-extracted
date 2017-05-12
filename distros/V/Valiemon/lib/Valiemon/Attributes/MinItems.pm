package Valiemon::Attributes::MinItems;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);

sub attr_name { 'minItems' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    return 1 unless ref $data eq 'ARRAY'; # ignore

    my $min_items = $schema->{minItems};
    $context->in_attr($class, sub {
        if (!$context->prims->is_integer($min_items) || !(0 <= $min_items)) {
            croak sprintf '`minItems` must be an integer. This integer must be greater than, or equal to 0 at %s',
                $context->position;
        }
        $min_items <= scalar @$data;
    });
}

1;
