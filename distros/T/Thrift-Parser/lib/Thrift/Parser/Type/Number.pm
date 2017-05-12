package Thrift::Parser::Type::Number;

=head1 NAME

Thrift::Parser::Type::Number - Number base class

=head1 DESCRIPTION

This class inherits from L<Thrift::Parser::Type>.  See the docs there for all the usage details.

=cut

use strict;
use warnings;
use Scalar::Util qw(blessed);
use base qw(Thrift::Parser::Type);

use overload '""' => sub { $_[0]->value }, 'eq' => sub { $_[0]->value };

=head1 USAGE

Firstly, you can use objects in this class in string context; the stringification overload will display the number, as you'd expect.

=head2 compose

Call with a signed number.  Throws L<Thrift::Parser::InvalidTypedValue>.

=cut

sub compose {
    my ($class, $value) = @_;

    Thrift::Parser::InvalidTypedValue->throw("'undef' is not valid for $class") if ! defined $value;

    if (blessed $value) {
        if (! $value->isa($class)) {
            Thrift::Parser::InvalidArgument->throw("$class compose() can't take a value of ".ref($value));
        }
        return $value;
    }

    if ($class eq 'Thrift::Parser::Type::double') {
        if ($value !~ m{^-?\d+\.?\d*$}) {
            Thrift::Parser::InvalidTypedValue->throw("Value '$value' is not a float");
        }
    }
    else {
        if ($value !~ m{^-?\d+$}) {
            Thrift::Parser::InvalidTypedValue->throw("Value '$value' is not a signed real number");
        }

        my $bit = sprintf '%d', (log($class->_max_value) / log(2)) + 1;

        Thrift::Parser::InvalidTypedValue->throw("Value '$value' exceeds signed $bit-bit range")
            if abs($value * 1) > $class->_max_value;
    }

    return $class->SUPER::compose($value);
}

sub values_equal {
    my ($class, $value_a, $value_b) = @_;
    return $value_a == $value_b;
}

sub value_plain {
    my $self = shift;
    return $self->value + 0; # ensure that it's a Perl number
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
