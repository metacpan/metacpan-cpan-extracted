package Valiemon::Attributes::UniqueItems;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use List::MoreUtils qw(any);

sub attr_name { 'uniqueItems' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    return 1 unless ref $data eq 'ARRAY'; # ignore
    return 1 unless $schema->{uniqueItems}; # skip on false

    $context->in_attr($class, sub {
        my $unique_data = [];
        for my $datum (@$data) {
            return 0 if any { $context->prims->is_equal($_, $datum) } @$unique_data;
            push @$unique_data, $datum;
        }
        return 1;
    });
}

1;
