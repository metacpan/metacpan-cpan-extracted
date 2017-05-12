package Valiemon::Attributes::Enum;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use List::MoreUtils qw(any);

sub attr_name { 'enum' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    my $enum = $schema->{enum};
    $context->in_attr($class, sub {
        if (ref $enum ne 'ARRAY' || scalar @$enum < 1) {
            croak sprintf '`enum` must be an array and have at leas one element at %s', $context->position
        }

        any { $context->prims->is_equal($data, $_) } @$enum;
    });
}

1;
