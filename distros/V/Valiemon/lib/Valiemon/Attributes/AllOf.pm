package Valiemon::Attributes::AllOf;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use List::MoreUtils qw(all);

sub attr_name { 'allOf' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    my $allOf = $schema->{allOf};
    $context->in_attr($class, sub {
        if (ref $allOf ne 'ARRAY' || scalar @$allOf < 1) {
            croak sprintf '`allOf` must be an array and have at least one element at %s', $context->position
        }

        my $idx = 0;
        all {
            my $sub_v = $context->sub_validator($_);
            $context->in($idx++, sub { $sub_v->validate($data, $context); });
        } @$allOf;
    });
}

1;
