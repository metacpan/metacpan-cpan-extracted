package Valiemon::Attributes::Not;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use List::MoreUtils qw(all);

sub attr_name { 'not' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;
    $context->in_attr($class, sub {
        my $not = $schema->{not};
        unless (ref $not eq 'HASH') {
            croak sprintf '`not` must be an object at %s', $context->position
        }
        my $sub_v = $context->sub_validator($not);
        my $res = $sub_v->validate($data);
        return !$res;
    });
}

1;
