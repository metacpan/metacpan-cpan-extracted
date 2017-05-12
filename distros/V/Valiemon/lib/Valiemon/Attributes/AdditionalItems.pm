package Valiemon::Attributes::AdditionalItems;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use List::MoreUtils qw(all);
use Valiemon;

sub attr_name { 'additionalItems' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;
    return 1 unless ref $data eq 'ARRAY'; # ignore

    my $items = $schema->{items};
    my $additionalItems = $schema->{additionalItems};

    # `additionalItems` works only when `items` is present and its type is array
    return 1 unless ref $items eq 'ARRAY';

    if (ref $additionalItems eq 'HASH') {
        # schema
        return $context->in_attr($class, sub {
            my $idx = 0;
            my $n = scalar @$items;
            my $sub_v = $context->sub_validator($additionalItems);
            all {
                # Initial n items are validated by `items`
                if ($idx >= $n) {
                    $context->in($idx, sub { $sub_v->validate($_, $context) });
                }
                $idx += 1;
            } @$data;
        });
    } elsif (ref $additionalItems eq 'ARRAY') {
        croak sprintf '`additionalItems` must be an object or boolean value at %s.',
            $context->position;
    } else {
        # boolean
        return $context->in_attr($class, sub {
            if (!$context->prims->is_boolean($additionalItems)) {
                croak sprintf '`additionalItems` must be an object or boolean value at %s.',
                    $context->position;
            }
            return 0 if !$additionalItems && (scalar @$data > scalar @$items);
            return 1;
        });
    }
}

1;
