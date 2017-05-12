package Thrift::Parser::Type::bool;

=head1 NAME

Thrift::Parser::Type::bool - bool type

=cut

use strict;
use warnings;
use base qw(Thrift::Parser::Type);
use Scalar::Util qw(blessed);
use JSON::XS;

=head1 USAGE

Stringification is overloaded to the values 'true' or 'false'.

When composing, the value doesn't matter; it will be evaluated in boolean context to determine the value here.

=cut

use overload '""' => sub { $_[0]->value ? 'true' : 'false' };

sub values_equal {
    my ($class, $value_a, $value_b) = @_;
    return $value_a && $value_b;
}

sub compose {
    my ($class, $value) = @_;

    if (ref $value && blessed($value) && $value->isa('JSON::XS::Boolean')) {
        $value = $value == JSON::XS::true ? 1 : 0;
    }

    return $class->SUPER::compose($value);
}

=head2 is_true

Returns 1 if is true, 0 otherwise.

=cut

sub is_true  { return $_[0]->value ? 1 : 0 }

=head2 is_false

Returns 1 if is false, 0 otherwise.

=cut

sub is_false { return $_[0]->value ? 0 : 1 }

sub value_plain {
    my $self = shift;
    return $self->value ? 1 : 0;
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
