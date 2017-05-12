package Valiemon::Attributes::AnyOf;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use List::MoreUtils qw(any);

use Valiemon::Context;

sub attr_name { 'anyOf' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    my $anyOf = $schema->{anyOf};
    if (ref $anyOf ne 'ARRAY' || scalar @$anyOf < 1) {
        croak sprintf '`anyOf` must be an array and have at least one element at %s', $context->position
    }

    $context->in_attr($class, sub {
        any {
            my $clone_context = Valiemon::Context->clone_from($context);
            $clone_context->sub_validator($_)->validate($data, $clone_context);
        } @$anyOf;
    });
}

1;
