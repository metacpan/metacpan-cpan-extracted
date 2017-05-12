# ABSTRACT: Value Directive for Validation Class Field Definitions

package Validation::Class::Directive::Value;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'        => 1;
has 'field'        => 1;
has 'multi'        => 1;
# ensure most core directives execute before this one
has 'dependencies' => sub {{
    normalization => [qw(
        default
    )],
    validation    => [qw(
        alias
        between
        depends_on
        error
        errors
        filtering
        filters
        label
        length
        matches
        max_alpha
        max_digits
        max_length
        max_sum
        min_alpha
        min_digits
        min_length
        min_sum
        mixin
        mixin_field
        multiples
        name
        options
        pattern
        readonly
        required
        toggle
    )]
}};

sub after_validation {

    my ($self, $proto, $field, $param) = @_;

    # set the field value

    $field->{value} = $param || '';

    return $self;

}

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    # set the field value

    $field->{value} = $param || '';

    return $self;

}

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # set the field value

    $field->{value} = $param || '';

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Value - Value Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 DESCRIPTION

Validation::Class::Directive::Value is a core validation class field directive
that holds the absolute value of the associated field.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
