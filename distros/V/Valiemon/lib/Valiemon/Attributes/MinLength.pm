package Valiemon::Attributes::MinLength;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);

sub attr_name { 'minLength' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    return 1 unless $context->prims->is_string($data); # ignore

    my $min_length = $schema->{minLength};
    $context->in_attr($class, sub {
        if (!$context->prims->is_integer($min_length) || !(0 <= $min_length)) {
            croak sprintf '`minLength` must be an integer. This integer must be greater than, or equal to, 0 at %s',
                $context->position;
        }
        $min_length <= length $data;
    });
}

1;
