package Valiemon::Attributes::MaxLength;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);

sub attr_name { 'maxLength' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    return 1 unless $context->prims->is_string($data); # ignore

    my $max_length = $schema->{maxLength};
    $context->in_attr($class, sub {
        if (!$context->prims->is_integer($max_length) || !(0 <= $max_length)) {
            croak sprintf '`maxLength` must be an integer. This integer must be greater than, or equal to, 0 at %s',
                $context->position;
        }
        length $data <= $max_length;
    });
}

1;
