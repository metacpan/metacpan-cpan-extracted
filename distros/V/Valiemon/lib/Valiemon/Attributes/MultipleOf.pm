package Valiemon::Attributes::MultipleOf;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);

sub attr_name { 'multipleOf' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    return 1 unless $context->prims->is_number($data); # skip on non-number value

    my $attr_name = $class->attr_name();
    my $multiple_of = $schema->{$attr_name};
    $context->in_attr($class, sub {
        if (!$context->prims->is_number($multiple_of) || !(0 < $multiple_of)) {
            croak sprintf '`%s` must be a number. This number must be greater than 0 at %s',
                $attr_name, $context->position;
        }
        $context->prims->is_integer($data/$multiple_of);
    });
}

1;
