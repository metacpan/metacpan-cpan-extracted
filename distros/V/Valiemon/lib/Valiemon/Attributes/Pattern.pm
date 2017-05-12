package Valiemon::Attributes::Pattern;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);

sub attr_name { 'pattern' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    return 1 unless $context->prims->is_string($data);

    $context->in_attr($class, sub {
        my $pattern = $schema->{pattern};

        unless ($context->prims->is_string($pattern)) {
            croak sprintf '`pattern` must be a string at %s', $context->position
        }

        $data =~ /$pattern/ ? 1 : 0;
    });
}

1;
