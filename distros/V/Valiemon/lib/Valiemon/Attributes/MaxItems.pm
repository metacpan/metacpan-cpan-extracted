package Valiemon::Attributes::MaxItems;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);

sub attr_name { 'maxItems' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    return 1 unless ref $data eq 'ARRAY'; # ignore

    my $max_items = $schema->{maxItems};
    $context->in_attr($class, sub {
        if (!$context->prims->is_integer($max_items) || !(0 <= $max_items)) {
            croak sprintf '`maxItems` must be an integer. This integer must be greater than, or equal to 0 at %s',
                $context->position;
        }
        scalar @$data <= $max_items;
    });
}

1;
