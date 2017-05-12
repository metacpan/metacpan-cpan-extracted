package Valiemon::Attributes::Items;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use List::MoreUtils qw(all);
use Valiemon;

sub attr_name { 'items' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;
    return 1 unless ref $data eq 'ARRAY'; # ignore

    my $items = $schema->{items};
    if (ref $items eq 'HASH') {
        # schema
        return $context->in_attr($class, sub {
            my $idx = 0;
            my $sub_v = $context->sub_validator($items);
            all {
                $context->in($idx, sub { $sub_v->validate($_, $context) });
                $idx += 1;
            } @$data;
        });
    } elsif (ref $items eq 'ARRAY') {
        # index base
        return $context->in_attr($class, sub {
            my $is_valid = 1;
            for (my $i = 0; $i < @$items; $i++) {
                my $v = $context->in($i, sub {
                    $context->sub_validator($items->[$i])->validate($data->[$i], $context);
                });
                unless ($v) {
                    $is_valid = 0;
                    last;
                }
            }
            $is_valid;
        });
    } else {
        croak 'invalid `items` definition';
    }
}

1;
