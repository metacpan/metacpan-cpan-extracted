package Valiemon::Attributes::OneOf;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use List::MoreUtils qw(one);

use Valiemon::Context;

sub attr_name { 'oneOf' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    my $oneOf = $schema->{oneOf};
    if (ref $oneOf ne 'ARRAY' || scalar @$oneOf < 1) {
        croak sprintf '`oneOf` must be an array and have at least one element at %s', $context->position
    }

    $context->in_attr($class, sub {
        one {
            my $clone_context = Valiemon::Context->clone_from($context);
            $clone_context->sub_validator($_)->validate($data, $clone_context);
        } @$oneOf;
    });
}

1;
