# ABSTRACT: Between Directive for Validation Class Field Definitions

package Validation::Class::Directive::Between;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 1;
has 'message' => '%s must contain between %s characters';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{between} && defined $param) {

        my $between = $field->{between};

        if ( $field->{required} || $param ) {

            my ( $min, $max )
                = isa_arrayref($between)
                ? @{$between} > 1
                ? @{$between}
                : (split /(?:\s{1,})?\D{1,}(?:\s{1,})?/, $between->[0])
                : (split /(?:\s{1,})?\D{1,}(?:\s{1,})?/, $between);

            $min = scalar($min);
            $max = scalar($max);

            my $value = length($param);

            unless ( $value >= $min && $value <= $max ) {

                $self->error(@_, "$min-$max");

            }

        }

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Between - Between Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            person_age  => {
                between => '18-95'
            }
        }
    );

    # set parameters to be validated
    $rules->params->add($parameters);

    # validate
    unless ($rules->validate) {
        # handle the failures
    }

=head1 DESCRIPTION

Validation::Class::Directive::Between is a core validation class field directive
that provides the ability to validate the numeric range of the associated
parameters.

=over 8

=item * alternative argument: an-array-of-numbers

This directive can be passed a single value or an array of values:

    fields => {
        person_age  => {
            between => [18, 95]
        }
    }

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
