package Valiemon::Attributes::Ref;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);

sub attr_name { '$ref' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;
    my $ref = $schema->{'$ref'};
    my $sub_schema = $context->rv->resolve_ref($ref);

    $context->in_attr($class, sub {
        $context->sub_validator($sub_schema)->validate($data, $context);
    });
}

1;
