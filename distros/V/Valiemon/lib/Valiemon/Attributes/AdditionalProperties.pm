package Valiemon::Attributes::AdditionalProperties;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use List::MoreUtils qw(all);

sub attr_name { 'additionalProperties' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    return 1 unless ref $data eq 'HASH'; # ignore

    my $additionalProperties = $schema->{additionalProperties};
    return 1 unless defined $additionalProperties;
    return 1 if $additionalProperties;

    my $properties = $schema->{properties};
    $context->in_attr($class, sub {
        all {
            exists $properties->{$_};
        } keys %$data;
    });
}

1;
